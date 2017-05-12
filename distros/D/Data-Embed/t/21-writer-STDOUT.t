use Test::More  tests => 192
;
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

for my $output ('missing', '', undef, '-') {
   my %output = (defined($output) && ($output eq 'missing')) ? () : (output => $output);

# no input
{
   ok(open(local(*STDOUT), '>:raw', $testfile), "opening STDOUT to '$testfile'");

   my $writer;
   lives_ok {
      $writer = writer(%output);
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
   ok(open(local(*STDOUT), '>:raw', $testfile), "opening STDOUT to '$testfile'");
   my $size;

   my $writer;
   lives_ok {
      $writer = writer(input => undef, %output);
   } 'constructor with undefined input lives';
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

# a previous input file, different from output file
{
   ok(open(local(*STDOUT), '>:raw', $testfile), "opening STDOUT to '$testfile'");

   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   my $writer;
   lives_ok {
      $writer = writer(input => $inputfile, %output);
   } 'constructor with input file different from output lives';
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
   ok(open(local(*STDOUT), '>:raw', $testfile), "opening STDOUT to '$testfile'");

   my $inputscalar = $prefix;
   my $size;

   my $writer;
   lives_ok {
      $writer = writer(input => \$inputscalar, %output);
   } 'constructor with input scalar and output file lives';
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
   ok(open(local(*STDOUT), '>:raw', $testfile), "opening STDOUT to '$testfile'");
   my $size;

   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   open my $ifh, '<', $inputfile;
   ok $ifh, "input file '$ifh' opened";

   my $writer;
   lives_ok {
      $writer = writer(input => $ifh, %output);
   } 'constructor with input filehandle and output file lives';
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
   ok(open(local(*STDOUT), '>:raw', $testfile), "opening STDOUT to '$testfile'");

   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   ok(open(local(*STDIN), '<', $inputfile), "opened '$inputfile' as STDIN");

   my $writer;
   lives_ok {
      $writer = writer(input => '-', %output);
   } 'constructor with "-" input (STDIN) and output file lives';
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

}

done_testing();
