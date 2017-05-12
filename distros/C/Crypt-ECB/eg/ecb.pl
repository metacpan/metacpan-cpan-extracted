#!/usr/bin/perl -w

use Getopt::Std;
use Crypt::ECB;

use strict;

my $usage = "Usage: ecb.pl [-d] [-c <cipher>] [-p <padding>] [-k <key>] [-f <keyfile>]
    or ecb.pl -l
    or ecb.pl -v

Encrypt/decrypt files using ECB mode. Reads from STDIN, writes to STDOUT.

Options:
  -l		list available ciphers
  -d		decrypt (default mode is encrypt)
  -k <key>	key to use
  -f <keyfile>	file containing key; either -k or -f must be specified
  -c <cipher>	block cipher to use, defaults to 'Rijndael' (AES)
  -p <padding>	padding mode to use, possible values are 'standard' (default),
		'zeroes', 'oneandzeroes', 'rijndael_compat', 'null', 'space'
		and 'none'. See Crypt::ECB for details on the different modes.
  -v		print Crypt::ECB version
";

my $version = "Using Crypt::ECB version $Crypt::ECB::VERSION.\n";

my $options = {}; getopts('vldc:p:k:f:', $options) || die $usage;

print($version), exit(0) if $options->{v};
list_ciphers(),  exit(0) if $options->{l};

die $usage unless $options->{k} or $options->{f};

sub slurp { open(F,$_[0]) || die "Couldn't open $_[0]: $!\n"; local $/; return <F> }

my $key		= $options->{k} || slurp($options->{f});
my $cipher	= $options->{c} || 'Rijndael';	# AES
my $padding	= $options->{p} || 'standard';
my $mode	= $options->{d}  ? 'decrypt' : 'encrypt';

my $ecb = Crypt::ECB->new(-key => $key,	-cipher	=> $cipher, -padding => $padding);

$ecb->start($mode);
print $ecb->crypt while read(STDIN, $_, 1024);
print $ecb->finish;

exit(0);


sub list_ciphers
{
	print "Checking your perl installation for block ciphers compliant with Crypt::ECB...\n";

	my ($ecb, $ok) = (Crypt::ECB->new, 0);

	close STDERR;	# avoid strange error messages from modules tried

	foreach my $path (@INC)
	{
		while (<$path/Crypt/*.pm $path/Crypt/*/*.pm>)
		{
			next unless /\.pm$/;

			s|^.*Crypt/||;
			s|\.pm$||;
			s|/|::|g;

			eval { $ecb->cipher($_) };

			printf(" found %-25s (keysize: %2s, blocksize: %2s)\n",
				"$_ ".$ecb->module->VERSION, $ecb->keysize, $ecb->blocksize)	if !$@ and ++$ok;
		}
	}

	print "There do not seem to be any block ciphers installed (at least none which I can\n"
	    . "use). Crypt::ECB will not be of any use to you unless you install some suitable\n"
	    . "cipher module(s).\n" unless $ok;
}
