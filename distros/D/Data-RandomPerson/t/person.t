#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 327;
use Time::Local;

use_ok('Data::RandomPerson');

my $r;

################################################################################
# Broken initialisers
################################################################################

eval { $r = Data::RandomPerson->new( fred => 42 ); };

like( $@, qr/^Unknown argument 'fred' passed to new at / );

eval { $r = Data::RandomPerson->new( male => 'UnknownClass' ); };

like( $@, qr/^Unable to load 'UnknownClass':/ );

eval { $r = Data::RandomPerson->new( female => 'UnknownClass' ); };

like( $@, qr/^Unable to load 'UnknownClass':/ );

eval { $r = Data::RandomPerson->new( last => 'UnknownClass' ); };

like( $@, qr/^Unable to load 'UnknownClass':/ );

################################################################################
# Create a reference to the object
################################################################################

$r = Data::RandomPerson->new(
    male   => 'Data::RandomPerson::Names::Male',
    female => 'Data::RandomPerson::Names::Female',
    last   => 'Data::RandomPerson::Names::Last'
);

is( ref($r), 'Data::RandomPerson' );

can_ok( $r, qw/new _pick_gender _pick_age _pick_title _pick_lastname _pick_firstname _pick_dob create / );

################################################################################
# Create a person
################################################################################

foreach ( 1 .. 20 ) {
    my $p = $r->create();

    is( ref($p), 'HASH' );

    foreach my $key (qw/dob gender age firstname lastname title/) {
        ok( $p->{$key} );
        isnt( $p->{$key}, '' );
    }

    like( $p->{age},    qr/^\d+$/ );
    like( $p->{gender}, qr/m|f/ );

    my ( $year, $month, $day ) = $p->{dob} =~ m/^(\d+)-(\d+)-(\d+)$/;

    ok( check_date( $year, $month, $day ), 'Test for valid DOB' ) or diag( $@ );
}

sub check_date {
    my ($year, $month, $day) = @_;
    eval { my $t = timelocal(0, 0, 0, $day, ($month - 1), $year); };
    return if $@;
    return 1;
}
