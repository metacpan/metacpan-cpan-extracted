#!/usr/bin/perl
use Test::More;
use lib 'lib';

foreach my $mod (qw(DBIx::Class::InflateColumn::JSON2Object DBIx::Class::InflateColumn::JSON2Object::Role::Storable DBIx::Class::InflateColumn::JSON2Object::Trait::NoSerialize)) {
    require_ok($mod);
}

done_testing();
