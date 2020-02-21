#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Encode 'encode';
use Data::Dumper;
use Test::More;

use D;

# $ perl -Mblib test.t 
# run du() test
{
  my $ref_data1 = {
    hira=>"あいう",
    kana=>"アイウ"
  };

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  du($ref_data1); my $line = __LINE__;

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $em1 = encode("UTF-8",'あいう');
  my $em2 = encode("UTF-8",'アイウ');
  my $re1 = "  'hira' => '$em1',";
  my $re2 = "  'kana' => '$em2'";
  my $re3 = "} at t/test.t line $line";
  like( $output, qr/\Q$re1/);
  like( $output, qr/\Q$re2/);
  like( $output, qr/\Q$re3/);
}

# run dw() test
{
  my $ref_data2 = {
    hira=>"あいう",
    kana=>"アイウ"
  };

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  dw($ref_data2); my $line = __LINE__;

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $em1 = encode("cp932",'あいう');
  my $em2 = encode("cp932",'アイウ');
  my $re1 = "  'hira' => '$em1',";
  my $re2 = "  'kana' => '$em2'";
  my $re3 = "} at t/test.t line $line";
  like( $output, qr/\Q$re1/);
  like( $output, qr/\Q$re2/);
  like( $output, qr/\Q$re3/);
}

# run dn() test
{
  my $ref_data3 = {
    hira=>encode("UTF-8","あいう"),
    kana=>encode("UTF-8","アイウ"),
  };

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  dn($ref_data3); my $line = __LINE__;

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $em1 = encode("UTF-8",'あいう');
  my $em2 = encode("UTF-8",'アイウ');
  my $re1 = "  'hira' => '$em1',";
  my $re2 = "  'kana' => '$em2'";
  my $re3 = "} at t/test.t line $line";
  like( $output, qr/\Q$re1/);
  like( $output, qr/\Q$re2/);
  like( $output, qr/\Q$re3/);
}

# run du test (array reference)
{
  my $ref_data4 = ["あいう", "アイウ"];

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  du($ref_data4); my $line = __LINE__;

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $em1 = encode("UTF-8",'あいう');
  my $em2 = encode("UTF-8",'アイウ');
  my $re1 = "  '$em1',";
  my $re2 = "  '$em2'";
  my $re3 = "] at t/test.t line $line";
  like( $output, qr/\Q$re1/);
  like( $output, qr/\Q$re2/);
  like( $output, qr/\Q$re3/);
}

# run scalar reference test
{
  my $tdata1 = 'あいう';

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  du(\$tdata1); my $line = __LINE__;

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $em1 = encode("UTF-8",'あいう');
  my $re1 = "\\'$em1' at t/test.t line $line";
  like( $output, qr/\Q$re1/); # \'あいう' at t/test.t line 98
}

# run code reference test
{
  my $code_ref = sub {
    print "test function.\n";
  };

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  du($code_ref); my $line = __LINE__;

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $re1 = "sub { \"DUMMY\" } at t/test.t line $line";
  like( $output, qr/\Q$re1/);
}

{
  my $ref_data5 = { int => 1 };

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  dn($ref_data5);

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $re1 = "  'int' => 1";
  like( $output, qr/\Q$re1/);
}

{
  my $ref_data6 = { int => 1 };
  local $D::DO_NOT_PROCESS_NUMERIC_VALUE = 1;

  my $output;
  
  # Start capture STDERR
  open my $temp, '>&', STDERR;
  close STDERR;
  open STDERR, '>', \$output;

  dn($ref_data6);

  # End capture STDERR
  close STDERR;
  open STDERR, '>&', $temp;
  close $temp;

  my $re1 = "  'int' => 1";
  like( $output, qr/\Q$re1/);
}

done_testing;
