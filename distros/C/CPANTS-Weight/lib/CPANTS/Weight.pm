package CPANTS::Weight;

=pod

=head1 NAME

CPANTS::Weight - Graph based weights for CPAN Distributions

=head1 DESCRIPTION

C<CPAN::Weight> is a module that consumes the CPANTS database, and
generates a variety of graph-based weighting values for the distributions,
producing a SQLite database of the weighting data, for use in higher-level
applications that work with the CPANTS data.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use File::Spec                       3.2701 ();
use File::HomeDir                      0.82 ();
use File::ShareDir                     1.00 ();
use Params::Util                       0.38 ();
use DateTime                         0.4501 ();
use CPAN::Version                       5.5 ();
use Algorithm::Dependency             1.108 ();
use Algorithm::Dependency::Weight           ();
use Algorithm::Dependency::Source::DBI 0.05 ();
use Algorithm::Dependency::Source::Invert   ();
use ORDB::CPANTS                       0.05 ();
use ORDB::CPANUploads                  0.04 ();
use ORDB::CPANTesters                  0.09 ();

our $VERSION = '0.15';

our $DEBUG;

sub trace {
	print STDERR "# $_[0]\n" if $DEBUG;
}

use constant ORLITE_FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'CPANTS-Weight',
	'CPANTS-Weight.sqlite',
);

use constant ORLITE_TIMELINE => File::Spec->catdir(
	File::ShareDir::dist_dir('CPANTS-Weight'),
	'timeline',
);

use ORLite          1.20 ();
use ORLite::Mirror  1.12 ();
use ORLite::Migrate 0.03 {
	file         => ORLITE_FILE,
	create       => 1,
	timeline     => ORLITE_TIMELINE,
	user_version => 3,
};

# Delay download/inflate for the ORDB:: modules until import,
# so we can pass them a common maxage param.
sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Download/inflate the CPANTS database
	ORDB::CPANTS->import( {
		maxage => $params->{maxage},
	} );

	# Download/inflate the CPAN PAUSE uploads database
	ORDB::CPANTUploads->import( {
		maxage => $params->{maxage},
	} );

	# Download/inflate the (huge) CPAN Testers database
	ORDB::CPANTesters->import( {
		maxage => $params->{maxage},
	} );

	return 1;
}

# Common string fragments
my $SELECT_IDS = <<'END_SQL';
select
	id
from
	dist
where
	id > 0
END_SQL

my $SELECT_DEPENDS = <<'END_SQL';
select
	dist,
	in_dist
from
	prereq
where
	in_dist is not null
	and
	dist > 0
	and
	in_dist > 0
END_SQL





#####################################################################
# Main Methods

# Only used internally, for caching reasons
sub new {
	my $class = shift;
	my $self  = bless { }, $class;
	return $self;
}

=pod

=head2 run

  CPANTS::Weight->run;

The main C<run> method does a complete generation cycle for the CPANTS
weighting database. It will retrieve the CPANTS data (if needed) calculate
the weights, and then (re)populate the CPANTS-Weight.sqlite database.

Once completed, the C<CPANTS::Weight-E<gt>sqlite> method can be used to
locate the completed SQLite database file.

=cut

