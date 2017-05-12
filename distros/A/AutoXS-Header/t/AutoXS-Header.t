use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok('AutoXS::Header') };

SKIP: {
  skip "File exists won't overwrite. Most certainly harmless.", 1 if -e 'AutoXS.h';
  AutoXS::Header::WriteAutoXSHeader();
  ok(-f 'AutoXS.h', "Wrote header file");
  unlink("AutoXS.h");
}

my $file = "tmpfile.h";
my $i = 0;
$i++, $file .= '_' while -e $file and $i < 10;

SKIP: {
  skip "File exists won't overwrite. Most certainly harmless.", 1 if -e $file;
  AutoXS::Header::WriteAutoXSHeader($file);
  ok(-f $file, "Wrote header file to custom name");
  unlink($file);
}



