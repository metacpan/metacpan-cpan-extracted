#!perl
use strict;
use warnings;
use Test::More;
use Cogit;
use Cogit::DirectoryEntry;
use File::Temp;
use Path::Class;

my @dirs = (File::Temp->newdir, File::Temp->newdir,);
for my $directory (@dirs) {

   my $git;
   if ($directory eq $dirs[1]) {
      $git = Cogit->init(gitdir => $directory);
   } else {
      $git = Cogit->init(directory => $directory);
   }

   isa_ok($git, 'Cogit', 'can init');

   is($git->description,
      'Unnamed repository; edit this file to name it for gitweb.');

   is($git->all_sha1s->all,   0, 'does not contain any sha1s');
   is($git->all_objects->all, 0, 'does not contain any objects');

   my $hello = Cogit::Object::Blob->new(content => 'hello');
   $git->put_object($hello);
   is($hello->sha1, 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
   is($git->get_object('b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0')->content,
      'hello');

   my $there = Cogit::Object::Blob->new(content => 'there');
   $git->put_object($there);
   is($there->sha1, 'c78ee1a5bdf46d22da300b68d50bc45c587c3293');
   is($git->get_object('c78ee1a5bdf46d22da300b68d50bc45c587c3293')->content,
      'there');

   my $hello_de = Cogit::DirectoryEntry->new(
      mode     => '100644',
      filename => 'hello.txt',
      sha1     => $hello->sha1,
   );
   my $there_de = Cogit::DirectoryEntry->new(
      mode     => '100644',
      filename => 'there.txt',
      sha1     => $there->sha1,
   );
   my $tree =
     Cogit::Object::Tree->new(directory_entries => [$hello_de, $there_de]);
   is($tree->sha1, '6d991aebc86bd09e86d74bb84bb9ebfb97e18026');
   $git->put_object($tree);
   my $tree2 = $git->get_object('6d991aebc86bd09e86d74bb84bb9ebfb97e18026');
   is($tree2->kind, 'tree');
   is($tree2->size, 74);
   my @directory_entries = @{$tree2->directory_entries};
   is(@directory_entries, 2);
   my $directory_entry = $directory_entries[0];
   is($directory_entry->mode,     '100644');
   is($directory_entry->filename, 'hello.txt');
   is($directory_entry->sha1,     'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
   my $directory_entry2 = $directory_entries[1];
   is($directory_entry2->mode,     '100644');
   is($directory_entry2->filename, 'there.txt');
   is($directory_entry2->sha1,     'c78ee1a5bdf46d22da300b68d50bc45c587c3293');

   my $actor = Cogit::Actor->new(
      name  => 'Your Name Comes Here',
      email => 'you@yourdomain.example.com'
   );
   my $commit = Cogit::Object::Commit->new(
      git            => $git,
      tree           => $tree->sha1,
      author         => $actor,
      authored_time  => DateTime->from_epoch(epoch => 1240341681),
      committer      => $actor,
      committed_time => DateTime->from_epoch(epoch => 1240341682),
      comment        => 'Fix',
   );

   is($commit->content, <<'CONTENT' );
tree 6d991aebc86bd09e86d74bb84bb9ebfb97e18026
author Your Name Comes Here <you@yourdomain.example.com> 1240341681 +0000
committer Your Name Comes Here <you@yourdomain.example.com> 1240341682 +0000

Fix
CONTENT
   is($commit->sha1, '860caea5ba298bb4f1df9a80fad84951fcc7db72');
   $git->put_object($commit);

   my $commit2 = $git->get_object('860caea5ba298bb4f1df9a80fad84951fcc7db72');
   is($commit2->tree_sha1, $tree->sha1);
   isa_ok($commit2->author, 'Cogit::Actor');
   is($commit2->author->name,  'Your Name Comes Here');
   is($commit2->author->email, 'you@yourdomain.example.com');
   isa_ok($commit2->committer, 'Cogit::Actor');
   is($commit2->committer->name,       'Your Name Comes Here');
   is($commit2->committer->email,      'you@yourdomain.example.com');
   is($commit2->authored_time->epoch,  1240341681);
   is($commit2->committed_time->epoch, 1240341682);
   is($commit2->comment,               'Fix');

   if ($directory eq $dirs[1]) {
      $git = Cogit->new(gitdir => $directory);
   } else {
      $git = Cogit->new(directory => $directory);
   }
   isa_ok($git, 'Cogit', 'can get object');

   is($git->all_sha1s->all,   4, 'contains four sha1s');
   is($git->all_objects->all, 4, 'contains four objects');

   my $checkout_directory = dir('t/checkout');
   $checkout_directory->rmtree;
   $checkout_directory->mkpath;
   unless ($directory eq 'test-init-bare.git') {
      $git->checkout($checkout_directory);
      is_deeply(
         [sort $checkout_directory->as_foreign('Unix')->children],
         ['t/checkout/hello.txt', 't/checkout/there.txt'],
         'checkout has two files'
      );
      is(file('t/checkout/hello.txt')->slurp,
         'hello', 'hello.txt has latest content');
      is(file('t/checkout/there.txt')->slurp,
         'there', 'there.txt has latest content');
   }

   is_deeply([$git->ref_names], ['refs/heads/master'], 'have ref master');

   isa_ok($git->ref('refs/heads/master'),
      'Cogit::Object::Commit', 'have master commit');
   is($git->ref('refs/heads/master')->sha1,
      $commit->sha1, 'master points to our commit');

   my $here = Cogit::Object::Blob->new(git => $git, content => 'here');
   $git->put_object($here);

   my $here_de = Cogit::DirectoryEntry->new(
      mode     => '100644',
      filename => 'there.txt',
      sha1     => $here->sha1,
   );
   $tree = Cogit::Object::Tree->new(directory_entries => [$hello_de, $here_de]);
   $git->put_object($tree);
   my $newcommit = Cogit::Object::Commit->new(
      git            => $git,
      tree           => $tree->sha1,
      parent         => $commit->sha1,
      author         => $actor,
      authored_time  => DateTime->from_epoch(epoch => 1240341683),
      committer      => $actor,
      committed_time => DateTime->from_epoch(epoch => 1240341684),
      comment        => 'Fix again',
   );
   $git->put_object($newcommit);

   my $newcommit2 = $git->get_object($newcommit->sha1);
   isa_ok($newcommit2->author, 'Cogit::Actor');
   is($newcommit2->author->name,  'Your Name Comes Here');
   is($newcommit2->author->email, 'you@yourdomain.example.com');
   isa_ok($newcommit2->committer, 'Cogit::Actor');
   is($newcommit2->committer->name,       'Your Name Comes Here');
   is($newcommit2->committer->email,      'you@yourdomain.example.com');
   is($newcommit2->authored_time->epoch,  1240341683);
   is($newcommit2->committed_time->epoch, 1240341684);
   is($newcommit2->comment,               'Fix again');

   is($git->ref('refs/heads/master')->sha1, $newcommit->sha1, 'master updated');

   is($git->all_sha1s->all,   7, 'contains seven sha1s');
   is($git->all_objects->all, 7, 'contains seven objects');
}

done_testing;
