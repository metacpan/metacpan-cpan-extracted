#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use HTTP::Status;
use Apache2::Const qw( 
    :common :http 
);

use YAML;
my @tags;

my %syms = %Apache2::Const:: ;
CONST_SYM:
for my $sym ( sort keys %syms ) {
    my $code = *{$syms{$sym}}{CODE};
    push @tags, $sym if defined $code && uc $sym eq $sym;
}

my %numbers;

for my $tag (@tags) {
    my $number;
    eval '$number = Apache2::Const::'.$tag.';';
    $numbers{$tag} = $number;
}

print sprintf(
    "%3s %35s %35s %35s", 'RC', 'Apache2::Const::*', 'HTTP::Status status_message'
), "\n", '-' x 77, "\n";

for my $tag (sort { $numbers{$a} <=> $numbers{$b} } @tags) {
    my $number = $numbers{$tag};
    my $lookup = status_message($number) || '-';
    print sprintf("%03d %35s %35s", $number, $tag, $lookup), "\n";
}
