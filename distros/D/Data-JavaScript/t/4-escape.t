BEGIN { $| = 1; print "1..6\n"; }

use Data::JavaScript;

#Test numbers: negative, real, engineering, octal/zipcode

$_ = join('', jsdump('ixi', -1));
print 'not ' unless $_ eq 'var ixi = -1;';
print "ok 1 #$_\n";

$_ = join('', jsdump('pi', 3.14159));
print 'not ' unless $_ eq 'var pi = 3.14159;';
print "ok 2 #$_\n";

$_ = join('', jsdump('c', '3E8'));
print 'not ' unless $_ eq 'var c = "3E8";';
print "ok 3 #$_\n";

$_ = join('', jsdump('zipcode', '02139'));
print 'not ' unless $_ eq 'var zipcode = "02139";';
print "ok 4 #$_\n";

$_ = join('', jsdump('hex', '0xdeadbeef'));
print 'not ' unless $_ eq 'var hex = "0xdeadbeef";';
print "ok 5 #$_\n";

$_ = join('', jsdump("IEsux", "</script>DoS!"));
print 'not ' unless $_ eq 'var IEsux = "\x3C\x2Fscript\x3EDoS!";';
print "ok 6 #$_\n";
