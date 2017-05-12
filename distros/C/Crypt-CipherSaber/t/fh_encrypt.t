#!perl -w

BEGIN
{
	chdir 't' if -d 't';
}

use strict;
use Test::More tests => 6;
use_ok( 'Crypt::CipherSaber' );

# tests the fh_crypt() method
# this will fail if the state array is not reinitialized ... oops!
use Crypt::CipherSaber;
use File::Spec;

open( IN, 'smiles.cs1' ) or die "Can't get IV!\n";
binmode(IN);
my $iv = unpack( "a10", <IN> );

# encrypt a message
my $cs = Crypt::CipherSaber->new( 'sdrawkcabsihtdaeR' );
open( IN,  'smiles.png' )      or die "Can't open input file!\n";
open( OUT, '> outsmiles.cs1' ) or die "Can't open output file!\n";
binmode(IN);
binmode(OUT);

ok( $cs->fh_crypt( \*IN, \*OUT, $iv ),
	'fh_crypt() should return true if everything works' );

open( ENCRYPTED, 'outsmiles.cs1' ) or die "Can't open encrypted file!\n";
open( FIXED,     'smiles.cs1' )    or die "Can't open fixed file!\n";
binmode(ENCRYPTED);
binmode(FIXED);

my $status = 0;
while (<ENCRYPTED>)
{
	my $fixed = <FIXED>;
	my $pos   = 0;
	for my $char ( split( //, $_ ) )
	{
		next if ( substr( $fixed, $pos++, 1 ) eq $char );
		$status = 1;
	}
	last if $status;
}

ok( ! $status,	
	'There should be no characters in common between input and output' );

open( IN,  'smiles.cs1' )      or die "Can't open input file 2!\n";
open( OUT, '> outsmiles.png' ) or die "Can't open output file 2!\n";
binmode(IN);
binmode(OUT);

ok( $cs->fh_crypt( \*IN, \*OUT ),
	'fh_crypt() should return true if everything works (decrypting)' );

close(IN);
close(OUT);

open( ENCRYPTED, 'outsmiles.png' ) or die "Can't open encrypted file!\n";
open( FIXED,     'smiles.png' )    or die "Can't open fixed file!\n";
binmode(ENCRYPTED);
binmode(FIXED);

$status = 0;
while (<ENCRYPTED>)
{
	my $fixed = <FIXED>;
	unless ($_ eq $fixed)
	{
		$status = 1;
		last;
	}
}

close(ENCRYPTED);
close(FIXED);

ok( ! $status, '... with no characters in common' );
open( IN, 'smiles.png' )      or die "Cannot read smiles.png: $!";
open( OUT, '> smiles_2.cs1' ) or die "Cannot write to smiles_2.cs1: $!";
binmode( IN );
binmode( OUT );
$cs->fh_crypt( \*IN, \*OUT, 1 );
close IN;
close OUT;

open( IN, 'smiles_2.cs1'    ) or die "Cannot read smiles_2.cs1: $!";
open( OUT, '> smiles_2.png' ) or die "Cannot write to smiles_2.png $!";
binmode( IN );
binmode( OUT );
$cs->fh_crypt( \*IN, \*OUT );
close IN;
close OUT;

open( SOURCE, 'smiles.png' )   or die "Cannot read smiles.png: $!";
open( DEST,   'smiles_2.png' ) or die "Cannot read smiles_2.png: $!";

binmode SOURCE;
binmode DEST;

$status = 0;
while (<SOURCE>)
{
	unless ($_ eq <DEST>)
	{
		$status = 1;
		last;
	}
}

ok( ! $status, 'autogenerating and autoreading IV should also round-trip' );

END
{
	1 while unlink qw( smiles_2.cs1 smiles_2.png outsmiles.cs1 outsmiles.png );
}
