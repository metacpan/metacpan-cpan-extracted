#!perl -T

use FindBin;
BEGIN { ( our $bindir ) = ( $FindBin::Bin =~ /^(.*)$/ ) } # Untaint
use lib $bindir."/lib";
use Test::More;
use strict;
use warnings;

BEGIN {
  use_ok ( "Catalyst::Test", "TestApp" );
}

sub filename_is {
  my $url = shift;
  my $filename = shift;

  my $res = request ( $url );
  is ( $res->filename, $filename );
}

{
  my $url = "/literal";
  action_ok ( $url );
  contenttype_is ( $url, "text/csv" );
  filename_is ( $url, "literal.csv" );
  my $content = get ( $url );
  is ( $content, <<"EOF" );
index,entry\r
1,"first entry"\r
2,second\r
3,third\r
4,fourth\r
5,fifth\r
EOF
}

{
  my $url = "/literal/";
  action_ok ( $url );
  contenttype_is ( $url, "text/csv" );
  filename_is ( $url, "literal.csv" );
  my $content = get ( $url );
  is ( $content, <<"EOF" );
index,entry\r
1,"first entry"\r
2,second\r
3,third\r
4,fourth\r
5,fifth\r
EOF
}

{
  my $url = "/db";
  action_ok ( $url );
  contenttype_is ( $url, "text/csv" );
  filename_is ( $url, "db.csv" );
  my $content = get ( $url );
  is ( $content, <<"EOF" );
Name,Age\r
Alan,42\r
Bob,27\r
Charlie,64\r
Dave,12\r
EOF
}

{
  my $url = "/noheader";
  action_ok ( $url );
  contenttype_is ( $url, "text/csv" );
  filename_is ( $url, "noheader.csv" );
  my $content = get ( $url );
  is ( $content, <<"EOF" );
Alan,42\r
Bob,27\r
Charlie,64\r
Dave,12\r
EOF
}

{
  my $url = "/tsv";
  action_ok ( $url );
  contenttype_is ( $url, "text/csv" );
  filename_is ( $url, "tsv.tsv" );
  my $content = get ( $url );
  is ( $content, <<"EOF" );
Name	Age\r
Dave	12\r
Bob	27\r
Alan	42\r
Charlie	64\r
EOF
}

{
  my $url = "/filename";
  action_ok ( $url );
  contenttype_is ( $url, "text/csv" );
  filename_is ( $url, "explicit.txt" );
  my $content = get ( $url );
  is ( $content, <<"EOF" );
Name,Age\r
Dave,12\r
Bob,27\r
Alan,42\r
Charlie,64\r
EOF
}

done_testing();
