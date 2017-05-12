#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 14;

use File::stat;  # an OO-ish module that has been in the core since forever

my $obj = stat('Makefile.PL');

BEGIN { use_ok('Data::Transactional') }

# NB some tests are done in parallel on tied and untied data structures
# as a sanity check
my $tied;
my $untied = [];

# create correct types of transactional whatsit
ok($tied = Data::Transactional->new(type => 'array'), "create an array");
ok(!eval { $tied->{pie} = 'meat' }, "... which can't be used as a hash");
ok($tied->[0] = 'meat', "... which we can use as an array");
ok(!eval { $tied->[1] = $obj }, "can't store objects in an array");

$untied->[4] = $tied->[4] = 'coconut';
ok($tied->[4] eq 'coconut' && $untied->[4] eq 'coconut', "STORE and FETCH work");
@{$tied} = qw(apple pear plum berry);
@{$untied} = qw(apple pear plum berry);
ok(exists($tied->[3]) && $tied->[3] eq 'berry' && exists($untied->[3]) && $untied->[3] eq 'berry', "EXISTS works");
ok(!exists($tied->[4]) && !exists($untied->[4]), "CLEAR works");
push @{$tied}, 'peach', 'apricot';
push @{$untied}, 'peach', 'apricot';
ok($tied->[4] eq 'peach' && $tied->[5] eq 'apricot' && $untied->[4] eq 'peach' && $untied->[5] eq 'apricot', "PUSH works");
ok(pop(@{$tied}) eq 'apricot' && (@{$tied}) == 5 && pop(@{$untied}) eq 'apricot' && (@{$untied}) == 5, "POP works");
ok(shift(@{$tied}) eq 'apple' && $tied->[0] eq 'pear' && (@{$tied}) == 4 && shift(@{$untied}) eq 'apple' && $untied->[0] eq 'pear' && (@{$untied}) == 4, "SHIFT works");
ok(unshift(@{$tied}, 'apple') == 5 && $tied->[0] eq 'apple' && $tied->[1] eq 'pear' && (@{$tied}) == 5 && unshift(@{$untied}, 'apple') == 5 && $untied->[0] eq 'apple' && $untied->[1] eq 'pear' && (@{$untied}) == 5, "UNSHIFT works");
ok(delete($tied->[2]) eq 'plum' && !defined($tied->[2]) && (@{$tied}) == 5 && delete($untied->[2]) eq 'plum' && !defined($untied->[2]) && (@{$untied}) == 5, "DELETE from middle works");
ok(delete($tied->[4]) eq 'peach' && (@{$tied}) == 4 && delete($untied->[4]) eq 'peach' && (@{$untied}) == 4, "DELETE from end works");
