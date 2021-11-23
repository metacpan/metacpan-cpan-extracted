#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use DNS::Unbound;

diag( 'Unbound ' . DNS::Unbound->unbound_version() );

use File::Temp;

my $should_be_fd = _get_next_fd();

my $fh = File::Temp::tempfile();
syswrite($fh, 'strawberry');

if (fileno($fh) != $should_be_fd) {
    plan skip_all => 'Expected lowest-numbered FD to be used';
}

my $pre_unbound_expect_fd = _get_next_fd();

my $dns = DNS::Unbound->new();

my $expect_fd = _get_next_fd();

for ( 1 .. 10 ) {

    $dns->debugout($fh);
    $dns->debugout(\*STDOUT);
}

my $next_fd = _get_next_fd();

is($next_fd, $expect_fd, 'debugout() to temp FH and STDOUT doesn’t leak');

$dns->debugout($fh);

undef $dns;

$next_fd = _get_next_fd();

is($next_fd, $pre_unbound_expect_fd, 'debugout() gets cleaned up with ub ctx');

done_testing();

sub _get_next_fd {
    fileno scalar(File::Temp::tempfile());
}
