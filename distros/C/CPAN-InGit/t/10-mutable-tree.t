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
   is( Git::Raw::Repository->open("$repodir")->index->find('example/test.txt'),
       object { call blob => object { call content => 'Hello'; }; },
       'addition persisted to the index before committing' );
   
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

   my $head_id= $git_repo->head->target->id;
   # Preserve changes the user already staged while adding, modifying, and removing files.
   mkfile("$repodir/unrelated.txt", 'Already staged');
   $git_repo->index->add('unrelated.txt');
   $git_repo->index->write;
   $mtree->set_path('example/test.txt', \'Updated');
   is( slurp("$repodir/example/test.txt"), 'Updated', 'working file updated' );
   is( Git::Raw::Repository->open("$repodir")->index->find('example/test.txt'),
       object { call blob => object { call content => 'Updated'; }; },
       'modification persisted to the index before committing' );
   $mtree->set_path('example/another.txt', \'Another');
   $mtree->set_path('example/test.txt', undef);
   ok( !-e "$repodir/example/test.txt", 'working file removed' );
   my $reopened= Git::Raw::Repository->open("$repodir");
   is( $reopened->index->find('example/test.txt'), undef, 'removal persisted to the index' );
   is( $reopened->index->find('example/another.txt'),
       object { call blob => object { call content => 'Another'; }; },
       'another addition persisted to the index' );
   is( $reopened->index->find('unrelated.txt'),
       object { call blob => object { call content => 'Already staged'; }; },
       'unrelated staged change preserved' );
   is( $reopened->head->target->id, $head_id, 'staging leaves the branch commit unchanged' );
   if ($have_git) {
      local $ENV{GIT_WORK_TREE}= $repodir;
      local $ENV{GIT_DIR}= "$repodir/.git";
      is( scalar `git status --porcelain`,
          "A  example/another.txt\nD  example/test.txt\nA  unrelated.txt\n",
          'git sees additions and deletion staged for the user to commit' );
   }
};

