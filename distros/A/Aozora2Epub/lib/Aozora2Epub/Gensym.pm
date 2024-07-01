package Aozora2Epub::Gensym;
use strict;
use warnings;
use utf8;
use base qw/Exporter/;
our @EXPORT = qw(gensym);

our $VERSION = '0.05';

my $gensym_counter = 0;

sub gensym { sprintf("g%09d", $gensym_counter++); }

sub reset_counter {
    $gensym_counter = 0;
}

1;
