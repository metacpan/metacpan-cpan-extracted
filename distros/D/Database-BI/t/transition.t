#!/usr/bin/env perl

# State transition tests for the two state machines documented in the POD: the
# lifecycle of a DataSource, and the geocoder load state and value-level states
# of Geocode.
#
# Neither object has a state field, so a state is what can be seen from outside:
# whether the backend was read, whether the cache was asked, what is held on the
# object.  Each path through a diagram gets a subtest named after it, which records
# the path as covered.  The compliance subtests at the end read the paths out of
# the POD and compare, in both directions, so that a path added to a diagram fails
# here until it has a test, and a tested path removed from one fails too.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Response;
use Readonly;
use Scalar::Util qw(blessed weaken);
use Test::Mockingbird qw(around mock_scoped restore_all);
use Test::Mojo;
use Test::Most;

# DataSource must be loaded through the app first: see the note in t/unit.t.
my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

require DBI;
require Database::Abstraction;
require Database::BI::Model::DataSource;
require Database::BI::Model::Geocode;
require LWP::UserAgent;
require Net::SFTP::Foreign;

Readonly my $DS       => 'Database::BI::Model::DataSource';
Readonly my $GEOCODE  => 'Database::BI::Model::Geocode';
Readonly my $BACKEND  => 'Database::Abstraction';
Readonly my $GCF      => 'Geo::Coder::Free';
Readonly my $GCF_FILE => 'Geo/Coder/Free.pm';
# Geocode puts Geo::Coder::Free in a Geo::Coder::List.  The transitions here are
# about the local geocoder, so the list is a stand-in too, whether or not the
# real one is installed (CI installs no recommended modules).
Readonly my $GCL_FILE => 'Geo/Coder/List.pm';

# The states of DataSource, as the diagram spells them.
Readonly my $START         => '[START]';
Readonly my $INITIALISING  => 'INITIALISING';
Readonly my $ERROR         => 'ERROR';
Readonly my $FETCH_ERROR   => 'FETCH ERROR';
Readonly my $READY         => 'READY';
Readonly my $FETCHING      => 'FETCHING';
Readonly my $DATA_RETURNED => 'DATA RETURNED';
Readonly my $CACHE_CHECK   => 'CACHE CHECK';
Readonly my $DESTROY       => 'DESTROY';

# The states of Geocode.
Readonly my $CONSTRUCTED       => 'CONSTRUCTED';
Readonly my $UNAVAILABLE       => 'UNAVAILABLE';
Readonly my $RECEIVED          => 'RECEIVED';
Readonly my $ATTEMPT           => 'ATTEMPT';
Readonly my $SKIPPED           => 'SKIPPED';
Readonly my $CACHED_RESOLVED   => 'CACHED_RESOLVED';
Readonly my $CACHED_UNRESOLVED => 'CACHED_UNRESOLVED';
Readonly my $NOT_ATTEMPTED     => 'NOT_ATTEMPTED';
Readonly my $EXCEPTION         => 'EXCEPTION';
Readonly my $RESOLVED_NEW      => 'RESOLVED_NEW';
Readonly my $UNRESOLVED_NEW    => 'UNRESOLVED_NEW';

Readonly my $TABLE       => 'sales';
Readonly my $HEADER      => "name,value\n";
Readonly my $CSV_TEXT    => "name,value\nA,1\n";
Readonly my $ROWS        => [ { name => 'A', value => 1 } ];
Readonly my $URL         => 'http://example.com/page/table.html';
Readonly my $URL_TTL     => '15 min';
Readonly my $UNUSED_PORT => 'redis://127.0.0.1:1';
Readonly my $REMOTE_DIR  => '/remote';
Readonly my $REMOTE_HOST => 'h.example';
Readonly my $BDB_MAGIC   => 0x00061561;
Readonly my $BDB_PADDING => 60;

Readonly my $HIGH_VERSION => '99';
Readonly my $LOW_VERSION  => '1';
Readonly my $LAT          => 51.5;
Readonly my $LON          => -0.1;
Readonly my $PLACE        => 'Ramsgate';
Readonly my $OTHER_PLACE  => 'Margate';
Readonly my $THIRD_PLACE  => 'Deal';
Readonly my $REFUSED      => 'refused by the rule';
Readonly my $LOST         => 'found by no one';
Readonly my $CAP          => 2;

