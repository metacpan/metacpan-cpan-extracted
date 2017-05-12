#!perl -w

BEGIN
{
	chdir 't' if -d 't';
}

use strict;
use Test::More tests => 2;

use_ok( 'Crypt::CipherSaber' );

my $cs = Crypt::CipherSaber->new( 'sdrawkcabsihtdaeR' );
open( INPUT, 'smiles.cs1' ) or die "Couldn't open: $!";
binmode(INPUT);
open(OUTPUT, '> smiles.png') or die "Couldn't open: $!";
binmode(OUTPUT);
$cs->fh_crypt(\*INPUT, \*OUTPUT);
close INPUT;
close OUTPUT;

open(TEST, 'smiles.png') or die "Couldn't open: $!";
my $line = <TEST>;

like( $line, qr/PNG/, 'Encrypting a large file should not mangle it' );
