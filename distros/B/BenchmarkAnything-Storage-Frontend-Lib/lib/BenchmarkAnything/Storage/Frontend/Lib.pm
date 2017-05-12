use 5.008;
use strict;
use warnings;
package BenchmarkAnything::Storage::Frontend::Lib;
# git description: v0.020-2-g8b989ab

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Basic functions to access a BenchmarkAnything store
$BenchmarkAnything::Storage::Frontend::Lib::VERSION = '0.021';
use Scalar::Util 'reftype';


sub new
{
        my $class = shift;
        my $self  = bless { @_ }, $class;
        require BenchmarkAnything::Config;
        $self->{config} = BenchmarkAnything::Config->new(cfgfile => $self->{cfgfile}) unless $self->{noconfig};
        $self->connect      unless $self->{noconnect};
        return $self;
}

sub _format_flat_inner_scalar
{
    my ($self, $result, $opt) = @_;

    no warnings 'uninitialized';

    return "$result";
}

sub _format_flat_inner_array
{
        my ($self, $result, $opt) = @_;

        no warnings 'uninitialized';

        return
         join($opt->{separator},
              map {
                   # only SCALARS allowed (where reftype returns undef)
                   die "benchmarkanything: unsupported innermost nesting (".reftype($_).") for 'flat' output.\n" if defined reftype($_);
                   "".$_
                  } @$result);
}

sub _format_flat_inner_hash
{
        my ($self, $result, $opt) = @_;

        no warnings 'uninitialized';

        return
         join($opt->{separator},
              map { my $v = $result->{$_};
                    # only SCALARS allowed (where reftype returns undef)
                    die "benchmarkanything: unsupported innermost nesting (".reftype($v).") for 'flat' output.\n" if defined reftype($v);
                    "$_=".$v
                  } keys %$result);
}

sub _format_flat_outer
{
        my ($self, $result, $opt) = @_;

        no warnings 'uninitialized';

        my $output = "";
        die "benchmarkanything: can not flatten data structure (undef) - try other output format.\n" unless defined $result;

        my $A = ""; my $B = ""; if ($opt->{fb}) { $A = "["; $B = "]" }
        my $fi = $opt->{fi};

        if (!defined reftype $result) { # SCALAR
                $output .= $result."\n"; # stringify
        }
        elsif (reftype $result eq 'ARRAY') {
                for (my $i=0; $i<@$result; $i++) {
                        my $entry  = $result->[$i];
                        my $prefix = $fi ? "$i:" : "";
                        if (!defined reftype $entry) { # SCALAR
                                $output .= $prefix.$A.$self->_format_flat_inner_scalar($entry, $opt)."$B\n";
                        }
                        elsif (reftype $entry eq 'ARRAY') {
                                $output .= $prefix.$A.$self->_format_flat_inner_array($entry, $opt)."$B\n";
                        }
                        elsif (reftype $entry eq 'HASH') {
                                $output .= $prefix.$A.$self->_format_flat_inner_hash($entry, $opt)."$B\n";
                        }
                        else {
                                die "benchmarkanything: can not flatten data structure (".reftype($entry).").\n";
                        }
                }
        }
        elsif (reftype $result eq 'HASH') {
                my @keys = keys %$result;
                foreach my $key (@keys) {
                        my $entry = $result->{$key};
                        if (!defined reftype $entry) { # SCALAR
                                $output .= "$key:".$self->_format_flat_inner_scalar($entry, $opt)."\n";
                        }
                        elsif (reftype $entry eq 'ARRAY') {
                                $output .= "$key:".$self->_format_flat_inner_array($entry, $opt)."\n";
                        }
                        elsif (reftype $entry eq 'HASH') {
                                $output .= "$key:".$self->_format_flat_inner_hash($entry, $opt)."\n";
                        }
                        else {
                                die "benchmarkanything: can not flatten data structure (".reftype($entry).").\n";
                        }
                }
        }
        else {
                die "benchmarkanything: can not flatten data structure (".reftype($result).") - try other output format.\n";
        }

        return $output;
}

