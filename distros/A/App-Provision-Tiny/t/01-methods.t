#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'App::Provision::Tiny';
my $x = new_ok 'App::Provision::Tiny';

use_ok 'App::Provision::Homebrew';
$x = new_ok 'App::Provision::Homebrew';
ok $x->can('meet'), 'can meet';

done_testing();
