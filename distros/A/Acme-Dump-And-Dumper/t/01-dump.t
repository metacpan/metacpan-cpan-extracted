#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

use Acme::Dump::And::Dumper;

my $obj = bless([qw/x y z/], 'Foo::Bar');

my $data_orig = {
    ber => {
        obj  => [ $obj, $obj ],
    },
};

my $output_DnD = <<'END';
$VAR1 = {
          'ber' => {
                     'obj' => [
                                'obj[Foo::Bar]',
                                'obj[Foo::Bar]'
                              ]
                   }
        };
END

is( DnD($data_orig), $output_DnD, q{Is it dumping?} );

