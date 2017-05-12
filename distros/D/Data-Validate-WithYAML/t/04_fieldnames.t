#!perl 

use strict;
use Test::More tests => 3;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test.yml' );
my @check1 = qw(
    email
    plz
    greeting
    age
);

my @check2 = qw(
    age
    street
    password
    admin
);

my %check_hash;
@check_hash{@check1,@check2} = undef;

my %test_hash;
@test_hash{$validator->fieldnames} = undef;

is_deeply( \%test_hash, \%check_hash );

my %default;
@default{@check1} = undef;
my %test_default;
@test_default{$validator->fieldnames('default')} = undef;

is_deeply( \%test_default, \%default );
