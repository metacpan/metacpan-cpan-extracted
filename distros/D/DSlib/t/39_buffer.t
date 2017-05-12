#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS::Transformer::Buffer.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Tests DS::Transformer::Buffer
# File:          $Source: /data/cvs/lib/DSlib/t/39_buffer.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 35;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use DS::TypeSpec::Any;
use DS::Transformer::Sub;
use DS::Target::Sink;

use_ok('DS::Transformer::Buffer');

my $transformer;

sub rowmap {
    my( $row ) = @_;
    
    my $result;
    
    if( $row ) {
        for( sort keys %$row ) {
            $result .= "$_ = \"$row->{$_}\" ";
        }
        chop( $result );
    } else {
        $result = '';
    }
        
    return $result;
}
    

for( $transformer ) {
    $_ = new DS::Transformer::Buffer;
    ok( $_ );
    isa_ok( $_ => 'DS::Transformer::Buffer' );

    eval {
        $_->fetch;
    };
    isnt( $@, '', 'Should not allow fetching from empty buffer' );

    my $importer = new ImporterTest( 9 );
    $_->attach_source( $importer );
    
    my $last = 'nothing yet';
    my $debugger = new DS::Transformer::Sub( 
        sub {
            my( $self, $row ) = @_;
            $last = rowmap( $row ) || 'nothing more';
            return $row;
        }, 
        $DS::TypeSpec::Any,
        $DS::TypeSpec::Any
    );
    $_->attach_target( $debugger );
    $debugger->attach_target( new DS::Target::Sink );

    eval {
        $_->fetch;
    };
    isnt( $@, '', 'Should not allow fetching from empty buffer' );
    
    is( $last, 'nothing yet' );

    $importer->execute( 1 );
    is( $last, 'count = "1" modulo_3 = "1"' );

    $importer->execute( 1 );
    is( $last, 'count = "2" modulo_3 = "2"' );

    $_->unfetch;
    $importer->execute( 1 );
    is( $last, 'count = "2" modulo_3 = "2"' );

    $importer->execute( 1 );
    is( $last, 'count = "3" modulo_3 = "0"' );

    is( rowmap( $_->fetch ), 'count = "4" modulo_3 = "1"' );

    eval {
        $_->fetch;
    };
    isnt( $@, '', 'Should not allow fetching past last available row in buffer' );
    
    for( my $i = 1; $i <= 4; $i++ ) {
        eval {
            $_->unfetch;
        };
        is( $@, '', 'Should be able to rewind through buffer.' );
    }
    
    eval {
        $_->unfetch;
    };
    isnt( $@, '', 'Should not allow unfetching beyond first row in buffer' );
    
    is( rowmap( $_->fetch ), 'count = "1" modulo_3 = "1"', 'Re-fetch first row in buffer');
    
    $_->flush;

    eval {
        $_->unfetch;
    };
    isnt( $@, '', 'Should not allow unfetching beyond first available row in buffer' );
    
    is( rowmap( $_->fetch ), 'count = "2" modulo_3 = "2"', 'Re-fetch second row in buffer');
    
    eval {
        $_->unfetch;
    };
    is( $@, '', 'Should allow unfetching second row in buffer' );
    
    # The buffer is 0-indexed, meaning that flush(2) will ensure that the first 
    # *three* elements are flushed.
    eval {
        $_->flush( 2 );
    };
    is( $@, '', 'Should allow flushing up to (and including) position 2' );

    eval {
        $_->unfetch;
    };
    isnt( $@, '', 'Should not allow unfetching beyond first available row in buffer' );

    is( rowmap( $_->fetch ), 'count = "4" modulo_3 = "1"' );

    $last = '';
    $importer->execute( 6 );
    is( $last, 'count = "10" modulo_3 = "1"' );

    $last = '';
    $importer->execute( 1 );
    is( $last, 'nothing more', 'Buffer should return end of stream (undef)' );

    $last = '';
    $importer->execute( 1 );
    is( $last, 'nothing more', 'Buffer should return end of stream (undef)' );

    $last = '';
    $importer->execute( 1 );
    is( $last, 'nothing more', 'Buffer should return end of stream (undef)' );


    # Check that after EOS it is still possible to unfetch and fetch last value
    eval {
        $_->unfetch;
        $_->unfetch;
    };
    is( $@, '' );

    is( rowmap( $_->fetch ), 'count = "10" modulo_3 = "1"' );
    is( rowmap( $_->fetch ), '' );

    eval {
        $_->fetch;
    };
    isnt( $@, '' );
    

    # Check that sending another EOS after unfetch will bring up
    # last element followed by EOS
    eval {
        $_->unfetch;
        $_->unfetch;
    };
    is( $@, '' );

    $last = '';
    $importer->execute( 1 );
    is( $last, 'count = "10" modulo_3 = "1"', 'Bring back last element after EOS should be possible with unfetch' );

    $last = '';
    $importer->execute( 1 );
    is( $last, 'nothing more', 'The buffer should be past last element now, returning EOS.' );
    
}

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
