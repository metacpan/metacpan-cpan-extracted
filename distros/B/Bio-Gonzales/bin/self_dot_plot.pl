#!/usr/bin/env perl
# NOTE: YOU MUST CHANGE THE LINE ABOVE TO POINT TO
# THE FULL PATH OF THE PERL EXECUTABLE ON YOUR SYSTEM.

# Please see copyright notice and system requirements
# in this document. 

# This program used to produce symmetric dot plots for:
# 
# Tomoko Kuroda-Kawaguchi, Helen Skaletsky, Laura G. Brown,
# Patrick J. Minx, Holland S. Cordum, Robert H. Waterston,
# Richard K. Wilson, Sherman Silber, Robert Oates, Steve
# Rozen & David C. Page. The AZFc region of the Y chromosome
# features massive palindromes and uniform recurrent
# deletions in infertile men. Nature Genetics, 29(3)
# (Nov. 2001), in press.

# Copyright (c) 2001 Helen Skaletsky and Whitehead Institute
# 
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the
# following conditions are met:
#
# 1.  Redistributions must reproduce the above copyright
# notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials
# provided with the distribution.  Redistributions of source
# code must also reproduce this information in the source code
# itself.
#
# 2.  If the program is modified, redistributions must
# include a notice (in the same places as above) indicating
# that the redistributed program is not identical to the
# version distributed by Whitehead Institute.
#
# 3.  All advertising materials mentioning features or use
# of this software must display the following
# acknowledgment:
#
#         This product includes software developed by 
#         Helen Skaletsky and the Whitehead Institute
#         for Biomedical Research.
#
# 4.  The name of the Whitehead Institute may not be used to
# endorse or promote products derived from this software
# without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE WHITEHEAD INSTITUTE AND
# HELEN SKALETSKY ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE WHITEHEAD
# INSTITUTE OR HELEN SKALETSKY BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# System requirements: requires perl and perl module GD.pm,
# available from CPAN (author LDS --- Lincoln D. Stein).
 
# For usage information, run this program with the flag
# -h.

require 5.10.0;

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;


use GD;
use strict;
use vars qw/$VERSION/;

our $VERSION = '1.0';

use Getopt::Long;

sub usage();
sub main();
sub print_dots ($$$$$$$$);
sub print_png ($$);

main();

sub usage() {
    print qq/
USAGE: $0 -w <word size> -s <step length>
          -i <in file> -o <out file> -d <dot file>
          -t <title>
          [ -h ]

Create a PNG ("portable network graphics") file
that displays a triangular dot plot of the input
sequence against itself.

<word size> is the word size for a match.  A dot
            is printed if there is a perfect match
            of length <word size>.

<step length> is the number of bases to move the
            word for each dot.

<in file>   is a fasta format file from which the
            sequence is taken.

<out file>  is the PNG file created.

<dot file>  contains 0 based positions of perfect
            matches of length <word size>.
            (E.g., the line "251 1077" means that
            substrings of length <word size>
            starting at 251 and at 1077 are
            identical.)

<title>     is a title to place in the output.

-h causes this message to printed.

(Version $VERSION)

/;
}

sub main() {

    my ($seqfile, $word, $step, $outfile, $title, $dotfile, $help);

    if (!GetOptions('infile=s'  => \$seqfile,
		    'wordlen=i' => \$word,
		    'step=i'    => \$step,
                    'outfile=s' => \$outfile,
                    'title=s'   => \$title,
		    'dotfile=s' => \$dotfile,
		    'help'      => \$help)) {
	usage;
	exit -1;
    }
    if ($help) {
	usage;
	exit;
    }

    if (!defined $word
	|| !defined $step
	|| !defined $seqfile
	|| !defined $outfile
	|| !defined $dotfile) {
	usage; exit -1;
    }
	    
    $title = '' unless defined $title;

    if ($word <= 0) {
	print STDERR "$0 -w <word size> must be >= 0\n";
	exit -1;
    }

    if ($step <= 0) {
	print STDERR "$0 -s <step length> must be >= 0\n";
	exit -1;
    }


    open(IN, $seqfile) || die "Cannot open $seqfile: $!";
    <IN>;
    my $seq = '';
    while(<IN>){
	chop;  $seq .= uc($_);
    }
    close IN;
    my $m = length($seq);

    my $k = 0; 
    my $n = $m - $word;

    open(OUT, ">$dotfile")
	|| die "Cannot write $dotfile: $!\n";

    while($k < $n) {
	my $s = substr($seq, $k, $word);
	while($seq =~ m/$s/g){
	    my $t = pos $seq; $t -= $word;
	    print OUT "$k\t$t\n";
	}
	my $s1 = reverse($s);
	$s1 =~ tr/ACGTURYMWSKDHVBN/TGCAAYRKWSMHDBVN/;
	while($seq =~ m/$s1/g){
	    my $t = pos $seq; $t -= $word;
	    print OUT "$k\t$t\n";
	}
	$k += $step;
    }
    close OUT;

    # Create and print the output.
    my $width = 700; my $height = 730; my $x0 = 30;
    my $img = new GD::Image($width, $height);
    my $white = $img->colorAllocate(255,255,255);
    my $black = $img->colorAllocate(0,0,0);
    my $gray = $img->colorAllocate(187,187,187);
    $img->interlaced('true');

    $x0 = 60; 
    $img->string(gdLargeFont, $x0, 30, 
		 "$title -w=$word -s=$step",
		 $black);
    $img->string(gdLargeFont, $x0, 0.5*$width-10,
		 "$m bp",
		 $black);
    print_dots($img, $width, $height, $x0, $black, $gray, $m, $dotfile);
    print_png($img, $outfile)
}

sub print_dots ($$$$$$$$) {
    my ($img, $width, $height, $x0, $black, $gray, $m, $dotfile) = @_;
    open(IN, $dotfile) || die "Cannot open $dotfile: $!\n";
    my ($x1, $y1, $del);
    $del = ($width - 80)/$m;
    my $count = 0;
    while(<IN>){
	chop; 
	my @x = split '\t';
	next if $x[1] < $x[0];
	# For progress report on very long run
        # if(int($count/10000)*10000 == $count){
        #    print STDERR "$x[0]   $x[1]\n";
	# }
	$x1 = $x0 + $del*$x[0];
	$y1 = $x0 + $del*$x[1];
	$img->setPixel(0.5*($x1+$y1), 
		       $width-0.5*($y1-$x1)-20-0.5*$width,
		       $black);
	$count++;
    }
    close IN;
    $img->line($x0, 0.5*$width-20, $width-20,
	       0.5*$width-20, $gray);
    $img->line(0.5*($x0+$width-20), 0.5*($x0-20),
	       $width-20, 0.5*$width-20, $gray);
    $img->line(0.5*($x0+$width-20), 0.5*($x0-20),
	       $x0, 0.5*$width-20, $gray);
}

sub print_png ($$) {
    my ($img, $outfile) = @_;
    if ($outfile) {
	open(OUT, ">$outfile")
	    || die "Cannot write $outfile: $!\n";
	print OUT $img->png;
	close OUT;
    } else {
	print $img->png;
    }
}