sub run {
	my $self = ref($_[0]) ? shift : shift->new;

	# Run import if we haven't already
	ref($self)->import;

	# Skip if the output database is newer than the input database
	# (but is not a new database)
	my $input_t  = (stat(ORDB::CPANTS->sqlite  ))[9];
	my $output_t = (stat(CPANTS::Weight->sqlite))[9];
	# if ( $output_t > $input_t and CPANTS::Weight::AuthorWeight->count ) {
	#	return 1;
	# }

	# Prefetch the author and dist lists
	trace("Loading CPANTS Authors...");
	my @authors = ORDB::CPANTS::Author->select(
		'where pauseid is not null'
	);

	trace("Loading CPANTS Distributions...");
	my @dists = ORDB::CPANTS::Dist->select(
		'where author not in ( select id from author where pauseid is null )'
	);

	trace("Loading Kwalitee...");
	my $kwalitee = ORDB::CPANTS->selectall_hashref(
		'select * from kwalitee',
		'dist',
	);

	# Indexed table of weighting scores
	trace("Precalculating weight...");
	my $weight     = $self->algorithm_weight->weight_all;
	trace("Precalculating volatility...");
	my $volatility = $self->algorithm_volatility->weight_all;

	trace("Generating FAIL counts");
	my $fails = CPANTS::Weight->fail_report;

	# Populate the AuthorWeight objects
	trace("Populating Author metrics...");
	CPANTS::Weight->begin;
	CPANTS::Weight::AuthorWeight->truncate;
	foreach my $author ( @authors ) { ### Authors [===|    ] % done
		# Find the list of distros for this author
		my $id    = $author->id;
		# my @ids = grep { $_->author } @dists;
		CPANTS::Weight::AuthorWeight->create(
			id      => $author->id,
			pauseid => $author->pauseid,
		);
	}
	CPANTS::Weight->commit;

	# Populate the DistWeight objects
	trace("Populating Distribution metrics...");
	CPANTS::Weight->begin;
	CPANTS::Weight::DistWeight->truncate;
	foreach my $dist ( @dists ) { ### Distributions [===|    ] % done
		my $id = $dist->id;

		# Does this distribution make life difficult
		# for downstream packagers.
		my $k = $kwalitee->{$id} || {};
		my $enemy_downstream = $k->{easily_repackagable} ? 0 : 1;

		# Is this distribution popular, but NOT provided in
		# Debian, making it a good candidate for packaging.
		my $debian_candidate = $k->{distributed_by_debian} ? 0 : 1;

		# Does this distribution supply useful metadata.
		# Level 1 requires a parsable META.yml file
		# Level 2 requires META.yml conforms to a known specification,
		# and has a license declaration.
		# Level 3 requires META.yml conform to the current specification,
		# and declares the required minimum Perl version.
		my $meta1 = ($k->{has_meta_yml} and $k->{metayml_parsable}) ? 0 : 1;
		my $meta2 = ($k->{metayml_conforms_to_known_spec} and $k->{metayml_has_license}) ? 0 : 1;
		my $meta3 = ($k->{metayml_conforms_current_spec} and $k->{metayml_declares_perl_version}) ? 0 : 1;
		if ( $meta1 ) {
			$meta2 = 0;
		}
		if ( $meta1 or $meta2 ) {
			$meta3 = 0;
		}
		CPANTS::Weight::DistWeight->create(
			id               => $id,
			dist             => $dist->dist,
			author           => $dist->author,
			weight           => $weight->{$id},
			volatility       => $volatility->{$id} - 1,
			enemy_downstream => $enemy_downstream,
			debian_candidate => $debian_candidate,
			meta1            => $meta1,
			meta2            => $meta2,
			meta3            => $meta3,
			fails            => $fails->{$dist->dist} || 0,
		);
	}
	CPANTS::Weight->commit;

	# Manually remove bogus records
	my $sth = CPANTS::Weight->prepare('delete from dist_weight where dist = ?');
	$sth->execute('Msql-Mysql-modules');
	$sth->execute('HTTP-BrowserDetect');
	$sth->execute('HTML-Widgets-Index');
	$sth->execute('Text-Tabs+Wrap');
	$sth->execute('FreeWRL');
	$sth->execute('Apache-LoggedAuthDBI');
	$sth->execute('Win32-File-Summary'); #contains Archive::Tar, IO::Zlib
	$sth->finish;

	return 1;
}





#####################################################################
# Utility Methods

sub algorithm_weight {
	my $self = shift;
	unless ( $self->{algorithm_weight} ) {
		$self->{algorithm_weight} = Algorithm::Dependency::Weight->new(
			source => $self->source_weight,
		);
	}
	return $self->{algorithm_weight};
}

