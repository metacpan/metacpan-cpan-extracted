#!/usr/bin/env perl

use strict;
use warnings;

use lib './lib';
use Class::Ref;
use Data::Dumper;

my $foo = 'foobar';
my $o = bless \\$foo => 'Class::Ref::SCALAR';

print "$o\n";
print "$$o\n";

my $t = Class::Ref->new(['foo']);
$t->[1] = {bar => 1};

my $r = Class::Ref->new(
    {
        foo => {
            bar => 1,
            baz => [
                { a => 3 },
                'foobar'
            ]
        },
        code => sub { print "hello\n" },
    }
);

package Class::Ref::SCALAR;

# 'overloading' added in 5.10.1
use overload '${}' => sub { no overloading '${}'; ${ $_[0] } }, fallback => 1;

exit;
