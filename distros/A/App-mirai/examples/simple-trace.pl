#!/usr/bin/env perl 
use strict;
use warnings;

# All the magic is in here. It's carefully hidden amidst much that
# is not pretty.
use App::mirai::Future;

my $script = shift @ARGV or die "need a script name";

my $w = App::mirai::Future->create_watcher;
$w->subscribe_to_event(
	create => sub {
		my ($ev, $f) = @_;
		printf STDERR "%s created at %s\n", $f, App::mirai::Future->future($f)->{created_at};
	},
	label => sub {
		my ($ev, $f) = @_;
		printf STDERR "%s was given a label, and it was: %s\n", $f, $f->label;
	},
	on_ready => sub {
		my ($ev, $f) = @_;
		printf STDERR "%s was marked ready: %s, elapsed time %.3fs\n", $f, App::mirai::Future->future($f)->{status}, $f->elapsed;
	},
	destroy => sub {
		my ($ev, $f) = @_;
		printf STDERR "%s went away, it was %s and had the label %s\n", $f, App::mirai::Future->future($f)->{status}, $f->label // '<undef>';
	}
);

do $script;

