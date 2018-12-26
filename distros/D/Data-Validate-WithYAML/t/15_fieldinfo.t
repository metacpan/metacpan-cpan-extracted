#!perl

use strict;

use Test::More;
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
is $validator->fieldinfo('field_does_not_exist'), undef;

done_testing();