sub _format_flat
{
        my ($self, $result, $opt) = @_;

        # ensure array container
        # for consistent output in 'getpoint' and 'search'
        my $resultlist = reftype($result) eq 'ARRAY' ? $result : [$result];

        my $output = "";
        $opt->{separator} = ";" unless defined $opt->{separator};
        $output .= $self->_format_flat_outer($resultlist, $opt);
        return $output;
}


sub _output_format
{
        my ($self, $data, $opt) = @_;

        my $output  = "";
        my $outtype = $opt->{outtype} || 'json';

        if ($outtype eq "yaml")
        {
                require YAML::Any;
                $output .= YAML::Any::Dump($data);
        }
        elsif ($outtype eq "json")
        {
                eval "use JSON -convert_blessed_universally";
                my $json = JSON->new->allow_nonref->pretty->allow_blessed->convert_blessed;
                $output .= $json->encode($data);
        }
        elsif ($outtype eq "ini") {
                require Config::INI::Serializer;
                my $ini = Config::INI::Serializer->new;
                $output .= $ini->serialize($data);
        }
        elsif ($outtype eq "dumper")
        {
                require Data::Dumper;
                $output .= Data::Dumper::Dumper($data);
        }
        elsif ($outtype eq "xml")
        {
                require XML::Simple;
                my $xs = new XML::Simple;
                $output .= $xs->XMLout($data, AttrIndent => 1, KeepRoot => 1);
        }
        elsif ($outtype eq "flat") {
                $output .= $self->_format_flat( $data, $opt );
        }
        else
        {
                die "benchmarkanything-storage: unrecognized output format: $outtype.";
        }
        return $output;
}


sub connect
{
        my ($self) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                require DBI;
                require BenchmarkAnything::Storage::Backend::SQL;
                no warnings 'once'; # avoid 'Name "DBI::errstr" used only once'

                # connect
                print "Connect db...\n" if $self->{verbose};
                my $dsn      = $self->{config}{benchmarkanything}{storage}{backend}{sql}{dsn};
                my $user     = $self->{config}{benchmarkanything}{storage}{backend}{sql}{user};
                my $password = $self->{config}{benchmarkanything}{storage}{backend}{sql}{password};
                my $dbh      = DBI->connect($dsn, $user, $password, {'RaiseError' => 1})
                 or die "benchmarkanything: can not connect: ".$DBI::errstr;

                # external search engine
                my $searchengine = $self->{config}{benchmarkanything}{searchengine} || {};

                # remember
                $self->{dbh}     = $dbh;
                $self->{backend} = BenchmarkAnything::Storage::Backend::SQL->new({dbh => $dbh,
                                                                                  dbh_config => $self->{config}{benchmarkanything}{storage}{backend}{sql},
                                                                                  debug => $self->{debug},
                                                                                  force => $self->{force},
                                                                                  verbose => $self->{verbose},
                                                                                  (keys %$searchengine ? (searchengine => $searchengine) : ()),
                                                                                 });
        }
        elsif ($backend eq 'http')
        {
                my $ua  = $self->_get_user_agent;
                my $url = $self->_get_base_url."/api/v1/hello";
                die "benchmarkanything: can't connect to result storage ($url)\n" if (!$ua->get($url)->res->code or $ua->get($url)->res->code != 200);
        }

        return $self;
}


sub disconnect
{
        my ($self) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                if ($self->{dbh}) {
                        $self->{dbh}->commit unless $self->{dbh}{AutoCommit};
                        undef $self->{dbh}; # setting dbh to undef does better cleanup than disconnect();
                }
        }
        return $self;
}


