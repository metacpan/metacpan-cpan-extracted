use Test::More tests => 55;
use Test::Exception;

use strict;
use Data::Embed qw< writer >;
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
my $testfile = __FILE__ . '.test-container';

# no input
{
   my $writer;
   lives_ok {
      $writer = writer(output => $testfile);
   } 'constructor without input lives';
   my $size = -s $testfile;
   is $size, 0, 'output file has been reset to empty contents';
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 371, 'output file size';
   my $generated = read_file($testfile);
   my $contents = join "\n", "$sample1\n", "$sample2\n",
      'Data::Embed/index/begin',
      '18 some%20thing',
      '269 anoth%25%25er',
      "Data::Embed/index/end\n";
   is $generated, $contents, 'generated file as expected';
   unlink $testfile;
}

# undefined input
{
   my $writer;
   lives_ok {
      $writer = writer(input => undef, output => $testfile);
   } 'constructor with undefined input lives';
   my $size = -s $testfile;
   is $size, 0, 'output file has been reset to empty contents';
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 371, 'output file size';
   my $generated = read_file($testfile);
   my $contents = join "\n", "$sample1\n", "$sample2\n",
      'Data::Embed/index/begin',
      '18 some%20thing',
      '269 anoth%25%25er',
      "Data::Embed/index/end\n";
   is $generated, $contents, 'generated file as expected';
   unlink $testfile;
}

# a previous input file, same as output file
{
   write_file($testfile, $prefix);
   my $size = -s $testfile;
   is $size, length($prefix), 'created starting input file';

   my $writer;
   lives_ok {
      $writer = writer(input => $testfile, output => $testfile);
   } 'constructor with same input and output lives';
   $size = -s $testfile;
   ok( ($size >= length($prefix)), 'output file did not clobber input');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 388, 'output file size';
   my $generated = read_file($testfile);
   is $generated, $contents, 'generated file as expected';
   unlink $testfile;
}

# a previous input file, different from output file
{
   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   # ensure that $testfile contains enough data
   write_file($testfile, $prefix x 3);

   my $writer;
   lives_ok {
      $writer = writer(input => $inputfile, output => $testfile);
   } 'constructor with input file different from output lives';
   $size = -s $testfile;
   ok( ($size <= length($prefix)), 'output file was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 388, 'output file size';
   my $generated = read_file($testfile);
   is $generated, $contents, 'generated file as expected';

   unlink $inputfile;
   unlink $testfile;
}

# previous input from a scalar reference
{
   my $inputscalar = $prefix;
   my $size;

   # ensure that $testfile contains enough data
   write_file($testfile, $prefix x 3);

   my $writer;
   lives_ok {
      $writer = writer(input => \$inputscalar, output => $testfile);
   } 'constructor with input scalar and output file lives';
   $size = -s $testfile;
   ok( ($size <= length($prefix)), 'output file was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 388, 'output file size';
   my $generated = read_file($testfile);
   is $generated, $contents, 'generated file as expected';
   unlink $testfile;
}

# previous input from a file handle, different from output file
{
   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   open my $ifh, '<', $inputfile;
   ok $ifh, "input file '$ifh' opened";

   # ensure that $testfile contains enough data
   write_file($testfile, $prefix x 3);

   my $writer;
   lives_ok {
      $writer = writer(input => $ifh, output => $testfile);
   } 'constructor with input filehandle and output file lives';
   $size = -s $testfile;
   ok( ($size <= length($prefix)), 'output file was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 388, 'output file size';
   my $generated = read_file($testfile);
   is $generated, $contents, 'generated file as expected';

   unlink $inputfile;
   unlink $testfile;
}

# previous input from a file handle, different from output file
{
   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   ok(open(local(*STDIN), '<', $inputfile), "opened '$inputfile' as STDIN");

   # ensure that $testfile contains enough data
   write_file($testfile, $prefix x 3);

   my $writer;
   lives_ok {
      $writer = writer(input => '-', output => $testfile);
   } 'constructor with "-" input (STDIN) and output file lives';
   $size = -s $testfile;
   ok( ($size <= length($prefix)), 'output file was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = -s $testfile;
   ok(($size < 310), "output file still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = -s $testfile;
   is $size, 388, 'output file size';
   my $generated = read_file($testfile);
   is $generated, $contents, 'generated file as expected';

   unlink $inputfile;
   unlink $testfile;
}

done_testing();