# ---------------------------------------------------------------------------
# Stand-ins
# ---------------------------------------------------------------------------
{
	package Local::Cache;

	sub new { return bless { store => {}, sets => [], gets => 0 }, shift }
	sub get { my ($self, $key) = @_; $self->{gets}++; return $self->{store}{$key} }
	sub set {
		my ($self, @args) = @_;
		push @{ $self->{sets} }, \@args;
		$self->{store}{ $args[0] } = $args[1];
		return;
	}
}
{
	# Serves files by remote path, as Net::SFTP::Foreign's get does.
	package Local::SFTP;

	my %files;
	sub serve { my ($class, %serve) = @_; %files = %serve; return }
	sub new   { return bless {}, shift }
	sub error { return 0 }
	sub get {
		my ($self, $remote, $local) = @_;
		return unless exists $files{$remote};
		open my $fh, '>', $local or die "$local: $!";
		print {$fh} $files{$remote};
		close $fh or die "$local: $!";
		return 1;
	}
}
{
	# A geocoder that says what it was asked.  It knows the places in `known`,
	# refuses $REFUSED through valid_location, and dies if told to.
	package Local::Geocoder;

	sub new { my ($class, %args) = @_; return bless { asked => [], valid => [], %args }, $class }
	sub valid_location {
		my ($self, $value) = @_;
		die "rule failure\n" if $self->{rule_dies};
		push @{ $self->{valid} }, $value;
		return $value ne ($self->{refuse} // '');
	}
	sub geocode_many {
		my ($self, $values, %opts) = @_;
		die "geocoder failure\n" if $self->{dies};
		push @{ $self->{asked} }, [ @{$values} ];
		$self->{opts} = \%opts;
		return { map { $_ => $self->{known}{$_} } @{$values} };
	}
}
{
	# Geo::Coder::List as far as building one goes: new() and push(), which
	# returns the list so that calls chain.
	package Local::FakeList;

	sub new  { my ($class, %args) = @_; return bless { %args, geocoders => [] }, $class }
	sub push { my ($self, $geocoder) = @_; push @{ $self->{geocoders} }, $geocoder; return $self }
}
{
	# Has neither method a geocoder needs.
	package Local::NotAGeocoder;

	sub new { return bless {}, shift }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# The paths tested so far, by module, then the value-level paths of Geocode.
my %covered;
my %value_covered;
my $machine = $DS;

# A documented path: the subtest is named after it, and it counts as covered.
sub _transition {
	my ($from, $trigger, $to, $code) = @_;
	$covered{$machine}{"$from -> $to"}++;
	return subtest "State: $from -> Trigger: $trigger -> State: $to" => $code;
}

# A documented path for one value in one Geocode call.  The trigger is the text in
# the diagram's brackets.
sub _value_transition {
	my ($from, $trigger, $to, $code) = @_;
	$value_covered{"$from -> [$trigger] -> $to"}++;
	return subtest "State: $from -> Trigger: $trigger -> State: $to" => $code;
}

# A path that must not exist.
sub _illegal {
	my ($from, $trigger, $to, $code) = @_;
	return subtest "Illegal: $from -> Trigger: $trigger -> State: $to" => $code;
}

# The =head1 STATE DIAGRAM section of a module.
sub _diagram_of {
	my ($module) = @_;
	(my $file = "$module.pm") =~ s{::}{/}g;
	open my $fh, '<', $INC{$file} or die "$INC{$file}: $!";
	my $text = do { local $/ = undef; <$fh> };
	close $fh or die "$INC{$file}: $!";
	my ($section) = $text =~ /^=head1 STATE DIAGRAM\n(.*?)^=head1 /ms;
	return $section // '';
}

# The paths in the "Valid state transitions summary" of a diagram.
sub _summary_paths {
	my ($module) = @_;
	my ($summary) = _diagram_of($module) =~ /Valid state transitions summary:\n\n(.*?)\n\n/s;
	my %paths;
	for my $line (split /\n/, $summary // '') {
		next unless $line =~ /\A\s*(\[?[A-Z][A-Z \/]*\]?)\s+->\s+([A-Z][A-Z ]*?)\s+\(/;
		my ($from, $to) = ($1, $2);
		$from =~ s/\s+\z//;
		$paths{"$_ -> $to"} = 1 for split m{\s*/\s*}, $from;
	}
	return \%paths;
}

# The exact text an error starts with.
sub _error_re {
	my ($key, @args) = @_;
	my $text = Database::BI::Model::DataSource::_fmt($key, @args);
	return qr/\A\Q$text\E/;
}

sub _write_file {
	my ($dir, $name, $text) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>:raw', $path or die "$path: $!";
	print {$fh} $text;
	close $fh or die "$path: $!";
	return $path;
}

# A fresh directory holding one file: two files with one stem are one table.
sub _dir_with {
	my ($name, $text) = @_;
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $name, $text);
	return $dir;
}

# A SQLite file with the given tables, each holding one row naming its table.
sub _sqlite {
	my ($dir, $stem, @tables) = @_;
	my $dbh = DBI->connect('dbi:SQLite:dbname=' . File::Spec->catfile($dir, "$stem.sqlite"), '', '',
		{ RaiseError => 1, PrintError => 0 });
	for my $table (@tables) {
		$dbh->do(qq{CREATE TABLE "$table" (label TEXT)});
		$dbh->do(qq{INSERT INTO "$table" VALUES ('in $table')});
	}
	return $dbh;
}

# Counts every call of a method or function, and otherwise leaves it alone.  The
# wrapper goes when restore_all() is called.
sub _count_calls {
	my ($package, $method) = @_;
	my $count = 0;
	around($package, $method, sub {
		my ($orig, @args) = @_;
		$count++;
		return $orig->(@args);
	});
	return \$count;
}

# A ready source over one CSV, and a count of its reads of the backend.
sub _counted_source {
	my (%args) = @_;
	my $reads = _count_calls($BACKEND, 'selectall_hashref');
	my $src   = $DS->new(directory => _dir_with("$TABLE.csv", $CSV_TEXT), table => $TABLE, %args);
	return ($src, $reads);
}

# Take a source to FETCH ERROR.
sub _fail_a_fetch {
	my ($src) = @_;
	my $guard = mock_scoped($BACKEND, selectall_hashref => sub { die "backend failure\n" });
	throws_ok { $src->fetch_all } qr/backend failure/, 'the fetch failed';
	return;
}

# Run some code and answer what it warned, then what it answered., then what it answered.
sub _quietly {
	my ($code) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @result = $code->();
	return (\@warnings, @result);
}

# Stand in for the default geocoder module's constructor.  The caller makes the
# module look present with `local`, which cannot be done from in here because it
# would end with this sub.
sub _install_fake_gcf {
	my ($made) = @_;
	no warnings qw(redefine once);
	no strict 'refs';
	*{"${GCF}::new"} = sub { ${$made}++; return Local::Geocoder->new(known => {}) };
	return;
}

my $ABSENT_HOOK = sub {
	my (undef, $file) = @_;
	die "Can't locate $file in \@INC (hidden by this test)\n" if $file eq $GCF_FILE;
	return;
};

# ===========================================================================
# DataSource: creating one
# ===========================================================================

_transition($START, 'new() invoked', $INITIALISING, sub {
	# Side effects: _init_backend runs once, and it runs _detect_file_info.  The
	# constructor does no more than that: no row is read until someone asks.
	my $inits   = _count_calls($DS, '_init_backend');
	my $detects = _count_calls($DS, '_detect_file_info');
	my ($src, $reads) = _counted_source();

	is(${$inits},   1, 'the backend is set up once');
	is(${$detects}, 1, 'and the file is looked at once');
	is(${$reads},   0, 'and no row has been read');
	isa_ok($src, $DS);
	restore_all();
});

_transition($INITIALISING, 'all checks passed', $READY, sub {
	my ($src, $reads) = _counted_source();

	isa_ok($src, $DS, 'new answers the object');
	ok(blessed($src->{_db}), 'it holds a backend');
	like($src->{_file_path}, qr/\Q$TABLE\E\.csv\z/, 'and knows its file');
	is($src->table_name, $TABLE, 'and its name');
	is_deeply($src->columns, [qw(name value)], 'and its columns, without a read');
	is(${$reads}, 0, 'READY is stable until a fetch');
	restore_all();
});

_transition($INITIALISING, 'croak on bad args', $ERROR, sub {
	my $good_dir = _dir_with("$TABLE.csv", $CSV_TEXT);

	throws_ok { $DS->new(directory => $good_dir) } _error_re('error_table_required'), 'no table';
	throws_ok { $DS->new(directory => File::Spec->catdir($good_dir, 'absent'), table => $TABLE) }
		_error_re('error_directory_missing', File::Spec->catdir($good_dir, 'absent')), 'no directory';
	throws_ok { $DS->new(directory => $good_dir, table => '../up') }
		_error_re('error_table_name_invalid', '../up'), 'a table name that climbs out';
	throws_ok { $DS->new(url => 'ftp://example.com/x') }
		_error_re('error_url_invalid', 'ftp://example.com/x'), 'a URL that is not http';
	throws_ok { $DS->new(redis => 'http://example.com') }
		_error_re('error_redis_invalid', 'http://example.com'), 'a Redis address that is not one';
	throws_ok { $DS->new(redis => $UNUSED_PORT) } _error_re('error_table_required'), 'Redis with no table';
});

_transition($INITIALISING, 'no safe id', $ERROR, sub {
	my $dir = _dir_with('words.csv', "First Name,Last Name\nA,B\n");
	throws_ok { $DS->new(directory => $dir, table => 'words') } _error_re('error_no_safe_id', 'words'),
		'a header with no name usable as an id';
});

_transition($INITIALISING, 'no SQLite tables', $ERROR, sub {
	my $dir = tempdir(CLEANUP => 1);
	my $dbh = _sqlite($dir, 'hollow', 'gone');
	$dbh->do('DROP TABLE gone');
	$dbh->disconnect;
	throws_ok { $DS->new(directory => $dir, table => 'hollow') } _error_re('error_no_tables', 'hollow'),
		'a database with nothing in it';

	# A file of no bytes is this case, not the empty-file one.
	my $zero = _dir_with('nothing.sqlite', '');
	throws_ok { $DS->new(directory => $zero, table => 'nothing') } _error_re('error_no_tables', 'nothing'),
		'a SQLite file of no bytes';
});

_transition($INITIALISING, 'unopenable database', $ERROR, sub {
	my $dir = _dir_with('broken.db', pack('N', $BDB_MAGIC) . ('x' x $BDB_PADDING));
	throws_ok { $DS->new(directory => $dir, table => 'broken') } _error_re('error_unsupported_db', 'broken'),
		'it is refused rather than read as text';
});

_transition($INITIALISING, 'SFTP failure', $ERROR, sub {
	my $guard = mock_scoped('Net::SFTP::Foreign', new => sub { return Local::SFTP->new });
	Local::SFTP->serve();
	throws_ok { $DS->new(directory => $REMOTE_DIR, table => $TABLE, host => $REMOTE_HOST) }
		qr/could not fetch any supported file from \Q$REMOTE_HOST\E/, 'nothing to download';
});

# ===========================================================================
# DataSource: fetching without a cache
# ===========================================================================

_transition($READY, 'fetch_all, no cache', $FETCHING, sub {
	my ($src, $reads) = _counted_source();
	$src->fetch_all;
	is(${$reads}, 1, 'the backend is read');
	restore_all();
});

_transition($READY, 'a narrowed query, with a cache', $FETCHING, sub {
	# Not the whole table, so it is neither looked up nor stored.
	my $cache = Local::Cache->new;
	my ($src) = _counted_source(cache => $cache);

	my $rows = $src->selectall_arrayref({ name => 'A' });
	is($rows->[0]{name}, 'A', 'the query is answered');
	is($cache->{gets}, 0, 'without asking the cache');
	is_deeply($cache->{sets}, [], 'or storing in it');
	restore_all();
});

_transition($FETCHING, 'backend answered', $DATA_RETURNED, sub {
	my ($src) = _counted_source();
	is_deeply($src->fetch_all, $ROWS, 'fetch_all answers an array of rows');
	is_deeply($src->selectall_arrayref, $ROWS, 'and so does selectall_arrayref');
	restore_all();

	# The one exception the diagram names: a table with no rows.
	my $header_only = $DS->new(directory => _dir_with("$TABLE.csv", $HEADER), table => $TABLE);
	my ($warnings, $none) = _quietly(sub { return $header_only->fetch_all });
	is_deeply($none, [], 'a table with no rows: fetch_all answers []');
	is(scalar($header_only->selectall_arrayref), undef, 'and selectall_arrayref answers undef');

	my ($full) = _counted_source();
	is(scalar($full->selectall_arrayref({ name => 'no such name' })), undef, 'as it does for a query that matches none');
	restore_all();
});

_transition($FETCHING, 'backend failed', $FETCH_ERROR, sub {
	# Each cause the diagram lists, and in each there is still an object.
	my $cache = Local::Cache->new;
	my ($src) = _counted_source(cache => $cache);
	{
		my $guard = mock_scoped($BACKEND, selectall_hashref => sub { die "backend failure\n" });
		throws_ok { $src->fetch_all } _error_re('error_fetch_failed', $TABLE, "backend failure\n"), 'the backend failing';
	}
	is_deeply($cache->{sets}, [], 'nothing was stored, so the failure cannot be served later');
	restore_all();

	my $no_file = $DS->new(directory => tempdir(CLEANUP => 1), table => $TABLE);
	isa_ok($no_file, $DS, 'a table with no file gets past new()');
	throws_ok { $no_file->fetch_all } qr/\A\QDataSource: fetch_all failed\E/, 'and fails here';

	no warnings qw(redefine once);
	{
		local *LWP::UserAgent::get = sub { return HTTP::Response->new(500, 'Broken') };
		my $unreachable = $DS->new(url => $URL);
		throws_ok { $unreachable->fetch_all } qr/\A\QDataSource: fetch_all failed\E/, 'a URL that cannot be fetched';
	}
	{
		local *LWP::UserAgent::get = sub {
			return HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'application/json' ], '[1,2,3]');
		};
		my $not_rows = $DS->new(url => "$URL.json");
		throws_ok { $not_rows->fetch_all } qr/\A\QDataSource: fetch_all failed\E/, 'a URL that does not answer with rows';
	}
	my $redis = $DS->new(redis => $UNUSED_PORT, table => $TABLE);
	throws_ok { $redis->fetch_all } qr/\A\QDataSource: fetch_all failed\E/, 'a Redis server that cannot be reached';
});

