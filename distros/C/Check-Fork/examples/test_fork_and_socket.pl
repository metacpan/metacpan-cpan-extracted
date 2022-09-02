#!/usr/bin/env perl

use strict;
use warnings;

use Check::Fork qw(check_fork);
use Check::Socket qw(check_socket);
use Test::More 'tests' => 1;

SKIP: {
        skip $Check::Fork::ERROR_MESSAGE, 1 unless check_fork();
        skip $Check::Socket::ERROR_MESSAGE, 1 unless check_socket();

        ok(1, 'Fork and Socket test');
};

# Output on Unix:
# 1..1
# ok 1 - Fork and Socket test