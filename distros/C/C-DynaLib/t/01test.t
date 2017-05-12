# -*- perl -*-
use Test::More tests => 11;
use C::DynaLib ();
# optional dependency
eval "use sigtrap;";
ok(1);

sub goof {
  require Carp;
  Carp::confess "Illegal memory operation";
}

eval {
  $SIG{SEGV} = \&goof;
  $SIG{ILL} = \&goof;
};
use vars qw ($tmp1 $tmp2);
use Config;
# Don't let old Exporters ruin our fun.
sub DeclareSub { &C::DynaLib::DeclareSub }
sub PTR_TYPE () { &C::DynaLib::PTR_TYPE }


my $libc = new C::DynaLib($Config{'libc'} || "-lc");
if (! $libc) {
  if ($^O =~ /linux/i) {
    # Some glibc versions install "libc.so" as a linker script,
    # unintelligible to dlopen().
    $libc = new C::DynaLib("libc.so.6");
  }
}
if (! $libc) {
  ok(0, "no libc"); #2
  die "Can't load -lc: ", DynaLoader::dl_error(), "\nGiving up.\n";
}

my $libm_arg = DynaLoader::dl_findfile("-lm");
my $libm;
if (! $libm_arg) {
  $libm = $libc;
} elsif ($^O eq 'cygwin') {
  $libm = $libc;
} else {
  $libm = new C::DynaLib("-lm");
}

$libm and $pow = $libm->DeclareSub ({ "name" => "pow",
				      "return" => "d",
				      "args" => ["d", "d"]});
SKIP: {
  skip "math lib tests. $pow $C::DynaLib::decl", 1
    if !$pow or $C::DynaLib::decl eq 'hack30';

  my $sqrt2 = 2**0.5;
  ok(&$pow(2, 0.5) == $sqrt2, "pow(2, 0.5) from -lm"); #2
}
my $strlen = $libc->DeclareSub ({ "name" => "strlen",
                                  "return" => "i",
                                  "args" => ["p"],
                                });

# Can't do this in perl <= 5.00401 because it results in a
# pack("p", constant):
#
# $len = &$strlen("oof rab zab");

my $len = &$strlen($tmp = "oof rab zab");
ok($len == 11, "len == 11, got: $len"); #3

