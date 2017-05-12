BEGIN { $| = 1; $] < 5.007 ?
      do{ print "1..0 # Skipped: No real Unicode\n"; exit} : print "1..4\n"; }
use Data::JavaScript;

#Test undef default

$_ = join('', jsdump('foo', [1,undef,1]));
print 'not ' unless $_ eq
      'var foo = new Array;foo[0] = 1;foo[1] = undefined;foo[2] = 1;';
print "ok 1 #$_\n";

#Test alphanumeric string output: quoting, ASCII/ANSI escaping, Unicode

$_ = join('', jsdump("ANSI", "M\xF6tley Cr\xFce"));
print 'not ' unless $_ eq 'var ANSI = "M\xF6tley Cr\xFCe";';
print "ok 2 #$_\n";

$_ = join('', jsdump("unicode", "Euros (\x{20ac}) aren't Ecus (\x{20a0})"));
print 'not ' unless $_ eq
	q(var unicode = "Euros (\u20AC) aren't Ecus (\u20A0)";);
print "ok 3 #$_\n";

$_ = join('', jsdump("Cherokee", "\x{13E3}\x{13E3}\x{13E3}"));
print 'not ' unless $_ eq q(var Cherokee = "\u13E3\u13E3\u13E3";);
print "ok 4 #$_\n";
