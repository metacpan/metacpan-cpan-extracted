#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Transformer/Stack.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Transformer/Stack.pm
# File:          $Source: /data/cvs/lib/DSlib/t/50_stack.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 27;

BEGIN {
        $|  = 1;
        $^W = 1;
}


use DS::TypeSpec;
use DS::TypeSpec::Field;
use DS::Target::Sink;
use DS::Transformer::Sub;
use DS::Importer::Sub;

my $typespec = new DS::TypeSpec( 'mytype', 
    [   new DS::TypeSpec::Field( 'count' ),
        new DS::TypeSpec::Field( 'modulo_3' )]
);

use_ok( 'DS::Transformer::Stack' );

my $stack = new DS::Transformer::Stack;

my $i = 1;
my $importer = new ImporterTest( 9 );
my $trace_before = new DS::Transformer::Sub( 
    sub {
        my( $self, $row ) = @_;
        if( $row ) {
            $self->{trace} .= '|' . join("\t", @{$row}{sort keys %$row}) . "|\n";
        } else {
            $self->{trace} .= "||\n";
        }
        return $row;
    },
    $DS::TypeSpec::Any,
    $DS::TypeSpec::Any
);

$importer->attach_target( $trace_before );

my $trace_after = new DS::Transformer::Sub( 
    sub {
        my( $self, $row ) = @_;
        if( $row ) {
            $self->{trace} .= '|' . join("\t", @{$row}{sort keys %$row}) . "|\n";
        } else {
            $self->{trace} .= "||\n";
        }
        return $row;
    },
    $DS::TypeSpec::Any,
    $DS::TypeSpec::Any
);
$trace_after->attach_target( new DS::Target::Sink );

my $trace_inside = new DS::Transformer::Sub( 
    sub {
        my( $self, $row ) = @_;
        if( $row ) {
            $self->{trace} .= '|' . join("\t", @{$row}{sort keys %$row}) . "|\n";
        } else {
            $self->{trace} .= "||\n";
        }
        return $row;
    },
    $DS::TypeSpec::Any,
    $DS::TypeSpec::Any
);
 

ok( $stack );

eval {
    $stack->push_transformer( $trace_inside );
};
ok( not $@ );

eval {
    $stack->attach_source( $trace_before );
};
ok( not $@ );
is( $trace_before->target, $stack );
is( $stack->source, $trace_before );
# Check internals
ok( $stack->{internal_source} );
is( $trace_inside->source, $stack->{internal_source} );
is( $stack->{internal_source}->target, $trace_inside );

diag $@;
eval {
    $stack->attach_target( $trace_after );
};
ok( not $@ );
is( $trace_after->source, $stack );
is( $stack->target, $trace_after );
# Check internals
ok( $stack->{internal_target} );
is( $trace_inside->target, $stack->{internal_target} );
is( $stack->{internal_target}->source, $trace_inside );


isnt( $trace_inside->source, $trace_before );
isnt( $trace_inside->target, $trace_after );

eval {
    $importer->execute;
};
ok( not $@ );

is( $trace_inside->{trace}, $trace_before->{trace} );
is( $trace_after->{trace}, $trace_before->{trace} );

# Now try working with stack internals

# Pass a row to the stack from outside the chain
eval {
    $stack->receive_row( { a => 100, b => 200 } );
};
ok( not $@ );

ok( $trace_inside->{trace} =~ /|100\t200|/ );
ok( $trace_after->{trace}  =~ /|100\t200|/ );

# Pass a row to top of stack and see that it comes
# right out without any processing.
eval {
    $stack->receive_row( { a => 200, b => 300 } );
};
ok( not $@ );

ok( $trace_inside->{trace} =~ /|100\t200|/ );
ok( $trace_after->{trace}  =~ /|200\t300|/ );

# process() should not work any longer
eval {
    $stack->process( { a => 1 } );
};
ok( $@ );


package ImporterTest;

use base qw{ DS::Importer };

sub new {
    my( $class, $max ) = @_;
    my $typespec = new DS::TypeSpec('mytype', 
        [   new DS::TypeSpec::Field( 'count' ),
            new DS::TypeSpec::Field( 'modulo_3' )]
    );
    my $self = $class->SUPER::new( $typespec );
    $self->{counter} = 0;
    $self->{max} = $max;
    return $self;
}

sub _fetch {
    my( $self ) = @_;
    if( $self->{counter} > $self->{max} ) {
        return undef;
    } else {
        $self->{counter}++;
        return {count => $self->{counter}, modulo_3 => $self->{counter} % 3};
    }
}

1;
