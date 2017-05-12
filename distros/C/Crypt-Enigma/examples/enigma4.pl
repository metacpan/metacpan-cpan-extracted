#!/usr/bin/perl -w

use Crypt::Enigma;

unless( defined($ARGV[0]) ) {
	print "Usage: ./enigma.pl 'plain text or encrypted string'\n";
	exit( 0 );
};

my $text = $ARGV[0];

my $args = {
	rotors       => [ 'RotorII', 'RotorIII', 'RotorVI' ],
	startletters => [ 'A', 'C', 'D' ],
	ringsettings => [ '0', '10', 15 ],
	reflector    => 'ReflectorB',
};

my $enigma = Crypt::Enigma->new( $args );

$enigma->setDebug( 1 );

$enigma->setSteckerBoard( [ 'G', 'D', 'Z', 'C' ] );
$enigma->setReflector( 'ReflectorCdunn' );

print "Plain text:\t$text\n";
print "Cipher Text:\t", $enigma->cipher( $text ), " \n";

$enigma->dumpSettings;

