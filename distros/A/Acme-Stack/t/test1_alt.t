# Based on a demo script provided provided by Trizen.
# See https://github.com/sisyphus/math-gmpz/issues/5

# This file is identical to test1.t, accept that it uses 
# a different "Class" syntax that is also supported by
# versions of perl that precede perl-5.14.0.

# use 5.014;

use Acme::Stack;

print "1..7\n";

package Number; #{

    sub new {
        my ($class, $n) = @_;
        bless \$n, $class;
    }

    sub add {
        my ($self, $n) = @_;
        Number->new($$self + $$n);
    }

    sub _routine_abc {  # calls Acme::Stack::abc with 4 args
        my ($self) = @_;
        my $in = $$self;
        Acme::Stack::abc(11, 12, 13, 14);
        return Number->new($in);
    }

    sub _routine_def {  # calls Acme::Stack::def with 4 args
        my ($self) = @_;
        my $in = $$self;
        Acme::Stack::def(11, 12, 13, 14);
        return Number->new($in);
    }

    sub _routine_ghi {  # calls Acme::Stack::ghi with 4 args
        my ($self) = @_;
        my $in = $$self;
        Acme::Stack::ghi(11, 12, 13, 14);
        return Number->new($in);
    }
package main; #}

# The first 4 tests in this script are identical to the first
# 4 tests t/test2.t. These pass in both scripts.

if($Acme::Stack::VERSION == 0.02) { print "ok 1\n" }
else { print "not ok 1\n" }

my $x = Number->new(420);

my $x_abc = ${$x->_routine_abc};
 if($x_abc == 420) { print "ok 2\n" }
else { print "not ok 2\n" };

my $x_def = ${$x->_routine_def};
if($x_def == 420) { print "ok 3\n" }
else { print "not ok 3\n" };

my $x_ghi = ${$x->_routine_ghi};
if($x_ghi == 420) { print "ok 4\n" }
else { print "not ok 4\n" };

# In the next 3 tests, the value returned by $x->_routine_abc
# is passed on directly to $x->add().
# In t/test2.t, the value returned by $x->_routine_abc is
# saved as a perl scalar, which is then passed on to
# $x->add().
# Test 5 passes both here and in test2.t, but tests 6 & 7
# pass only in test2.t.

$x_abc = ${$x->add($x->_routine_abc)};
if($x_abc == 840) { print "ok 5\n" }
else { print "not ok 5 \n" };

eval {$x_def = ${$x->add($x->_routine_def)};};
if($@) {
  warn "\$\@: $@";
  print "not ok 6\n";
}
elsif($x_def == 840) { print "ok 6\n" }
else {
  warn "Test 6: Got $x_def Expected 840\n";
  print "not ok 6 \n";
}

eval {$x_ghi = ${$x->add($x->_routine_ghi)};};
if($@) {
  warn "\$\@: $@";
  print "not ok 7\n";
}
elsif($x_ghi == 840) { print "ok 7\n" }
else {
  warn "Test 7: Got $x_ghi Expected 840\n";
  print "not ok 7 \n";
}

__END__

