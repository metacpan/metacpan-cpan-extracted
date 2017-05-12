BEGIN { 
  # Don't fail on P5.004
  eval "package XYZ; sub foo {}; package ZYX; use base ( 'XYZ' ); ";
  if ( $@ ) {
    print "Skipping test on this platform (no base pragma).\n";
    exit 0;
  }
}

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
use Class::MakeMethods::Emulator::AccessorFast;
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
BEGIN { $Total_tests = 20 }


# Set up a testing package.
package Foo;

@Foo::ISA = qw(Class::MakeMethods::Emulator::AccessorFast);
Foo->mk_accessors(qw( foo bar yar car mar ));
Foo->mk_ro_accessors(qw(static unchanged));
Foo->mk_wo_accessors(qw(sekret double_sekret));


sub car {
    shift->_car_accessor(@_);
}

sub mar {
    return "Overloaded";
}

package main;

my Foo $test = Foo->new({ static       => "variable",
                          unchanged    => "dynamic",
                        });

# Test accessors.
$test->foo(42);
$test->bar('Meep');
ok( $test->foo   == 42 and
    $test->{foo} == 42,                                 'accessor get/set'  );

ok( $test->static eq 'variable',                        'accessor read-only' );
eval {
    $test->static('foo');
};
ok( scalar $@ =~ /(read-only)/, 'accessor read-only:  write protection' );

$test->double_sekret(1001001);
ok( $test->{double_sekret} == 1001001,                  'accessor write-only');
eval {
    () = $test->double_sekret;
};
ok( scalar $@ =~ /(write-only)/, 'accessor write-only:  read protection' );


ok( $test->_foo_accessor == 42,                         'accessor alias'    );

$test->car("AMC Javalin");
ok( $test->car eq 'AMC Javalin' );

# Make sure we can "override" accessors.
ok( $test->mar eq 'Overloaded' );

# Make sure bogus accessors die.
eval { $test->gargle() };
ok( $@,                                                 'bad accessor()'    );



# Test that the accessor works properly in list context with a single arg.
my Foo $test2 = Foo->new;
my @args = ($test2->foo, $test2->bar);
ok( @args == 2,                         'accessor get in list context'      );



# Make sure a DESTROY field won't slip through.
package Arrgh;
@Arrgh::ISA = qw(Foo);

eval {
    local $SIG{__WARN__} = sub { die @_ };
    Arrgh->mk_accessor(qw(DESTROY));
};

::ok( $@ and $@ =~ /Having a data accessor named DESTROY in 'Arrgh'/i,
                                                        'No DESTROY field'  );

# Override &Arrgh::DESTROY to shut up the warning we intentionally created
#*Arrgh::DESTROY = sub {};
#() = *Arrgh::DESTROY;  # shut up typo warning.



package Altoids;

@Altoids::ISA = qw(Class::MakeMethods::Emulator::AccessorFast);
use fields qw(curiously strong mints);
Altoids->mk_accessors(keys %Altoids::FIELDS);

::ok(defined &Altoids::curiously);
::ok(defined &Altoids::strong);
::ok(defined &Altoids::mints);

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    return fields::new($class);
}

my Altoids $tin = Altoids->new;

$tin->curiously('Curiouser and curiouser');
::ok($tin->{curiously} eq 'Curiouser and curiouser');


# Subclassing works, too.
package Mint::Snuff;
use base qw(Altoids);

::ok(defined &Altoids::curiously);
::ok(defined &Altoids::strong);
::ok(defined &Altoids::mints);

my Mint::Snuff $pouch = Mint::Snuff->new;
$pouch->strong('Fuck you up strong!');
::ok($pouch->{strong} eq 'Fuck you up strong!');
