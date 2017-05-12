#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_split_params);

# Hash reference with default parameters.
my $self = {
       'foo' => undef,
};

# Set bad params.
my @other_params = set_split_params($self,
'foo', 'bar',
'bad', 'value',
);

# Print out.
print "Foo: $self->{'foo'}\n";
print join ': ', @other_params;
print "\n";

# Output:
# Foo: bar
# bad: value