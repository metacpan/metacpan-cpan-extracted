# $Id: 03scalar.t,v 0.19 2006/10/08 03:37:29 ray Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use B q{svref_2object};
use B::COW;

my $has_data_dumper;

BEGIN {
  $| = 1;
  my $tests = 12;
  $tests += 2 if B::COW::can_cow();
  eval q[use Data::Dumper];
  if (!$@) {
    $has_data_dumper = 1;
    $tests++;
  }
  print "1..$tests\n";
}
END {print "not ok 1\n" unless $loaded;}
use Clone qw( clone );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package Test::Scalar;

use vars @ISA;

@ISA = qw(Clone);

sub new
  {
    my $class = shift;
    my $self = shift;
    bless \$self, $class;
  }

sub DESTROY 
  {
    my $self = shift;
    # warn "DESTROYING $self";
  }

package main;
                                                
sub ok     {
  my ( $check, $msg ) = @_;

  $msg = '' unless defined $msg;
  if ( $check ) {
    print "ok $test $msg\n";
  } else {
    print "not ok $test $msg\n";
  }

  $test++;

  return;
}

$^W = 0;
$test = 2;

my $a = Test::Scalar->new(1.0);
my $b = $a->clone(1);

ok( $$a == $$b, '$$a == $$b' );
ok( $a != $b, '$a != $b' );

{
  print "# using a reference on a string (CowREFCNT == 0).\n";

  my $c = \"something";
  my $d = Clone::clone($c, 2);

  ok( $$c == $$d, 'test 2 scalar content' );
  ok( $c != $d, 'SV are differents SVs' );
}

{
  print "# using a reference on one SvPV (CowREFCNT > 0).\n";

  my $str = "my string";
  my $c = \$str;

  my $d = Clone::clone($c, 2);

  ok( $$c == $$d, 'test 2 scalar content' );
  ok( $c != $d, 'SV are differents SVs' );


  if ( B::COW::can_cow() ) {
    my $sv_c = svref_2object( $c );
    my $sv_d = svref_2object( $d );

    ok( $sv_c->FLAGS & B::SVf_IsCOW, 'COW flag set on c' );
    ok( $sv_d->FLAGS & B::SVf_IsCOW, 'COW flag set on d' );
  }
}


$$d .= 'abcd';
ok( $$c ne $$d, 'only one scalar changed' );

my $circ = undef;
$circ = \$circ;
$aref = clone($circ);
if ($has_data_dumper) {
  ok( Dumper($circ) eq Dumper($aref), 'Dumper check' );
}

# the following used to produce a segfault, rt.cpan.org id=2264
undef $a;
$b = clone($a);
ok( $$a == $$b, 'int check' );

# used to get a segfault cloning a ref to a qr data type.
my $str = 'abcdefg';
my $qr = qr/$str/;
my $qc = clone( $qr );
ok( $qr eq $qc, 'string check' ) or warn "$qr vs $qc";
ok( $str =~ /$qc/, 'regexp check' );

# test for unicode support
{
  my $a = \( chr(256) );
  my $b = clone( $a );
  ok( ord($$a) == ord($$b) );
}
