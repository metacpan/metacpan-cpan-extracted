#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Importer.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Importer.pm
# File:          $Source: /data/cvs/lib/DSlib/t/35_importer.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 47;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS::Importer' );

my $importer;

$importer = new DS::Importer();
ok( $importer );

# Shouldn't be possible to call importer without target
eval {
    $importer->execute();
};
ok( defined( $@ ) and $@ ne '');

# Test if importer imports correctly
$importer = new ImporterTest(10);
my $counter = new CountTarget();
isa_ok( $counter, 'CountTarget' );
{
    # Suppress type check warning when attaching source and target without types
    local $SIG{__WARN__} = sub {};
    $importer->attach_target( $counter );
}


is_deeply( $importer->_fetch(), {count => 1} );
$importer->pass_row( $importer->_fetch() );
is( $counter->{row}->{count}, 2);

isnt( $counter->{eos}, 1);

$importer->execute();

is( $importer->{counter}, 11 );
is( $counter->{row}->{count}, 10);
is( $counter->{eos}, 1);
is( $importer->_fetch, undef );

package ImporterTest;

use base qw{ DS::Importer };

sub new {
    my( $class, $max ) = @_;
    my $self = $class->SUPER::new();
    $self->{counter} = 1;
    $self->{max} = $max;
    return $self;
}

sub _fetch {
    my( $self ) = @_;
    if( $self->{counter} > $self->{max} ) {
        return undef;
    } else {
        return {count => $self->{counter}++};
    }
}

1;

package CountTarget;

use base qw{ DS::Target };

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new();
    return $self;
}

sub receive_row {
    my( $self, $row ) = @_;
    # Check that we didn't get end of stream before
    # ($self->{eos} is undef until set further down below when end of stream
    # has been received
    main::is( $self->{eos}, undef );
    # Got end of stream event?
    if( $row ) {
        # Check that we got a hash ref
        main::is( ref( $row ), 'HASH' );
        # Check that count has been set
        main::isnt( $row->{count}, undef );
        # Check that the counter has increased since last call
        if( $self->{row} ) {
            main::is( $row->{count}, $self->{row}->{count} + 1);
        }
        $self->{row} = {%$row};
    } else {
        $self->{eos} = 1;
    }
}

1;
