#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

my $m; BEGIN { use_ok($m = "Context::Handle", "context_sensitive") }

sub foo { $m->new(sub { wantarray ? "list" : "scalar" })->return }

sub bar {
	my $rv = context_sensitive { wantarray ? "list" : "scalar"; };
	return $rv->return;
}

{
	my $scalar = foo;
	is($scalar, "scalar", "scalar context");

	my @list = foo;
	is_deeply(\@list, ["list"], "list context");
}

{
	my $scalar = bar;
	is($scalar, "scalar", "scalar context");

	my @list = bar;
	is_deeply(\@list, ["list"], "list context");
}


