#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh track_require => 1;

my $dir = prepare_temp_dir_for('new-modules');
push @INC, $dir->dirname;

Class::Refresh->refresh;

# load Foo after the first call to refresh
require Foo;

is(Foo->bar, 1);

sleep 2;
update_temp_dir_for('new-modules', $dir, 'middle');

Class::Refresh->refresh;

is(Foo->bar, 2);

sleep 2;
update_temp_dir_for('new-modules', $dir, 'after');

Class::Refresh->refresh;

is(Foo->bar, 3);

done_testing;
