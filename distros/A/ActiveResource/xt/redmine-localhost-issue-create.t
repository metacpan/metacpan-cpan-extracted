#!/usr/bin/env perl
use common::sense;

package Issue;
use parent 'ActiveResource::Base';

__PACKAGE__->site("http://localhost:3000");
__PACKAGE__->user("admin");
__PACKAGE__->password("admin");

package main;
use Test::More;

my $issue = Issue->create(
    project_id => 1,
    subject => "Created from $$, " . __FILE__,
    description => "Lipsum"
);

like($issue->id, qr/^\d+$/, "The issue id should be a number");
like($issue->subject, qr/^Created from \d+,/, "The issue subject should look right");
is($issue->description, "Lipsum", "The issue description should look right");

done_testing;
