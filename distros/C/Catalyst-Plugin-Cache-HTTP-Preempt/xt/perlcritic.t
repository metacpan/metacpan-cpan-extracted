#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use Test::Perl::Critic;

all_critic_ok(qw( lib ));
