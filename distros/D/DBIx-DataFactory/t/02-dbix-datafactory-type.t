package test::DBix::DataFactory::Type;
use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use Test::TypeConstraints;

use DBIx::DataFactory::Type::Int;
use DBIx::DataFactory::Type::Num;
use DBIx::DataFactory::Type::Str;
use DBIx::DataFactory::Type::Set;

sub _int : Test(3) {
    is DBIx::DataFactory::Type::Int::type_name, 'Int';
    my $rand = DBIx::DataFactory::Type::Int->make_value(size => 5);
    ok ($rand < 100000);
    type_isa $rand, 'Int';
}

sub _num : Test(3) {
    is DBIx::DataFactory::Type::Num::type_name, 'Num';
    my $rand = DBIx::DataFactory::Type::Num->make_value(size => 5);
    ok ($rand < 100000);
    type_isa $rand, 'Num';
}

sub _str : Test(5) {
    is DBIx::DataFactory::Type::Str::type_name, 'Str';
    my $rand = DBIx::DataFactory::Type::Str->make_value(size => 5);
    like $rand, qr{[a-zA-Z0-9]{5}};
    type_isa $rand, 'Str';

    $rand = DBIx::DataFactory::Type::Str->make_value(regexp => '[a-z]{20}');
    like $rand, qr{[a-z]{20}};
    type_isa $rand, 'Str';
}

sub _set : Test(2) {
    is DBIx::DataFactory::Type::Set::type_name, 'Set';
    my $rand = DBIx::DataFactory::Type::Set->make_value(set => ['test', 'test2']);
    ok($rand eq 'test' || $rand eq 'test2');
}

__PACKAGE__->runtests;

1;
