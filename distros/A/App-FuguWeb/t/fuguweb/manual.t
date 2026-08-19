#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Manual: the name, the section, the page, the staged
# name, and the description of one manual source.
#
# The test builds its sources in a File::Temp directory. It never reads
# the repository, so a change under man/ or lib/ cannot break it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Manual');

my $ROOT = tempdir( CLEANUP => 1 );

# write_source($relative, $text):
#	Write one source below the temporary root and return its path.
sub write_source ( $relative, $text )
{
	my $path = "$ROOT/$relative";
	my $dir  = $path =~ s{/[^/]+$}{}r;
	make_path($dir);

	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $text;
	close $fh;

	return $path;
}

# A group is a plain object here. The test asks Manual about a manual,
# not Config about a group.
{

	package TestGroup;
	sub new ( $class, $namespace = undef )
	{
		return bless { namespace => $namespace }, $class;
	}
	sub namespace ($self) { return $self->{namespace}; }
}

subtest 'an mdoc page takes its name and section from the file' => sub {
	my $path = write_source( 'man/openhap/hapctl.8', <<'MDOC' );
.Dd $Mdocdate: July 27 2026 $
.Dt HAPCTL 8
.Os
.Sh NAME
.Nm hapctl
.Nd control utility for openhapd
MDOC

	my $manual =
	    App::FuguWeb::Manual->from_mdoc( $path, TestGroup->new );

	is( $manual->name,        'hapctl',          'the name' );
	is( $manual->section,     '8',               'the section' );
	is( $manual->page,        'hapctl.8.html',   'the page' );
	is( $manual->staged_name, 'hapctl.8',        'the staged name' );
	is( $manual->path,        $path,             'the path' );
	ok( !$manual->is_pod, 'an mdoc page is not a sidecar' );
	is( $manual->description, 'control utility for openhapd',
		'the .Nd description' );
};

subtest 'a group namespace prefixes the name and the staged name' => sub {
	my $path = write_source( 'man/fugu/Daemon.3p', <<'MDOC' );
.Dd $Mdocdate: July 27 2026 $
.Dt DAEMON 3p
.Os
.Sh NAME
.Nm Fugu::Daemon
.Nd daemonize a process the OpenBSD way
MDOC

	my $manual =
	    App::FuguWeb::Manual->from_mdoc( $path,
		TestGroup->new('Fugu::') );

	is( $manual->name,    'Fugu::Daemon', 'the namespace prefixes' );
	is( $manual->section, '3p',           'the section' );
	is( $manual->page, 'Fugu::Daemon.3p.html', 'the page' );

	# mandoc reads a .Xr target as a local link only when a file
	# named %N.%S sits in its working directory.
	is( $manual->staged_name, 'Fugu::Daemon.3p', 'the staged name' );
};

subtest 'a nested sidecar takes its name from its path' => sub {
	my $path = write_source( 'lib/App/OpenHAP/Tasmota/Heater.pod',
		<<'POD' );
=head1 NAME

App::OpenHAP::Tasmota::Heater - a Tasmota heater

=head1 DESCRIPTION

Words.
POD

	my $manual =
	    App::FuguWeb::Manual->from_pod( $path, TestGroup->new,
		"$ROOT/lib" );

	is( $manual->name, 'App::OpenHAP::Tasmota::Heater', 'the name' );
	is( $manual->section, '3p', 'a sidecar is always 3p' );
	is( $manual->page, 'App::OpenHAP::Tasmota::Heater.3p.html',
		'the page' );
	ok( $manual->is_pod, 'a sidecar is a sidecar' );
	is( $manual->description, 'a Tasmota heater',
		'the =head1 NAME description' );
};

subtest 'a source with no description answers undef' => sub {
	my $mdoc = write_source( 'man/openhap/quiet.5', <<'MDOC' );
.Dd $Mdocdate: July 27 2026 $
.Dt QUIET 5
.Os
.Sh NAME
.Nm quiet
MDOC
	is( App::FuguWeb::Manual->from_mdoc( $mdoc, TestGroup->new )
		    ->description,
		undef, 'an mdoc page with no .Nd' );

	my $pod = write_source( 'lib/Quiet.pod', <<'POD' );
=head1 DESCRIPTION

Words, but no NAME section.
POD
	is( App::FuguWeb::Manual->from_pod( $pod, TestGroup->new,
			"$ROOT/lib" )->description,
		undef, 'a sidecar with no NAME section' );

	my $bare = write_source( 'lib/Bare.pod', <<'POD' );
=head1 NAME

Bare

=head1 DESCRIPTION

Words.
POD
	is( App::FuguWeb::Manual->from_pod( $bare, TestGroup->new,
			"$ROOT/lib" )->description,
		undef, 'a NAME section with no dash' );

	my $missing = "$ROOT/lib/NoSuchFile.pod";
	is( App::FuguWeb::Manual->from_pod( $missing, TestGroup->new,
			"$ROOT/lib" )->description,
		undef, 'a source that does not open' );
};

subtest 'the description is the first one and nothing after it' => sub {
	my $path = write_source( 'man/openhap/twice.5', <<'MDOC' );
.Sh NAME
.Nm twice
.Nd the first description
.Sh DESCRIPTION
.Nd the second description
MDOC

	is( App::FuguWeb::Manual->from_mdoc( $path, TestGroup->new )
		    ->description,
		'the first description', 'the first .Nd wins' );
};

done_testing();
