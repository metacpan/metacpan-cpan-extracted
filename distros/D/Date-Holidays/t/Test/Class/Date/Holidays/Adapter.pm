package Test::Class::Date::Holidays::Adapter;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;

our $VERSION = '1.33';

#run prior and once per suite
sub startup : Test(startup => 1) {

    use_ok('Date::Holidays::Adapter');

    return 1;
}

#run after and once per suite
sub shutdown : Test(shutdown) {
    return 1;
}

sub constructor : Test(2) {
    my ($self) = @_;

  SKIP: {
        eval { require Date::Holidays::DK };
        skip "Date::Holidays::DK not installed", 2 if $@;

        ok( my $adapter = Date::Holidays::Adapter->new( countrycode => 'DK' ) );

        isa_ok( $adapter, 'Date::Holidays::Adapter' );
    }
}

sub _load : Test(3) {
    my ($self) = @_;

  SKIP: {
        eval { require Date::Holidays::DK };
        skip "Date::Holidays::DK not installed", 3 if $@;

        ok( my $adapter = Date::Holidays::Adapter->new( countrycode => 'DK' ) );

        isa_ok( $adapter, 'Date::Holidays::Adapter' );

        ok( $adapter->_load('Date::Holidays::Adapter::DK') );
    }
}

sub _fetch : Test(5) {
    my ($self) = @_;

  SKIP: {
        eval { require Date::Holidays::DK };
        skip "Date::Holidays::DK not installed", 5 if $@;

        ok( my $adapter = Date::Holidays::Adapter->new( countrycode => 'DK' ) );

        isa_ok( $adapter, 'Date::Holidays::Adapter' );

        ok( $adapter->_fetch( { no_check => 1 } ) );

        is( $adapter->{_countrycode}, 'DK' );

        is( $adapter->{_adaptee}, 'Date::Holidays::DK' );
    }
}

#run prior and once per test method
sub setup : Test(setup) {

    # body...

    return 1;
}

#run after and once per test method
sub teardown : Test(teardown) {

    # body...

    return 1;
}

1;
