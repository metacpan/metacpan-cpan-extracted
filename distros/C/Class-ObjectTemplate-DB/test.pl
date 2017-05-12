# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded;}
# use blib;
# use Class::ObjectTemplate::DB;
$loaded = 1;
$i=1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

BEGIN {
  unshift (@INC, '.');
  open(F,">Foo.pm") or die "Couldn't write Foo.pm";

  print F <<'EOF';
package Foo;
use Class::ObjectTemplate::DB;
@ISA = qw(Class::ObjectTemplate::DB);
attributes(one, two, three);

package FooFoo;
use Class::ObjectTemplate::DB;
@ISA = qw(Class::ObjectTemplate::DB);
attributes(no_lookup=>['one']);

sub undefined {return 23;}

1;
EOF
  close(F);
}
use lib '.';
require Foo;
my $f = new Foo(one=>23);

#
# test that a value defined at object creation is properly set
#
result($f->one() == 23);

#
# test that a value not defined at object creation is undefined
#
result(! defined $f->two());

#
# test that we can set and retrieve a value
#
$f->two(45);
result($f->two() == 45);

#
# We used the hash-style parameters to specify 'no_lookup' for the
# FooFoo class.
#
my $f = new FooFoo();
result(! defined $f->one());

#
# Check the we are handling free properly, by adding to the free list
#
$f = FooFoo->new();
$old_free = scalar @FooFoo::_free;
undef $f;
result(scalar  @FooFoo::_free > $old_free);

$f = FooFoo->new();
result((scalar @FooFoo::_free) == $old_free);

END { 1 while unlink 'Foo.pm'}

BEGIN {
  open(F,">Bar.pm") or die "Couldn't write Bar.pm";

  print F <<'EOF';
package Bar;
use Class::ObjectTemplate::DB;
@ISA = qw(Class::ObjectTemplate::DB);

attributes(lookup=>['one']);

sub undefined {return 27}
1;
EOF
  close(F);
}

require Bar;
$f = new Bar();

#
# test that Bar::undefined is being called
#
result($f->one() == 27);

#
# This test added to check bug fix. Once upon a time, setting an
# attribute to 'undef' had the side effect of calling the setter
# function. If lookup was turned on, this would trigger undefined()
# which was bad.
#
$f = new Bar();
result($f->one(undef) != 27);

END { 1 while unlink 'Bar.pm'}

BEGIN {
  open(F,">Baz.pm") or die "Couldn't write Baz.pm";

  print F <<'EOF';
package Baz;
# BEGIN {
#  $Class::ObjectTemplate::DEBUG=1;
#  $Class::ObjectTemplate::DB::DEBUG=1;
# }
use Class::ObjectTemplate::DB;
use subs qw(undefined);
@ISA = qw(Class::ObjectTemplate::DB);
attributes(no_lookup=>['one'],lookup=>['two']);

sub undefined {return 27}


package BazINC;
use Class::ObjectTemplate::DB;
@ISA = qw(Baz);
attributes();

package BazINC2;
use Class::ObjectTemplate::DB;
@ISA = qw(Baz);

attributes(no_lookup=>['three'],lookup=>['four']);

1;
EOF
  close(F);
}

require Baz;
$baz = new Baz();

#
# test that Baz::undefined is *not* being called.
#
result(!defined $baz->one());

#
# test that Baz::undefined *is* being called. We have called 
# attributes with the hash-style parameter and 'no_lookup' for two()
result($baz->two() == 27);

#
# test that the data for attributes is being stored in the 'Baz::' namespace
# this is to monitor a bug that was storing lookup data in the 'main::'
# namespace
result(scalar @Baz::_two);

# test that @Baz::_ATTRIBUTES_ and is being properly set. This is to
# check a bug that overwrote it on each call to attributes()
result(scalar @Baz::_ATTRIBUTES_ == 2);

#
# Test an inherited class that defines no new attributes
#
$baz_inc = new BazINC();

# test that @Baz::_ATTRIBUTES_ is not being set. This is to check a
# bug where inherited classes didn't get their attributes properly
# initialized
result(scalar @BazINC::_ATTRIBUTES_ == 2);

#
# test that Baz::undefined is *not* being called. 
#
result(! defined $baz_inc->one());

$baz_inc->one(34);
result($baz_inc->one() == 34);

#
# test that the data is being stored in the 'BazINC::' namespace
# this is to monitor a bug that was storing lookup data in the 'main::'
# namespace
result(scalar @BazINC::_one);

#
# test that Baz::undefined *is* being called.
#
result($baz_inc->two() == 27);

#
# test that Baz and BazINC not interfering with one another
# even though there attribute arrays are in Baz's namespace
$baz->one(45);
$baz_inc->one(56);
result($baz_inc->one() != $baz->one());

#
# test that $baz_inc->DESTROY properly modifies that @_free array in
# Baz and does not add one to BazINC
$old_free = scalar @BazINC::_free;
$baz_inc->DESTROY();
result(!scalar @Baz::_free);

result($old_free != scalar @BazINC::_free);

#
# Now test inheritance from a class that defines new attributes
#
$baz_inc2 = BazINC2->new();
$baz_inc2->one(34);
result($baz_inc2->one() == 34);

$baz_inc2->three(34);
result($baz_inc2->three() == 34);

$old_free = scalar @BazINC2::_free;
$baz_inc2->DESTROY();
result(! scalar @Baz::_free);

result($old_free != scalar @BazINC2::_free);

END { 1 while unlink 'Baz.pm'}

BEGIN {
  open(F,">FooBar.pm") or die "Couldn't write FooBar.pm";

  print F <<'EOF';
package FooBar;
use Class::ObjectTemplate;
use subs qw(undefined);
@ISA = qw(Class::ObjectTemplate);
attributes('one', 'two');
attributes('three');

1;
EOF
  close(F);
}

#
# Test that we get an error trying to call attributes() twice
#
eval "require FooBar;";
result($@);

END { 1 while unlink 'FooBar.pm'}

#
# test that attributes works properly when a subroutine
# of the same name already exists
#
BEGIN {
  open(F,">Foo2.pm") or die "Couldn't write Foo2.pm";
  print F <<'EOT';
package Foo2;
use Class::ObjectTemplate::DB;
@ISA = qw(Class::ObjectTemplate::DB);
attributes(lookup=>[qw(one two three)]);
sub one {return 1;}
sub undefined {return 27};

1;
EOT
  close(F);
}
require Foo2;

my $f = Foo2->new();

# the original subroutine gets called
result($f->one() == 1);

# but the attribute is undefined
result(!defined $f->get_attribute('one'));

# set the attribute and check its value
my $value = 5;
$f->set_attribute('one',$value);
result($f->get_attribute('one') == $value);

# check that the subroutine is still called
result($f->one() == 1);

# test get_attributes() doesn't call undefined
$f->two(24);
my @list2 = $f->get_attributes('two','three');
my @list = ($f->two,$f->three);
my $equal = 1;
for (my $i=0;$i<scalar @list;$i++) {
  if ($list[$i] != $list2[$i]) {
    $equal = 0;
    last;
  }
}
result(!$equal);

END { 1 while unlink 'Foo2.pm'}

sub result {
  my $cond = shift;
  print STDOUT "not " unless $cond;
  print STDOUT "ok ", $i++, "\n";
}
