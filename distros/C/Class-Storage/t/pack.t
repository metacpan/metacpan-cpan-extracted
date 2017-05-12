use strict;

use Test::More;

use lib '../lib';

use Class::Storage qw(packObjects unpackObjects);
use Clone 'clone';

## Create a few Classes for testing purposes

package HasConverters;

# This is just a simple class with TO_UNBLESSED and TO_BLESSED functions.
# Assume the class in memory has a 'val' member, but in JSON it must have a VAL
# member.

sub new {
    my ($class, $val) = @_;
    return bless { val => $val }, $class;
}

sub TO_PACKED {
    my ($self) = @_;
    return { VAL => $self->{val} };
}

sub FROM_PACKED {
    my ($class, $packed) = @_;
    return bless({ val => $packed->{VAL} }, $class);
}

package HasConverters::SubClass;

use base qw(HasConverters);

package HasToFromJSON::Array;

sub new {
    my ($class, $val) = @_;
    return bless [ $val ], $class;
}

sub TO_JSON {
    my ($self) = @_;
    return [ "FOOBAR", $self->[0] ];
}

sub FROM_JSON {
    my ($class, $packed) = @_;
    $packed->[0] eq 'FOOBAR'
        or die "Expected FOOBAR";
    return bless([ $packed->[1] ], $class);
}

package main;

## Actually perform the tests

foreach my $set (
    {
        name => 'simpleClasses',
        blessed => {
            'a' => bless( { 'b' => bless( {}, "c" ), }, "d" ),
            'e' => [ bless( [], "f" ), bless( [], "g" ), ]
        },
        packed => {
          'a' => {
            '__class__' => 'd',
            'b' => {
              '__class__' => 'c'
            }
          },
          'e' => [
            [
              '__class__',
              'f'
            ],
            [
              '__class__',
              'g'
            ]
          ]
        }
    },
    {
        name => 'magic string option',
        blessed => {
            'a' => bless( { 'b' => bless( {}, "c" ), }, "d" ),
        },
        packed => {
          'a' => {
            'MAGIC' => 'd',
            'b' => {
              'MAGIC' => 'c'
            }
          },
        },
        options => {
            magicString => 'MAGIC'
        }
    },
    {
        name => 'HasConverters',
        blessed => HasConverters->new(47),
        packed => {
            VAL => 47,
            __class__ => 'HasConverters'
        }
    },
    {
        name => 'HasConverters::SubClass',
        blessed => HasConverters::SubClass->new(29),
        packed => {
            VAL => 29,
            __class__ => 'HasConverters::SubClass'
        }
    },
    {
        name => 'HasToFromJSON::Array (uses method name options)',
        blessed => HasToFromJSON::Array->new(11),
        packed => [ '__class__', 'HasToFromJSON::Array', 'FOOBAR', 11 ],
        options => {
            toPackedMethodName => 'TO_JSON',
            fromPackedMethodName => 'FROM_JSON',
        }
    },
) {
    subtest $set->{name} => sub {

        my %options = $set->{options} ? ( %{ $set->{options} } ) : ();
        my $blessedCopy = clone ($set->{blessed});
        my $packed = packObjects($blessedCopy, %options);
        is_deeply(
            $packed, $set->{packed},
            "packed as expected"
        ) or diag explain $packed;
        my $unpacked = unpackObjects($packed, %options);
        is_deeply(
            $unpacked, $set->{blessed},
            "unpacked as expected"
        ) or diag explain $unpacked;
    };
}

subtest "False magicString" => sub {
    my $blessed = {
        'a' => bless( { 'b' => bless( {}, "c" ), }, "d" ),
        'e' => [ bless( [], "f" ), bless( [], "g" ), ]
    };
    my $expected = {
      'a' => {
        'b' => {}
      },
      'e' => [
        [],
        []
      ]
    };
    my $packed = packObjects($blessed, magicString => undef);
    is_deeply(
        $packed, $expected,
        "Unbless without magic string as expected"
    ) or diag explain $packed;
};

done_testing;