_transition($FETCH_ERROR, 'next call, no cache', $FETCHING, sub {
	my ($src, $reads) = _counted_source();
	_fail_a_fetch($src);
	is_deeply($src->fetch_all, $ROWS, 'the object is not spoilt: the next fetch works');
	is(${$reads}, 1, 'by reading the backend');
	restore_all();
});

_transition($DATA_RETURNED, 'next call, no cache', $FETCHING, sub {
	my ($src, $reads) = _counted_source();
	$src->fetch_all;
	is_deeply($src->fetch_all, $ROWS, 'the second call answers the same rows');
	is(${$reads}, 2, 'and with no cache it read again');
	restore_all();
});

# ===========================================================================
# DataSource: fetching with a cache
# ===========================================================================

_transition($READY, 'a call for the whole table, cache configured', $CACHE_CHECK, sub {
	my $cache = Local::Cache->new;
	my ($src) = _counted_source(cache => $cache);
	is($cache->{gets}, 0, 'a new source has not asked the cache');
	$src->fetch_all;
	is($cache->{gets}, 1, 'fetch_all asks it');
	$src->selectall_arrayref;
	is($cache->{gets}, 2, 'and so does selectall_arrayref with no arguments');
	restore_all();

	# Arguments, but still the whole table, since DataSource does this sort itself.
	my $people = Local::Cache->new;
	my $dir    = _dir_with('people.csv', "First Name,value\nA,1\n");
	my $src2   = $DS->new(directory => $dir, table => 'people', cache => $people);
	$src2->selectall_arrayref(sort_by => 'First Name');
	is($people->{gets}, 1, 'and so does a sort on a column that is not a safe identifier');
	is(scalar @{ $people->{sets} }, 1, 'which stores the table too');
	$src2->selectall_arrayref(sort_by => 'First Name', limit => 1, offset => 0);
	is($people->{gets}, 2, 'and with a page of it, which is cut from the table');
});

_transition($CACHE_CHECK, 'cache miss', $FETCHING, sub {
	my $cache = Local::Cache->new;
	my ($src, $reads) = _counted_source(cache => $cache);
	is_deeply($src->fetch_all, $ROWS, 'a miss answers the rows');
	is(${$reads}, 1, 'by reading the backend');

	# Side effect of FETCHING, as the diagram says: the result is stored.  A file's
	# entry has no time limit, as its key carries the file's time.
	my $path  = $src->{_file_path};
	my $mtime = (stat $path)[9];
	is_deeply($cache->{sets}, [ [ "bi:file:$path:$mtime", $ROWS ] ], 'and the result is stored');

	# A changed file is a new key, so a natural miss.  The object does not go back
	# to INITIALISING for it.
	my $later = $mtime + 60;
	utime $later, $later, $path or die "$path: $!";
	$src->fetch_all;
	is(${$reads}, 2, 'a changed file misses');
	is(scalar @{ $cache->{sets} }, 2, 'and is stored under its new key');
	restore_all();
});

