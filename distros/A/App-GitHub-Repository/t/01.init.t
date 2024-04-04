use Test::More; # -*- mode:cperl -*-

use lib qw(../lib lib);

use App::GitHub::Repository;

my $rnd = int( rand ( 1000000 ));
my $test_dir = "/tmp/AGR-test-$rnd";
mkdir( $test_dir );

my $repo = App::GitHub::Repository->new('https://github.com/JJ/p5-app-github-repository', $test_dir);

isa_ok($repo, 'App::GitHub::Repository');
$repo->has_readme( "Has README" );
$repo->has_file( ".gitignore", "Has .gitignore" );
$repo->has_milestones( 1, "Correct number of milestones" );
$repo->issues_well_closed( "Issues closed from a commit" );

eval {
  App::GitHub::Repository->new('https://github.com/JJ/p5-app-github-repository', $test_dir)
};

like( $@, qr/already exists/ );

done_testing;
