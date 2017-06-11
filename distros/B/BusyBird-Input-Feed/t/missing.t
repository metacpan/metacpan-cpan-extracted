use strict;
use warnings;
use Test::More;
use Test::Warnings;
use BusyBird::Input::Feed;
use File::Spec;

my $input = BusyBird::Input::Feed->new(use_favicon => 0);

my $got = $input->parse_file(File::Spec->catfile(".", "t", "samples", "missing_fields.atom"));

is($got->[0]{text}, "", "title is missing. text should be an empty string.");
ok(!exists($got->[1]{busybird}{status_permalink}), "link is missing. status_permalink should not even exist.");

done_testing;
