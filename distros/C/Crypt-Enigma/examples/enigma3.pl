#!/usr/bin/perl -w

use Crypt::Enigma;

unless( defined($ARGV[0]) ) {
	print "Usage: ./enigma.pl 'plain text or encrypted string'\n";
	exit( 0 );
};

my $text = $ARGV[0];

my $args = {
	rotors       => [ 'RotorI', 'RotorII', 'RotorIII', 'RotorVI' ],
	startletters => [ 'A', 'B', 'C', 'D' ],
	ringsettings => [ '0', '5', '10', 15 ],
	reflector    => 'ReflectorB',
};

my $enigma = Crypt::Enigma->new( $args );

$enigma->setDebug( 1 );

$enigma->setSteckerBoard( [ 'G' ] );

print "Plain text:\t$text\n";
print "Cipher Text:\t", $enigma->cipher( $text ), " \n";

$enigma->dumpSettings;

