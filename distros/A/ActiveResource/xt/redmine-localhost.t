#!/usr/bin/env perl
package Project;
use parent 'ActiveResource::Base';

package Issue;
use parent 'ActiveResource::Base';

package main;
use common::sense;
use Test::More;

ActiveResource::Base->site("http://localhost:3000");
ActiveResource::Base->user("admin");
ActiveResource::Base->password("admin");

subtest "Some simple matter of finding" => sub {
    my $project = Project->find(1);
    is $project->name, "test";

    my $issue = Issue->find(1);
    is $issue->id, 1;
    is $issue->project->id, 1;
    is $issue->project->name, "test";
    is $issue->status->name, "Resolved";
    ok $issue->can('save');
    done_testing;
};

subtest "Creating new issues" => sub {
    my $issue = Issue->create(
        project => { id => 1 },
        subject => "Created from $$, " . __FILE__,
    );

    like($issue->id, /^\d+$/);
    like($issue->subject, /^Created from \d+,/);

    done_testing;
};


subtest "lvalue attribute setter and saving" => sub {
    my $issue = Issue->find(1);
    my $old_description = $issue->description;
    my $new_description = "Shiny new description. $$";
    $issue->description = $new_description;
    $issue->save;

    is $issue->description, $new_description;

    {
        my $i2 = Issue->find(1);
        is $i2->description, $new_description;
    }

    $issue->description = $old_description;
    $issue->save;

    is $issue->description, $new_description;

    done_testing;
};


done_testing;
