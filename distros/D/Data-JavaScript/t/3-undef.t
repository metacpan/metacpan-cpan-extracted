BEGIN { $| = 1; print "1..3\n"; }
use Data::JavaScript {UNDEF=>0};

#Test undef value overloading

$_ = join('', jsdump('foo', [1,undef,1]));
print 'not ' unless $_ eq
      'var foo = new Array;foo[0] = 1;foo[1] = undefined;foo[2] = 1;';
print "ok 1 #$_\n";

$_ = join('', jsdump('bar', [1,undef,1], 'null'));
print 'not ' unless $_ eq
      'var bar = new Array;bar[0] = 1;bar[1] = null;bar[2] = 1;';
print "ok 2 #$_\n";

#Test hashes
$_ = join('', jsdump('qux', {color=>'monkey', age=>2, eyes=>'blue'}));
print 'not ' unless $_ eq
      'var qux = new Object;qux["age"] = 2;qux["color"] = "monkey";qux["eyes"] = "blue";';
print "ok 3 #$_\n";