sub _are_you_sure
{
        my ($self) = @_;

        # DSN
        my $dsn = $self->{config}{benchmarkanything}{storage}{backend}{sql}{dsn};

        # option --really
        if ($self->{really})
        {
                if ($self->{really} eq $dsn)
                {
                        return 1;
                }
                else
                {
                        print STDERR "DSN does not match - asking interactive.\n";
                }
        }

        # ask on stdin
        print "REALLY DROP AND RE-CREATE DATABASE TABLES [$dsn] (y/N): ";
        read STDIN, my $answer, 1;
        return 1 if $answer && $answer =~ /^y(es)?$/i;

        # default: NO
        return 0;
}


sub createdb
{
        my ($self) = @_;

        if ($self->_are_you_sure)
        {
                no warnings 'once'; # avoid 'Name "DBI::errstr" used only once'

                require DBI;
                require File::Slurper;
                require File::ShareDir;
                use DBIx::MultiStatementDo;

                my $batch            = DBIx::MultiStatementDo->new(dbh => $self->{dbh});

                # get schema SQL according to driver
                my $dsn      = $self->{config}{benchmarkanything}{storage}{backend}{sql}{dsn};
                my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn)
                 or die "benchmarkanything: can not parse DBI DSN '$dsn'";
                my ($dbname) = $driver_dsn =~ m/database=(\w+)/g;
                my $sql_file = File::ShareDir::dist_file('BenchmarkAnything-Storage-Backend-SQL', "create-schema.$driver");
                my $sql      = File::Slurper::read_text($sql_file);
                $sql         =~ s/^use `testrundb`;/use `$dbname`;/m if $dbname; # replace BenchmarkAnything::Storage::Backend::SQL's default

                # execute schema SQL
                my @results = $batch->do($sql);
                if (not @results)
                {
                        die "benchmarkanything: error while creating BenchmarkAnything DB: ".$batch->dbh->errstr;
                }

        }

        return;
}


sub _default_additional_keys
{
        my ($self) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                return { $self->{backend}->default_columns };
        }
        else
        {
                # Hardcoded from BenchmarkAnything::Storage::Backend::SQL::Query::common,
                # as it is a backend-special and internal thing anyway.
                return {
                    'NAME'      => 'b.bench',
                    'UNIT'      => 'bu.bench_unit',
                    'VALUE'     => 'bv.bench_value',
                    'VALUE_ID'  => 'bv.bench_value_id',
                    'CREATED'   => 'bv.created_at',
                };
        }
}



sub _get_benchmark_operators
{
        my ($self) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                return [ $self->{backend}->benchmark_operators ];
        }
        else
        {
                # Hardcoded from BenchmarkAnything::Storage::Backend::SQL::Query::common,
                # as it is a backend-special and internal thing anyway.
                return [ '=', '!=', 'like', 'not like', '<', '>', '<=', '>=' ];
        }
}



sub _get_additional_key_id
{
        my ($self, $key_name) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                return $self->{backend}->_get_additional_key_id($key_name);
        }
        else
        {
                die "benchmarkanything: no backend '$backend' allowed here, available backends are: 'local'.\n";
        }
}



