#!perl 

use strict;
use Test::More;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test5.yml',
);

my %positive_check = ();
my %positive       = (
    email   => 'test@test.de',
    plz     => 'hallo',
    country => 'DE',
);

my %errors_positive = $validator->validate( 'default', %positive );
is_deeply \%errors_positive, \%positive_check, 'correct values';

my %negative_check = ( email => 'Email is not correct', age => 'age must be either 1 or 2' );
my %negative       = (
    email   => 'test@test.de235235',
    plz     => 'hallo',
    country => 'DE',
    age     => 3,
);

{
    my %errors_negative = $validator->validate( 'default', %negative );
    is_deeply \%errors_negative, \%negative_check, 'negative values';
}

{
    my %errors_negative = $validator->validate( 'step1', age2 => 22, password => 'test123456789' );
    is_deeply \%errors_negative, { admin => '', password => 'Password is too short' }, 'step1 - depends on';
}

{
    my %local_negative = %negative;
    $local_negative{does_not_exist} = 'test';
    my %errors_negative = $validator->validate( %negative );
    is_deeply \%errors_negative, {}, 'negative values';
}


{
    my %errors_negative = $validator->validate();
    is_deeply \%errors_negative, {
        admin => '',
        password => 'Password is too short',
        email => 'Email is not correct',
        country => '',
        age2 => '',
    }, 'empty call';
}

{
    $validator->_optional->{testfield}->{depends_on} = 'age2';
    push @{ $validator->{fieldnames}->{step1} }, 'testfield';
    my %errors_negative = $validator->validate( 'step1', age2 => 22, password => 'test123456789' );
    is_deeply \%errors_negative, { admin => '', password => 'Password is too short' }, 'step1 - depends on';
}

done_testing();