_transition($CACHE_CHECK, 'no key to look under', $FETCHING, sub {
	my $cache = Local::Cache->new;
	my ($src, $reads) = _counted_source(cache => $cache);
	unlink $src->{_file_path} or die "$src->{_file_path}: $!";

	eval { $src->fetch_all };	# whether the backend can still answer is its affair
	is(${$reads}, 1, 'the file having gone, the read goes on to the backend');
	is($cache->{gets}, 0, 'with no lookup');
	is_deeply($cache->{sets}, [], 'and nothing stored');
	restore_all();
});

_transition($CACHE_CHECK, 'cache hit', $DATA_RETURNED, sub {
	my $cache = Local::Cache->new;
	my ($src, $reads) = _counted_source(cache => $cache);
	my $key = $src->_cache_key;
	my $held = [ { name => 'held' } ];
	$cache->{store}{$key} = $held;

	is($src->fetch_all, $held, 'the entry in the cache is what comes back');
	is($src->selectall_arrayref, $held, 'for both ways of asking');
	is(${$reads}, 0, 'the backend is not read');
	is_deeply($cache->{sets}, [], 'and nothing is stored again');
	restore_all();
});

_transition($DATA_RETURNED, 'next call, cache configured', $CACHE_CHECK, sub {
	my $cache = Local::Cache->new;
	my ($src, $reads) = _counted_source(cache => $cache);
	$src->fetch_all;
	is_deeply($src->fetch_all, $ROWS, 'the second call answers the same rows');
	is($cache->{gets}, 2, 'having asked the cache again');
	is(${$reads}, 1, 'and it did not read again');
	restore_all();
});

_transition($FETCH_ERROR, 'next call, cache configured', $CACHE_CHECK, sub {
	my $cache = Local::Cache->new;
	my ($src, $reads) = _counted_source(cache => $cache);
	_fail_a_fetch($src);
	is($cache->{gets}, 1, 'the failed read asked the cache');
	is_deeply($src->fetch_all, $ROWS, 'and the next one works');
	is($cache->{gets}, 2, 'having asked it again');
	is(scalar @{ $cache->{sets} }, 1, 'and it stores the rows this time');
	restore_all();
});

subtest 'URL and Redis sources are not touched by INITIALISING' => sub {
	# new() reaches READY with no request made and no file looked at.  The URL is
	# fetched by the first read, which stores the rows with the TTL, since a URL has
	# no time of its own to key on.  The second read is a hit.
	my $requests = 0;
	my $detects  = _count_calls($DS, '_detect_file_info');
	no warnings qw(redefine once);
	local *LWP::UserAgent::get = sub {
		$requests++;
		return HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/html' ],
			'<html><body><table><tr><th>name</th></tr><tr><td>A</td></tr></table></body></html>');
	};
	my $cache = Local::Cache->new;
	my $src   = $DS->new(url => $URL, cache => $cache);
	is($requests, 0, 'new() makes no request');
	is_deeply($src->fetch_all, [ { name => 'A' } ], 'the first read gets the page and its rows');
	is($requests, 1, 'with one request');
	is_deeply($cache->{sets}, [ [ "bi:url:$URL:0", [ { name => 'A' } ], $URL_TTL ] ], 'stored with a time limit');
	$src->fetch_all;
	is($requests, 1, 'and the next read is a hit');

	isa_ok($DS->new(redis => $UNUSED_PORT, table => $TABLE), $DS, 'a Redis source needs no server to be READY');
	is(${$detects}, 0, 'and neither looked at a file');
	restore_all();
};

# ===========================================================================
# DataSource: the special cases branching from INITIALISING
# ===========================================================================

_transition($READY, 'an empty file', $DATA_RETURNED, sub {
	# Special case 1.  The fast path: an answer of [] with no backend, no warning and
	# no cache.  A blank first line is the same as no bytes at all.
	for my $ext (qw(csv tsv psv)) {
		for my $text ('', "\n") {
			my $cache = Local::Cache->new;
			my $dir   = _dir_with("$TABLE.$ext", $text);
			my $src   = $DS->new(directory => $dir, table => $TABLE, cache => $cache);

			ok($src->{_file_is_empty}, "$ext: the flag is set");
			is($src->{_db}, undef, 'and there is no backend to read');
			my ($warnings, $rows) = _quietly(sub { return $src->fetch_all });
			is_deeply($rows, [], 'fetch_all answers no rows');
			is_deeply($warnings, [], 'without a warning');
			is_deeply($src->selectall_arrayref, [], 'and so does selectall_arrayref');
			is($cache->{gets}, 0, 'and without asking the cache');
			is($src->count, 0, 'and there are 0 of them');
		}
	}

	SKIP: {
		eval { require Excel::Writer::XLSX; 1 } or skip 'Excel::Writer::XLSX is not installed', 1;
		my $dir = tempdir(CLEANUP => 1);
		my $wb  = Excel::Writer::XLSX->new(File::Spec->catfile($dir, "$TABLE.xlsx"));
		$wb->add_worksheet;
		$wb->close;
		ok($DS->new(directory => $dir, table => $TABLE)->{_file_is_empty}, 'a blank worksheet is the same');
	}
});

_transition($DATA_RETURNED, 'next call, an empty file', $DATA_RETURNED, sub {
	my $src = $DS->new(directory => _dir_with("$TABLE.csv", ''), table => $TABLE);
	for my $call (1, 2) {
		is_deeply($src->fetch_all, [], "call $call answers no rows");
	}
	is($src->{_db}, undef, 'and still has no backend');
});

subtest 'Special case 2: a header-less file becomes a copy with a header' => sub {
	my %separator = (csv => ',', tsv => "\t", psv => '|');
	for my $ext (sort keys %separator) {
		my $dir = _dir_with("bank.$ext", join($separator{$ext}, '2026-01-02', '12.50', 'Two words') . "\n");
		my $src = $DS->new(directory => $dir, table => 'bank');

		ok(-d "$src->{_headerless_tmpdir}", "$ext: the copy is in a temporary directory");
		is_deeply($src->columns, [qw(Date Amount Description)], 'its columns are made up');
		my ($row) = @{ $src->fetch_all };
		is($row->{Description}, 'Two words', 'and its rows are read from the copy');
	}
};

subtest 'Special case 3: a SQLite file, no table named' => sub {
	# READY with the list held, and no fetch needed to see it: a caller can look at
	# the list and go elsewhere.  A fetch opens the table chosen automatically.
	my $dir = tempdir(CLEANUP => 1);
	_sqlite($dir, 'shop', qw(orders customers))->disconnect;

	my $reads = _count_calls($BACKEND, 'selectall_hashref');
	my $src   = $DS->new(directory => $dir, table => 'shop');
	is_deeply([ sort @{ $src->sqlite_tables } ], [qw(customers orders)], 'the tables are listed');
	is(${$reads}, 0, 'with nothing read');
	is_deeply($src->fetch_all, [ { label => 'in customers' } ], 'a fetch opens the first by name');
	restore_all();

	_sqlite($dir, 'named', qw(first named))->disconnect;
	is_deeply($DS->new(directory => $dir, table => 'named')->fetch_all, [ { label => 'in named' } ],
		'or the one named after the file');
};