sub my_sprintf {
  my ($fmt, @args) = @_;
  my (@arg_types) = ("P", "p");
  my ($width) = (length($fmt) + 1);

  # note this is a *simplified* (non-crash-proof) printf parser!
  while ($fmt =~ m/(?:%[-\#0 +\']*\d*(?:\.\d*)?h?(.).*?)[^%]*/g) {
    my $spec = $1;
    next if $spec eq "%";
    if (index("dic", $spec) > -1) {
      push @arg_types, "i";
      $width += 20;
    } elsif (index("ouxXp", $spec) > -1) {
      push @arg_types, "I";
      $width += 20;
    } elsif (index("eEfgG", $spec) > -1) {
      push @arg_types, "d";
      $width += 30;
    } elsif ("s" eq $spec) {
      push @arg_types, "p";
      $width += length($args[$#arg_types]);
    } else {
      die "Unknown printf specifier: $spec\n";
    }
  }
  my $buffer = "\0" x $width;
  &{$libc->DeclareSub("sprintf", "", @arg_types)}
  ($buffer, $fmt, @args);
  $buffer =~ s/\0.*//;
  return $buffer;
}

my $fmt = "%x %10sfoo %d %10.7g %f %d %d %d";
my @args = (253, "bar", -789, 2.32578, 3.14, 5, 6, 7);

my $expected = sprintf($fmt, @args);
my $got = my_sprintf($fmt, @args);

ok($got eq $expected, "expected: $expected"); #4

my $ptr_len = length(pack("p", $tmp = "foo"));

# Try passing a pointer to DeclareSub.
my $fopen_ptr = DynaLoader::dl_find_symbol($libc->LibRef(), "fopen")
  or die DynaLoader::dl_error();
my $fopen = DeclareSub ({ "ptr" => $fopen_ptr,
                          "return" => PTR_TYPE,
                          "args" => ["p", "p"] });

open TEST, ">tmp.tmp"
  or die "Can't write file tmp.tmp: $!\n";
print TEST "a string";
close TEST;

# Can't do &$fopen("tmp.tmp", "r") in perls before 5.00402.
my $fp = &$fopen($tmp1 = "tmp.tmp", $tmp2 = "r");
if (! $fp) {
  ok(0, q(Can't do &$fopen("tmp.tmp", "r") in perls before 5.00402.)); #5
} else {
  # Hope "I" will work for type size_t!
  my $fread = $libc->DeclareSub("fread", "i",
                                "P", "I", "I", PTR_TYPE);
  my $buffer = "\0" x 4;
  my $result = &$fread($buffer, 1, length($buffer), $fp);
  ok($result == 4); #5
  ok($buffer eq "a st"); #6
}
unlink "tmp.tmp";

if (@$C::DynaLib::Callback::Config) {
  sub compare_lengths {
    length(unpack("p", $_[0])) <=> length(unpack("p", $_[1]));
  }
  my @list = qw(A bunch of elements with unique lengths);
  my $array = pack("p*", @list);

  my $callback = new C::DynaLib::Callback("compare_lengths", "i",
                                          "P$ptr_len", "P$ptr_len");

  my $qsort = $libc->DeclareSub("qsort", "",
			     "P", "I", "I", PTR_TYPE);
  &$qsort($array, scalar(@list), length($array) / @list, $callback->Ptr());

  my @expected = sort { length($a) <=> length($b) } @list;
  my @got = unpack("p*", $array);
  ok("[@got]" eq "[@expected]"); #7

  # Hey!  We've got callbacks.  We've got a way to call them.
  # Who needs libraries?
  undef $callback;
  $callback = new C::DynaLib::Callback
    (sub {
       $_[0] + 10*$_[1] + 100*$_[2];
     }, "i", "i", "p", "i");
  my $sub = DeclareSub($callback->Ptr(), "i", "i", "p", "i");

  my $got = &$sub(1, $tmp = 7, 3.14);
  my $expected = 371;
  ok($got == $expected); #8

  undef $callback;
  $callback = new C::DynaLib::Callback(sub { shift }, "I", "i");
  $sub = DeclareSub($callback->Ptr(), "I", "i");
  $got = &$sub(-1);

  # Can't do this generally because it's broken in too many Perl versions:
  if (0) { # TODO: needed for an earlier version
    $expected = unpack("I", pack("i", -1));
  } else {
    $expected = 0;
    for ($i = 1; $i > 0; $i <<= 1) {
      $expected += $i;
    }
    $expected -= $i;
  }
  ok($got == $expected, "Callback Ii $got == $expected"); #9

  my $int_size = length(pack("i",0));
  undef $callback;
  $callback = new C::DynaLib::Callback
    (sub {
       $global = shift;
       $global .= pack("i", shift);
       return unpack(PTR_TYPE, pack("P", $global));
     }, PTR_TYPE, "P".(2 * $int_size), "i");

  $sub = DeclareSub($callback->Ptr(), "P".(3 * $int_size), PTR_TYPE, "i");
  $array = pack("ii", 1729, 31415);
  $pointer = unpack(PTR_TYPE, pack("P", $array));
  $struct = &$sub($pointer, 253);
  @got = unpack("iii", $struct);
  ok("[@got]" eq "[1729 31415 253]"); #10

} else {
  print ("# Skipping callback tests on this platform\n");
}

my $buf = "willo";
C::DynaLib::Poke(unpack(PTR_TYPE, pack("p", $buf)), "he");
ok($buf eq "hello"); #11
