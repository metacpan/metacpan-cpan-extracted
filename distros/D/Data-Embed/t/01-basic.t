use Test::More tests => 15;
use Test::Exception;

use strict;
use Data::Embed qw< embed embedded >;
use File::Basename qw< dirname >;
use lib dirname(__FILE__);
use DataEmbedTestUtil qw< read_file write_file >;

my $prefix   = "something before\n";
my $sample1  = "This is some data\n";
my $sample2  = join '', "binary data:\n", map { chr($_) } 0 .. 255;
my $contents = join "\n", "$prefix$sample1\n", "$sample2\n",
  'Data::Embed/index/begin',
  '18 some%20thing',
  '269 anoth%25%25er',
  "Data::Embed/index/end\n";
my $testfile = __FILE__ . '.test1';

{  # embed
   write_file($testfile, $prefix);
   lives_ok {
      embed(input => $testfile, output => $testfile, data => $sample1, name => 'some thing');
      embed(container => $testfile, data => $sample2, name => 'anoth%%er');
   } 'two calls to embed() lived';
   my $generated = read_file($testfile);
   is $generated, $contents, 'generated file is as expected';
}

{  # embedded
   write_file($testfile, $contents);
   my @files;
   lives_ok {
      @files = embedded($testfile);
   } 'call to embedded() lived';
   is scalar(@files), 2, 'number of embedded files';

   my ($f1, $f2) = @files;
   isa_ok $f1, 'Data::Embed::File';
   is $f1->{name}, 'some thing', 'name of first file';
   my $contents1;
   lives_ok {
      $contents1 = $f1->contents();
   } 'call to contents() lived';
   is $contents1, $sample1, 'contents of first embedded file, via contents()';

   isa_ok $f2, 'Data::Embed::File';
   is $f2->{name}, 'anoth%%er', 'name of second file';
   my $fh;
   lives_ok {
      $fh = $f2->fh();
   } 'call to fh() lived';
   isa_ok $fh, 'GLOB', 'fh() output';

   my ($first_line, $rest);
   lives_ok {
      $first_line = <$fh>;
      $rest = do { local $/; <$fh> };
   } 'reading from filehandle lived';
   is $first_line, "binary data:\n", 'first line of second file';
   is $first_line . $rest, $sample2, 'contents of second file';

   unlink $testfile;
}
