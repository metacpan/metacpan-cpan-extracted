package CPANDB::Generator;

=pod

=head1 NAME

CPANDB::Generator - Generator module for the CPAN Index Database

=head1 SYNOPSIS

  # Simplicity itself
  CPANDB::Generator->new->run;

=head1 DESCRIPTION

This is a module used to generate a unified index database, pulling in
data from various other sources to produce a single schema that contains
the essential elements from all of them.

It is uploaded to the CPAN for the purpose of full disclosure, or in case
the author gets hit by a bus. Generating the index database involves
downloading a number of relatively large SQLite datasets, the consumption
of several gigabytes of disk, and a fairly large amount of CPU time.

If you are interested in using the index database, you should
instead see the L<CPANDB> distribution.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use Carp                                    ();
use File::Spec                         3.30 ();
use File::Temp                         0.21 ();
use File::Path                         2.07 ();
use File::pushd                        1.00 ();
use File::Remove                       1.42 ();
use File::HomeDir                      0.86 ();
use File::Basename                          ();
use Params::Util                       1.00 ();
use URI                                1.37 ();
use URI::file                               ();
use DBI                               1.608 ();
use DBD::SQLite                        1.25 ();
use CPAN::SQLite                      0.197 ();
use CPAN::Mini::Visit                  0.11 ();
use LWP::UserAgent                    5.819 ();
use Xtract::Publish                    0.10 ();
use Algorithm::Dependency             1.108 ();
use Algorithm::Dependency::Weight           ();
use Algorithm::Dependency::Source::DBI 1.06 ();

our $VERSION = '0.19';

use Object::Tiny 1.06 qw{
	cpan
	urllist
	sqlite
	publish
	trace
	dbh
	cpanmeta
	minicpan
};

use CPANDB::Generator::GetIndex ();





#####################################################################
# Constructor

=pod

=head2 new

  my $cpan = CPANDB::Generator->new(
      cpan   => '/root/.cpan',
      sqlite => '/root/CPANDB.sqlite',
  );

Creates a new generation object.

The optional C<cpan> param identifies the path to your
cpan operating directory. By default, a fresh one will be
generated in a temporary directory, and deleted at the end of
the generation run.

The optional C<sqlite> param specifies where the SQLite database
should be written to. By default, this will be to a standard
location in your home directory.

Returns a new B<CPANDB::Generator> object.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Default the CPAN path to a temp directory,
	# so that we don't disturb any existing files.
	unless ( defined $self->cpan ) {
		$self->{cpan} = File::Temp::tempdir( CLEANUP => 1 );
	}

	# Establish where we will be writing to
	unless ( defined $self->sqlite ) {
		$self->{sqlite} = File::Spec->catdir(
			File::HomeDir->my_data,
			($^O eq 'MSWin32' ? 'Perl' : '.perl'),
			'CPANDB-Generator',
			'cpan.db',
		);
	}

	# Set the default path to the publishing location
	unless ( exists $self->{publish} ) {
		$self->{publish} = 'cpan';
	}

	# If we have a minicpan and no urllist,
	# derive the latter from the former.
	if ( $self->minicpan and not $self->urllist ) {
		my $uri = URI::file->new( $self->minicpan, undef )->as_string;
		unless ( $uri =~ m/\/\z/ ) {
			$uri .= '/';
		}	
		$self->{urllist} = [ $uri ];
	}

	return $self;
}

=pod

=head2 dir

The C<dir> method returns the directory that the SQLite
database will be written into.

=cut

sub dir {
	File::Basename::dirname($_[0]->sqlite);
}

=pod

=head2 dsn

The C<dsn> method returns the L<DBI> DSN that is used to connect
to the generated database.

=cut

sub dsn {
	"DBI:SQLite:" . $_[0]->sqlite
}

=pod

=head2 cpan_sql

Once it has been fetched or updated from your CPAN mirror, the
C<cpan_sql> method returns the location of the L<CPAN::SQLite>
database used by the CPAN client.

This database is used as the source of the information that forms
the core of the unified index database, and that the rest of the
data will be decorated around.

=cut

sub cpan_sql {
	File::Spec->catfile($_[0]->cpan, 'cpandb.sql');
}





#####################################################################
# Main Methods

=pod

=head2 run

The C<run> method executes the process that will produce and fill the
final database.

=cut

