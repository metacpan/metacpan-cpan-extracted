use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use File::Temp;
use Git::Raw;
use CPAN::InGit;
use v5.36;

for my $selection (
   [ implied => [] ],
   [ explicit => [ '--branch=my_app' ] ],
   [ HEAD => [ '--branch=HEAD' ] ],
) {
   subtest $selection->[0] => sub {
      my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
      my $git_repo= Git::Raw::Repository->init($repodir, 0);
      my $cpan_repo= CPAN::InGit->new(repo => $git_repo);

      # A local source keeps the command-line test independent of network access.
      my $source= $cpan_repo->create_archive_tree('source');
      my $dist= 'L/LO/LOCAL/Regression-Example-1.00.tar.gz';
      my $dist_path= "authors/id/$dist";
      my $entry= [ 'Regression::Example', '1.00', $dist ];
      $source->set_path($dist_path, \'Mock distribution');
      $source->package_details->{by_module}{'Regression::Example'}= $entry;
      $source->package_details->{by_dist}{$dist}= [ $entry ];
      $source->write_package_details;
      $source->commit('Add test distribution');
      $cpan_repo->create_archive_tree('my_app',
         default_import_sources => ['source'], use_workdir => 1);
      my $head_id= $git_repo->head->target->id;

      mkfile("$repodir/unrelated.txt", 'Already staged');
      $git_repo->index->add('unrelated.txt');
      $git_repo->index->write;

      is( system($^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../bin/cpangit-add",
          "--git-dir=$repodir", '--quiet', '--quiet', '--quiet',
          $selection->[1]->@*, 'Regression::Example'),
          0, 'cpangit-add succeeds' );

      # Reopen the repository so only the on-disk index can satisfy these checks.
      my $reopened= Git::Raw::Repository->open("$repodir");
      is( $reopened->head->shorthand, 'my_app', 'current branch unchanged' );
      is( $reopened->head->target->id, $head_id, 'no commit generated' );
      is( $reopened->index->find($dist_path),
          object { call blob => object { call content => 'Mock distribution'; }; },
          'imported distribution staged on disk' );
      is( $reopened->index->find('modules/02packages.details.txt'),
          object { call blob => object { call content => match qr/^Regression::Example\s+1\.00\s+\Q$dist\E$/m; }; },
          'updated package list staged on disk' );
      is( $reopened->index->find('unrelated.txt'),
          object { call blob => object { call content => 'Already staged'; }; },
          'user staging preserved' );
      is( slurp("$repodir/$dist_path"), 'Mock distribution', 'distribution written to workdir' );
   };
}

done_testing;
