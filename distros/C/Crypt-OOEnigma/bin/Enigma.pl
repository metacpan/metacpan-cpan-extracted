#!/usr/bin/perl -w
#
# sample.pl:
#
# Copyright (c) 2002 Ambriel Consulting
# sjb Mon Mar 18 20:55:53 GMT 2002
#

use vars qw($opt_h);
use Getopt::Std;
use Crypt::OOEnigma;

#
# usage: display usage message
#
sub usage() {
    print<<EOF;
usage: $0 [ options ] message

Options:
    -h Displays this help message

EOF
    exit(1);
}

#
# main:
#

getopts("h");

if ($opt_h or @ARGV == 0) {
    usage();
}

my $source = $ARGV[0];

my $e       = new Crypt::OOEnigma;
my $code    = $e->encipher($source);
my $decode  = $e->decipher($code);
print "With a default Enigma:\n";
print "$source is enciphered as $code and deciphered as $decode\n";

$e       = Crypt::OOEnigma->new( start_positions => [10,20,5]);
$code    = $e->encipher($source);
$decode  = $e->decipher($code);
print "An Enigma with chosen start positions:\n";
print "$source is enciphered as $code and deciphered as $decode\n";

$e       = Crypt::OOEnigma->new( rotor_choice    => [3,4,5],
                                 start_positions => [10,20,5]);
$code    = $e->encipher($source);
$decode  = $e->decipher($code);
print "An Enigma with chosen start positions and rotors:\n";
print "$source is enciphered as $code and deciphered as $decode\n";

exit ;

