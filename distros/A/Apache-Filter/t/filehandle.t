#!/usr/bin/perl -w

use Test;
BEGIN { plan tests => 8 }
use Apache::Filter;
ok(1);


ok tie(*FH, 'Apache::Filter');

print FH "line1\n";
ok <FH>, "line1\n";

print FH "line1", "\n", "line2";
ok <FH>, "line1\n";
ok <FH>, "line2";

print FH "line1\nline2\n";
ok join('', <FH>), "line1\nline2\n";


{
  # Test the read() function
  my $buf = '';
  print FH "123456789";
  read(FH, $buf, 2);
  ok $buf, '12';
  read(FH, $buf, 10, 2);
  ok $buf, '123456789';
}
