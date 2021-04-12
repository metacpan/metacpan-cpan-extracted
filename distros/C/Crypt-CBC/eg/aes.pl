#!/usr/bin/perl

use lib '../blib/lib';

use Getopt::Std;
use Crypt::CBC;
use strict vars;

my %options;

getopts('edk:p:i:o:',\%options) || die <<USAGE;
Usage: aes.pl [options] file1 file2 file3...
    AES encrypt/decrypt files using Cipher Block Chaining mode, and
    the PBKDF2 key derivation function.
    
    It is compatible with files encrypted using 
    "openssl enc -pbkdf2 -aes-256-cbc".
Options:
       -e                  encrypt (default)
       -d                  decrypt
       -p,-k 'passphrase'  provide passphrase on command line
       -i file             input file
       -o file             output file
USAGE
    ;

@ARGV = $options{'i'} if $options{'i'};
push(@ARGV,'-') unless @ARGV;
open(STDOUT,">$options{'o'}") or die "$options{'o'}: $!"
    if $options{'o'};

my $decrypt = $options{'d'} and !$options{'e'};
my $key = $options{'k'} || $options{'p'} || get_key(!$decrypt);
my $cipher = Crypt::CBC->new(-pass   =>  $key,
			     -cipher => 'Crypt::Cipher::AES',
			     -pbkdf  => 'pbkdf2',
			     -chain_mode => 'ctr',
			    ) || die "Couldn't create CBC object";
$cipher->start($decrypt ? 'decrypt' : 'encrypt');

my $in;
while (@ARGV) {
    my $file = shift @ARGV;
    open(ARGV,$file) || die "$file: $!";
    print $cipher->crypt($in) while read(ARGV,$in,1024);
    close ARGV;
}
print $cipher->finish;

sub get_key {
    my $verify = shift;
    
    local($|) = 1;
    local(*TTY);
    open(TTY,"/dev/tty");
    my ($key1,$key2);
    system "stty -echo </dev/tty";
    do {
	print STDERR "AES key: ";
        chomp($key1 = <TTY>);
	if ($verify) {
	    print STDERR "\r\nRe-type key: ";
	    chomp($key2 = <TTY>);
	    print STDERR "\r\n";
	    print STDERR "The two keys don't match. Try again.\r\n"
		unless $key1 eq $key2;
	} else {
	    $key2 = $key1;
	}
    } until $key1 eq $key2;
    system "stty echo </dev/tty";
    close(TTY);
    $key1;
}
