#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use File::Spec qw();
use JSON::PP ();
use Test::More;

BEGIN {
	if ( !$ENV{RELEASE_TESTING} ) {
		plan skip_all =>
			'set RELEASE_TESTING=1 to run Module::CPANTS::Analyse (slow / heavy deps)';
	}
	if ( !eval { require Module::CPANTS::Analyse; 1 } ) {
		plan skip_all =>
			'Module::CPANTS::Analyse is required for this author test ($^X): '
			. ( $@ || 'unknown error' );
	}
	if ( !eval { require Module::CPANTS::Kwalitee; 1 } ) {
		plan skip_all =>
			'Module::CPANTS::Kwalitee is required for CPANTS (install with Analyse; $^X): '
			. ( $@ || 'unknown error' );
	}
	if ( !Module::CPANTS::Kwalitee->can('new') ) {
		plan skip_all =>
			'Module::CPANTS::Kwalitee has no new() — incompatible or stale install; '
			. 'reinstall: cpanm Module::CPANTS::Analyse Module::CPANTS::Kwalitee';
	}
}

my $dist_root = abs_path(getcwd);
my $mymeta    = File::Spec->catfile( $dist_root, 'MYMETA.json' );

if ( !-f $mymeta ) {
	my $rc = system( 'perl', 'Makefile.PL' );
	BAIL_OUT("perl Makefile.PL failed (exit $rc)") if $rc != 0;
}

open my $mfh, '<:raw', $mymeta
	or BAIL_OUT("Cannot open MYMETA.json: $!");
my $meta = JSON::PP::decode_json( do { local $/; <$mfh> } );
close $mfh;

my $tb_name = $meta->{name} . '-' . $meta->{version} . '.tar.gz';
my $tb_path = File::Spec->catfile( $dist_root, $tb_name );

if ( !-f File::Spec->catfile( $dist_root, 'Makefile' ) ) {
	my $rc = system( 'perl', 'Makefile.PL' );
	BAIL_OUT("perl Makefile.PL failed (exit $rc)") if $rc != 0;
}

my $make = $ENV{MAKE} || 'make';
if ( -e $tb_path ) {
	unlink $tb_path
		or BAIL_OUT("Cannot remove stale tarball $tb_path (gzip would prompt): $!");
}
{
	my $rc = system( $make, 'tardist' );
	BAIL_OUT("make tardist failed (exit $rc)") if $rc != 0;
}
-f $tb_path && -s _
	or BAIL_OUT("Expected tarball $tb_path after tardist");

my $an = eval {
	Module::CPANTS::Analyse->new( { dist => $tb_path, opts => {} } );
};
if ( !$an ) {
	plan skip_all =>
		'Module::CPANTS::Analyse->new failed ($^X): ' . ( $@ || 'unknown error' );
}

my $uerr = $an->unpack;

ok( !defined($uerr), 'CPANTS unpack' );
diag($uerr) if defined $uerr;

SKIP: {
	skip 'CPANTS unpack failed', 4 if defined $uerr;

	$an->analyse;
	$an->calc_kwalitee;

	my $d = $an->d;
	ok( $d->{extractable}, 'CPANTS extractable flag' )
		or diag( explain $d->{error} );

	my $k = $d->{kwalitee};
	ok( $k && ref $k eq 'HASH', 'CPANTS kwalitee hash present' );

	SKIP: {
		skip 'no CPANTS kwalitee hash', 2 unless $k && ref $k eq 'HASH';

		ok( defined $k->{kwalitee}, 'CPANTS aggregate kwalitee key present' );
		cmp_ok( $k->{kwalitee} // 0, '>', 0, 'CPANTS kwalitee score > 0' );

		for my $name ( sort keys %$k ) {
			next if $name eq 'kwalitee';
			next if $name eq 'extractable';
			next unless defined $k->{$name};
			next if $k->{$name};
			diag "CPANTS kwalitee indicator: FAIL $name";
		}
	}
}

if ( -f $tb_path ) {
	unlink $tb_path
		or diag "Could not remove tarball $tb_path (portability tests dislike *.tar.gz in tree): $!";
}

done_testing;
