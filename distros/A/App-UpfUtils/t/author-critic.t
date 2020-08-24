#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/UpfUtils.pm','script/upf-add-delete-user-groups','script/upf-add-group','script/upf-add-user','script/upf-add-user-to-group','script/upf-delete-group','script/upf-delete-user','script/upf-delete-user-from-group','script/upf-get-group','script/upf-get-max-gid','script/upf-get-max-uid','script/upf-get-user','script/upf-get-user-groups','script/upf-group-exists','script/upf-is-member','script/upf-list-groups','script/upf-list-users','script/upf-list-users-and-groups','script/upf-modify-group','script/upf-modify-user','script/upf-set-user-groups','script/upf-set-user-password','script/upf-user-exists'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
