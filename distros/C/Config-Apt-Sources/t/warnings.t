#!perl -T
use warnings;
use strict;

### Test failure conditions and warnings
use Test::More tests => 2; # Evidently Test::Warn doesn't do plans.
use Test::Warn;
use Config::Apt::Sources;

my $srcs = Config::Apt::Sources->new();

warning_is { Config::Apt::SourceEntry->new('') } {carped => 'Invalid source' }, "SourceEntry::from_string (no args)";
warning_is { $srcs->set_sources('aoeu', 'fnord') } {carped => 'arguments must be Config::Apt::SourceEntry objects' }, "Sources::set_sources (bad args)";
