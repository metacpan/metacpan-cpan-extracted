use Test::More # tests => 45
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

{
   my $generated = '';
   lives_ok {
      my $writer = writer(output => \$generated);
      $writer->add(name => 'some thing', data => $sample1);
      $writer->add_data('anoth%%er', $sample2);
   } 'operations on writer live, including destruction';
   is $generated, $contents, 'generated data as expected';
}

done_testing();
