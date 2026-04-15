#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Load Class.pm once
require_ok('Class');

# Simulate cross-file inheritance by using different packages
# that would normally be in different files

{
    # This simulates Shape.pm
    package Test::Cross::Shape;
    use Class;

    sub id   { shift->{id}   }
    sub type { shift->{type} }

    sub BUILD {
        my ($self, $args) = @_;
        die "Missing id" unless exists $args->{id};
    }
}

{
    # This simulates Shape/Circle.pm
    package Test::Cross::Shape::Circle;
    use Class;
    extends 'Test::Cross::Shape';

    sub BUILD {
        my ($self, $args) = @_;
        $self->{type} = 'Circle';
    }

    sub draw { "drawing circle" }
}

{
    # This simulates Shape/Square.pm
    package Test::Cross::Shape::Square;
    use Class;
    extends 'Test::Cross::Shape';

    sub BUILD {
        my ($self, $args) = @_;
        $self->{type} = 'Square';
    }

    sub draw { "drawing square" }
}

{
    # This simulates ShapeCache.pm
    package Test::Cross::ShapeCache;
    use Class;

    sub BUILD {
        my ($self, $args) = @_;
        $self->{shapes} = {
            circle => Test::Cross::Shape::Circle->new(id => 1),
            square => Test::Cross::Shape::Square->new(id => 2),
        };
    }

    sub getShape {
        my ($self, $type) = @_;
        my $original = $self->{shapes}->{$type};
        return bless { %$original }, ref($original);
    }
}

# Test cross-file inheritance
my $circle = Test::Cross::Shape::Circle->new(id => 10);
is($circle->id, 10, 'Cross-file: circle id method');
is($circle->type, 'Circle', 'Cross-file: circle type method');
is($circle->draw, 'drawing circle', 'Cross-file: circle draw method');

my $square = Test::Cross::Shape::Square->new(id => 20);
is($square->id, 20, 'Cross-file: square id method');
is($square->type, 'Square', 'Cross-file: square type method');
is($square->draw, 'drawing square', 'Cross-file: square draw method');

# Test method availability
ok(Test::Cross::Shape::Circle->can('id'), 'Cross-file: circle can id');
ok(Test::Cross::Shape::Circle->can('type'), 'Cross-file: circle can type');
ok(Test::Cross::Shape::Square->can('id'), 'Cross-file: square can id');
ok(Test::Cross::Shape::Square->can('type'), 'Cross-file: square can type');

# Test the original cloning issue
my $cache = Test::Cross::ShapeCache->new;
my $cloned_circle = $cache->getShape('circle');
is($cloned_circle->id, 1, 'Cross-file cloning: cloned circle id works');
is($cloned_circle->type, 'Circle', 'Cross-file cloning: cloned circle type works');

done_testing;