subtest directories => sub {
   for my $use_workdir (0, 1) {
      my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
      my $git_repo= Git::Raw::Repository->init($repodir, !$use_workdir);
      my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
      my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo, use_workdir => $use_workdir);
      my $label= $use_workdir? 'workdir' : 'bare';

      is( $mtree->list_dir, undef, "$label: no root directory in an empty tree" ) unless $use_workdir;
      $mtree->set_path('top.txt', \'top');
      $mtree->set_path('dir', {
         'a.txt'       => \'A',
         'bin/run'     => [ \'#!/bin/sh', 0100755 ],
         'sub'         => { 'b.txt' => \'B', 'link' => [ \'b.txt', 0120000 ] },
      });
      is( $mtree->list_dir('dir'),
         { 'a.txt' => [ object { call content => 'A' }, 0100644 ],
           'bin'   => [ object { call is_tree => T }, 0040000 ],
           'sub'   => [ object { call is_tree => T }, 0040000 ] },
         "$label: list_dir of pending directory" );
      is( $mtree->get_path('dir/bin/run'), [ object { call content => '#!/bin/sh' }, 0100755 ], "$label: executable" );
      is( $mtree->get_path('dir/sub/link'), [ object { call content => 'b.txt' }, 0120000 ], "$label: symlink" );
      is( [ sort keys %{ $mtree->list_dir } ], [ 'dir', 'top.txt' ], "$label: list_dir of root" );
      is( $mtree->list_dir('top.txt'), undef, "$label: list_dir of a file" );
      is( $mtree->list_dir('nope'), undef, "$label: list_dir of a missing path" );
      if ($use_workdir) {
         is( slurp("$repodir/dir/sub/b.txt"), 'B', 'workdir: file written' );
         is( readlink("$repodir/dir/sub/link"), 'b.txt', 'workdir: symlink written' );
         ok( -x "$repodir/dir/bin/run", 'workdir: executable bit' );
      }
      $mtree->commit('first', create_branch => 'main');

      # Setting a directory replaces everything that was there
      my $before= $mtree->get_path('dir')->[0];
      $mtree->set_path('dir', { 'a.txt' => \'A2', 'new/c.txt' => \'C' });
      is( [ sort keys %{ $mtree->list_dir('dir') } ], [ 'a.txt', 'new' ], "$label: directory replaced" );
      is( $mtree->get_path('dir/sub/b.txt'), undef, "$label: old file is gone" );
      is( $mtree->get_path('dir/sub'), undef, "$label: old subdirectory is gone" );
      is( $mtree->get_path('dir/new/c.txt'), [ object { call content => 'C' }, 0100644 ], "$label: new file" );
      ok( !-e "$repodir/dir/sub", 'workdir: old subdirectory removed' ) if $use_workdir;
      # and can then be modified further
      $mtree->set_path('dir/new/d.txt', \'D');
      is( [ sort keys %{ $mtree->list_dir('dir/new') } ], [ 'c.txt', 'd.txt' ], "$label: added to new directory" );

      # compare the pending state to the previous directory
      is( $mtree->diff($mtree->tree, paths => ['top.txt']), [], "$label: no difference in top.txt" );
      my $deltas= CPAN::InGit::MutableTree->new(parent => $cpan_repo, tree => $before)
         ->diff($mtree->get_path('dir')->[0], patch => 1);
      is( $deltas,
         [
            { path => 'a.txt', status => 'modified', binary => 0, additions => 1, deletions => 1,
              old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644,
              patch => match qr/^-A\n.*^\+A2\n/ms },
            { path => 'bin/run', status => 'deleted', binary => 0, additions => 0, deletions => 1,
              old_id => T, new_id => undef, old_mode => 0100755, new_mode => undef, patch => T },
            { path => 'new/c.txt', status => 'added', binary => 0, additions => 1, deletions => 0,
              old_id => undef, new_id => T, old_mode => undef, new_mode => 0100644, patch => T },
            { path => 'new/d.txt', status => 'added', binary => 0, additions => 1, deletions => 0,
              old_id => undef, new_id => T, old_mode => undef, new_mode => 0100644, patch => T },
            { path => 'sub/b.txt', status => 'deleted', binary => 0, additions => 0, deletions => 1,
              old_id => T, new_id => undef, old_mode => 0100644, new_mode => undef, patch => T },
            { path => 'sub/link', status => 'deleted', binary => 0, additions => 0, deletions => 1,
              old_id => T, new_id => undef, old_mode => 0120000, new_mode => undef, patch => T },
         ],
         "$label: diff" );
      is( scalar @{ $mtree->diff(undef) }, 4, "$label: diff with an empty tree" );

      # A Git tree can be used as a directory, and then modified
      $mtree->set_path('copy', $before);
      is( $mtree->get_path('copy/sub/b.txt'), [ object { call content => 'B' }, 0100644 ], "$label: path within a tree" );
      $mtree->set_path('copy/sub/b.txt', undef);
      is( [ sort keys %{ $mtree->list_dir('copy/sub') } ], [ 'link' ], "$label: removed a file of the tree" );
      $mtree->set_path('copy', undef);
      is( $mtree->get_path('copy'), undef, "$label: removed directory" );
      $mtree->commit('second');
      is( [ sort keys %{ $mtree->list_dir('dir/new') } ], [ 'c.txt', 'd.txt' ], "$label: after commit" );
      is( $mtree->get_path('dir/sub'), undef, "$label: replaced directory stays gone after commit" );

      like( dies { $mtree->set_path('x', { 'a' => \'1', 'a/b' => \'2' }) }, qr/Conflicting/, "$label: conflicting entries" );
      like( dies { $mtree->set_path('x', { '../a' => \'1' }) }, qr/Invalid path/, "$label: path escaping the directory" );
   }
};

done_testing;
