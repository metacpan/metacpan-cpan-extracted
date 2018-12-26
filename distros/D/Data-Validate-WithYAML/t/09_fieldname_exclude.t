#!perl 

use strict;
use Test::More;
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
delete $check_hash{age};

my @names = eval { $validator->fieldnames( undef, exclude => [ 'age' ] ) };
my %test_hash;
@test_hash{@names} = undef;

is_deeply( \%test_hash, \%check_hash );

my %default;
@default{@check1} = undef;
my %test_default;
@test_default{$validator->fieldnames('default')} = undef;

is_deeply( \%test_default, \%default );

{
    my @names = eval { $validator->fieldnames( exclude => [ 'age' ] ) };
    my %test_hash;
    @test_hash{@names} = undef;

    is_deeply( \%test_hash, {} );
}

{
    my @names = eval { $validator->fieldnames( 'step_five' ); };
    my %test_hash;
    @test_hash{@names} = undef;

    is_deeply( \%test_hash, {} );
}

done_testing();
