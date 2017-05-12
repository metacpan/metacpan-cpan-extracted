#!perl -T

use strict;
use warnings;
use Test::More tests => 13;

use App::CSV;
use IO::String;

my $input = <<'.';
"1","2","3"
11,22,33
111,222,333
.

sub setup {
  my $input = shift;
  local @ARGV = @_;
  my $output_fh = IO::String->new;
  my $ac = App::CSV->new_with_options(
    _input_fh  => IO::String->new($input),
    _output_fh => $output_fh);
  return($ac, $output_fh->string_ref);
}

{
  my($ac, $output) = setup($input, 2);  # "csv 2"
  $ac->init;
  is_deeply($ac->columns, [1], "column normalization");
  $ac->run;
  is($$output, "2\n22\n222\n", "1-based, single column");
}

{
  my($ac, $output) = setup($input, 1, -1);  # "csv 1 -1"
  $ac->init;
  is_deeply($ac->columns, [0, -1], "column normalization");
  $ac->run;
  is($$output, "1,3\n11,33\n111,333\n",
      "1-based, two columns, negative columns");
}

my $input_with_headers = qq["one","two","three"\n] . $input;

{
  no warnings 'qw';
  my ($ac, $output) = setup($input_with_headers, qw[-f three,1]);   # csv -f three,1
  $ac->init;
  is_deeply($ac->columns, [2, 0], "column normalization");
  $ac->run;
  is($$output, "three,one\n3,1\n33,11\n333,111\n",
      "1-based, two columns, named fields");
}

{
  my ($ac, $output) = setup($input_with_headers, qw[-f 2-3 -f 1]);   # csv -f 2-3 -f 1
  $ac->init;
  is_deeply($ac->columns, [1, 2, 0], "column normalization");
  $ac->run;
  is($$output, "two,three,one\n2,3,1\n22,33,11\n222,333,111\n",
      "1-based, three columns, field ranges");
}

my $input_with_tricky_headers = qq["Revenue","Q4 2012","Q1 2013"\n] . $input;

{
  my ($ac, $output) = setup($input_with_tricky_headers, qq[-f], qq[Q1 2013,1]);   # csv -f "Q1 2013",1
  $ac->init;
  is_deeply($ac->columns, [2, 0], "column normalization");
  $ac->run;
  is($$output, qq["Q1 2013",Revenue\n3,1\n33,11\n333,111\n],
      "1-based, two columns, named fields with spaces");
}

{
  no warnings 'qw';
  my ($ac, $output) = setup($input_with_headers, qw[-f three,four,1]);   # csv -f three,four,1
  eval { $ac->init };
  ok($@, "init failed");
  like($@, qr/^The following named fields aren't in the input header: four/,
      "error about bad field name");
  is($$output, "", "no output");
}
