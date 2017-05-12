#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Data::Kanji::Tomoe;
my $obj = Data::Kanji::Tomoe->new (
    tomoe_data_file => '/path/to/data/file',
    character_callback => \& user_callback,
);
