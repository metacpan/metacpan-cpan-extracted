#!/usr/bin/env perl

use strict;
use warnings;

use Test::Perl::Critic
    -profile => '/etc/perlcriticrc',
    -verbose => 9;
all_critic_ok(qw/ lib bin script /);
