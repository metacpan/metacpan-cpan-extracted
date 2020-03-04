#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'App::Provision::Tiny';
my $x = App::Provision::Tiny->new;
isa_ok $x, 'App::Provision::Tiny';

use_ok 'App::Provision::Homebrew';
$x = App::Provision::Homebrew->new;
isa_ok $x, 'App::Provision::Homebrew';
ok $x->can('meet'), 'can meet';

done_testing();
