# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..51\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Delegation;
$loaded = 1;
print "ok 1\n";

my $n = 2;
sub ok {
	print "not " if @_ && !$_[0];
	print  "ok $n\n";
	$n++
}

######################### End of black magic.


package Other;

sub new { 
	my ($class, $count) = @_;
	bless \$count, $class;
}

sub method1  { return "Other(${$_[0]})::method1" }
sub method2  { return "Other(${$_[0]})::method2" }
sub method3  { return "Other(${$_[0]})::method3" }
sub method4a { return "Other(${$_[0]})::method4a" }
sub method4b { return "Other(${$_[0]})::method4b" }
sub method5a { return "Other(${$_[0]})::method5a" }
sub method5b { return "Other(${$_[0]})::method5b" }

package Attr;

sub new { 
	my ($class, $count) = @_;
	bless \$count, $class;
}

sub method1 { return "Attr(${$_[0]})::method1" }
sub method2 { return "Attr(${$_[0]})::method2" }
sub method3 { return "Attr(${$_[0]})::method3" }

package Base;

sub basemethod { return "Base::basemethod" }

package Def;

sub new { bless {}, $_[0] }

sub AUTOLOAD { return $AUTOLOAD }

sub can { 1 }

package Derived;
@ISA = 'Base';

use Class::Delegation
	send => 'method1',
	  to => 'other1',

	send => 'method2',
	  to => 'attr2',

	send => 'method3',
	  to => ['other2', 'attr1'],

	send => 'method3a',
	  to => ['other2', 'attr1'],
	  as => 'method3',

	send => 'method3b',
	  to => 'other2',
	  as => ['method2','method1'],

	send => 'method3c',
	  to => ['other2', 'attr1'],
	  as => ['method2','method1'],

	send => ['method4a', 'method4b'],
	  to => other1,

	send => qr/method5([a-z])/,
	  to => other1,
	  as => sub { "method4$1" },

	send => sub { substr($_[1], 0, 6) eq 'strip_' },
	  to => other1,
	  as => sub { substr($_[1], 6) },

	send => 'method6',
	  to => qr/other\d/,
	  as => 'method3',

	send => ['METHOD1', qr/Method[23]/, sub{substr($_[1],0,6) eq 'MeTHoD'}],
	  to => ['attr2', qr/other\d/],
	  as => sub { lc $_[1] },

	send => 'virtual',
	  to => -SELF,
	  as => 'actual',

	send => 'virtual2',
	  to => -SELF,
	  as => ['actual','factual'],

	send => 'virtual3',
	  to => [-SELF, 'other1'],
	  as => ['actual','method3'],

	send => 'methodical',
	  to => '->otherwise',
	  as => 'method3',

	send => 'methodical2',
	  to => -SELF->otherwise,
	  as => 'method3',

	send => 'objective',
	  to => sub { $_[0]->otherwise },
	  as => 'method3',

	send => 'objective2',
	  to => sub { Other->new(9) },
	  as => 'method1',
;

sub new {
	my ($class) = @_;
	bless {
		other1  => Other->new(1),
		other2  => Other->new(2),
		attr1   => Attr->new(1),
		attr2   => Attr->new(2),
		default => Def->new(),
	      }, $class;
}

sub actual { return 'Derived::Actual' }
sub factual { return 'Derived::Factual' }
sub otherwise { return Attr->new(3) }

sub AUTOLOAD { return 'AUTOLOAD' }

sub DESTROY { main::ok }


package main;

my $obj = Derived->new() and ok;

# CO-EXISTENCE WITH AUTOLOADING AND BASE CLASSES...

ok($obj->non_existent_method eq 'AUTOLOAD');
ok($obj->method0 eq 'AUTOLOAD');
ok($obj->basemethod eq 'Base::basemethod');

# SIMPLE DELEGATION

ok($obj->method1 eq 'Other(1)::method1');
ok($obj->method2 eq 'Attr(2)::method2');
ok($obj->method4a eq 'Other(1)::method4a');
ok($obj->method4b eq 'Other(1)::method4b');
ok($obj->method5a eq 'Other(1)::method4a');
ok($obj->method5b eq 'Other(1)::method4b');
ok($obj->strip_method1 eq 'Other(1)::method1');

# MULTI-TARGET DELEGATION

$res = $obj->method3;
ok(@$res == 2);
ok($res->[0] eq 'Other(2)::method3');
ok($res->[1] eq 'Attr(1)::method3');

$res = $obj->method6;
ok(@$res == 2);
@$res = sort @$res;
ok($res->[0] eq 'Other(1)::method3');
ok($res->[1] eq 'Other(2)::method3');

# MULTI-TARGET DELEGATION WITH RENAMING

$res = $obj->method3a;
ok(@$res == 2);
@$res = sort @$res;
ok($res->[0] eq 'Attr(1)::method3');
ok($res->[1] eq 'Other(2)::method3');


# MULTI-TARGET DELEGATION WITH MULTI-RENAMING

$res = $obj->method3b;
ok(@$res == 2);
@$res = sort @$res;
ok($res->[0] eq 'Other(2)::method1');
ok($res->[1] eq 'Other(2)::method2');

$res = $obj->method3c;
ok(@$res == 2);
@$res = sort @$res;
ok($res->[0] eq 'Attr(1)::method1');
ok($res->[1] eq 'Other(2)::method2');


# MULTI-EVERYTHING

$res = $obj->METHOD1;
ok(@$res == 3);
@$res = sort @$res;
ok($res->[0] eq 'Attr(2)::method1');
ok($res->[1] eq 'Other(1)::method1');
ok($res->[2] eq 'Other(2)::method1');

$res = $obj->Method2;
@$res = sort @$res;
ok(@$res == 3);
ok($res->[0] eq 'Attr(2)::method2');
ok($res->[1] eq 'Other(1)::method2');
ok($res->[2] eq 'Other(2)::method2');

$res = $obj->MeTHoD3;
@$res = sort @$res;
ok(@$res == 3);
ok($res->[0] eq 'Attr(2)::method3');
ok($res->[1] eq 'Other(1)::method3');
ok($res->[2] eq 'Other(2)::method3');

# SELF-DELEGATION

$res = $obj->virtual;
ok($res eq 'Derived::Actual');

$res = $obj->virtual2;
ok(@$res == 2);
ok($res->[0] eq 'Derived::Actual');
ok($res->[1] eq 'Derived::Factual');

$res = $obj->virtual3;
ok(@$res == 2);
ok($res->[0] eq 'Derived::Actual');
ok($res->[1] eq 'Other(1)::method3');

$res = $obj->methodical;
ok($res eq 'Attr(3)::method3');

$res = $obj->methodical2;
ok($res eq 'Attr(3)::method3');

$res = $obj->objective;
ok($res eq 'Attr(3)::method3');

$res = $obj->objective2;
ok($res eq 'Other(9)::method1');
