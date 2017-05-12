use Test::More tests => 53
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

# no input
{
   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor without input lives';
   my $size = length $generated;
   is $size, 0, 'output scalar has empty contents';
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 371, 'output scalar size';
   my $contents = join "\n", "$sample1\n", "$sample2\n",
      'Data::Embed/index/begin',
      '18 some%20thing',
      '269 anoth%25%25er',
      "Data::Embed/index/end\n";
   is $generated, $contents, 'generated data as expected';
}

# undefined input
{
   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(input => undef, output => \$generated);
   } 'constructor with undefined input lives';
   my $size = length $generated;
   is $size, 0, 'output scalar has empty contents';
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 371, 'output scalar size';
   my $contents = join "\n", "$sample1\n", "$sample2\n",
      'Data::Embed/index/begin',
      '18 some%20thing',
      '269 anoth%25%25er',
      "Data::Embed/index/end\n";
   is $generated, $contents, 'generated data as expected';
}

# a previous input scalar, same as output file
{
   my $generated = $prefix;

   my $writer;
   lives_ok {
      $writer = writer(input => \$generated, output => \$generated);
   } 'constructor with same input and output lives';
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   my $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 388, 'output scalar size';
   is $generated, $contents, 'generated data as expected';
}

# a previous input file, different from output file
{
   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   # ensure that $generated contains enough data
   my $generated = $prefix x 3;

   my $writer;
   lives_ok {
      $writer = writer(input => $inputfile, output => \$generated);
   } 'constructor with input file lives';
   $size = length $generated;
   ok( ($size <= length($prefix)), 'output scalar was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 388, 'output scalar size';
   is $generated, $contents, 'generated data as expected';

   unlink $inputfile;
}

# previous input from a scalar reference
{
   my $inputscalar = $prefix;
   my $size;

   # ensure that $generated contains enough data
   my $generated = $prefix x 3;

   my $writer;
   lives_ok {
      $writer = writer(input => \$inputscalar, output => \$generated);
   } 'constructor with input scalar different from output lives';
   $size = length $generated;
   ok( ($size <= length($prefix)), 'output scalar was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 388, 'output scalar size';
   is $generated, $contents, 'generated data as expected';
}

# previous input from a file handle, different from output file
{
   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   open my $ifh, '<', $inputfile;
   ok $ifh, "input file '$ifh' opened";

   # ensure that $generated contains enough data
   my $generated = $prefix x 3;

   my $writer;
   lives_ok {
      $writer = writer(input => $ifh, output => \$generated);
   } 'constructor with input filehande lives';
   $size = length $generated;
   ok( ($size <= length($prefix)), 'output scalar was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 388, 'output scalar size';
   is $generated, $contents, 'generated data as expected';
   unlink $inputfile;
}

# previous input from a file handle, different from output file
{
   my $inputfile = $testfile . '.input';
   write_file($inputfile, $prefix);
   my $size = -s $inputfile;
   is $size, length($prefix), 'created starting input file';

   ok(open(local(*STDIN), '<', $inputfile), "opened '$inputfile' as STDIN");

   # ensure that $generated contains enough data
   my $generated = $prefix x 3;

   my $writer;
   lives_ok {
      $writer = writer(input => '-', output => \$generated);
   } 'constructor with "-" input (STDIN) lives';
   $size = length $generated;
   ok( ($size <= length($prefix)), 'output scalar was reset');
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add(name => 'anoth%%er',  data => $sample2);
   } 'two consecutive calls to add() live';
   $size = length $generated;
   ok(($size < 310), "output scalar still without index (size: $size)");
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   $size = length $generated;
   is $size, 388, 'output scalar size';
   is $generated, $contents, 'generated data as expected';
   unlink $inputfile;
}

done_testing();