sub init_workdir
{
        my ($self) = @_;

        require File::Basename;
        require File::ShareDir;
        require File::HomeDir;
        require File::Slurper;

        my $home_ba = File::HomeDir->my_home."/.benchmarkanything";
        my $command = File::Basename::basename($0);

        if (-d $home_ba)
        {
                print "Workdir '$home_ba' already exists - skipping.\n" if $self->{verbose};
        }
        else
        {
                require File::Path;
                File::Path::make_path($home_ba);
        }

        foreach my $basename (qw(client.cfg server.cfg default.cfg README))
        {
                my $source_file = File::ShareDir::dist_file('BenchmarkAnything-Storage-Frontend-Lib', "config/$basename");
                my $dest_file   = "$home_ba/$basename";

                if (! -e $dest_file)
                {
                        my $content     =  File::Slurper::read_text($source_file);

                        # poor man's templating
                        $content        =~ s{\[%\s*CLIENTCFG\s*%\]}{$home_ba/client.cfg}g;
                        $content        =~ s{\[%\s*SERVERCFG\s*%\]}{$home_ba/server.cfg}g;
                        $content        =~ s{\[%\s*LOCALCFG\s*%\]}{$home_ba/default.cfg}g;
                        $content        =~ s{\[%\s*CFG\s*%\]}{$dest_file}g;
                        $content        =~ s{\[%\s*HOME\s*%\]}{$home_ba}g;

                        print "Create configfile: $dest_file...\n" if $self->{verbose};
                        open my $CFGFILE, ">", $dest_file or die "Could not create $dest_file.\n";
                        print $CFGFILE $content;
                        close $CFGFILE;
                }
                else
                {
                        print "Config '$dest_file' already exists - skipping.\n" if $self->{verbose};
                }
        }

        my $dbfile = "$home_ba/benchmarkanything.sqlite";
        my $we_created_db = 0;
        if (! -e $dbfile)
        {
                print "Create storage: $dbfile...\n" if $self->{verbose};
                __PACKAGE__->new(cfgfile => "$home_ba/default.cfg",
                                 really  => "dbi:SQLite:$dbfile",
                                )->createdb;
                $we_created_db = 1;
        }
        else
        {
                print "Storage '$dbfile' already exists - skipping.\n" if $self->{verbose};
        }

        if ($self->{verbose})
        {
                print "\n";
                print "By default it will use this config: $home_ba/default.cfg\n";
                print "If you want another one, set it in your ~/.bash_profile:\n";
                print "  export BENCHMARKANYTHING_CONFIGFILE=$home_ba/client.cfg\n";

                unless ($we_created_db)
                {
                        print "\n";
                        print "Initialize a new database (it asks for confirmation) with:\n";
                        print "  $command createdb\n";
                        print "\nReady.\n";
                }
                else
                {
                        print "\n";
                        print "Create sample values like this:\n";
                        print qq(  echo '{"BenchmarkAnythingData":[{"NAME":"benchmarkanything.hello.world", "VALUE":17.2}]}' | $command add\n);
                        print "\n";
                        print "List metric names:\n";
                        print qq(  $command listnames\n);
                        print "\n";
                        print "Query sample values:\n";
                        print qq(  echo '{"select":["NAME","VALUE"],"where":[["=","NAME","benchmarkanything.hello.world"]]}' | $command search\n);
                        print "\n";
                }
        }

        return;
}


sub add
{
        my ($self, $data) = @_;

        # --- validate ---
        if (not $data)
        {
                die "benchmarkanything: no input data provided.\n";
        }

        if (not $self->{skipvalidation}) {
            require BenchmarkAnything::Schema;
            print "Verify schema...\n" if $self->{verbose};
            if (not my $result = BenchmarkAnything::Schema::valid_json_schema($data))
            {
                die "benchmarkanything: add: invalid input: ".join("; ", $result->errors)."\n";
            }
        }

        # --- add to storage ---

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                my $success;
                if ($self->{queuemode})
                {
                        # only queue for later processing
                        print "Enqueue data [backend:local]...\n" if $self->{verbose} or $self->{debug};
                        $success = $self->{backend}->enqueue_multi_benchmark($data->{BenchmarkAnythingData});
                }
                else
                {
                        print "Add data [backend:local]...\n" if $self->{verbose} or $self->{debug};
                        # preserve order, otherwise add_multi_benchmark() would reorder to optimize insert
                        foreach my $chunk (@{$data->{BenchmarkAnythingData}})
                        {
                                print "." if $self->{debug};
                                $success = $self->{backend}->add_multi_benchmark([$chunk]);
                        }
                }
                if (not $success)
                {
                        die "benchmarkanything: error while adding data: ".$@;
                }
                print "Done.\n" if $self->{verbose} or $self->{debug};
        }
        elsif ($backend eq 'http')
        {
                require BenchmarkAnything::Reporter;
                $self->{config} = BenchmarkAnything::Reporter->new(config  => $self->{config},
                                                                   verbose => $self->{verbose},
                                                                   debug   => $self->{debug},
                                                                  );
        }
        else
        {
                die "benchmarkanything: no backend '$backend', available backends are: 'http', 'local'.\n";
        }

        return $self;
}

