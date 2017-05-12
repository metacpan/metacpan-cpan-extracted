#!perl -w
use strict;
use warnings; 

use Test::More tests => 3;

BEGIN { use_ok('Data::Maker'); }
BEGIN { use_ok('Data::Maker::Field::Format'); }

my $maker = Data::Maker->new;
my $format = '\d \w \W \l \L \x \X';
my $field = Data::Maker::Field::Format->new( format => $format );
$field->generate;

like($field->value,
     qr/\A\d [0-9a-zA-Z] [0-9A-Z] [a-zA-Z] [A-Z] [0-9a-f]{2} [0-9A-F]{2}/,
     "format conversions work (or at least seem to)");

