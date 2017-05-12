#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 23;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use CPAN::Mini::Visit ();

my $minicpan = {
	local        => catdir('t', 'minicpan'),
	remote       => 'http://cpan.strawberryperl.com/',
	offline      => 1,
	skip_cleanup => 1,
};
ok( -d $minicpan->{local}, "Found root minicpan '$minicpan->{local}'" );

my @data  = ();
my $visit = new_ok( 'CPAN::Mini::Visit' => [
	minicpan => $minicpan,
	acme     => 0,
	ignore   => [ qr/\bFile\b/ ],
	callback => sub {
		push @data, { %{ $_[0] } };
	},
] );

# Kick off the visit
ok( $visit->run, '->run ok' );

# Do a detailed check of the results
is( scalar(@data), 3, 'Triggered three visits' );
ok( -f $data[0]->{archive} );
is( $data[0]->{author}, 'ADAMK' );
ok( ! -d $data[0]->{tempdir} );
is( $data[0]->{dist}, 'ADAMK/CSS-Tiny-1.15.tar.gz' );
ok( -f $data[1]->{archive} );
is( $data[1]->{author}, 'ADAMK' );
is( $data[1]->{dist}, 'ADAMK/Config-Tiny-2.12.tar.gz' );
ok( ! -d $data[1]->{tempdir} );
ok( -f $data[2]->{archive} );
is( $data[2]->{author}, 'ANDYA' );
is( $data[2]->{dist}, 'ANDYA/HTML-Tiny-1.05.tar.gz' );
ok( ! -d $data[2]->{tempdir} );

# Check the acme option
my $acme = new_ok( 'CPAN::Mini::Visit' => [
	minicpan => $minicpan,
	acme     => 1,
	callback => sub {
		push @data, { %{ $_[0] } };
	},
] );
ok( $acme->run, 'Acme ->run ok' );
is( scalar(@data), 7, 'Acme triggered four visits' );

# Check the author option
my $author = new_ok( 'CPAN::Mini::Visit' => [
	minicpan => $minicpan,
	author   => 'ADAMK',
	acme     => 0,
	callback => sub {
		push @data, { %{ $_[0] } };
	},
] );
ok( $author->run, 'Author ->run ok' );
is( scalar(@data), 9, 'Author triggered two visits' );
