use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Mojo;
use Test2AndUtils;
use Archive::Tar;
use File::Temp;
use Git::Raw;
use IO::Compress::Gzip 'gzip';
use IO::Uncompress::Gunzip 'gunzip';
use POSIX 'strftime';
use CPAN::InGit;
use CPAN::InGit::Server;
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

subtest 'unpack distributions for local editing' => sub {
   my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
   my $repo= Git::Raw::Repository->init($repodir, 0);
   my $pan= CPAN::InGit->new(repo => $repo);
   my $source= $pan->create_archive_tree('source');
   my $upstream= 'R/RE/REGRESSION/Regression-Example-1.00.tar.gz';
   my $tar= Archive::Tar->new;
   my $pm= <<~'PM';
      package Regression::Example;
      our $VERSION = '1.00';
      package Regression::Bundled v2.3.4;
      package Regression::Private;
      1;
      PM
   $tar->add_data('Regression-Example-1.00/lib/Regression/Example.pm', $pm, { mode => 0755 });
   my $contents= $tar->write;
   gzip \$contents => \my $archive or die 'gzip failed';
   $source->set_path("authors/id/$upstream", \$archive);
   $source->index_distribution($upstream, { 'Regression::Example' => '1.00', 'Regression::Bundled' => '2.50' });
   $source->commit('Add source distribution');
   $pan->create_archive_tree('app', default_import_sources => ['source'], use_workdir => 1);
   $pan->create_archive_tree('other');
   my $head= $repo->head->target->id;
   my @add= ($^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../bin/cpangit-add", "--git-dir=$repodir", '--local');

   is(system(@add, 'Regression::Example'), 0, 'localize by package name');
   my $reopened= Git::Raw::Repository->open("$repodir");
   my $local= 'L/LO/LOCAL/Regression-Example-1.00';
   my $module_path= "authors/id/$local/lib/Regression/Example.pm";
   is($reopened->head->target->id, $head, 'HEAD did not move');
   is(slurp("$repodir/$module_path"), $pm, 'module file is editable in the workdir');
   is($reopened->index->find($module_path)->mode, 0100755, 'executable mode staged');
   ok($reopened->index->find("authors/id/$local.meta"), 'sidecar metadata staged');
   ok(!$reopened->index->find("authors/id/$upstream"), 'upstream archive was not staged');
   ok(!$reopened->index->find("authors/id/$local.tar.gz"), 'LOCAL archive is generated from the tree');

   my $app= CPAN::InGit->new(repo => $reopened)->get_archive_tree('app');
   is($app->get_module_dist('Regression::Example'), "$local.tar.gz", 'primary package uses LOCAL');
   is($app->get_module_dist('Regression::Bundled'), "$local.tar.gz", 'bundled package uses LOCAL');
   is($app->get_module_version('Regression::Bundled'), '2.50', 'source-index version is retained');
   is($app->get_module_dist('Regression::Private'), undef, 'source-index exclusions are retained');
   is($app->dist_storage("$local.tar.gz"), q{unpacked}, 'unpacked tree is visible from the staged index');
   like(dies { $app->add_local_dist($upstream, \$archive) }, qr/already exists/, 'repeat import preserves edits');

   my $file= "$repodir/Regression-Example-1.00.tar.gz";
   mkfile($file, $archive);
   my $other_before= $pan->get_archive_tree('other')->branch->target->id;
   is(system(@add, '--branch=other', $file), 0, 'localize a file on another branch');
   my $other= $pan->get_archive_tree('other');
   isnt($other->branch->target->id, $other_before, 'other branch has a new commit');
   is($other->get_module_dist('Regression::Private'), "$local.tar.gz", 'source inspection finds unversioned package');
   is($other->get_module_version('Regression::Bundled'), 'v2.3.4', 'source inspection finds package version declaration');
   is($other->get_module_version('Regression::Example'), '1.00', 'source inspection finds literal VERSION');
   is($other->get_path($module_path)->[0]->content, $pm, 'source file committed on other branch');
   is($reopened->head->target->id, $head, 'checked-out branch still has no new commit');

   my $target= $pan->create_archive_tree('target');
   my $other_author= 'O/OT/OTHER/Regression-Private-9.00.tar.gz';
   $target->index_distribution($other_author, { 'Regression::Private' => '9.00' });
   {
      my @warnings;
      Log::Any::Adapter->set({ lexically => \my $guard }, 'Capture', text => \@warnings, log_level => 'warning');
      $target->import_dist($pan->get_archive_tree('source'), $upstream);
      like(join("\n", @warnings), qr/Packages claimed by \Q$upstream\E.* in source: Regression::Private$/m,
         'importing from a peer without an upstream warns about the unindexed claim');
   }
   is($target->get_module_dist('Regression::Private'), $other_author, 'import preserves the existing provider');
   is($target->get_module_dist('Regression::Example'), $upstream, 'import registers the indexed package');

   my $now= strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime);
   my $index_text= "Last-Updated: $now\n\nRegression::Example 1.00 $upstream\n";
   gzip \$index_text => \my $index_gz or die 'gzip failed';
   my @fetched;
   no warnings 'redefine';
   local *CPAN::InGit::MirrorTree::fetch_upstream_file= sub ($tree, $path, %options) {
      push @fetched, $path;
      return \$index_gz if $path eq 'modules/02packages.details.txt.gz';
      return \$archive if $path eq "authors/id/$upstream";
      die "Unexpected upstream request $path";
   };
   $pan->create_archive_tree('mirror', upstream_url => 'http://upstream.invalid');
   my $mirror= $pan->get_archive_tree('mirror');
   is($mirror->localize_module('Regression::Example'), "$local.tar.gz", 'download using the mirror upstream path');
   $mirror->add_upstream_package_details;
   $mirror->commit('Localize package on mirror');
   my $published= $pan->get_archive_tree('mirror');
   is($published->get_module_dist('Regression::Example'), "$local.tar.gz", 'mirror refresh preserves the LOCAL package');
   ok(!$published->tree->entry_bypath("authors/id/$upstream"), 'mirror did not store the upstream archive');

   my $http= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($http->app->routes->any('/'), $pan,
      app => $http->app, archive_tree => $published);
   $http->get_ok("/authors/id/$local.tar.gz")->status_is(200);
   my $body= $http->tx->res->body;
   gunzip \$body => \my $raw_tar or die 'gunzip failed';
   open my $fh, '<:raw', \$raw_tar or die $!;
   my $download= Archive::Tar->new($fh);
   is(($download->get_files)[0]->get_content, $pm, 'server archive contains the editable source');
   is(\@fetched, [
      'modules/02packages.details.txt.gz', "authors/id/$upstream", 'modules/02packages.details.txt.gz',
   ], 'serving the local distribution needs no upstream fetch');

   my $consumer= $pan->create_archive_tree('consumer', default_import_sources => ['other']);
   $consumer->import_modules({ 'Regression::Example' => '1.00' });
   is($consumer->get_module_dist('Regression::Example'), "$local.tar.gz", 'ordinary import can use a LOCAL distribution');
   ok($consumer->get_path("authors/id/$local.tar.gz")->[0]->is_blob, 'ordinary import stores the generated archive');
};

done_testing;