subtest 'Special case 4: a SQLite file, one table named' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_sqlite($dir, 'shop', qw(orders customers))->disconnect;

	my $src = $DS->new(directory => $dir, table => 'shop', internal_table => 'orders');
	ok(-l File::Spec->catfile("$src->{_tmpdir}", 'orders.sqlite'), 'a symlink for the named table');
	is_deeply($src->fetch_all, [ { label => 'in orders' } ], 'a fetch opens that table');

	throws_ok { $DS->new(directory => $dir, table => 'shop', internal_table => 'absent') }
		_error_re('error_table_not_found', 'shop', 'absent'), 'a table it does not have goes to ERROR';

	my $odd = tempdir(CLEANUP => 1);
	_sqlite($odd, 'mixed', 'fine', 'odd name')->disconnect;
	throws_ok { $DS->new(directory => $odd, table => 'mixed', internal_table => 'odd name') }
		qr/odd name/, 'and so does one with an unsafe name';

	# The name of the file: nothing to link.
	_sqlite($dir, 'same', qw(same other))->disconnect;
	my $same = $DS->new(directory => $dir, table => 'same', internal_table => 'same');
	is($same->{_tmpdir}, undef, 'a table named after the file needs no symlink');
	is_deeply([ sort @{ $same->sqlite_tables } ], [qw(other same)], 'and its tables are listed');
	is_deeply($same->fetch_all, [ { label => 'in same' } ], 'and it is opened');
};

subtest 'Special case 5: an SFTP file' => sub {
	# Downloaded to a directory the object keeps alive, then normal from there on.
	my $guard = mock_scoped('Net::SFTP::Foreign', new => sub { return Local::SFTP->new });
	Local::SFTP->serve("$REMOTE_DIR/$TABLE.csv" => $CSV_TEXT);

	my $src = $DS->new(directory => $REMOTE_DIR, table => $TABLE, host => $REMOTE_HOST);
	my $tmp = "$src->{_remote_tmpdir}";
	ok(-d $tmp, 'the download directory is kept');
	is_deeply($src->fetch_all, $ROWS, 'and the copy in it is read');

	undef $src;
	ok(!-d $tmp, 'until the object is destroyed');
};

# ===========================================================================
# DataSource: the end
# ===========================================================================

_transition($READY, 'out of scope', $DESTROY, sub {
	my $src = $DS->new(directory => _dir_with('my data.csv', $CSV_TEXT), table => 'my data');
	my $tmp = "$src->{_tmpdir}";
	ok(-l File::Spec->catfile($tmp, 'my_data.csv'), 'a symlink is held');

	my $weak = $src;
	weaken($weak);
	undef $src;
	is($weak, undef, 'nothing else holds the object');
	ok(!-d $tmp, 'and its temporary directory went with it');
});

_transition($DATA_RETURNED, 'out of scope', $DESTROY, sub {
	my $src = $DS->new(directory => _dir_with('my data.csv', $CSV_TEXT), table => 'my data');
	my $tmp = "$src->{_tmpdir}";
	my $rows = $src->fetch_all;

	undef $src;
	ok(!-d $tmp, 'the temporary directory is removed');
	is_deeply($rows, $ROWS, 'and the rows already answered are still good');
});

_transition($FETCH_ERROR, 'out of scope', $DESTROY, sub {
	my $src = $DS->new(directory => _dir_with('my data.csv', $CSV_TEXT), table => 'my data');
	my $tmp = "$src->{_tmpdir}";
	_fail_a_fetch($src);

	undef $src;
	ok(!-d $tmp, 'the temporary directory is removed');
});

# ===========================================================================
# DataSource: paths the diagram does not have
# ===========================================================================

_illegal($START, 'fetch_all with no object', $FETCHING, sub {
	# Nothing can be fetched without going through new().
	throws_ok { $DS->fetch_all } qr/strict refs/, 'fetch_all on the class';
	throws_ok { $DS->selectall_arrayref } qr/strict refs/, 'selectall_arrayref on the class';
	throws_ok { $DS->count } qr/strict refs/, 'count on the class';
});

_illegal($ERROR, 'carry on regardless', $READY, sub {
	# ERROR is terminal: no object escapes, so there is nothing to carry on with.
	my $dir = _dir_with('words.csv', "First Name,Last Name\nA,B\n");
	my $src = eval { $DS->new(directory => $dir, table => 'words') };
	ok($@, 'new failed');
	is($src, undef, 'and no object came out of it');

	# Nor does the failure stay behind: the next object over a good file starts afresh.
	_write_file($dir, 'words.csv', "first,last\nA,B\n");
	my $fixed = $DS->new(directory => $dir, table => 'words');
	is_deeply($fixed->fetch_all, [ { first => 'A', last => 'B' } ], 'a new object is unaffected');
});

_illegal($READY, 'any read', $INITIALISING, sub {
	# Once READY a source stays set up.  A fetch does not set it up again, even
	# when the file underneath has changed.
	my $inits   = _count_calls($DS, '_init_backend');
	my $detects = _count_calls($DS, '_detect_file_info');
	my ($src) = _counted_source(cache => Local::Cache->new);

	my $path  = $src->{_file_path};
	my $later = (stat $path)[9] + 60;
	$src->fetch_all;
	utime $later, $later, $path or die "$path: $!";
	$src->fetch_all;
	$src->selectall_arrayref;
	$src->columns;
	$src->count;

	is(${$inits},   1, 'the backend was set up only once');
	is(${$detects}, 1, 'and the file was looked at only once');
	restore_all();
});

_illegal($READY, 'calling _init_backend from outside', $INITIALISING, sub {
	# The one way to force it is refused.  HARNESS_ACTIVE turns the protection off, so
	# this runs in a child without it, and the source must still read afterwards.
	my $dir = _dir_with("$TABLE.csv", $CSV_TEXT);
	my $program = <<'END_PROGRAM';
use Database::BI::Model::DataSource;
my ($dir, $table) = @ARGV;
my $src = Database::BI::Model::DataSource->new(directory => $dir, table => $table);
my $ok  = eval { $src->_init_backend; 1 };
print $ok ? "ALLOWED\n" : "REFUSED\n";
print scalar(@{ $src->fetch_all }), " rows\n";
END_PROGRAM

	delete local $ENV{HARNESS_ACTIVE};
	my @lib = map { "-I$_" } grep { !ref } @INC;
	# From a file: Windows does not pass a program of several lines through -e.
	my $script = File::Spec->catfile(tempdir(CLEANUP => 1), 'child.pl');
	Mojo::File->new($script)->spew($program);
	open my $child, '-|', $^X, @lib, $script, $dir, $TABLE or die "$^X: $!";
	my @output = <$child>;
	close $child;

	is_deeply(\@output, [ "REFUSED\n", "1 rows\n" ], 'it is refused, and the object is unharmed');
});

# ===========================================================================
# Geocode: the load state
# ===========================================================================

$machine = $GEOCODE;

_transition($START, 'new() given a geocoder', $READY, sub {
	my $loads    = _count_calls($GEOCODE, '_load_geocoder');
	my $geocoder = Local::Geocoder->new;
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);
	is($geocode->{_geocoder}, $geocoder, 'it holds the geocoder');
	my ($available) = $geocode->geocoder_available;
	is($available, 1, 'and is available');
	is(${$loads}, 0, 'with nothing loaded');
	restore_all();
});

