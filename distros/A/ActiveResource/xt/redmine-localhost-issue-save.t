#!/usr/bin/env perl
use common::sense;

package Issue;
use parent 'ActiveResource::Base';

__PACKAGE__->site("http://localhost:3000");
__PACKAGE__->user("admin");
__PACKAGE__->password("admin");

package main;
use Test::More;

subtest "Save a new record" => sub {
    my $issue = Issue->new;
    $issue->project_id(1);
    $issue->subject("OHAI from " . __FILE__);
    my $d = "Updated by $$, " . __FILE__ . ", " . localtime;
    $issue->description($d);
    $issue->save;

    like($issue->id, qr/^\d+$/);
    is($issue->description, $d);

    done_testing;
};

subtest "Save an existing record" => sub {
    my $issue = Issue->find(1);
    my $new_description = "Updated by $$, " . __FILE__ . ", " . localtime;

    $issue->description($new_description);
    $issue->save;

    my $i2 = Issue->find(1);
    is ($i2->description, $new_description);

    done_testing;
};

done_testing;

