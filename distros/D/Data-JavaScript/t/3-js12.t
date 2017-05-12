#Lame switch because old Test::Harness does not support trailing test count
BEGIN { $| = 1;  print "1..4\n" }
use Data::JavaScript {JS=>1.2}; #No Unicode, undef yields empty strings

#Test undef default

$_ = join('', jsdump('foo', [1,undef,1]));
print 'not ' unless $_ eq
      "var foo = new Array;foo[0] = 1;foo[1] = '';foo[2] = 1;";
print "ok 1 #$_\n";

#Test alphanumeric string output: quoting, ASCII/ANSI escaping, Unicode

$_ = join('', jsdump("ANSI", "M\xF6tley Cr\xFce"));
print 'not ' unless $_ eq 'var ANSI = "M\xF6tley Cr\xFCe";';
print "ok 2 #$_\n";

if( $] >= 5.006 ){
  $_ = join('', jsdump("unicode", "Euros (\x{20ac}) aren't Ecus (\x{20a0})"));
  print 'not ' unless $_ eq
    q(var unicode = "Euros (\xE2\x82\xAC) aren't Ecus (\xE2\x82\xA0)";);
  print "ok 3 #$_\n";
}
else{
  print "ok 3 # Skipped: No real Unicode\n";
}

$_ = join('', jsdump('thang', qq('	"\n\\\xa0) ));
print 'not ' unless $_ eq q(var thang = "'\t\"\n\\\\\xA0";);
print "ok 4 #$_\n";