_transition($START, 'new() refuses its arguments', $ERROR, sub {
	for my $bad (Local::NotAGeocoder->new, 'not an object') {
		my $geocode = eval { $GEOCODE->new(geocoder => $bad) };
		ok($@, 'a geocoder that cannot answer is refused');
		is($geocode, undef, 'and no object comes out of it');
	}
	throws_ok { $GEOCODE->new(geocoder => Local::NotAGeocoder->new) } qr/valid_location/, 'it says what is missing';
});

_transition($START, 'new() with no geocoder', $CONSTRUCTED, sub {
	# Nothing is loaded until it is needed, so the application starts without it.
	my $loads = _count_calls($GEOCODE, '_load_geocoder');
	my $geocode = $GEOCODE->new;
	ok(!exists $geocode->{_geocoder}, 'no attempt has been made');
	is(${$loads}, 0, 'and nothing was loaded');
	restore_all();
});

_transition($CONSTRUCTED, 'first call, module OK', $READY, sub {
	# The stand-in module is in %INC, so nothing real is loaded.
	my $made = 0;
	local $INC{$GCF_FILE} = __FILE__;
	no warnings 'once';
	local $Geo::Coder::Free::VERSION = $HIGH_VERSION;
	local *Geo::Coder::Free::new;
	_install_fake_gcf(\$made);
	local $INC{$GCL_FILE} = __FILE__;
	local $Geo::Coder::List::VERSION = $HIGH_VERSION;
	local *Geo::Coder::List::new = sub { shift; return Local::FakeList->new(@_) };
	my $loads = _count_calls($GEOCODE, '_load_geocoder');

	my $geocode = $GEOCODE->new;
	my ($available, $reason) = $geocode->geocoder_available;
	is($available, 1, 'geocoder_available: it can be had');
	is($reason, undef, 'with no reason why not');
	is($made, 1, 'and it was built');
	is(${$loads}, 1, 'by one load');

	# The other first call: resolve_values gets there as well.
	my $second = $GEOCODE->new;
	is($second->resolve_values([])->{available}, 1, 'resolve_values: the same');
	is(${$loads}, 2, 'by its own load');
	restore_all();
});

_transition($CONSTRUCTED, 'the module loads and its new() dies', $CONSTRUCTED, sub {
	# It is told to the caller, and nothing is remembered, so the next call tries
	# again and can succeed.
	my $built = 0;
	local $INC{$GCF_FILE} = __FILE__;
	no warnings qw(once redefine);
	local $Geo::Coder::Free::VERSION = $HIGH_VERSION;
	local $INC{$GCL_FILE} = __FILE__;
	local $Geo::Coder::List::VERSION = $HIGH_VERSION;
	local *Geo::Coder::List::new = sub { shift; return Local::FakeList->new(@_) };
	local *Geo::Coder::Free::new = sub {
		$built++;
		die "no data files\n" if $built == 1;
		return Local::Geocoder->new;
	};

	my $geocode = $GEOCODE->new;
	throws_ok { $geocode->geocoder_available } qr/no data files/, 'the failure comes out';
	ok(!exists $geocode->{_geocoder}, 'and nothing is remembered');
	my ($available) = $geocode->geocoder_available;
	is($available, 1, 'so the next call tries again, and can succeed');
	is($built, 2, 'having built it twice');
});

_transition($CONSTRUCTED, 'first call, module absent', $UNAVAILABLE, sub {
	delete local $INC{$GCF_FILE};
	local @INC = ($ABSENT_HOOK, @INC);

	my $geocode = $GEOCODE->new;
	my ($available, $reason) = $geocode->geocoder_available;
	is($available, 0, 'it cannot be had');
	like($reason, qr/it is not installed/, 'and the reason says why');
	ok(exists $geocode->{_geocoder}, 'the attempt has been made');
	is($geocode->{_geocoder}, undef, 'and came to nothing');
});

_transition($CONSTRUCTED, 'first call, module too old', $UNAVAILABLE, sub {
	my $made = 0;
	local $INC{$GCF_FILE} = __FILE__;
	no warnings 'once';
	local $Geo::Coder::Free::VERSION = $LOW_VERSION;
	local *Geo::Coder::Free::new;
	_install_fake_gcf(\$made);

	my $geocode = $GEOCODE->new(min_geocoder_version => $HIGH_VERSION);
	my ($available, $reason) = $geocode->geocoder_available;
	is($available, 0, 'it cannot be had');
	like($reason, qr/\Q$LOW_VERSION\E is installed/, 'and the reason names the version it found');
	is($made, 0, 'and an old one is not built');
});

_transition($CONSTRUCTED, 'first call, module will not load', $UNAVAILABLE, sub {
	delete local $INC{$GCF_FILE};
	local @INC = (sub { die "syntax error\n" if $_[1] eq $GCF_FILE; return }, @INC);

	my ($available, $reason) = $GEOCODE->new->geocoder_available;
	is($available, 0, 'it cannot be had');
	like($reason, qr/could not be loaded/, 'and the reason says why');
});

_transition($CONSTRUCTED, 'first call, its new() answers nothing', $UNAVAILABLE, sub {
	local $INC{$GCF_FILE} = __FILE__;
	no warnings qw(once redefine);
	local $Geo::Coder::Free::VERSION = $HIGH_VERSION;
	local *Geo::Coder::Free::new = sub { return };
	local $INC{$GCL_FILE} = __FILE__;
	local $Geo::Coder::List::VERSION = $HIGH_VERSION;
	local *Geo::Coder::List::new = sub { shift; return Local::FakeList->new(@_) };

	my $geocode = $GEOCODE->new;
	my ($available, $reason) = $geocode->geocoder_available;
	is($available, 0, 'it cannot be had');
	like($reason, qr/it could not be started/, 'and the reason says why');
	unlike($reason, qr/not installed/, 'and does not claim the module is missing');
	ok(exists $geocode->{_geocoder}, 'and the attempt is remembered');
});

_transition($READY, 'resolve_*() geocodes + cache', $READY, sub {
	my $geocoder = Local::Geocoder->new(known => { $PLACE => { lat => $LAT, lon => $LON } });
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);
	my $loads    = _count_calls($GEOCODE, '_load_geocoder');

	for my $resolve (
		sub { return $geocode->resolve_values([$PLACE]) },
		sub { return $geocode->resolve_column([ { where => $PLACE } ], 'where') },
	) {
		my $result = $resolve->();
		is($result->{available}, 1, 'it is still available');
		is_deeply([ @{ $result->{points}{$PLACE} }{qw(lat lon)} ], [ $LAT, $LON ], 'the place is found');
		is_deeply($result->{cache}{$PLACE}, [ $LAT, $LON ], 'and remembered in the answer');
	}
	is($geocode->{_geocoder}, $geocoder, 'the geocoder is the same one');
	is(${$loads}, 0, 'and nothing was loaded');
	restore_all();
});

