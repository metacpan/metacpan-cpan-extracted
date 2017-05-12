#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 2;
use Data::Inherited;

package A;
use overload '""' => 'stringify';
sub prop { qw/one two three/ }
sub new { bless {}, shift }
sub stringify { join '-', $_[0]->get_prop }

sub get_prop {
    my $self       = shift;
    my @every_list = $self->EVERY::LAST::prop;
    return unless scalar @every_list;
    my @list;
    while (my ($class, $class_list) = splice(@every_list, 0, 2)) {
        push @list => @$class_list;
    }
    @list;
}

package B;
our @ISA = 'A';
sub prop { qw/four five/ }

package main;
is(sprintf('%s', A->new), 'one-two-three',           'A stringification');
is(sprintf('%s', B->new), 'one-two-three-four-five', 'B stringification');
