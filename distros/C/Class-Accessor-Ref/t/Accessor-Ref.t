# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num;
BEGIN { $| = 1; $^W = 1; $test_num=1}
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Class::Accessor::Ref;
$loaded = 1;
ok(1,                                                           'compile()' );
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) { 
        unless($a1->[$_] eq $a2->[$_]) {
        $ok = 0;
        last;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 5 }


# Set up a testing package.
package Foo;

@Foo::ISA = qw(Class::Accessor::Ref);
Foo->mk_accessors(qw( foo bar baz ));
Foo->mk_refaccessors(qw(foo baz));

package main;

my Foo $test = Foo->new({ foo => 'cat', bar => 'dog', });

sub beautify {
	my $thing = shift; # assumes a reference.
	$$thing = "pretty $$thing";
};

# Test accessors.
beautify($test->_ref_foo);
ok( $test->foo eq 'pretty cat',                           'refaccessor generation' );
ok( $test->_ref_foo eq $test->get_ref('foo'),             'get_ref access (scalar context)' );
ok( $test->_ref_baz eq ($test->get_ref(qw/foo baz/))[1],  'get_ref access (list context))' );

eval {
    beautify($test->_ref_bar);
};
ok( scalar $@ =~ /^Can't locate object method "_ref_bar" via package "Foo"/, 'refaccessor generation leak check' );
