#! /usr/bin/env perl

use strict;
use warnings;
use File::Temp ();
use IO::Handle;

=head1 USAGE

  asm-test.pl [FILENAME|-]

where FILENAME is either assembly text, or binary machine code.
If FILENAME is '-' or missing, read STDIN.

=head1 OPTIONS

=over

=item -e

Evaluate a command line argument as assembly input

=back

=cut

use Getopt::Long 2.24 qw(:config no_ignore_case bundling permute);
sub pod2usage { require Pod::Usage; goto &Pod::Usage::pod2usage }
GetOptions(
	'help|?' => sub { pod2usage(1) },
	'e=s'    => \my $opt_input,
	'i=s'    => \my $opt_input_format,
	'o=s'    => \my $opt_output_format,
) or pod2usage(2);
$opt_input_format //= 'nasm';
$opt_output_format //= 'nasm';

if ($opt_input) {
	push @ARGV, make_tmpfile(fixup_input($opt_input));
}
push @ARGV, '-' unless @ARGV or defined $opt_input;
my $tmp;
for my $src (@ARGV) {
	my $fname;
	if (!ref $src && $src eq '-') {
		local $/= undef;
		$fname= make_tmpfile(fixup_input(<STDIN>));
	}
	else {
		$fname= ref $src? $src->filename : $src;
	}
	
	my $outfile= File::Temp->new(TEMPLATE => 'asm-XXXXXX', SUFFIX => '.o')
		or die "tmpfile: $!";
	
	if ($opt_input_format eq 'gas') {
		#open($asm, '-|:raw', 
	} else {
		system("nasm -o $outfile $fname") == 0 or die "nasm: $!";
	}
	
	if ($opt_output_format eq 'gas') {
		system("objdump -D -b binary -m i386:x86-64 $outfile | sed -e '0,/^00000000/d'")  == 0 or die "objdump: $!";
	} else {
		system("ndisasm -b 64 $outfile") == 0 or die "ndisasm: $!";
	}
}
sub fixup_input {
	my $text= shift;
	$text =~ s/([^;])\n/$1;\n/g;
	$text =~ s/;\s*([^\n])/;\n$1/g;
	$text =~ /^\[bits / or $text= "[bits 64]\n".$text;
	return $text;
}
sub make_tmpfile {
	my $data= shift;
	my $tmp= File::Temp->new(TEMPLATE => 'asm-XXXXXX', SUFFIX => '.asm')
		or die "tmpfile: $!";
	binmode $tmp;
	$tmp->print($data);
	$tmp->flush;
	return $tmp;
}
