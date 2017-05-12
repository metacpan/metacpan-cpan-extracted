use Test::More    # tests => 46
  ;
use Test::Exception;

use strict;
use Data::Embed qw< reassemble reader >;
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

   lives_ok {
      reassemble(
         target   => \$generated,
         sequence => [
            {name => 'some thing', data => $sample1},
            {name => 'anoth%%er',  data => $sample2},
         ]
      );
   } ## end lives_ok
   'reassemble() lives, plain "creation" with two elements';
   is $generated, $contents, 'generated data as expected';
}

{
   my $prefix    = 'Something to begin with';
   my $generated = $prefix;

   lives_ok {
      reassemble(
         target   => \$generated,
         sequence => [
            {name => 'some thing', data => $sample1},
            {name => 'anoth%%er',  data => $sample2},
         ]
      );
   } ## end lives_ok
   'reassemble() lives, container with previous "raw" data';
   is $generated, "$prefix$contents", 'generated data as expected';
}

{
   my $prefix    = 'Something to begin with';
   my $generated = $prefix . join "\n",
     'you', '',
     'Data::Embed/index/begin',
     '3 ciao',
     'Data::Embed/index/end',
     '';

   lives_ok {
      reassemble(
         target   => \$generated,
         sequence => [
            {name => 'some thing', data => $sample1},
            {name => 'anoth%%er',  data => $sample2},
         ]
      );
   } ## end lives_ok
   'reassemble() lives, container with previous incompatible stuff';
   is $generated, "$prefix$contents", 'generated data as expected';
}

{
   my $prefix    = 'Something to begin with';
   my $generated = "$prefix$contents";

   my $previous = reader(\$generated);

   lives_ok {
      reassemble(
         target   => \$generated,
         sequence => [$previous->files()],
      );
   } ## end lives_ok
   'reassemble() lives, nop';
   is $generated, "$prefix$contents", 'generated data as expected';
}

{
   my $prefix = 'Something to begin with';
   my $reduced_contents = join "\n", "$sample1\n",
     'Data::Embed/index/begin',
     '18 some%20thing',
     "Data::Embed/index/end\n";
   my $generated = "$prefix$contents";
   my $expected  = "$prefix$reduced_contents";

   my $previous = reader(\$generated);

   lives_ok {
      reassemble(
         target   => \$generated,
         sequence => [($previous->files())[0]],
      );
   } ## end lives_ok
   'reassemble() lives, truncation';
   is $generated, $expected, 'generated data as expected';
}

{
   my $prefix = 'Something to begin with';
   my $reversed_contents = join "\n", "$sample2\n", "$sample1\n",
   'Data::Embed/index/begin',
   '269 anoth%25%25er',
   '18 some%20thing',
   "Data::Embed/index/end\n";
   my $generated = "$prefix$contents";
   my $expected  = "$prefix$reversed_contents";

   my $previous = reader(\$generated);

   lives_ok {
      reassemble(
         target   => \$generated,
         sequence => [ reverse $previous->files() ],
      );
   } ## end lives_ok
   'reassemble() lives, reversing';
   is $generated, $expected, 'generated data as expected';
}

{
   my $prefix    = 'Something to begin with';
   my $generated = '';
   open my $fh, '>', \$generated or BAIL_OUT "open(): $!";
   print {$fh} $prefix;

   lives_ok {
      reassemble(
         target   => $fh,
         sequence => [
            {name => 'some thing', data => $sample1},
            {name => 'anoth%%er',  data => $sample2},
         ]
      );
   } ## end lives_ok
   'reassemble() lives, using a filehandle';
   close $fh;
   is $generated, "$prefix$contents", 'generated data as expected';
}

done_testing();
