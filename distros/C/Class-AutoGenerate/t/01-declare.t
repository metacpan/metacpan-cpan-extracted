#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 6;

package TestApp::Declare;
use Class::AutoGenerate -base;

declare {
    my $self = shift;

    requiring '**' => generates {
        my $name = $1;

        if ($self->{flurp}) {
            defines 'flurp' => sub { $name };
        }

        defines 'flup' => sub { $name };
    };
};

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = $class->SUPER::new(%args);

    $self->{flurp} = $args{flurp};

    return $self;
}

package main;

TestApp::Declare->new( flurp => 0, match_only => 'Prefix1::**' );
TestApp::Declare->new( flurp => 1, match_only => 'Prefix2::**' );

require_ok('Prefix1::Foo');
require_ok('Prefix2::Foo');

can_ok('Prefix1::Foo', 'flup');
ok(!Prefix1::Foo->can('flurp'), "not Prefix1::Foo->can('flurp')");

can_ok('Prefix2::Foo', 'flup');
can_ok('Prefix2::Foo', 'flurp');