sub run {
	my $self = shift;

	# Create the output directory
	File::Path::make_path($self->dir);
	unless ( -d $self->dir ) {
		Carp::croak("Failed to create '" . $self->dir . "'");
	}

	# Clear the database if it already exists
	if ( -f $self->sqlite ) {
		File::Remove::remove($self->sqlite);
	}
	if ( -f $self->sqlite ) {
		Carp::croak("Failed to clear " . $self->sqlite);
	}

	# Connect to the database
	unless ( $self->{dbh} = DBI->connect($self->dsn) ) {
		Carp::croak("connect: \$DBI::errstr");
	}

	# Allocate a lot more memory to cut down file churn
	$self->do('PRAGMA cache_size = 100000');

	# Refresh the CPAN index database
	$self->say("Fetching CPAN Index...");
	my $update = CPANDB::Generator::GetIndex->new(
		cpan    => $self->cpan,
		urllist => $self->urllist,
	)->delegate;
	unless ( -f $self->cpan_sql ) {
		Carp::croak("Failed to fetch CPAN index");
	}

	# Load the CPAN Uploads database
	$self->say("Fetching CPAN Uploads...");
	require ORDB::CPANUploads;
	ORDB::CPANUploads->import( {
		show_progress => 1,
	} );

	# Load the CPAN Testers database
	$self->say("Fetching CPAN Testers... (This may take a while)");
	require ORDB::CPANTesters;
	ORDB::CPANTesters->import( {
		show_progress => 1,
	} );

	# Load the CPAN META.yml database
	my $cpanmeta;
	if ( $self->cpanmeta ) {
		# Generate out own CPANMeta database
		$self->say("Generating META.yml Data...");
		require ORDB::CPANMeta::Generator;
		my $prefer_bin = $^O eq 'MSWin32' ? 0 : 1;
		$cpanmeta = ORDB::CPANMeta::Generator->new(
			minicpan   => $self->minicpan,
			trace      => $self->trace,
			prefer_bin => $prefer_bin,
			publish    => undef,
			warnings   => 1,
			delta      => 1,
		);
		$cpanmeta->run;
	} else {
		$self->say("Fetching META.yml Data...");
		require ORDB::CPANMeta;
		ORDB::CPANMeta->import;
	}

	# Attach the various databases
	my $cpanmeta_sqlite = $cpanmeta ? $cpanmeta->sqlite : ORDB::CPANMeta->sqlite;
	$self->do( "ATTACH DATABASE ? AS meta",    {}, $cpanmeta_sqlite          );
	$self->do( "ATTACH DATABASE ? AS cpan",    {}, $self->cpan_sql           );
	$self->do( "ATTACH DATABASE ? AS upload",  {}, ORDB::CPANUploads->sqlite );
	$self->do( "ATTACH DATABASE ? AS testers", {}, ORDB::CPANTesters->sqlite );

	# Pre-process the cpan data to produce cleaner intermediate
	# temp tables that produce better joins later on.
	$self->say("Cleaning CPAN Index...");
	$self->do(<<'END_SQL');
CREATE TABLE t_distribution AS
SELECT
	d.dist_name as dist,
	d.dist_vers as version,
	d.dist_name || ' ' || d.dist_vers as dist_version,
	a.cpanid as author,
	a.cpanid || '/' || d.dist_file as release
FROM
	auths a,
	dists d
WHERE
	a.auth_id = d.auth_id
END_SQL

	# Index the cleaned dist table
	$self->create_index( t_distribution => qw{
		dist
		version
		dist_version
		author
		release
	} );

	# Pre-process the uploads data to produce a cleaner intermediate
	# temp table that won't break the joins we'll need to do later on.
	$self->say("Cleaning CPAN Uploads...");
	$self->do(<<'END_SQL');
CREATE TABLE t_uploaded AS
SELECT
	author || '/' || filename as release,
	DATE(released, 'unixepoch') AS uploaded
FROM upload.uploads
END_SQL

	# Index the temporary tables so our joins don't take forever
	$self->create_index( t_uploaded => 'release' );

	# Pre-process the CPAN Testers results to produce a smaller
	# database that provides sub-totals for each dist/version/result.
	$self->say("Cleaning CPAN Testers (pass 1)...");
	$self->do(<<'END_SQL');
CREATE TABLE t_cpanstats AS
SELECT
	dist AS dist,
	dist || ' ' || version AS dist_version,
	state AS state
FROM testers.cpanstats
WHERE
	state IN ( 'pass', 'fail', 'unknown', 'na' )
	AND perl NOT LIKE '%patch%'
	AND perl NOT LIKE '%RC%'
	AND (
		perl LIKE '5.4%'
		OR perl LIKE '5.5%'
		OR perl LIKE '5.6%'
		OR perl LIKE '5.8%'
		OR perl LIKE '5.10%'
	)
	AND dist_version in (
		select dist_version from t_distribution
	)
	AND tester NOT LIKE '%dcollins%'
END_SQL

	# Step two, group into the smaller totals table
	$self->say("Cleaning CPAN Testers (pass 2)...");
	$self->do(<<'END_SQL');
CREATE TABLE t_testers AS
SELECT
	dist AS dist,
	state AS state,
	COUNT(*) AS total
FROM
	t_cpanstats
GROUP BY
	dist_version, state
END_SQL

	# Index the totals table
	$self->say("Cleaning CPAN Testers (indexing)...");
	$self->create_index( t_testers => qw{
		dist
		state
	} );

	# Create the author table
	$self->say("Generating table author...");
	$self->do(<<'END_SQL');
CREATE TABLE author (
	author TEXT NOT NULL PRIMARY KEY,
	name TEXT NOT NULL
)
END_SQL

	# Fill the author table
	$self->do(<<'END_SQL');
INSERT INTO author
SELECT
	cpanid AS author,
	fullname AS name
FROM
	cpan.auths
ORDER BY
	author
END_SQL

	# Index the author table
	$self->create_index( author => 'name' );

	# Create the distribution table
	$self->say("Generating table distribution...");
	$self->do(<<'END_SQL');
CREATE TABLE distribution (
	distribution TEXT NOT NULL PRIMARY KEY,
	version TEXT NULL,
	author TEXT NOT NULL,
	meta INTEGER NOT NULL,
	license TEXT NULL,
	release TEXT NOT NULL,
	uploaded TEXT NOT NULL,
	pass INTEGER NOT NULL,
	fail INTEGER NOT NULL,
	unknown INTEGER NOT NULL,
	na INTEGER NOT NULL,
	rating TEXT NULL,
	ratings INTEGER NOT NULL,
	weight INTEGER NOT NULL,
	volatility INTEGER NOT NULL,
	FOREIGN KEY ( author ) REFERENCES author ( author )
)
END_SQL

	# Fill the distribution table
	$self->do(<<'END_SQL');
INSERT INTO distribution
SELECT
	d.dist AS distribution,
	d.version AS version,
	d.author AS author,
	0 as meta,
	NULL as license,
	d.release AS release,
	u.uploaded AS uploaded,
	0 AS pass,
	0 AS fail,
	0 AS unknown,
	0 AS na,
	NULL AS rating,
	0 AS ratings,
	0 AS weight,
	0 AS volatility
FROM
	t_distribution d,
	t_uploaded u
WHERE
	d.release = u.release
ORDER BY
	distribution
END_SQL

	# Fetch the popular ratings for the distributions
	my $counter = 0;
	# require Parse::CPAN::Ratings;
	if ( Parse::CPAN::Ratings->VERSION ) {
		$self->say('Fetching CPAN Ratings...');
		my $ratings_url  = 'http://cpanratings.perl.org/csv/all_ratings.csv';
		my $ratings_dir  = File::Temp::tempdir( CLEANUP => 1 );
		my $ratings_file = File::Spec->catfile( $ratings_dir, 'all_ratings.csv' );
		my $response     = LWP::UserAgent->new(
			agent   => "CPANDB::Generator/$VERSION",
			timeout => 10,
		)->mirror( $ratings_url => $ratings_file );
		unless ( $response->is_success or $response->code == 304 ) {
			Carp::croak("Error: Failed to fetch $ratings_url");
		}
		my $ratings = Parse::CPAN::Ratings->new(
			filename => $ratings_file,
		) or Carp::croak("Error: Failed to parse $ratings_url");
		$self->say('Populating CPAN Ratings...');
		$self->dbh->begin_work;
		foreach my $rating ( $ratings->ratings ) {
			$self->do(
				'UPDATE distribution SET rating = ?, ratings = ? WHERE distribution = ?',
				{}, $rating->rating, $rating->review_count, $rating->distribution,
			);
			next if ++$counter % 100;
			$self->dbh->commit;
			$self->dbh->begin_work;
		}
		$self->dbh->commit;
	}

	# Create the module table
	$self->say("Generating table module...");
	$self->do(<<'END_SQL');
CREATE TABLE module (
	module TEXT NOT NULL PRIMARY KEY,
	version TEXT NULL,
	distribution TEXT NOT NULL,
	FOREIGN KEY ( distribution ) REFERENCES distribution ( distribution )
)
END_SQL

	# Fill the module table
	$self->do(<<'END_SQL');
INSERT INTO module
SELECT
	m.mod_name as module,
	m.mod_vers as version,
	d.dist_name as distribution
FROM
	mods m,
	dists d
WHERE
	d.dist_id = m.dist_id
ORDER BY
	module
END_SQL

	# Index the module table
	$self->create_index( module => qw{
		version
		distribution
	} );

	# Create the module dependency table
	$self->say("Generating table t_requires...");
	$self->do(<<'END_SQL');
CREATE TABLE t_requires (
	distribution TEXT NOT NULL,
	module TEXT NOT NULL,
	version TEXT NULL,
	phase TEXT NOT NULL,
	core REAL NULL
)
END_SQL

	# Fill the module dependency table
	$self->create_index( distribution => 'release' );
	$self->do(<<'END_SQL');
INSERT INTO t_requires
SELECT
	d.distribution AS distribution,
	m.module AS module,
	m.version AS version,
	m.phase AS phase,
	m.core AS core
FROM
	distribution d,
	meta.meta_dependency m
WHERE
	d.release = m.release
ORDER BY
	distribution,
	phase,
	core desc,
	module
END_SQL

	# Index the module dependency table
	$self->create_index( t_requires => qw{
		distribution
		module
		version
		phase
	} );

	# Create the distribution dependency table
	$self->say("Generating table dependency...");
	$self->do(<<'END_SQL');
CREATE TABLE dependency (
	distribution TEXT NOT NULL,
	dependency TEXT NOT NULL,
	phase TEXT NOT NULL,
	core REAL NULL,
	PRIMARY KEY ( distribution, dependency, phase ),
	FOREIGN KEY ( distribution ) REFERENCES distribition ( distribution ),
	FOREIGN KEY ( dependency ) REFERENCES distribution ( distribution )
)
END_SQL

	# Fill the distribution dependency table
	$self->do(<<'END_SQL');
INSERT INTO dependency
SELECT
	distribution,
	dependency,
	phase,
	core
FROM (
	SELECT	
		r.distribution as distribution,
		m.distribution as dependency,
		r.phase as phase,
		r.core as core
	FROM
		module m,
		t_requires r
	WHERE
		m.module == r.module
	ORDER BY
		distribution,
		phase,
		dependency,
		core
)
GROUP BY
	distribution,
	dependency,
	phase
END_SQL

	# Index the distribution dependency table
	$self->create_index( dependency => qw{
		distribution
		dependency
		phase
		core
	} );

	# Generate the final version of the requires table
	# dropping the unneeded core column.
	$self->say('Generating table requires...');
	$self->do(<<'END_SQL');
CREATE TABLE requires (
	distribution TEXT NOT NULL,
	module TEXT NOT NULL,
	version TEXT NULL,
	phase TEXT NOT NULL,
	PRIMARY KEY ( distribution, module, phase ),
	FOREIGN KEY ( distribution ) REFERENCES distribution ( distribution ),
	FOREIGN KEY ( module ) REFERENCES module ( module )
)
END_SQL

	# Fill it
	$self->do(<<'END_SQL');
INSERT INTO requires
SELECT
	distribution,
	module,
	version,
	phase
FROM
	t_requires
ORDER BY
	distribution,
	phase,
	module
END_SQL

	# Add the indexes
	$self->create_index( requires => qw{
		distribution
		module
		version
		phase
	} );

	# Derive the distribution weights
	$self->say('Generating column  distribution.weight...');
	SCOPE: {
		my $weight  = $self->weight->weight_all;
		$self->say('Populating column  distribution.weight...');
		$self->dbh->begin_work;
		foreach my $distribution ( sort keys %$weight ) {
			$self->do(
				'UPDATE distribution SET weight = ? WHERE distribution = ?',
				{}, $weight->{$distribution}, $distribution,
			);
			next if ++$counter % 100;
			$self->dbh->commit;
			$self->dbh->begin_work;
		}
		$self->dbh->commit;
	}

	# Derive the distribution volatility
	$self->say('Generating column  distribution.volatility...');
	SCOPE: {
		my $volatility = $self->volatility->weight_all;
		$self->say('Populating column  distribution.volatility...');
		$self->dbh->begin_work;
		foreach my $distribution ( sort keys %$volatility ) {
			$self->do(
				'UPDATE distribution SET volatility = ? WHERE distribution = ?',
				{}, $volatility->{$distribution} - 1, $distribution,
			);
			next if ++$counter % 100;
			$self->dbh->commit;
			$self->dbh->begin_work;
		}
		$self->dbh->commit;
	}

	# Populate distribution-level META.yml information
	$self->say('Generating columns distribution.(meta|license)...');
	SCOPE: {
		my $metas = $self->dbh->selectall_arrayref(
			'SELECT * FROM meta.meta_distribution',
			{ Slice => {} },
		);
		$self->dbh->begin_work;
		foreach my $meta ( @$metas ) {
			$self->do(
				'UPDATE distribution SET meta = ?, license = ? WHERE release = ?',
				{}, $meta->{meta}, $meta->{meta_license}, $meta->{release},
			);
			next if ++$counter % 100;
			$self->dbh->commit;
			$self->dbh->begin_work;
		}
		$self->dbh->commit;
	}

	# Fill the CPAN Testers totals
	$self->say("Generating columns distribution.(pass|fail|unknown|na)...");
	SCOPE: {
		my $testers = $self->dbh->selectall_arrayref(
			'SELECT * FROM t_testers', {}
		);
		$self->dbh->begin_work;
		foreach my $t ( @$testers ) {
			$self->do(
				"UPDATE distribution SET $t->[1] = ? WHERE distribution = ?",
				{}, $t->[2], $t->[0],
			);
			next if ++$counter % 100;
			$self->dbh->commit;
			$self->dbh->begin_work;
		}
		$self->dbh->commit;
	}

	# Index the rest of the distribution table
	$self->create_index( distribution => qw{
		version
		author
		meta
		license
		pass
		fail
		unknown
		na
		uploaded
		rating
		ratings
		weight
		volatility
	} );

	# Clean up tables
	$self->say("Dropping excess tables...");
	$self->do( "DROP TABLE t_requires"     );
	$self->do( "DROP TABLE t_distribution" );
	$self->do( "DROP TABLE t_uploaded"     );
	$self->do( "DROP TABLE t_cpanstats"    );
	$self->do( "DROP TABLE t_testers"      );

	# Clean up databases
	$self->say("Dropping attached databases...");
	$self->do( "DETACH DATABASE cpan"  );
	$self->do( "DETACH DATABASE upload"  );
	$self->do( "DETACH DATABASE meta"    );
	$self->do( "DETACH DATABASE testers" );

	# Shrink the main database file
	$self->say("Freeing excess space...");
	$self->do( "VACUUM" );

	# Optimise the indexes
	$self->say("Optimising indexes...");
	$self->do( "ANALYZE main" );

	# Publish the database to the current directory
	if ( defined $self->publish ) {
		$self->say('Publishing the generated database...');
		Xtract::Publish->new(
			from   => $self->sqlite,
			sqlite => $self->publish,
			trace  => $self->trace,
			raw    => 0,
			gz     => 1,
			bz2    => 1,
			lz     => 1,
		)->run;
	}

	return 1;
}

