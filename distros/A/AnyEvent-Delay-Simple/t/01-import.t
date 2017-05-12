#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::Delay::Simple qw(delay easy_delay);


ok !!__PACKAGE__->can('delay');
ok !!__PACKAGE__->can('easy_delay');

ok !AE->can('delay');
ok !AE->can('easy_delay');


done_testing;
