#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);

use Data::Dumper;
use Getopt::Std qw(getopts);

sub usage()
{
    print <<eof;
        usage: perl $0 [ OPTIONS ]

            OPTIONS:
                -h              - this helpscreen

                -k count        - keys in one hash (default 10)
                -c count        - hashes in array (defeult 100)

                -u percent      - undef chance (default 20)
                -n percent      - number chance (default 60)
eof
    exit;
}

getopts 'hk:n:u:c:' => \my %opts or usage;
usage if $opts{h};

our $keys = $opts{k} || 10;
our $count = $opts{c} || 100;
our $undef_chance = $opts{u} || 20;
our $number_chance = $opts{n} || 60;

sub random_word(;$)
{
    my $undef_chance = shift || 0;
    my @letter = qw(q w e r t y u i o p a s d f g h j k l z x c v b n m);


    return if $undef_chance and $undef_chance > rand 100;

    my $str = '';
    for (0 .. 5 + int rand 16) {
        $str .= $letter[rand @letter];
    }
    return $str;
}

my @keys = map { random_word } 1 .. $keys;
my @array;

for (0 .. $count - 1) {
    my @elem;

    for (@keys) {
        push @elem, $_;
        if ($number_chance > rand 100) {
            push @elem, int rand 1000000;
        } else {
            push @elem, random_word;
        }
    }

    push @array, { @elem };
}

local $Data::Dumper::Indent = 1;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Useqq = 1;
local $Data::Dumper::Deepcopy = 1;
print Dumper \@array;