sub algorithm_volatility {
	my $self = shift;
	unless ( $self->{algorithm_volatility} ) {
		$self->{algorithm_volatility} = Algorithm::Dependency::Weight->new(
			source => $self->source_volatility,
		);
	}
	return $self->{algorithm_volatility};
}

sub source_weight {
	my $self = shift;
	unless ( $self->{source_weight} ) {
		$self->{source_weight} = Algorithm::Dependency::Source::DBI->new(
			dbh            => ORDB::CPANTS->dbh,
			select_ids     => "$SELECT_IDS",
			select_depends => "$SELECT_DEPENDS and ( is_prereq = 1 or is_build_prereq = 1 )",
		);
	}
	return $self->{source_weight};
}

sub source_volatility {
	my $self = shift;
	unless ( $self->{source_volatility} ) {
		$self->{source_volatility} = Algorithm::Dependency::Source::Invert->new(
			$self->source_weight,
		);
	}
	return $self->{source_volatility};
}

# Generate a FAIL count report
sub fail_report {
	my %fail    = ();
	my %version = ();

	# Build the statement
	my $rows = 0;
	my $sth  = ORDB::CPANTesters->prepare(<<'END_SQL') or die("prepare: $DBI::errstr");
		select dist, version, state, perl from cpanstats
		where state = ? or (
			state in ( ?, ? ) and
			perl not like ? and
			perl not like ? and
			(
				perl like ? or
				perl like ? or
				perl like ? or
				perl like ? or
				perl like ?
			)
		)
END_SQL
	$sth->execute(
		'cpan', 'fail', 'unknown', '%patch%', '%RC%',
		'5.4%', '5.5%', '5.6%', '5.8%', '5.10%'
	) or die("execute: $DBI::errstr");
	while ( my $row = $sth->fetchrow_arrayref ) {
		my ($dist, $version, $state) = @$row;

		# If this is the first time we've seen the distribution,
		# create the entry for it
		unless ( exists $fail{$dist} ) {
			$fail{$dist}    = 0;
			$version{$dist} = $version;
		}

		# Ignore developer releases and weird versions
		next unless defined $version;
		next unless $version =~ /^[\d\.]+$/;

		# If the version is older than the current version,
		# shortcut and go to the next row.
		my $vcmp = CPAN::Version->vcmp($version, $version{$dist});
		if ( $vcmp < 0 ) {
			next;
		}

		# If the version is newer than the current version,
		# reset the current fail count back to zero.
		if ( $vcmp > 0 ) {
			$fail{$dist}    = 0;
			$version{$dist} = $version;
		}

		# If the row is a FAIL or UNKNOWN record, increment the fail count
		if ( $state eq 'fail' or $state eq 'unknown' ) {
			$fail{$dist}++;
		}
	}

	return \%fail;
}

1;

=pod

=head2 dsn

  my $string = Foo::Bar->dsn;

The C<dsn> accessor returns the dbi connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = Foo::Bar->dbh;

To reliably prevent potential SQLite deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with ORLite's connection
management.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond the immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 begin

  Foo::Bar->begin;

The C<begin> method indicates the start of a transaction.

In the same way that ORLite allows only a single connection, likewise
it allows only a single application-wide transaction.

No indication is given as to whether you are currently in a transaction
or not, all code should be written neutrally so that it works either way
or doesn't need to care.

Returns true or throws an exception on error.

=head2 commit

  Foo::Bar->commit;

The C<commit> method commits the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the commit has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

Returns true or throws an exception on error.

=head2 rollback

The C<rollback> method rolls back the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the rollback has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

If a transaction exists at END-time as the process exits, it will be
automatically rolled back.

Returns true or throws an exception on error.

=head2 do

  Foo::Bar->do('insert into table (foo, bar) values (?, ?)', {},
      $foo_value,
      $bar_value,
  );

The C<do> method is a direct wrapper around the equivalent L<DBI> method,
but applied to the appropriate locally-provided connection or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = Foo::Bar->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a datase. See the SQLite documentation for more details.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANTS-Weight>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