sub _get_user_agent
{
        require Mojo::UserAgent;
        return Mojo::UserAgent->new;
}

sub _get_base_url
{
        shift->{config}{benchmarkanything}{backends}{http}{base_url};
}


sub search
{
        my ($self, $query, $value_id) = @_;

        # --- validate ---
        if (not $query and not $value_id)
        {
                die "benchmarkanything: no query or value_id provided.\n";
        }

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                # single values
                return $self->{backend}->get_single_benchmark_point($value_id) if $value_id;
                return $self->{backend}->search_array($query);
        }
        elsif ($backend eq 'http')
        {
                my $ua  = $self->_get_user_agent;
                my $url = $self->_get_base_url."/api/v1/search";
                my $res;
                if ($value_id) {
                        $url .= "/$value_id";
                        $res = $ua->get($url)->res;
                } else {
                        $res = $ua->post($url => json => $query)->res;
                }

                die "benchmarkanything: ".$res->error->{message}." ($url)\n" if $res->error;

                return $res->json;
        }
        else
        {
                die "benchmarkanything: no backend '$backend', available backends are: 'http', 'local'.\n";
        }
}


sub listnames
{
        my ($self, $pattern) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                return $self->{backend}->list_benchmark_names(defined($pattern) ? ($pattern) : ());
        }
        elsif ($backend eq 'http')
        {
                my $ua  = $self->_get_user_agent;
                my $url = $self->_get_base_url."/api/v1/listnames";

                my $res = $ua->get($url)->res;
                die "benchmarkanything: ".$res->error->{message}." ($url)\n" if $res->error;

                my $result = $res->json;

                # output
                return $result;
        }
        else
        {
                die "benchmarkanything: no backend '$backend', available backends are: 'http', 'local'.\n";
        }
}


sub listkeys
{
        my ($self, $pattern) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                return $self->{backend}->list_additional_keys(defined($pattern) ? ($pattern) : ());
        }
        elsif ($backend eq 'http')
        {
                my $ua  = $self->_get_user_agent;
                my $url = $self->_get_base_url."/api/v1/listkeys";

                my $res = $ua->get($url)->res;
                die "benchmarkanything: ".$res->error->{message}." ($url)\n" if $res->error;

                my $result = $res->json;

                # output
                return $result;
        }
        else
        {
                die "benchmarkanything: no backend '$backend', available backends are: 'http', 'local'.\n";
        }
}


sub stats
{
        my ($self) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                return $self->{backend}->get_stats;
        }
        elsif ($backend eq 'http')
        {
                my $ua  = $self->_get_user_agent;
                my $url = $self->_get_base_url."/api/v1/stats";

                my $res = $ua->get($url)->res;
                die "benchmarkanything: ".$res->error->{message}." ($url)\n" if $res->error;

                my $result = $res->json;

                # output
                return $result;
        }
        else
        {
                die "benchmarkanything: no backend '$backend', available backends are: 'http', 'local'.\n";
        }
}


sub gc
{
        my ($self) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                $self->{backend}->gc;
        }
}


sub process_raw_result_queue
{
        my ($self, $count) = @_;

        $count ||= 10;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                my $dequeued_raw_bench_bundle_id;
                do {
                        $dequeued_raw_bench_bundle_id = $self->{backend}->process_queued_multi_benchmark;
                        $count--;
                } until ($count < 1 or not defined($dequeued_raw_bench_bundle_id));
        }
        else
        {
                die "benchmarkanything: only backend 'local' allowed in 'process_raw_result_queue'.\n";
        }
        return;
}


sub init_search_engine
{
        my ($self, $force) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                $self->{backend}->init_search_engine($force);
        }
        else
        {
                die "benchmarkanything: only backend 'local' allowed in 'init_search_engine'.\n";
        }
        return;
}


