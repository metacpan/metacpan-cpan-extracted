#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

my $root = tempdir( CLEANUP => 1 );

my $yml = App::prepare4release->render_github_ci_yml( ['5.10'], [] );
App::prepare4release->ensure_github_workflow( $root, $yml, 0 );

my $p = File::Spec->catfile( $root, '.github', 'workflows', 'ci.yml' );
ok( -e $p, 'GitHub ci.yml created' );

App::prepare4release->ensure_github_workflow( $root, $yml, 0 );
ok( -e $p, 'second run keeps file' );

my $glp = File::Spec->catfile( $root, '.gitlab-ci.yml' );
my $gly = App::prepare4release->render_gitlab_ci_yml( ['5.10'], [] );
App::prepare4release->ensure_gitlab_ci( $root, $gly, 0 );
ok( -e $glp, 'GitLab .gitlab-ci.yml created' );

done_testing;
