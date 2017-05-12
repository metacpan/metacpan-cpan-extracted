#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;
use File::Spec;

use_ok('App::Git::Workflow');
use_ok('App::Git::Workflow::Command');
use_ok('App::Git::Workflow::Command::BranchClean');
use_ok('App::Git::Workflow::Command::BranchGrep');
use_ok('App::Git::Workflow::Command::Committers');
use_ok('App::Git::Workflow::Command::Cows');
use_ok('App::Git::Workflow::Command::Feature');
use_ok('App::Git::Workflow::Command::Files');
use_ok('App::Git::Workflow::Command::Jira');
use_ok('App::Git::Workflow::Command::Pom');
use_ok('App::Git::Workflow::Command::TagGrep');
use_ok('App::Git::Workflow::Command::UpToDate');
use_ok('App::Git::Workflow::Command::Recent');
use_ok('App::Git::Workflow::Command::Watch');
use_ok('App::Git::Workflow::Pom');
use_ok('App::Git::Workflow::Repository');
use_ok('Test::Git::Workflow::Command');
use_ok('Mock::App::Git::Workflow::Repository');

my $perl = File::Spec->rel2abs($^X);
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-branch-clean"), "bin/git-branch-clean compiles");
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-branch-grep" ), "bin/git-branch-grep compiles" );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-committers"  ), "bin/git-committers compiles"  );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-cows"        ), "bin/git-cows compiles"        );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-feature"     ), "bin/git-feature compiles"     );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-files"       ), "bin/git-files compiles"       );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-hook-setup"  ), "bin/git-hook-setup compiles"  );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-jira"        ), "bin/git-jira compiles"        );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-pom"         ), "bin/git-pom compiles"         );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-tag-grep"    ), "bin/git-tag-grep compiles"    );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-up-to-date"  ), "bin/git-up-to-date compiles"  );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-recent"      ), "bin/git-recent compiles"      );
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/git-watch"       ), "bin/git-watch compiles"       );

diag( "Testing App-Git-Workflow, Perl $], $^X" );
done_testing();