sub sync_search_engine
{
        my ($self, $force, $start, $count) = @_;

        my $backend = $self->{config}{benchmarkanything}{backend};
        if ($backend eq 'local')
        {
                $self->{backend}->sync_search_engine($force, $start, $count);
        }
        else
        {
                die "benchmarkanything: only backend 'local' allowed in 'sync_search_engine'.\n";
        }
        return;
}



sub getpoint
{
        my ($self, $value_id) = @_;

        return $self->search(undef, $value_id);
        die "benchmarkanything: please provide a benchmark value_id'\n" unless $value_id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Frontend::Lib - Basic functions to access a BenchmarkAnything store

=head2 new

Instantiate a new object.

=over 4

=item * cfgfile

Path to config file. If not provided it uses env variable
C<BENCHMARKANYTHING_CONFIGFILE> or C<$home/.benchmarkanything.cfg>.

=item * noconfig

If set to 1, do not initialize configuration.

=item * noconnect

If set to 1, do not automatically connect to backend store.

=item * really

Used for critical functions like createdb. Provide a true value or, in
case of L</createdb>, the DSN of the database that you are about to
(re-)create.

=item * skipvalidation

Disables schema validation checking, e.g., when you know your data is
correct and want to save execution time, ususally for C<add()>.

=item * verbose

Print out progress messages.

=item * debug

Pass through debug option to used modules, like
L<BenchmarkAnything::Storage::Backend::SQL|BenchmarkAnything::Storage::Backend::SQL>.

=item * separator

Used for output format I<flat>. Sub entry separator (default=;).

=item * fb

Used for output format I<flat>. If set it generates [brackets] around
outer arrays (default=0).

=item * fi

Used for output format I<flat>. If set it prefixes outer array lines
with index.

=back

=head2 _output_format

This function converts a data structure into requested output format.

=head3 Output formats

The following B<output formats> are allowed:

 yaml   - YAML::Any
 json   - JSON (default)
 xml    - XML::Simple
 ini    - Config::INI::Serializer
 dumper - Data::Dumper (including the leading $VAR1 variable assignment)
 flat   - pragmatic flat output for typical unixish cmdline usage

=head3 The 'flat' output format

The C<flat> output format is meant to support typical unixish command
line uses. It is not a strong serialization format but works well for
simple values nested max 2 levels.

Output looks like this:

=head4 Plain values

 Affe
 Tiger
 Birne

=head4 Outer hashes

One outer key per line, key at the beginning of line with a colon
(C<:>), inner values separated by semicolon C<;>:

=head4 inner scalars:

 coolness:big
 size:average
 Eric:The flat one from the 90s

=head4 inner hashes:

Tuples of C<key=value> separated by semicolon C<;>:

 Affe:coolness=big;size=average
 Zomtec:coolness=bit anachronistic;size=average

=head4 inner arrays:

Values separated by semicolon C<;>:

 Birne:bissel;hinterher;manchmal

=head4 Outer arrays

One entry per line, entries separated by semicolon C<;>:

=head4 Outer arrays / inner scalars:

 single report string
 foo
 bar
 baz

=head4 Outer arrays / inner hashes:

Tuples of C<key=value> separated by semicolon C<;>:

 Affe=amazing moves in the jungle;Zomtec=slow talking speed;Birne=unexpected in many respects

=head4 Outer arrays / inner arrays:

Entries separated by semicolon C<;>:

 line A-1;line A-2;line A-3;line A-4;line A-5
 line B-1;line B-2;line B-3;line B-4
 line C-1;line C-2;line C-3

=head4 Additional markup for arrays:

 --fb            ... use [brackets] around outer arrays
 --fi            ... prefix outer array lines with index
 --separator=;   ... use given separator between array entries (defaults to ";")

Such additional markup lets outer arrays look like this:

 0:[line A-1;line A-2;line A-3;line A-4;line A-5]
 1:[line B-1;line B-2;line B-3;line B-4]
 2:[line C-1;line C-2;line C-3]
 3:[Affe=amazing moves in the jungle;Zomtec=slow talking speed;Birne=unexpected in many respects]
 4:[single report string]

=head2 connect

Connects to the database according to the DB handle from config.

Returns the object to allow chained method calls.

=head2 disconnect

Commits and disconnects the current DB handle from the database.

Returns the object to allow chained method calls.

=head2 _are_you_sure

Internal method.

Find out if you are really sure. Usually used in L</createdb>. You
need to have provided an option C<really> which matches the DSN of the
database that your are about to (re-)create.

If the DSN does not match it asks interactively on STDIN - have this
in mind on non-interactive backend programs, like a web application.

=head2 createdb

Initializes the DB, as configured by C<backend> and C<dsn>.  On
the backend this means executing the DROP TABLE and CREATE TABLE
statements that come with
L<BenchmarkAnything::Storage::Backend::SQL|BenchmarkAnything::Storage::Backend::SQL>. Because that is a severe
operation it verifies an "are you sure" test, by comparing the
parameter C<really> against the DSN from the config, or if that
doesn't match, asking interactively on STDIN.

=head2 _default_additional_keys

Internal method. Specific to SQL backend.

Return default columns that are part of each BenchmarkAnything data point.

=head2 _get_benchmark_operators

Internal method. Specific to SQL backend.

Return the allowed operators of the BenchmarkAnything query API.

=head2 _get_additional_key_id

Internal method. Specific to SQL backend.

Returns id of the additional key.

=head2 init_workdir

Initializes a work directory C<~/.benchmarkanything/> with config
files, which should work by default and can be tweaked by the user.

=head2 add ($data)

Adds all data points of a BenchmarkAnything structure to the backend
store.

=head2 search ($query)

Execute a search query against the backend store, currently
L<BenchmarkAnything::Storage::Backend::SQL|BenchmarkAnything::Storage::Backend::SQL>, and returns the list of found
data points, as configured by the search query.

=head2 listnames ($pattern)

Returns an array ref with all metric NAMEs. Optionally allows to
restrict the search by a SQL LIKE search pattern, allowing C<%> as
wildcard.

=head2 listkeys ($pattern)

Returns an array ref with all additional key names that are used for
metrics. Optionally allows to restrict the search by a SQL LIKE search
pattern, allowing C<%> as wildcard.

=head2 stats

Returns a hash with info about the storage, like how many data points,
how many metrics, how many additional keys, are stored.

=head2 gc()

Run garbage collector. This cleans up potential garbage that might
have piled up, in particular qeued raw results that are already
processed but still in the storage.

Initially the garbage collection is made for the queing functionality
(see L</process_raw_result_queue> until we are confident it is
waterproof. However, generally there might be new code arriving in the
future for which garbage collection might also make sense, so we
provide this function as general entry point to do The Right Thing -
whatever that is by that time.

=head2 process_raw_result_queue($count)

Works on the queued entries created by C<add> in I<queuemode=1>. It
finishes as soon as there are no more unprocessed raw entries, or it
processed C<$count> entries (default=10).

=head2 init_search_engine($force)

Initializes the configured search engine (Elasticsearch). If the index
already exists it does nothing, except when you set C<$force> to a
true value which deletes and re-creates the index. This is necessary
for example to apply new type mappings.

After a successful (re-)init you need to run C<sync_search_engine>.

During (re-init) and sync you should disable querying by setting

  benchmarkanything.searchengine.elasticsearch.enable_query: 0

=head3 Options

=over 4

=item force

If set, an existing index is deleted before (re-)creating.

=back

=head2 sync_search_engine($force, $start, $count)

Synchronizes entries from the ::SQL backend into the configured search
engine (usually Elasticsearch). It starts at entry C<$start> and bulk
indexes in blocks of C<$count>.

=head3 Options

=over 4

=item force

If set, all entries are (re-)indexed, not just the new ones.

=back

=head2 getpoint ($value_id)

Returns a single benchmark point with B<all> its key/value pairs.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
