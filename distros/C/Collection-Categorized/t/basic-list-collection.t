#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 14;

use Collection::Categorized;

my $cc = Collection::Categorized->new([ '+' => sub { $_ >  0 },
                                        '-' => sub { $_ <  0 },
                                        '=' => sub { $_ == 0 },
                                      ]);

# probe the internals
is $cc->{_sorter}->(1),  '+';
is $cc->{_sorter}->(-1), '-';
is $cc->{_sorter}->(0), '=';

$cc->add(1);
my @categories = $cc->categories;
is_deeply [sort @categories], [sort qw/+/];

$cc->add(2);
@categories = $cc->categories;
is_deeply [sort @categories], [sort qw/+/];

$cc->add(0);
@categories = $cc->categories;
is_deeply [sort @categories], [sort qw/+ =/];

$cc->add(-1);
@categories = $cc->categories;
is_deeply [sort @categories], [sort qw/+ = -/];

is_deeply [$cc->get('+')], [1,2];
is_deeply [$cc->get('=')], [0];
is_deeply [$cc->get('-')], [-1];

$cc->edit(sub { map { $_ * 2 } @_ });
is_deeply [$cc->get('+')], [2,4];
is_deeply [$cc->get('=')], [0];
is_deeply [$cc->get('-')], [-2];

is_deeply [sort $cc->all], [-2, 0, 2, 4], 'everything there';