_transition($UNAVAILABLE, 'resolve_*() cache only; not_attempted', $UNAVAILABLE, sub {
	delete local $INC{$GCF_FILE};
	local @INC = ($ABSENT_HOOK, @INC);
	my $geocode = $GEOCODE->new;
	my $loads   = _count_calls($GEOCODE, '_load_geocoder');

	for my $resolve (
		sub { return $geocode->resolve_values([ $PLACE, $OTHER_PLACE ], cache => { $PLACE => [ $LAT, $LON ] }) },
		sub {
			return $geocode->resolve_column(
				[ { where => $PLACE }, { where => $OTHER_PLACE } ], 'where',
				cache => { $PLACE => [ $LAT, $LON ] },
			);
		},
	) {
		my $result = $resolve->();
		is($result->{available}, 0, 'it is still unavailable');
		is_deeply([ @{ $result->{points}{$PLACE} }{qw(lat lon)} ], [ $LAT, $LON ], 'the cache is still served');
		is_deeply($result->{not_attempted}, [$OTHER_PLACE], 'and the rest is left alone');
		ok(!exists $result->{cache}{$OTHER_PLACE}, 'and not remembered, so it can be tried again');
		ok(scalar(grep { $_->{key} eq 'error_map_geocoder_missing' } @{ $result->{messages} }), 'and the reason is given');
	}
	is(${$loads}, 1, 'and it was looked for once only');
	restore_all();
});

# ===========================================================================
# Geocode: paths the load state diagram does not have
# ===========================================================================

_illegal($UNAVAILABLE, 'the module appears', $READY, sub {
	# "The object's geocoder-load state does not change after the first load attempt."
	my $geocode;
	{
		delete local $INC{$GCF_FILE};
		local @INC = ($ABSENT_HOOK, @INC);
		$geocode = $GEOCODE->new;
		my ($available) = $geocode->geocoder_available;
		is($available, 0, 'it starts unavailable');
	}

	my $made = 0;
	local $INC{$GCF_FILE} = __FILE__;
	no warnings 'once';
	local $Geo::Coder::Free::VERSION = $HIGH_VERSION;
	local *Geo::Coder::Free::new;
	_install_fake_gcf(\$made);

	my ($available) = $geocode->geocoder_available;
	is($available, 0, 'and stays so, though the module could now be loaded');
	is($made, 0, 'nothing was built');
});

_illegal($READY, 'the module disappears', $UNAVAILABLE, sub {
	my $geocoder = Local::Geocoder->new;
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);

	delete local $INC{$GCF_FILE};
	local @INC = ($ABSENT_HOOK, @INC);
	my ($available) = $geocode->geocoder_available;
	is($available, 1, 'it stays available');
	is($geocode->{_geocoder}, $geocoder, 'with the same geocoder');
});

_transition($CONSTRUCTED, 'arguments refused', $CONSTRUCTED, sub {
	# A refused call is a caller's mistake, and uses up nothing: the attempt to load
	# is still to come.
	my $loads   = _count_calls($GEOCODE, '_load_geocoder');
	my $geocode = $GEOCODE->new;

	throws_ok { $geocode->resolve_values('not a list') } qr/./, 'values that are not a list';
	throws_ok { $geocode->resolve_values([], max => 0) } qr/./, 'a cap of nothing';
	throws_ok { $geocode->resolve_column('not a list', 'where') } qr/./, 'rows that are not a list';
	throws_ok { $geocode->resolve_column([], '') } qr/./, 'no column';

	is(${$loads}, 0, 'nothing was loaded');
	ok(!exists $geocode->{_geocoder}, 'and it is still CONSTRUCTED');
	restore_all();
});

_transition($READY, 'arguments refused', $READY, sub {
	# The same with a geocoder in hand: none of these may reach it.
	my $geocoder = Local::Geocoder->new;
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);

	throws_ok { $geocode->resolve_values('not a list') } qr/./, 'values that are not a list';
	for my $max (0, -1, 'many', '1.5') {
		throws_ok { $geocode->resolve_values([$PLACE], max => $max) } qr/\Q$max\E/, "a cap of $max";
	}
	throws_ok { $geocode->resolve_column([ { a => 1 } ], 'where') } qr/where/, 'a column the rows do not have';

	is_deeply($geocoder->{asked}, [], 'the geocoder was asked nothing');
	is_deeply($geocoder->{valid}, [], 'not even whether a value is valid');
	is($geocode->{_geocoder}, $geocoder, 'and it is still READY');
});

_transition($UNAVAILABLE, 'arguments refused', $UNAVAILABLE, sub {
	delete local $INC{$GCF_FILE};
	local @INC = ($ABSENT_HOOK, @INC);
	my $geocode = $GEOCODE->new;
	$geocode->geocoder_available;

	throws_ok { $geocode->resolve_values('not a list') } qr/./, 'values that are not a list';
	my ($available) = $geocode->geocoder_available;
	is($available, 0, 'and it is still UNAVAILABLE');
});

# ===========================================================================
# Geocode: what happens to one value in one call
# ===========================================================================

_value_transition($RECEIVED, 'undef / ref / empty', $SKIPPED, sub {
	# The first test of all: it is refused whether or not there is a geocoder.
	my $geocoder = Local::Geocoder->new;
	my $result   = $GEOCODE->new(geocoder => $geocoder)->resolve_values([ undef, [], {} ]);
	is($result->{counts}{skipped}, 1, 'all of them are one distinct nothing');
	is_deeply($geocoder->{valid}, [], 'and the geocoder is not asked');

	my $empty = $GEOCODE->new(geocoder => $geocoder)->resolve_values(['']);
	is_deeply($empty->{skipped}, [''], 'an empty string is the same');
});

_value_transition($RECEIVED, 'in cache, has position', $CACHED_RESOLVED, sub {
	# -> POINTS.  The cache comes before the rule: a place remembered is plotted even
	# if the rule would now refuse it, and the geocoder is not asked.
	my $geocoder = Local::Geocoder->new(refuse => $PLACE);
	my $result   = $GEOCODE->new(geocoder => $geocoder)
		->resolve_values([$PLACE], cache => { $PLACE => [ $LAT, $LON ] });

	is_deeply($result->{points}{$PLACE}, { lat => $LAT, lon => $LON }, 'it is a point');
	is($result->{counts}{cached}, 1, 'counted as cached');
	is($result->{counts}{resolved}, 1, 'and resolved');
	is_deeply($geocoder->{valid}, [], 'the rule is not asked');
	is_deeply($geocoder->{asked}, [], 'nor the geocoder');
});

_value_transition($RECEIVED, 'in cache, no position (= 0)', $CACHED_UNRESOLVED, sub {
	# -> UNRESOLVED.  A remembered failure stays one, and is not asked about again.
	my $geocoder = Local::Geocoder->new(known => { $PLACE => { lat => $LAT, lon => $LON } });
	my $result   = $GEOCODE->new(geocoder => $geocoder)->resolve_values([$PLACE], cache => { $PLACE => 0 });

	is_deeply($result->{unresolved}, [$PLACE], 'it is unresolved');
	is_deeply($result->{points}, {}, 'and not a point');
	is($result->{cache}{$PLACE}, 0, 'and stays remembered');
	is_deeply($geocoder->{asked}, [], 'and the geocoder, which now knows it, is not asked');
});

