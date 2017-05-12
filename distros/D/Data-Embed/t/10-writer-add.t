use Test::More  tests => 46
;
use Test::Exception;

use strict;
use Data::Embed qw< writer >;
use File::Basename qw< dirname >;
use lib dirname(__FILE__);
use DataEmbedTestUtil qw< read_file write_file >;

my $sample1  = "This is some data\n";
my $sample2  = join '', "binary data:\n", map { chr($_) } 0 .. 255;
my $contents = join "\n", "$sample1\n", "$sample2\n",
  'Data::Embed/index/begin',
  '18 some%20thing',
  '269 anoth%25%25er',
  "Data::Embed/index/end\n";
my $testfile1 = __FILE__ . '.test-sample1';
my $testfile2 = __FILE__ . '.test-sample2';

{
   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', data => $sample1);
   } 'add() with data lives';
   lives_ok {
      $writer->add_data('anoth%%er', $sample2);
   } 'add_data() lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
}

{
   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', filename => \$sample1);
   } 'add() with file pointing to scalar ref lives';
   lives_ok {
      $writer->add_file('anoth%%er', \$sample2);
   } 'add_file() with scalar ref lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
}

{
   write_file($testfile1, $sample1);
   write_file($testfile2, $sample2);

   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', filename => $testfile1);
   } 'add() with filename lives';
   lives_ok {
      $writer->add_file('anoth%%er', $testfile2);
   } 'add_file() lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
   unlink for ($testfile1, $testfile2);
}

{
   write_file($testfile1, $sample1);
   ok(open(my $ifh1, '<', $testfile1), "open('$testfile1')");
   write_file($testfile2, $sample2);
   ok(open(my $ifh2, '<', $testfile2), "open('$testfile2')");

   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', fh => $ifh1);
   } 'add() with filehandle lives';
   lives_ok {
      $writer->add_fh('anoth%%er', $ifh2);
   } 'add_fh() lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
   unlink for ($testfile1, $testfile2);
}

{
   my $generated = '';
   ok(open(local(*STDIN), '<', \$sample1), 'localized open() for STDIN to scalar ref');
   ok(binmode(STDIN), 'binmode STDIN');

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', input => '-');
   } 'add() with input set to "-" lives';
   lives_ok {
      $writer->add_file('anoth%%er', \$sample2);
   } 'add_file() with scalar ref lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
}

{
   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', input => \$sample1);
   } 'add() with input pointing to scalar ref lives';
   lives_ok {
      $writer->add_file('anoth%%er', \$sample2);
   } 'add_file() with scalar ref lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
}

{
   write_file($testfile1, $sample1);
   write_file($testfile2, $sample2);

   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', input => $testfile1);
   } 'add() with input filename lives';
   lives_ok {
      $writer->add_file('anoth%%er', $testfile2);
   } 'add_file() lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
   unlink for ($testfile1, $testfile2);
}

{
   write_file($testfile1, $sample1);
   ok(open(my $ifh1, '<', $testfile1), "open('$testfile1')");
   write_file($testfile2, $sample2);
   ok(open(my $ifh2, '<', $testfile2), "open('$testfile2')");

   my $generated = '';

   my $writer;
   lives_ok {
      $writer = writer(output => \$generated);
   } 'constructor (no input, output to scalar ref)';
   lives_ok {
      $writer->add(name => 'some thing', input => $ifh1);
   } 'add() with input filehandle lives';
   lives_ok {
      $writer->add_fh('anoth%%er', $ifh2);
   } 'add_fh() lives';
   lives_ok {
      $writer->write_index();
   } 'write_index() lives';
   is $generated, $contents, 'generated data as expected';
   unlink for ($testfile1, $testfile2);
}

done_testing();
