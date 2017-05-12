#!perl

use strict;
use Test::More tests => 3;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test6.yml',
    no_steps => 1,
);

my $greeting_check = { enum => [ qw/Herr Frau Firma/ ] };
my $age_check      = { type => 'required', min => 18, max => 67 };

is_deeply $validator->fieldinfo( 'greeting' ), $greeting_check;
is_deeply $validator->fieldinfo( 'age2' ), $age_check;
