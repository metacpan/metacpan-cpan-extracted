#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use App::PM::Announce;
use Directory::Scratch;

$ENV{APP_PM_ANNOUNCE_HOME} = 't/assets/home';

my $app = App::PM::Announce->new;
my $document = $app->parse(\<<_END_);
# Just a comment
---
datetime: today
xyzzy: 1
xyzxy: |-
    Multi-line fun
    Yup!
---
Document body
Yoink!
_END_

ok($document);
is($document->preamble, "# Just a comment\n");
is($document->header->{xyzzy}, 1);
is($document->header->{xyzxy}, "Multi-line fun\nYup!");
is($document->body, "Document body\nYoink!\n");
