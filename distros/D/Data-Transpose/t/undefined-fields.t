#!perl

use strict;
use warnings;
use utf8;
use Data::Transpose;
use Data::Dumper;
use Test::More tests => 1;

my @records = (
               {
                first => 'f',
                second => 's',
               },
               {
                first => 'f',
               },
               {
                second => 'c',
               },
               {
               },
              );

my $tp = Data::Transpose->new;

$tp->field('first')->target('primo');
$tp->field('second')->target('secondo');

my @transposed;

foreach my $r (@records) {
    push @transposed, $tp->transpose($r);
}

is_deeply \@transposed, [
                         {
                          primo => 'f',
                          secondo => 's',
                         },
                         {
                          primo => 'f',
                          secondo => undef,
                         },
                         {
                          secondo => 'c',
                          primo => undef,
                         },
                         {
                          secondo => undef,
                          primo => undef,
                         },
                        ];
