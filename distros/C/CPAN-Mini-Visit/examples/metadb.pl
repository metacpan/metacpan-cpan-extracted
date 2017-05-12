#!/usr/bin/perl

use strict;
use File::Remove 'remove';
use File::Spec::Functions ':ALL';
use Parse::CPAN::Meta 'LoadFile';
use CPAN::Mini::Visit;
use DBI;

my $minicpan_location='D:\minicpan';

remove('metadb.sqlite');

my $dbh = DBI->connect('DBI:SQLite:metadb.sqlite');
$dbh->do(<<'END_SQL');
CREATE TABLE meta_dist (
	release TEXT NOT NULL,
	meta_name TEXT,
	meta_version TEXT,
	meta_abstract TEXT,
	meta_generated TEXT,
	meta_from TEXT,
	meta_license TEXT
);
END_SQL

$dbh->do(<<'END_SQL');
CREATE TABLE meta_deps (
	release TEXT NOT NULL,
	phase TEXT NOT NULL,
	module TEXT NOT NULL,
	version TEXT NOT NULL DEFAULT 0
)
END_SQL

$dbh->begin_work;
my $counter   = 0;
my @meta_dist = ();
my @meta_deps = ();
my $visit = CPAN::Mini::Visit->new(
	minicpan => $minicpan_location,
	callback => sub {
		print $_[0]->{dist} . "\n";
		my $dist = { release => $_[0]->{dist} };
		my @deps = ();
		my @yaml = eval {
			LoadFile( catfile(
				$_[0]->{tempdir}, 'META.yml',
			) );
		};
		unless ( $@ ) {
			$dist->{meta_name}      = $yaml[0]->{name};
			$dist->{meta_version}   = $yaml[0]->{version};
			$dist->{meta_abstract}  = $yaml[0]->{abstract};
			$dist->{meta_generated} = $yaml[0]->{generated_by};
			$dist->{meta_from}      = $yaml[0]->{version_from};
			$dist->{meta_license}   = $yaml[0]->{license},

			my $requires = $yaml[0]->{requires} || {};
			$requires = { $requires => 0 } unless ref $requires;
			push @deps, map { +{
				release => $_[0]->{dist},
				phase   => 'runtime',
				module  => $_,
				version => $requires->{$_},
			} } sort keys %$requires;

			my $build = $yaml[0]->{build_requires} || {};
			$build = { $build => 0 } unless ref $build;
			push @deps, map { +{
				release => $_[0]->{dist},
				phase   => 'build',
				module  => $_,
				version => $build->{$_},
			} } sort keys %$build;

			my $configure = $yaml[0]->{configure_requires} || {};
			$configure = { $configure => 0 } unless ref $configure;
			push @deps, map { +{
				release => $_[0]->{dist},
				phase   => 'configure',
				module  => $_,
				version => $configure->{$_},
			} } sort keys %$configure;
		}
		$dbh->do(
			'INSERT INTO meta_dist VALUES ( ?, ?, ?, ?, ?, ?, ? )', {},
			$dist->{release},
			$dist->{meta_name},
			$dist->{meta_version},
			$dist->{meta_abstract},
			$dist->{meta_generated},
			$dist->{meta_from},
			$dist->{meta_license},
		);
		foreach ( @deps ) {
			$dbh->do(
				'INSERT INTO meta_deps VALUES ( ?, ?, ?, ? )', {},
				$_->{release},
				$_->{phase},
				$_->{module},
				$_->{version},
			);
		}
		if ( ++$counter % 100 ) {
			$dbh->commit;
			$dbh->begin_work;
		}
	},
)->run;
$dbh->commit;
