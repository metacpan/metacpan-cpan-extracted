#!/usr/bin/perl

use Text::Template;
use strict;
our $OUT;

my $file = shift or die 'file name not supplied';
my $out = "${file}-out";

my $template = Text::Template->new
    (TYPE => 'FILE',  SOURCE => $file, DELIMITERS => [ '<tt>', '</tt>' ]);
        
sub pod_include {
    my ($file, $indent, $prepend) = @_;

    open F, $file or die "couldnt open file : $!";
    
    $OUT = $prepend;

    my $spaces = " " x $indent;

    while (<F>) {
	$OUT .= "$spaces$_";
    }
    $OUT;
}

sub pod_code {
    
    my $file = shift or die "NO FILE SUPPLIED";
    my $show_filename = shift;
    my $flag = " #\n #   $file\n #\n \n" if $show_filename;
    pod_include($file, 1, $flag);

}

open O, ">$out" or die "couldnt open $out: $!";

print O $template->fill_in;

close(O);

