#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use Getopt::Long;
use Crypt::Komihash qw(komihash_hex komihash);

my $debug   = 0;
my $hex     = 0;
my $decimal = 0;
my $GLOBAL_SEED    = undef;
GetOptions(
	'debug'   => \$debug,
	'hex'     => \$hex,
	'decimal' => \$decimal,
	'seed=i'  => \$GLOBAL_SEED,
);

###############################################################################
###############################################################################

my $file  = $ARGV[0] || "";
if (!@ARGV) {
	die(usage());
}

my @lines;
if (-r $file) {
	@lines = file_get_contents($file, 1);
} else {
	@lines = @ARGV;
}

foreach my $l (@lines) {
	my $input = trim($l);
	my $hash  = '';
	my $func  = '';
	my $seed  = perl_rand64();

	if (defined($GLOBAL_SEED)) {
		$seed = $GLOBAL_SEED;
	}

	if ($hex) {
		$hash = komihash_hex($input, $seed);
		$func = 'komihash_hex';

		printf("cmp_ok($func(%15s, %23llu), 'eq', '%s');\n", "\"$input\"", $seed, $hash);
	} else {
		$hash = komihash($input, $seed);
		$func = 'komihash';

		printf("cmp_ok($func(%15s, %23llu), '==', %u);\n", "\"$input\"", $seed, $hash);
	}

}

###############################################################################
###############################################################################

sub trim {
	my ($s) = (@_, $_); # Passed in var, or default to $_
	if (!defined($s) || length($s) == 0) { return ""; }
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
    my ($str, $txt) = @_;

    # If we're NOT connected to a an interactive terminal don't do color
    if (-t STDOUT == 0) { return $txt || ""; }

    # No string sent in, so we just reset
    if (!length($str) || $str eq 'reset') { return "\e[0m"; }

    # Some predefined colors
    my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
    $str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

    # Get foreground/background and any commands
    my ($fc,$cmd) = $str =~ /^(\d{1,3})?_?(\w+)?$/g;
    my ($bc)      = $str =~ /on_(\d{1,3})$/g;

    if (defined($fc) && int($fc) > 255) { $fc = undef; } # above 255 is invalid

    # Some predefined commands
    my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
    my $cmd_num = $cmd_map{$cmd // 0};

    my $ret = '';
    if ($cmd_num)      { $ret .= "\e[${cmd_num}m"; }
    if (defined($fc))  { $ret .= "\e[38;5;${fc}m"; }
    if (defined($bc))  { $ret .= "\e[48;5;${bc}m"; }
    if (defined($txt)) { $ret .= $txt . "\e[0m";   }

    return $ret;
}

sub file_get_contents {
	open(my $fh, "<", $_[0]) or return undef;
	binmode($fh, ":encoding(UTF-8)");

	my $array_mode = ($_[1]) || (!defined($_[1]) && wantarray);

	if ($array_mode) { # Line mode
		my @lines  = readline($fh);

		# Right trim all lines
		foreach my $line (@lines) { $line =~ s/[\r\n]+$//; }

		return @lines;
	} else { # String mode
		local $/       = undef; # Input rec separator (slurp)
		return my $ret = readline($fh);
	}
}

sub file_put_contents {
	my ($file, $data) = @_;

	open(my $fh, ">", $file) or return undef;
	binmode($fh, ":encoding(UTF-8)");
	print $fh $data;
	close($fh);

	return length($data);
}

sub usage {
	my $ret = "$0 [input.txt] [word1] [word2]\n";

	return $ret;
}

# Creates methods k() and kd() to print, and print & die respectively
BEGIN {
	if (eval { require Data::Dump::Color }) {
		*k = sub { Data::Dump::Color::dd(@_) };
	} else {
		require Data::Dumper;
		*k = sub { print Data::Dumper::Dumper(\@_) };
	}

	sub kd {
		k(@_);

		printf("Died at %2\$s line #%3\$s\n",caller());
		exit(15);
	}
}

sub perl_rand64 {
	my $high = int(rand() * 4294967295);
	my $low  = int(rand() * 4294967295);

	my $ret = ($high << 32) | $low;

	return $ret;
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
