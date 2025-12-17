use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use File::Temp;
use Git::Raw;
use CPAN::InGit;
use CPAN::InGit::MutableTree;
use v5.36;

my $have_git= `git --version`;
note "git command ".($have_git // 'unavailable');

subtest in_bare_repo => sub {
   my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
   my $git_repo= Git::Raw::Repository->init($repodir, 1); # new bare repo in tmpdir
   note "repo at $repodir";

   my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   
   # get_path on an empty tree returns undef (doesn't die)
   is( $mtree->get_path("example/test.txt"), undef, 'nonexistent test.txt' );
   is( $mtree->has_changes, F, 'has_changes = false' );
   # set_path should succeed, and then get_path should return an "entry" [ $blob, $mode ]
   ok( $mtree->set_path("example/test.txt", \"Hello"), 'set_path test.txt' );
   is( $mtree->has_changes, T, 'has_chagnes = true' );
   is( $mtree->get_path("example/test.txt"),
       [ object { call is_blob => T; }, number_gt 0 ],
       'get_path test.txt' );
   #  build the tree to be committed
   ok( $mtree->update_tree(), 'update_tree' );
   is( $mtree->tree, object { call is_tree => T; }, 'tree attribute updated' );
   # Make first commit of a new branch
   is( $mtree->commit("Initial commit", create_branch => 'www_cpan_org'),
       object { call message => 'Initial commit'; },
       'commit' );
   is( $mtree->branch,
       object {
          call is_head => F;
          call name => 'refs/heads/www_cpan_org';
       },
       'new branch' );
};

subtest in_workdir => sub {
   my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
   my $git_repo= Git::Raw::Repository->init($repodir, 0); # new repo with workdir
   note "repo at $repodir";

   my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo, use_workdir => 1);
   
   # get_path on an empty tree returns undef (doesn't die)
   is( $mtree->get_path("example/test.txt"), undef, 'nonexistent test.txt' );
   is( $mtree->has_changes, F, 'has_changes = false' );
   # set_path should succeed, and then get_path should return an "entry" [ $blob, $mode ]
   ok( $mtree->set_path("example/test.txt", \"Hello"), 'set_path test.txt' );
   is( $mtree->has_changes, T, 'has_chagnes = true' );
   is( $mtree->get_path("example/test.txt"),
       [ object { call is_blob => T; }, number_gt 0 ],
       'get_path test.txt' );
   # the path should also exist in the filesystem now
   is( -s "$repodir/example/test.txt", 5, 'disk file created to match' );
   
   #  build the tree to be committed
   ok( $mtree->update_tree(), 'update_tree' );
   is( $mtree->tree, object { call is_tree => T; }, 'tree attribute updated' );
   # Make first commit of a new branch
   is( $mtree->commit("Initial commit", create_branch => 'www_cpan_org'),
       object { call message => 'Initial commit'; },
       'commit' );
   is( $mtree->branch, object { call is_head => T; call name => 'refs/heads/www_cpan_org'; }, 'new branch' );
   is( slurp("$repodir/.git/HEAD"), "ref: refs/heads/www_cpan_org\n", 'HEAD pointed at branch' );
   # Git command should report no changes and that HEAD points at the branch
   if ($have_git) {
      local $ENV{GIT_WORK_TREE}= $repodir;
      local $ENV{GIT_DIR}= "$repodir/.git";
      is( scalar `git status -sb`, "## www_cpan_org\n", 'on branch www_cpan_org, no changes in workdir' );
   }
};

done_testing;