sub create_index {
	my $self  = shift;
	my $table = shift;
	foreach my $column ( @_ ) {
		$self->do("CREATE INDEX ${table}__${column} ON ${table} ( ${column} )");
	}
	return 1;
}





######################################################################
# Weight and Volatility Math

sub weight {
	Algorithm::Dependency::Weight->new(
		source => $_[0]->weight_source,
	);
}

sub weight_source {
	Algorithm::Dependency::Source::DBI->new(
		dbh            => $_[0]->dbh,
		select_ids     => "SELECT distribution FROM distribution WHERE distribution NOT LIKE 'Task-%' AND distribution NOT LIKE 'Acme-%'",
		select_depends => "SELECT DISTINCT distribution, dependency FROM dependency",
	);
}

sub volatility {
	Algorithm::Dependency::Weight->new(
		source => $_[0]->volatility_source,
	);
}

sub volatility_source {
	Algorithm::Dependency::Source::DBI->new(
		dbh            => $_[0]->dbh,
		select_ids     => "SELECT distribution FROM distribution",
		select_depends => "SELECT DISTINCT dependency, distribution FROM dependency",
	);
}





######################################################################
# Support Methods

sub do {
	my $self = shift;
	my $dbh  = $self->dbh;
	unless ( $dbh->do(@_) ) {
		Carp::croak("Database Error: " . $dbh->errstr);
	}
	return 1;
}

sub say {
	my $self = shift;
	if ( Params::Util::_CODE($self->trace) ) {
		$self->trace->say( @_ );
	} elsif ( $self->trace ) {
		my $t = scalar localtime time;
		print map { "[$t] $_\n" } @_;
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANDB-Generator>

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