_value_transition($RECEIVED, 'geocoder unavailable', $NOT_ATTEMPTED, sub {
	delete local $INC{$GCF_FILE};
	local @INC = ($ABSENT_HOOK, @INC);

	my $result = $GEOCODE->new->resolve_values([$PLACE]);
	is_deeply($result->{not_attempted}, [$PLACE], 'it is not attempted');
	is_deeply($result->{skipped}, [], 'and not refused, since there is no rule to ask');
	is_deeply($result->{cache}, {}, 'and not remembered');
});

_value_transition($RECEIVED, 'valid_location() = false', $SKIPPED, sub {
	my $geocoder = Local::Geocoder->new(refuse => $REFUSED);
	my $result   = $GEOCODE->new(geocoder => $geocoder)->resolve_values([$REFUSED]);

	is_deeply($result->{skipped}, [$REFUSED], 'it is skipped');
	is_deeply($geocoder->{valid}, [$REFUSED], 'on the word of the rule');
	is_deeply($geocoder->{asked}, [], 'and never reaches a lookup');
	is_deeply($result->{cache}, {}, 'and is not remembered');
});

_value_transition($RECEIVED, 'within cap', $ATTEMPT, sub {
	my $geocoder = Local::Geocoder->new;
	my $result   = $GEOCODE->new(geocoder => $geocoder)
		->resolve_values([ $PLACE, $OTHER_PLACE ], max => $CAP, region => 'gb');

	is_deeply($geocoder->{asked}, [ [ $PLACE, $OTHER_PLACE ] ], 'one batch, with every value at the cap');
	is_deeply($geocoder->{opts}, { region => 'gb', on_error => 'undef' }, 'in the non-croaking mode, with the hint');
	is($result->{counts}{attempted}, $CAP, 'counted as attempted');
	is($result->{capped}, 0, 'and the cap did not bite');
});

_value_transition($RECEIVED, 'beyond cap', $NOT_ATTEMPTED, sub {
	my $geocoder = Local::Geocoder->new;
	# Named here so the one message is the cap's, wherever this runs: without
	# OPENADDR_HOME a lookup adds warn_map_geocoder_unavailable_data as well.
	my $result   = $GEOCODE->new(geocoder => $geocoder, openaddr => '/no/such/openaddr')
		->resolve_values([ $PLACE, $OTHER_PLACE, $THIRD_PLACE ], max => $CAP);

	is_deeply($geocoder->{asked}, [ [ $PLACE, $OTHER_PLACE ] ], 'the first ones are asked about');
	is_deeply($result->{not_attempted}, [$THIRD_PLACE], 'the last is held back');
	is($result->{capped}, 1, 'and it says so');
	ok(!exists $result->{cache}{$THIRD_PLACE}, 'and it is left out of the cache, for the next request');
	is_deeply([ map { $_->{key} } @{ $result->{messages} } ], ['warn_map_geocode_capped'], 'with a message');
});

_value_transition($ATTEMPT, 'geocoder returns position', $RESOLVED_NEW, sub {
	# -> POINTS, CACHE==[lat,lon].  In the answer's cache, not the caller's.
	my $geocoder = Local::Geocoder->new(known => { $PLACE => { lat => $LAT, lon => $LON, database => 'osm' } });
	my %mine;
	my $result = $GEOCODE->new(geocoder => $geocoder)->resolve_values([$PLACE], cache => \%mine);

	is_deeply($result->{points}{$PLACE}, { lat => $LAT, lon => $LON, backend => 'osm' }, 'it is a point');
	is_deeply($result->{cache}{$PLACE}, [ $LAT, $LON ], 'remembered with its position');
	is($result->{counts}{resolved}, 1, 'and counted');
	is_deeply(\%mine, {}, 'the cache that was passed in is not touched');
});

_value_transition($ATTEMPT, 'geocoder returns no position', $UNRESOLVED_NEW, sub {
	# CACHE==0: looked up and not found, so the next request does not ask again.
	my $geocoder = Local::Geocoder->new;
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);
	my $result   = $geocode->resolve_values([$LOST]);

	is_deeply($result->{unresolved}, [$LOST], 'it is unresolved');
	is($result->{cache}{$LOST}, 0, 'and remembered as such');
	is_deeply($result->{points}, {}, 'and is not a point');

	# Round the loop: the next request starts from that cache, which is the edge to
	# CACHED_UNRESOLVED.
	my $next = $geocode->resolve_values([$LOST], cache => $result->{cache});
	is(scalar @{ $geocoder->{asked} }, 1, 'the next request does not ask again');
	is_deeply($next->{unresolved}, [$LOST], 'and it is still unresolved');

	# An answer with no position in it is no better than no answer.
	my $vague = $GEOCODE->new(geocoder => Local::Geocoder->new(known => { $LOST => { name => 'somewhere' } }))
		->resolve_values([$LOST]);
	is_deeply($vague->{unresolved}, [$LOST], 'a result without a position is unresolved too');
	is($vague->{cache}{$LOST}, 0, 'and remembered as such');
});

_value_transition($ATTEMPT, 'geocoder throws', $EXCEPTION, sub {
	# The whole request fails, on purpose, so that a cache cannot be half-written.
	my %mine = ($PLACE => [ $LAT, $LON ]);
	my $geocoder = Local::Geocoder->new(dies => 1);
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);

	throws_ok { $geocode->resolve_values([ $PLACE, $OTHER_PLACE ], cache => \%mine) } qr/geocoder failure/, 'it comes out';
	is_deeply(\%mine, { $PLACE => [ $LAT, $LON ] }, 'with the cache as it was');
	is($geocode->{_geocoder}, $geocoder, 'and the load state is not changed: READY');
});

_value_transition($RECEIVED, 'valid_location() throws', $EXCEPTION, sub {
	my %mine;
	my $geocoder = Local::Geocoder->new(rule_dies => 1);
	my $geocode  = $GEOCODE->new(geocoder => $geocoder);

	throws_ok { $geocode->resolve_values([$PLACE], cache => \%mine) } qr/rule failure/, 'it comes out';
	is_deeply(\%mine, {}, 'with the cache as it was');
	is_deeply($geocoder->{asked}, [], 'and no lookup was made');
});

# ===========================================================================
# Compliance: the tests against the diagrams, read from the POD
# ===========================================================================

for my $module ($DS, $GEOCODE) {
	subtest "Compliance: every path in the $module summary is tested, and no other" => sub {
		my $documented = _summary_paths($module);
		cmp_ok(scalar keys %{$documented}, '>', 1, 'the paths were read');
		is_deeply([ sort keys %{ $covered{$module} } ], [ sort keys %{$documented} ], 'the tests above and the summary agree');
	};
}

subtest 'Compliance: every value path in the Geocode diagram is tested, and no other' => sub {
	my %documented;
	my ($values) = _diagram_of($GEOCODE) =~ /(Value-level state transitions.*)/s;
	for my $line (split /\n/, $values // '') {
		next unless $line =~ /\+--\[(.+?)\]-*>\s*(\w+)/;
		my ($trigger, $to) = ($1, $2);
		my $from = $line =~ /\|\s+\+--/ ? $ATTEMPT : $RECEIVED;
		$documented{"$from -> [$trigger] -> $to"} = 1;
	}
	cmp_ok(scalar keys %documented, '>', 1, 'the paths were read');
	is_deeply([ sort keys %value_covered ], [ sort keys %documented ], 'the tests above and the diagram agree');
};

restore_all();
done_testing();
