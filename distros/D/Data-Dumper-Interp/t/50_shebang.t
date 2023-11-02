#!/usr/bin/env perl

# Compile this before anything is modified by t_Setup
our ($test_sub, $test_sub_withproto);
BEGIN {
  # WHY???  It must be something in Perl which otherwise
  # is not suppressed, triggering our __WARNING__ trap error.
  local ${^WARNING_BITS} = 0; # undo -w flag
  $test_sub = sub{ my $x = 42; };
  $test_sub_withproto = sub(@){ my $x = 42; };
}

use FindBin qw($Bin);
use lib $Bin;
use t_Common ; # strict, warnings, Carp
use t_TestCommon ##':silent', # Test2::V0 etc.
                 qw/bug displaystr fmt_codestring timed_run
                    rawstr showstr showcontrols
                    mycheckeq_literal mycheck @quotes/;

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; } # trying to find mysterious failure on one CPAN windows smoker

sub oops(@) {
  @_ = ("TestOOPS:", @_);
  goto &confess;
}

$SIG{__WARN__} = sub { confess("warning trapped: @_") };

use Data::Compare qw(Compare);

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }

# This test mysteriously dies (exit 5) with no visible message
# on certain Windows machines.  Try to explicitly 'fail' instead of
# actually dieing.
$SIG{__DIE__} = sub {
  if ($^S or !defined($^S)) {
    die(@_); # in eval or at compile time
  } else {
    warn "!! die trapped : @_";
    my $via_carp;
    for (my $i=0; ;$i++) {
      my $pkg = caller($i) || last;
      if ($pkg eq "Carp") {
        $via_carp=1;
        last;
      }
    }
    if ($via_carp) {
      fail("croak/confess caught", @_);
    } else {
      my ($fn, $lno) = (caller(0))[1,2];
      fail("die caught at ${fn}:$lno", Carp::longmess(@_));
    }
    bail_out("__DIE__ trap");
  }
};

confess("Non-zero CHILD_ERROR ($?)") if $? != 0;

# This script was written before the author knew anything about standard
# Perl test-harness tools.  So it is a big monolithic thing.

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
use Data::Dumper::Interp qw/:all/;

sub visFoldwidth() {
  "Data::Dumper::Interp::Foldwidth=".u($Data::Dumper::Interp::Foldwidth)
 ." Foldwidth1=".u($Data::Dumper::Interp::Foldwidth1)
 .($Data::Dumper::Interp::Foldwidth ? ("\n".("." x $Data::Dumper::Interp::Foldwidth)) : "")
}

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
diag "##DEBUG at line ",__LINE__;

confess("Non-zero initial CHILD_ERROR ($?)") if $? != 0;


# Run a variety of tests on an item which is a string or strigified object
# which is not presented as a bare number (i.e. it is shown in quotes).
# The caller provides a sub which does the eval in the desired context,
# for example with "use bignum".
# The expected_re matches the item without surrounding quotes.
# **CURRENTLY NO LONGER USED** (3/12/2022)
#sub checkstringy(&$$) {
#  my ($doeval, $item, $expected_re) = @_;
#  my $expqq_re = "\"${expected_re}\"";
#  my $expq_re  = "'${expected_re}'";
#  foreach (
#    [ 'Data::Dumper::Interp->new()->vis($_[1])',  '_Q_' ],
#    [ 'vis($_[1])',              '_Q_' ],
#    [ 'visq($_[1])',             '_q_' ],
#    [ 'avis($_[1])',             '(_Q_)' ],
#    [ 'avisq($_[1])',            '(_q_)' ],
#    #currently broken due to $VAR problem: [ 'avisq($_[1], $_[1])',     '(_q_, _q_)' ],
#    [ 'avisl($_[1])',             '_Q_' ],
#    [ 'avislq($_[1])',            '_q_' ],
#    [ 'ivis(\'$_[1]\')',         '_Q_' ],
#    [ 'ivis(\'foo$_[1]\')',      'foo_Q_' ],
#    [ 'ivis(\'foo$\'."_[1]")',   'foo_Q_' ],
#    [ 'dvis(\'$_[1]\')',         '$_[1]=_Q_' ],
#    [ 'dvis(\'foo$_[1]bar\')',   'foo$_[1]=_Q_bar' ],
#    [ 'dvisq(\'foo$_[1]\')',     'foo$_[1]=_q_' ],
#    [ 'dvisq(\'foo$_[1]bar\')',  'foo$_[1]=_q_bar' ],
#    [ 'vis({ aaa => $_[1], bbb => "abc" })', '{aaa => _Q_,bbb => "abc"}' ],
#  ) {
#    my ($code, $exp) = @$_;
#    $exp = quotemeta $exp;
#    $exp =~ s/_Q_/$expqq_re/g;
#    $exp =~ s/_q_/$expq_re/g;
#    my $code_display = $code . " with \$_[1]=«$item»";
#    local $Data::Dumper::Interp::Foldwidth = 0;  # disable wrapping
#    mycheck $code_display, qr/$exp/, $doeval->($code, $item) ;
#  }
#}#checkstringy()

# Run a variety of tests on non-string item, i.e. something which is a
# number or structured object (which might contain strings within, e.g.
# values or quoted keys in a hash).
#
# The given regexp specifies the expected result with Useqq(1), i.e.
# double-quoted; a single-quoted version is derived internally.
sub mychecklit(&$$) {
  my ($doeval, $item, $dq_expected_re) = @_;
  (my $sq_expected_re = $dq_expected_re)
    =~ s{ ( [^\\"]++|(\\.) )*+ \K " }{'}xsg
       or do{ confess "bug" if $dq_expected_re =~ /(?<![^\\])'/; }; #probably
  foreach (
    [ "Data::Dumper::Interp->new()->vis(\$_[1])",  '_Q_' ],
    [ 'vis($_[1])',              '_Q_' ],
    [ 'visq($_[1])',             '_q_' ],
    [ 'avis($_[1])',             '(_Q_)' ],
    [ 'avisq($_[1])',            '(_q_)' ],
    #currently broken due to $VAR problem: [ 'avisq($_[1], $_[1])',     '(_q_, _q_)' ],
    [ 'avisl($_[1])',             '_Q_' ],
    [ 'avislq($_[1])',            '_q_' ],
    [ 'ivis(\'$_[1]\')',         '_Q_' ],
    [ 'ivis(\'foo$_[1]\')',      'foo_Q_' ],
    [ 'ivis(\'foo$\'."_[1]")',   'foo_Q_' ],
    [ 'dvis(\'$_[1]\')',         '$_[1]=_Q_' ],
    [ 'dvis(\'foo$_[1]bar\')',   'foo$_[1]=_Q_bar' ],
    [ 'dvisq(\'foo$_[1]\')',     'foo$_[1]=_q_' ],
    [ 'dvisq(\'foo$_[1]bar\')',  'foo$_[1]=_q_bar' ],
    [ 'vis({ aaa => $_[1], bbb => "abc" })', '{aaa => _Q_,bbb => "abc"}' ],
  ) {
    my ($code, $exp_template) = @$_;
    my $exp = quotemeta $exp_template;
    $exp =~ s/_Q_/$dq_expected_re/g;
    $exp =~ s/_q_/$sq_expected_re/g;
    my $code_display = $code . "(OS=$^O) with \$_[1]=$quotes[0].$item.$quotes[1]";
    local $Data::Dumper::Interp::Foldwidth = 0;  # disable wrapping
    mycheck $code_display, qr/$exp/, $doeval->($code, $item) ;
  }
}#checklit()

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
diag "##DEBUG at line ",__LINE__;

# Basic test of OO interfaces
{ my $code="Data::Dumper::Interp->new->vis('foo')  ;"; mycheck $code, '"foo"',     eval $code }
diag "##DEBUG at line ",__LINE__;
{ my $code="Data::Dumper::Interp->new->avis('foo') ;"; mycheck $code, '("foo")',   eval $code }
diag "##DEBUG at line ",__LINE__;
{ my $code="Data::Dumper::Interp->new->hvis(k=>'v');"; mycheck $code, '(k => "v")',eval $code }
diag "##DEBUG at line ",__LINE__;
{ my $code="Data::Dumper::Interp->new->dvis('foo') ;"; mycheck $code, 'foo',       eval $code }
diag "##DEBUG at line ",__LINE__;
{ my $code="Data::Dumper::Interp->new->ivis('foo') ;"; mycheck $code, 'foo',       eval $code }
diag "##DEBUG at line ",__LINE__;

foreach (
          ['Foldwidth',0,1,80,9999],
          ['MaxStringwidth',undef,0,1,80,9999],
          ['Truncsuffix',"","...","(trunc)"],
          ## FIXME: This will spew debug messages.  Trap them somehow??
          #['Debug',undef,0,1],
          # Now the 'q' interfaces force Useqq(0) internally
          # ['Useqq',0,1,'utf8'],
          ['Quotekeys',0,1],
          ['Sortkeys',0,1,sub{ [ sort keys %{shift @_} ] } ],
        )
{
  my ($confname, @values) = @$_;
  foreach my $value (@values) {
    foreach my $base (qw(vis avis hvis avisl hvisl dvis ivis)) {
      foreach my $q ("", "q") {
        my $codestr = $base . $q . "(42";
         $codestr .= ", 43" if $base =~ /^[ahl]/;
         $codestr .= ")";
        {
          my $v = eval "{ local \$Data::Dumper::Interp::$confname = \$value;
                          my \$obj = Data::Dumper::Interp->new();
                          () = \$obj->$codestr ;   # discard dump result
                          \$obj->$confname()  # fetch effective setting
                        }";
        confess("bug:$@ ") if $@;
        confess("\$Data::Dumper::Interp::$confname value is not preserved by $codestr\n",
            "(Set \$Data::Dumper::Interp::$confname=",u($value)," but new()...->$confname() returned ",u($v),")\n")
          unless (! defined($v) and ! defined($value))
                 || (defined($v) and defined($value) and $v eq $value);
        }
      }
    }
  }
}

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
diag "##DEBUG at line ",__LINE__;

# Changing these are not allowed:
foreach my $confname (qw/Indent Terse Sparseseen/) {
  no strict 'refs';
  my $val = ${"Data::Dumper::Interp::$confname"};
  confess "\${Data::Dumper::Interp::$confname} = ",vis($val)," SHOULD NOT EXIST"
    if defined($val);
  eval {newvis->$confname(42)};
  like($@,qr/locate.*method.*$confname/, "$confname method does not exist");
}

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
diag "##DEBUG at line ",__LINE__;

# ---------- Check formatting or interpolation --------

sub MyClass::meth {
  my $self = shift;
  return @_ ? [ "methargs:", @_ ] : "meth_with_noargs";
}

# Many tests assume this
$Data::Dumper::Interp::Foldwidth = 72;

diag "##DEBUG at line ",__LINE__;
@ARGV = ('fake','argv');
$. = 1234;
$ENV{EnvVar} = "Test EnvVar Value";

my $BS = "\\";
my $SQ = "'";
my $DQ = '"';

diag "##DEBUG at line ",__LINE__;

my %toplex_h = ("" => "Emp", A=>111,"B B"=>222,C=>{d=>888,e=>999},D=>{},EEEEEEEEEEEEEEEEEEEEEEEEEE=>\42,F_long_enough_to_force_wrap_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF=>\\\43, G=>qr/foo.*bar/xsi);
   # EEE... identifer is long to force linewrap
my @toplex_a = (0,1,"C",\%toplex_h,[],[0..9]);
my $toplex_ar = \@toplex_a;
my $toplex_hr = \%toplex_h;
my $toplex_obj = bless {}, 'MyClass';
my $toplex_regexp= qr/my.*regexp/;

our %global_h = %toplex_h;
our @global_a = @toplex_a;
our $global_ar = \@global_a;
our $global_hr = \%global_h;
our $global_obj = bless {}, 'MyClass';
our $global_regexp = $toplex_regexp;

our %maskedglobal_h = (key => "should never be seen");
our @maskedglobal_a = ("should never be seen");
our $maskedglobal_ar = \@maskedglobal_a;
our $maskedglobal_hr = \%maskedglobal_h;
our $maskedglobal_obj = bless {}, 'ShouldNeverBeUsedClass';
our $maskedglobal_regexp = qr/should.*never.*be_seen/;

our %local_h = (key => "should never be seen");
our @local_a = ("should never be seen");
our $local_ar = \@local_a;
our $local_hr = \%local_h;
our $local_obj = \%local_h;
our $local_regexp = qr/should.*never.*be_seen/;

our $a = "global-a";  # used specially used by sort()
our $b = "global-b";

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
diag "##DEBUG at line ",__LINE__;

package A::B::C;
our %ABC_h = %main::global_h;
our @ABC_a = @main::global_a;
our $ABC_ar = \@ABC_a;
our $ABC_hr = \%ABC_h;
our $ABC_obj = $main::global_obj;
our $ABC_regexp = $main::global_regexp;

package main::Mybase;
sub new { bless \do{ my $t = 1000+$_[1] }, $_[0] }
use overload
  '""' => sub{ my $self=shift; "Mybase-ish-".$$self }, # "Mybase-ish-1xxxx"
  # Implement '&' so Data::Dumper::Interp::_show_as_number
  # will decide it should be displayed as an unquoted number.
  '&'  => sub{ my ($self,$operand,$swapped)=@_; $$self & $operand },
  ;
package main::Myderived;
our @ISA = ("main::Mybase");

package main;

diag "##DEBUG at line ",__LINE__;
$_ = "GroupA.GroupB";
/(.*)\W(.*)/sp or confess "nomatch"; # set $1 and $2
diag "##DEBUG at line ",__LINE__;

{ my $code = 'qsh("a b")';           mycheck $code, '"a b"',  eval $code; }
{ my $code = 'qsh(undef)';           mycheck $code, "undef",  eval $code; }
{ my $code = 'qsh("undef")';         mycheck $code, "\"undef\"",  eval $code; }
{ my $code = 'qshpath("a b")';       mycheck $code, '"a b"',  eval $code; }
{ my $code = 'qshpath("~user")';     mycheck $code, "~user",  eval $code; }
{ my $code = 'qshpath("~user/a b")'; mycheck $code, '~user/"a b"', eval $code; }
{ my $code = 'qshpath("~user/ab")';  mycheck $code, "~user/ab", eval $code; }
{ my $code = 'qsh("~user/ab")';      mycheck $code, '"~user/ab"', eval $code; }
{ my $code = 'qsh($_)';              mycheck $code, "${_}",   eval $code; }
{ my $code = 'qsh()';                mycheck $code, "${_}",   eval $code; }
{ my $code = 'qsh';                  mycheck $code, "${_}",   eval $code; }
{ my $code = 'qshpath($_)';          mycheck $code, "${_}",   eval $code; }
{ my $code = 'qshpath()';            mycheck $code, "${_}",   eval $code; }
{ my $code = 'qshpath';              mycheck $code, "${_}",   eval $code; }

diag "##DEBUG at line ",__LINE__;
foreach my $os ($^O, 'linux', 'MSWin32') {
  local $^O = "$os"; # re-stringify to avoid undef when setting local $^O = $^O;

  if ($^O eq "MSWin32") {
diag "##DEBUG os=$os at line ",__LINE__;
    { my $code = q(qshlist("a b","c",'$d')); mycheck $code." (OS=$^O)", q("a b" c "$d"),  eval $code; }
    { my $code = q( qsh("a b\\\\")        ); mycheck $code." (OS=$^O)", q("a b\\\\"),     eval $code; }
    { my $code = q( qsh(q<a b">)          ); mycheck $code." (OS=$^O)", q("a b\\""),      eval $code; }
  } else {
    { my $code = q(qshlist("a b","c",'$d')); mycheck $code." (OS=$^O)", q("a b" c '$d'),  eval $code; }
    { my $code = q( qsh("a b${BS}")       ); mycheck $code." (OS=$^O)", q('a b\\'),       eval $code; }
    { my $code = q( qsh("a b${BS}${BS}")  ); mycheck $code." (OS=$^O)", q('a b\\\\'),     eval $code; }
    { my $code = q( qsh(q<a b">)          ); mycheck $code." (OS=$^O)", q('a b"'),        eval $code; }
  }
}

# Basic checks
diag "##DEBUG at line ",__LINE__;
{ my $code = 'vis($_)'; mycheck $code, "\"${_}\"", eval $code; }
{ my $code = 'vis()'; mycheck $code, "\"${_}\"", eval $code; }
{ my $code = 'vis'; mycheck $code, "\"${_}\"", eval $code; }
{ my $code = 'avis($_,1,2,3)'; mycheck $code, "(\"${_}\",1,2,3)", eval $code; }
{ my $code = 'hvis("foo",$_)'; mycheck $code, "(foo => \"${_}\")", eval $code; }
{ my $code = 'hvisl("foo",$_)'; mycheck $code, "foo => \"${_}\"", eval $code; }
{ my $code = 'avis(@_)'; mycheck $code, '()', eval $code; }
{ my $code = 'hvis(@_)'; mycheck $code, '()', eval $code; }
{ my $code = 'hvisl(@_)'; mycheck $code, '', eval $code; }
{ my $code = 'avis(undef)'; mycheck $code, "(undef)", eval $code; }
{ my $code = 'hvis("foo",undef)'; mycheck $code, "(foo => undef)", eval $code; }
{ my $code = 'vis(undef)'; mycheck $code, "undef", eval $code; }
{ my $code = 'ivis(undef)'; mycheck $code, "<undef arg>", eval $code; }
{ my $code = 'dvis(undef)'; mycheck $code, "<undef arg>", eval $code; }
{ my $code = 'dvisq(undef)'; mycheck $code, "<undef arg>", eval $code; }
{ my $code = 'vis(\undef)'; mycheck $code, "\\undef", eval $code; }
{ my $code = 'vis(\123)'; mycheck $code, "\\123", eval $code; }
{ my $code = 'vis(\"xy")'; mycheck $code, "\\\"xy\"", eval $code; }

diag "##DEBUG at line ",__LINE__;
{ my $code = q/my $s; my @a=sort{ $s=dvis('$a $b'); $a<=>$b }(3,2); "@a $s"/ ;
  mycheck $code, '2 3 a=3 b=2', eval $code;
}

# Vis v1.147ish+ : Check corner cases of re-parsing code
diag "##DEBUG at line ",__LINE__;
{ my $code = q(my $v = undef; dvis('$v')); mycheck $code, "v=undef", eval $code; }
{ my $code = q(my $v = \undef; dvis('$v')); mycheck $code, "v=\\undef", eval $code; }
{ my $code = q(my $v = \"abc"; dvis('$v')); mycheck $code, 'v=\\"abc"', eval $code; }
{ my $code = q(my $v = \"abc"; dvisq('$v')); mycheck $code, "v=\\'abc'", eval $code; }
{ my $code = q(my $v = \*STDOUT; dvisq('$v')); mycheck $code, "v=\\*::STDOUT", eval $code; }
{ my $code = q(open my $fh, "</dev/null" or oops $!; dvis('$fh'));
  mycheck $code, "fh=\\*{\"::\\\$fh\"}", eval $code; }
{ my $code = q(open my $fh, "</dev/null" or oops $!; dvisq('$fh'));
  mycheck $code, "fh=\\*{'::\$fh'}", eval $code; }

diag "##DEBUG at line ",__LINE__;

# Data::Dumper::Interp 2.12 : hex escapes including illegal code points:
#   10FFFF is the highest legal Unicode code point which will ever be assigned.
# Perl (v5.34 at least) mandates code points be <= max signed integer,
# which on 32 bit systems is 7FFFFFFF.
{ my $code = q(my $v = "beyondmax:\x{110000}\x{FFFFFF}\x{7FFFFFFF}"; dvis('$v'));
  mycheck $code, 'v="beyondmax:\x{110000}\x{ffffff}\x{7fffffff}"', eval $code; }

# Check that $1 etc. can be passed (this was once a bug...)
# The duplicated calls are to check that $1 is preserved
{ my $code = '" a~b" =~ / (.*)()/ && qsh($1) && ($1 eq "a~b") && qsh($1)';
  mycheck $code, '"a~b"', eval $code; }
{ my $code = '" a~b" =~ / (.*)()/ && qshpath($1) && ($1 eq "a~b") && qshpath($1)';
  mycheck $code, '"a~b"', eval $code; }
{ my $code = '" a~b" =~ / (.*)()/ && vis($1) && ($1 eq "a~b") && vis($1)';
  mycheck $code, '"a~b"', eval $code; }
{ my $code = 'my $vv=123; \' a $vv b\' =~ / (.*)/ && dvis($1) && ($1 eq "a \$vv b") && dvis($1)';
  mycheck $code, 'a vv=123 b', eval $code; }

diag "##DEBUG at line ",__LINE__;
# Check Deparse support
{ my $data = $test_sub;
  { my $code = 'vis($data)'; mycheck $code, 'sub { "DUMMY" }', eval $code; }
  local $Data::Dumper::Interp::Deparse = 1;
  { my $code = 'vis($data)'; mycheck $code, qr/sub \{\s*my \$x = 42;\s*\}/, eval $code; }
}
{ my $data = $test_sub_withproto;
  { my $code = 'vis($data)'; mycheck $code, 'sub { "DUMMY" }', eval $code; }
  local $Data::Dumper::Interp::Deparse = 1;
  { my $code = 'vis($data)'; mycheck $code, qr/sub \(\@\) \{\s*my \$x = 42;\s*\}/, eval $code; }
}

diag "##DEBUG at line ",__LINE__;
# Floating point values (single values special-cased to show not as 'string')
{ my $code = 'vis(3.14)'; mycheck $code, '3.14', eval $code; }
# But multiple values are sent through Data::Dumper, so...
{ my $code = 'vis([3.14])'; mycheck $code, '[3.14]', eval $code; }

# bigint, bignum, bigrat support
#
# Recently Data::Dumper::Interp was changed to prepend (objtype) to stringified values,
# e.g. "(Math::BigFloat)3.14159265358979323846264338327950288419"
# but we might later change this back, or make the prefix optional;
# therefore we accept the result with or without with (type) prefix.

my $bigfstr = '9988776655443322112233445566778899.8877';
my $bigistr = '9988776655443322112233445566778899887766';
my $ratstr  = '1/9';

diag "##DEBUG at line ",__LINE__;
{
  use bignum;  # BigInt and BigFloat together
diag "##DEBUG at line ",__LINE__;

  # stringify everything possible
  local $Data::Dumper::Interp::Objects = 1;  # NOTE: the '1' will be a BigInt !

  my $bigf = eval $bigfstr // oops;
  oops(u(blessed($bigf))," <<$bigfstr>> ",u($bigf)," $@") unless blessed($bigf) =~ /^Math::BigFloat/;
  mychecklit(sub{eval $_[0]}, $bigf, qr/(?:\(Math::BigFloat[^\)]*\))?${bigfstr}/);

  # Some implementations make everything a Math::BigFloat, others make
  # integers a Math::BigInt .
  my $bigi = eval $bigistr // oops;
  oops(u(blessed($bigi))," <<$bigistr>> ",u($bigi)," $@")
    unless blessed($bigi) =~ /^Math::Big\w*/;
  mychecklit(sub{eval $_[0]}, $bigi, qr/(?:\(Math::Big\w*[^\)]*\))?${bigistr}/);

  # Confirm that various Objects values disable
  foreach my $Sval (0, undef, "", [], [0], [""]) {
    local $Data::Dumper::Interp::Objects = $Sval;
    #my $s = vis($bigf);
    my $s = visnew->Debug(0)->vis($bigf);
    oops "bug(",u($Sval),")($s)" unless $s =~ /^\(?bless.*BigFloat/s;
  }
}
{
  # no 'bignum' etc. in effect, just explicit class names
  use Math::BigFloat;
diag "##DEBUG at line ",__LINE__;
  my $bigf = Math::BigFloat->new($bigfstr);
  oops unless $bigf->isa("Math::BigFloat");
diag "##DEBUG at line ",__LINE__;

  use Math::BigRat;
diag "##DEBUG at line ",__LINE__;
  my $rat = Math::BigRat->new($ratstr);
  oops unless $rat->isa("Math::BigRat");
diag "##DEBUG at line ",__LINE__;

  # No stringification if disabled
  { local $Data::Dumper::Interp::Objects = 0;
    my $s = vis($bigf); oops "bug($s)" unless $s =~ /^bless.*BigFloat/s;
  }
  # No stringification if only some other class enabled (string)
  { local $Data::Dumper::Interp::Objects = 'Some::Other::Class';
    my $s = vis($bigf); oops "bug($s)" unless $s =~ /^bless.*BigFloat/s;
  }
  # No stringification if only some other class enabled (regex)
  { local $Data::Dumper::Interp::Objects = qr/Some::Other::Class/;
    my $s = vis($bigf); oops "bug($s)" unless $s =~ /^bless.*BigFloat/s;
  }
  # Yes if globally enabled
  { local $Data::Dumper::Interp::Objects = 1;
    mychecklit(sub{eval $_[0]}, $bigf, qr/(?:\(Math::BigFloat[^\)]*\))?${bigfstr}/);
  }
  # Yes if enabled only that class (regex)
  { local $Data::Dumper::Interp::Objects = [qr/^Math::BigFloat/];
    mychecklit(sub{eval $_[0]}, $bigf, qr/(?:\(Math::BigFloat[^\)]*\))?${bigfstr}/);
  }
  # Yes if enabled only that class (string)
  { local $Data::Dumper::Interp::Objects = 'Math::BigFloat';
    mychecklit(sub{eval $_[0]}, $bigf, qr/(?:\(Math::BigFloat[^\)]*\))?${bigfstr}/);
  }
  # Yes if enabled for class as well as others (string)
  { local $Data::Dumper::Interp::Objects = ['Somewhat::Bogus', 'Math::BigFloat'];
    mychecklit(sub{eval $_[0]}, $bigf, qr/(?:\(Math::BigFloat[^\)]*\))?${bigfstr}/);
  }
  # Yes if enabled for class as well as others (regex)
  { local $Data::Dumper::Interp::Objects = ['AAA', qr/Bogus/, qr/^Math::BigFloat/, qr/xx/];
    mychecklit(sub{eval $_[0]}, $bigf, qr/(?:\(Math::BigFloat[^\)]*\))?${bigfstr}/);
  }
  # Yes if enabled only for a base class (string)
  { local $Data::Dumper::Interp::Objects = ['main::Mybase'];
    my $obj = main::Myderived->new(42);
    $obj->isa("main::Mybase") or oops "urp";
    mychecklit(sub{eval $_[0]}, $obj, qr/\(main::Myderived\)Mybase-ish-1042/);
  }
}

diag "##DEBUG at line ",__LINE__;
{
  # There is a new (with bigrat 0.51) bug where "use bigrat" immediately and
  # permanently causes math operations on Math::BitFloat to produce BigRats in all
  # scopes, not just in the scope of the 'use bigrat'.   This breaks Math::BigFloat
  # tests which execute after the bigrat package is loaded.
  #
  # So we have to do the bigrat test in an eval to defer loading it until after
  # all other bignum tests have run.
  # Arrgh!
  eval <<'EOF';
    use bigrat;
    my $rat = eval $ratstr // oops;
    oops unless $rat->isa("Math::BigRat");
    mychecklit(sub{eval $_[0]}, $rat, qr/(?:\(Math::BigRat[^\)]*\))?${ratstr}/);
EOF
  oops "urp\n$@" if $@
}

diag "##DEBUG at line ",__LINE__;
# Check string truncation, and that the original data is not modified in-place
{ my $orig_str  = '["abcDEFG",["xyzABCD",{bareword => "fghIJKL"}]]';
  my $check_data = eval $orig_str; oops "bug" if $@;
  my $orig_data  = eval $orig_str; oops "bug" if $@;
  foreach my $MSw (1..9) {
    # hand-truncate to create "expected result" data
    (my $exp_str = $orig_str) =~ s{(")([a-zA-Z]{$MSw})([a-zA-Z]*+)(\1)}{
                                    local $_ = $1
                                             . $2
                                             . (length($3) > 3 ? "..." : $3)
                                             . $4 ;
                                    # v5.005: hash keys are no longer substituted
                                    #$_ = "\"$_\"" if m{^\w.*\.\.\.$}; #bareword
                                    $_
                                  }segx;
    local $Data::Dumper::Interp::MaxStringwidth = $MSw;
    mycheck "with MaxStringwidth=$MSw", $exp_str, eval 'vis($orig_data)';
    oops "MaxStringwidth=$MSw : Original data corrupted"
      unless Compare($orig_data, $check_data);
  }
}

# There was a bug for s/dvis called direct from outer scope, so don't use eval:
#
# Another bug was here: On some older platforms qr/.../ can visualize to a
# different, longer representation, so forcing wrap to be the same everywhere
#
my $SS = do{ my $x=" "; dvis('$x') =~ /x="(.)"/ or die; $1 }; # spacedots?

diag "##DEBUG at line ",__LINE__;
mycheck
  'global dvis %toplex_h',
q!%toplex_h=(
  "" => "Emp",
  A => 111,
  "B!.$SS.q!B" => 222,
  C => {d => 888,e => 999},
  D => {},
  EEEEEEEEEEEEEEEEEEEEEEEEEE => \\42,
  F_long_enough_to_force_wrap_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    => \\\\\\43,
  G => qr/foo.*bar/six
)!,
  dvis('%toplex_h');
diag "##DEBUG at line ",__LINE__;
mycheck 'global divs @ARGV', q(@ARGV=("fake","argv")), dvis('@ARGV');
mycheck 'global divs $.', q($.=1234), dvis('$.');
mycheck 'global divs $ENV{EnvVar}', q("Test EnvVar Value"), ivis('$ENV{EnvVar}');
diag "##DEBUG at line ",__LINE__;
sub func {
  mycheck 'func args', q(@_=(1,2,3)), dvis('@_');
}
func(1,2,3);

# There was once a "took almost forever" backtracking problem
my @backtrack_bugtest_data = (
  42,
  {A => 0, BBBBBBBBBBBBB => "foo"},
);
timed_run {
  mycheck 'dvis @backtrack_bugtest_data',
        '@backtrack_bugtest_data=(42,{A => 0,BBBBBBBBBBBBB => "foo"})',
        dvis('@backtrack_bugtest_data');
} 0.10; # some cpan test machines are slow!
diag "##DEBUG at line ",__LINE__;

sub doquoting($$) {
  my ($input, $useqq) = @_;
  my $quoted = $input;
  if ($useqq) {
    my %subopts;
    if ($useqq ne "1") {
      foreach my $item (split /:/, $useqq) {
        if ($item =~ /^([^=]+)=(.*)/) {
          $subopts{$1} = $2;
        } else {
          $subopts{$item} = 1;
        }
      }
    }
    $quoted =~ s/([\$\@\\])/\\$1/gs;
    if (delete $subopts{controlpic}) {
      $quoted =~ s/\n/\N{SYMBOL FOR NEWLINE}/gs;
      $quoted =~ s/\t/\N{SYMBOL FOR HORIZONTAL TABULATION}/gs;
    } else {
      $quoted =~ s/\n/\\n/gs;
      $quoted =~ s/\t/\\t/gs;
    }
    my $unicode = delete $subopts{unicode} || delete $subopts{utf8};
    if (!$unicode) {
      $quoted = join("", map{ ord($_) > 127 ? sprintf("\\x{%x}", ord($_)) : $_ }
                           split //,$quoted);
    }
    if (my $arg = delete $subopts{qq}) {
      my ($left, $right) = split //, ($arg eq 1 ? "{}" : $arg);
      $quoted =~ s/([\Q${left}${right}\E])/\\$1/g;
      $quoted = "qq" . $left . $quoted . $right;
    } else {
      $quoted =~ s/"/\\"/g;
      $quoted = '"' . $quoted . '"';
    }
    oops("testbug: Useqq subopt: '",keys(%subopts),"'\n")
      if %subopts;
  } else {
    $quoted =~ s/([\\'])/\\$1/gs;
    $quoted = "'${quoted}'";
  }
  return $quoted;
}

sub show_white($) {
  local $_ = shift;
  return "(Is undef)" unless defined;
  s/\t/<tab>/sg;
  s/( +)$/"<space>" x length($1)/seg; # only trailing spaces
  s/\n/<newline>\n/sg;
  $_
}

diag "##DEBUG at line ",__LINE__;
my $unicode_str = join "", map { chr($_) } (0x263A .. 0x2650);
my $byte_str = join "",map { chr $_ } 10..30;
diag "##DEBUG at line ",__LINE__;

sub get_closure(;$) {
 my ($clobber) = @_;
 confess "Non-zero CHILD_ERROR ($?)" if $? != 0;

 my %closure_h = (%toplex_h);
 my @closure_a = (@toplex_a);
 my $closure_ar = \@closure_a;
 my $closure_hr = \%closure_h;
 my $closure_obj = $toplex_obj;
 if ($clobber) { # try to over-write deleted objects
   @closure_a = ("bogusa".."bogusz");
 }

 return sub {

  confess "Non-zero CHILD_ERROR ($?)" if $? != 0;

  # Perl is inconsistent about whether an eval in package DB can see
  # lexicals in enclosing scopes.  Sometimes it can, sometimes not.
  # However explicitly referencing those "global lexicals" in the closure
  # seems to make it work.
  #   5/16/16: Perl v5.22.1 *segfaults* if these are included
  #   (at least *_obj).  But removing them all causes some to appear
  #   to be non-existent.
  my $forget_me_not = [
     \$unicode_str, \$byte_str,
     \@toplex_a, \%toplex_h, \$toplex_hr, \$toplex_ar, \$toplex_obj,
     \@global_a, \%global_h, \$global_hr, \$global_ar, \$global_obj,
  ];

  # Referencing these intermediate variables also prevents them from
  # being destroyed before this closure is executed:
  my $saverefs = [ \%closure_h, \@closure_a, \$closure_ar, \$closure_hr, \$closure_obj ];


  my $zero = 0;
  my $one = 1;
  my $two = 2;
  my $EnvVarName = 'EnvVar';
  my $flex = 'Lexical in sub f';
  my $flex_ref = \$flex;
  my $ARGV_ref = \@ARGV;
  eval { die "FAKE DEATH\n" };  # set $@
  my %sublexx_h = %toplex_h;
  my @sublexx_a = @toplex_a;
  my $sublexx_ar = \@sublexx_a;
  my $sublexx_hr = \%sublexx_h;
  my $sublexx_obj = $toplex_obj;
  our %subglobal_h = %toplex_h;
  our @subglobal_a = @toplex_a;
  our $subglobal_ar = \@subglobal_a;
  our $subglobal_hr = \%subglobal_h;
  our $subglobal_obj = $toplex_obj;
  our %maskedglobal_h = %toplex_h;
  our @maskedglobal_a = @toplex_a;
  our $maskedglobal_ar = \@maskedglobal_a;
  our $maskedglobal_hr = \%maskedglobal_h;
  our $maskedglobal_obj = $toplex_obj;
  our $maskedglobal_regexp = $toplex_regexp;
  local %local_h = %toplex_h;
  local @local_a = @toplex_a;
  local $local_ar = \@toplex_a;
  local $local_hr = \%local_h;
  local $local_obj = $toplex_obj;
  local $local_regexp = $toplex_regexp;

  use constant CPICS_DEFAULT => 0; # is Useqq('controlpics') the default?

  my @dvis_tests = (
    [ __LINE__, q(hexesc:\x{263a}), qq(hexesc:\N{U+263A}) ],   # \x{...} in dvis input
    [ __LINE__, q(NUesc:\N{U+263a}), qq(NUesc:\N{U+263A}) ], # \N{U+...} in dvis input
    [ __LINE__, q(aaa\\\\bbb), q(aaa\bbb) ],
    [ __LINE__, q(re is $toplex_regexp), q(re is toplex_regexp=qr/my.*regexp/) ],

    #[ q($unicode_str\n), qq(unicode_str=\" \\x{263a} \\x{263b} \\x{263c} \\x{263d} \\x{263e} \\x{263f} \\x{2640} \\x{2641} \\x{2642} \\x{2643} \\x{2644} \\x{2645} \\x{2646} \\x{2647} \\x{2648} \\x{2649} \\x{264a} \\x{264b} \\x{264c} \\x{264d} \\x{264e} \\x{264f} \\x{2650}\"\n) ],
    [__LINE__, q($unicode_str\n), qq(unicode_str="${unicode_str}"\n) ],

    [__LINE__, q(unicodehex_str=\"\\x{263a}\\x{263b}\\x{263c}\\x{263d}\\x{263e}\\x{263f}\\x{2640}\\x{2641}\\x{2642}\\x{2643}\\x{2644}\\x{2645}\\x{2646}\\x{2647}\\x{2648}\\x{2649}\\x{264a}\\x{264b}\\x{264c}\\x{264d}\\x{264e}\\x{264f}\\x{2650}\"\n), qq(unicodehex_str="${unicode_str}"\n) ],

    (CPICS_DEFAULT ? (
     [__LINE__, q($byte_str\n), qq(byte_str=\"\N{SYMBOL FOR NEWLINE}\\13\N{SYMBOL FOR FORM FEED}\N{SYMBOL FOR CARRIAGE RETURN}\\16\\17\\20\\21\\22\\23\\24\\25\\26\\27\\30\\31\\32\N{SYMBOL FOR ESCAPE}\\34\\35\\36\"\n) ]
    ):(
     [__LINE__, q($byte_str\n), qq(byte_str=\"\\n\\13\\f\\r\\16\\17\\20\\21\\22\\23\\24\\25\\26\\27\\30\\31\\32\\e\\34\\35\\36\"\n) ],
     #[__LINE__, q($byte_str\n), qq(byte_str=\"\\n\\x{B}\\f\\r\\x{E}\\x{F}\\x{10}\\x{11}\\x{12}\\x{13}\\x{14}\\x{15}\\x{16}\\x{17}\\x{18}\\x{19}\\x{1A}\\e\\x{1C}\\x{1D}\\x{1E}\"\n) ],
    )),

    [__LINE__, q($flex\n), qq(flex=\"Lexical${SS}in${SS}sub${SS}f\"\n) ],
    [__LINE__, q($$flex_ref\n), qq(\$\$flex_ref=\"Lexical${SS}in${SS}sub${SS}f\"\n) ],

    [__LINE__, q($_ $ARG\n), qq(\$_=\"GroupA.GroupB\" ARG=\"GroupA.GroupB\"\n) ],
    [__LINE__, q($a\n), qq(a=\"global-a\"\n) ],
    [__LINE__, q($b\n), qq(b=\"global-b\"\n) ],
    [__LINE__, q($1\n), qq(\$1=\"GroupA\"\n) ],
    [__LINE__, q($2\n), qq(\$2=\"GroupB\"\n) ],
    [__LINE__, q($3\n), qq(\$3=undef\n) ],
    [__LINE__, q($&\n), qq(\$&=\"GroupA.GroupB\"\n) ],
    [__LINE__, q(${^MATCH}\n), qq(\${^MATCH}=\"GroupA.GroupB\"\n) ],
    [__LINE__, q($.\n), qq(\$.=1234\n) ],
    [__LINE__, q($NR\n), qq(NR=1234\n) ],
    (CPICS_DEFAULT ? (
     [__LINE__, q($/\n), qq(\$/=\"\N{SYMBOL FOR NEWLINE}\"\n) ],
    ):(
     [__LINE__, q($/\n), qq(\$/=\"\\n\"\n) ],
    )),
    [__LINE__, q($\\\n), qq(\$\\=undef\n) ],
    [__LINE__, q($"\n), qq(\$\"=\" \"\n) ],
    [__LINE__, q($~\n), qq(\$~=\"STDOUT\"\n) ],
    #20 :
    [__LINE__, q($^\n), qq(\$^=\"STDOUT_TOP\"\n) ],
    (CPICS_DEFAULT ? (
     [__LINE__, q($:\n), qq(\$:=\" \N{SYMBOL FOR NEWLINE}-\"\n) ],
     [__LINE__, q($^L\n), qq(\$^L=\"\N{SYMBOL FOR FORM FEED}\"\n) ],
    ):(
     [__LINE__, q($:\n), qq(\$:=\" \\n-\"\n) ],
    )),
    [__LINE__, q($?\n), qq(\$?=0\n) ],
    [__LINE__, q($[\n), qq(\$[=0\n) ],
    [__LINE__, q($$\n), qq(\$\$=$$\n) ],
    [__LINE__, q($^N\n), qq(\$^N=\"GroupB\"\n) ],
    [__LINE__, q($+\n), qq(\$+=\"GroupB\"\n) ],
    [__LINE__, q(@+ $#+\n), qq(\@+=(13,6,13) \$#+=2\n) ],
    [__LINE__, q(@- $#-\n), qq(\@-=(0,0,7) \$#-=2\n) ],
    #30 :
    [__LINE__, q($;\n), qq(\$;=\"\\34\"\n) ],
    #[__LINE__, q($;\n), qq(\$;=\"\\x{1C}\"\n) ],
    [__LINE__, q(@ARGV\n), qq(\@ARGV=(\"fake\",\"argv\")\n) ],
    [__LINE__, q($ENV{EnvVar}\n), qq(\$ENV{EnvVar}=\"Test EnvVar Value\"\n) ],
    [__LINE__, q($ENV{$EnvVarName}\n), qq(\$ENV{\$EnvVarName}=\"Test EnvVar Value\"\n) ],
    [__LINE__, q(@_\n), <<'EOF' ],  # N.B. Foldwidth was set to 72
@_=(
  42,
  [
    0,
    1,
    "C",
    {
      "" => "Emp",
      A => 111,
      "B B" => 222,
      C => {d => 888,e => 999},
      D => {},
      EEEEEEEEEEEEEEEEEEEEEEEEEE => \42,
      F_long_enough_to_force_wrap_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        => \\\43,
      G => qr/foo.*bar/six
    },
    [],
    [0,1,2,3,4,5,6,7,8,9]
  ]
)
EOF
    [__LINE__, q($#_\n), qq(\$#_=1\n) ],
    (CPICS_DEFAULT ? (
     [__LINE__, q($@\n), qq(\$\@=\"FAKE DEATH\N{SYMBOL FOR NEWLINE}\"\n) ],
    ):(
     [__LINE__, q($@\n), qq(\$\@=\"FAKE DEATH\\n\"\n) ],
    )),
    #37 :
    map({
      my ($LQ,$RQ) = (/^(.)(.)$/) or oops "bug";
      map({
        my $name = $_;
        map({
          my ($dollar, $r) = @$_;
          my $dolname_scalar = $dollar ? "\$$name" : $name;
          # Make total prefix length constant to avoid wrap variations
          my $maxnamelen = 12;
          my $spfx = "x" x (
            (1+1+$maxnamelen+1)  # {dollar}$name{r}
            - (length($dollar)+length($dolname_scalar)+length($r)) );
          my $pfx = substr($spfx,0,length($spfx)-1);
          #state $depth=0;
          #say "##($depth) spfx=<$spfx> pfx=<$pfx> dollar=<$dollar> r=<$r> dns=<$dolname_scalar> n=<$name>"; $depth++;

          #my $p = " " x length("?${dollar}${name}_?${r}");
          my $p = "";

          [__LINE__, qq(${pfx}%${dollar}${name}_h${r}\n), <<EOF ],
${pfx}\%${dollar}${name}_h${r}=(
${p}  "" => "Emp",
${p}  A => 111,
${p}  "B B" => 222,
${p}  C => {d => 888,e => 999},
${p}  D => {},
${p}  EEEEEEEEEEEEEEEEEEEEEEEEEE => \\42,
${p}  F_long_enough_to_force_wrap_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
${p}    => \\\\\\43,
${p}  G => qr/foo.*bar/six
${p})
EOF

          [__LINE__, qq(${pfx}\@${dollar}${name}_a${r}\n), <<EOF ],
${pfx}\@${dollar}${name}_a${r}=(
${p}  0,
${p}  1,
${p}  "C",
${p}  {
${p}    "" => "Emp",
${p}    A => 111,
${p}    "B B" => 222,
${p}    C => {d => 888,e => 999},
${p}    D => {},
${p}    EEEEEEEEEEEEEEEEEEEEEEEEEE => \\42,
${p}    F_long_enough_to_force_wrap_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
${p}      => \\\\\\43,
${p}    G => qr/foo.*bar/six
${p}  },
${p}  [],
${p}  [0,1,2,3,4,5,6,7,8,9]
${p})
EOF

          [__LINE__, qq(${pfx}\$#${dollar}${name}_a${r}),
            qq(${pfx}\$#${dollar}${name}_a${r}=5)
          ],
          [__LINE__, qq(${pfx}\$#${dollar}${name}_a${r}\n),
            qq(${pfx}\$#${dollar}${name}_a${r}=5\n)
          ],

          [__LINE__, qq(${spfx}\$${dollar}${name}_a${r}[3]{C}{e}\n),
            qq(${spfx}\$${dolname_scalar}_a${r}[3]{C}{e}=999\n)
          ],

          [__LINE__, qq(${spfx}\$${dollar}${name}_a${r}[3]->{A}\n),
            qq(${spfx}\$${dolname_scalar}_a${r}[3]->{A}=111\n)
          ],
          [__LINE__, qq(${spfx}\$${dollar}${name}_a${r}[3]->{$LQ$RQ}\n),
            qq(${spfx}\$${dolname_scalar}_a${r}[3]->{$LQ$RQ}="Emp"\n)
          ],
          [__LINE__, qq(${spfx}\$${dollar}${name}_a${r}[3]{C}->{e}\n),
            qq(${spfx}\$${dolname_scalar}_a${r}[3]{C}->{e}=999\n)
          ],
          [__LINE__, qq(${spfx}\$${dollar}${name}_a${r}[3]->{C}->{e}\n),
            qq(${spfx}\$${dolname_scalar}_a${r}[3]->{C}->{e}=999\n)
          ],
          [__LINE__, qq(${spfx}\@${dollar}${name}_a${r}[\$zero,\$one]\\n),
            qq(${spfx}\@${dollar}${name}_a${r}[\$zero,\$one]=(0,1)\n)
          ],
          [__LINE__, qq(${spfx}\@${dollar}${name}_h${r}{${LQ}A${RQ},${LQ}B B${RQ}}\\n),
            qq(${spfx}\@${dollar}${name}_h${r}{${LQ}A${RQ},${LQ}B B${RQ}}=(111,222)\n)
          ],
        }
          #(['',''], ['$','r'])
          (['$','r'],['',''])
        ), #map [$dollar,$r]

        ( $] >= 5.022000 && $] <= 5.022001
            ?  (do{ state $warned = 0;
                    diag "\n\n** obj->method() tests disabled to avoid segfault (using Perl $^V)\n\n"
                     unless $warned++; ()
                  },())
            : (
               [__LINE__, qq(\$${name}_obj->meth ()), qq(\$${name}_obj->meth="meth_with_noargs" ()) ],
               [__LINE__, qq(\$${name}_obj->meth(42)), qq(\$${name}_obj->meth(42)=["methargs:",42]) ],
              )
        ),

        map({
          my ($dollar, $r, $arrow) = @$_;
          my $dolname_scalar = $dollar ? "\$$name" : $name;
          [__LINE__, qq(\$${dollar}${name}_h${r}${arrow}{\$${name}_a[\$two]}{e}\\n),
            qq(\$${dolname_scalar}_h${r}${arrow}{\$${name}_a[\$two]}{e}=999\n)
          ],
          [__LINE__, qq(\$${dollar}${name}_a${r}${arrow}[3]{C}{e}\\n),
            qq(\$${dolname_scalar}_a${r}${arrow}[3]{C}{e}=999\n)
          ],
          [__LINE__, qq(\$${dollar}${name}_a${r}${arrow}[3]{C}->{e}\\n),
            qq(\$${dolname_scalar}_a${r}${arrow}[3]{C}->{e}=999\n)
          ],
          [__LINE__, qq(\$${dollar}${name}_h${r}${arrow}{A}\\n),
            qq(\$${dolname_scalar}_h${r}${arrow}{A}=111\n)
          ],
        } (['$','r',''], ['','r','->'])
        ), #map [$dollar,$r,$arrow]
        }
        qw(closure sublexx toplex global subglobal
           maskedglobal local A::B::C::ABC)
      ), #map $name
      } ('""', "''")
    ), #map ($LQ,$RQ)
  );
  for my $test (@dvis_tests) {
    my ($lno, $dvis_input, $expected, $skip_condition) = @$test;
    #warn "##^^^^^^^^^^^ lno=$lno dvis_input='$dvis_input' expected='$expected'\n";

    # FUTURE: wrap in subtest with plan skip_all => $skip_condition if skip_condition is true
    oops "skip_condition not impl" if $skip_condition;

    { local $@;  # check for bad syntax first, to avoid uncontrolled die later
      # For some reason we can't catch exceptions from inside package DB.
      # undef is returned but $@ is not set
      # 3/5/22: The above comment may not longer be true; there might have been
      #  a bug where $@ was not saved properly.
      #  BUT VERIFY b4 deleting this comment.
      my $ev = eval { "$dvis_input" };
      oops "Bad test string:$dvis_input\nPerl can't interpolate it (lno=$lno)"
         .($@ ? ":\n  $@" : "\n")
        if $@ or ! defined $ev;
    }

    my sub mycheckspunct($$$) {
      my ($varname, $actual, $expecting) = @_;
      mycheck "dvis('$dvis_input') lno $lno : $varname NOT PRESERVED : ",
            $actual//"<undef>", $expecting//"<undef>" ;
    }
    my sub mychecknpunct($$$) {
      my ($varname, $actual, $expecting) = @_;
      # N.B. mycheck() compares as strings
      mycheck "dvis('$dvis_input') lno $lno : $varname NOT PRESERVED : ",
            defined($actual) ? $actual+0 : "<undef>",
            defined($expecting) ? $expecting+0 : "<undef>" ;
    }

    for my $use_oo (0,1) {
      my $actual;
      my $dollarat_val = $@;
      eval { $@ = $dollarat_val;
        # Verify that special vars are preserved and don't affect Data::Dumper::Interp
        # (except if testing a punctuation var, then don't change it's value)

        my ($origAt,$origFs,$origBs,$origComma,$origBang,$origCarE,$origCarW)
          = ($@, $/, $\, $,, $!+0, $^E, $^W);

        # Don't change a value if being tested in $dvis_input
        my ($fakeAt,$fakeFs,$fakeBs,$fakeCom,$fakeBang,$fake_cE,$fake_cW)
          = ($dvis_input =~ /(?<!\\)\$@/    ? $origAt : "FakeAt",
             $dvis_input =~ /(?<!\\)\$\//   ? $origFs : "FakeFs",
             $dvis_input =~ /(?<!\\)\$\\\\/ ? $origBs : "FakeBs",
             $dvis_input =~ /(?<!\\)\$,/    ? $origComma : "FakeComma",
             $dvis_input =~ /(?<!\\)\$!/    ? $origBang : 6,
             $dvis_input =~ /(?<!\\)\$^E/   ? $origCarE : 6,  # $^E aliases $! on most OSs
             $dvis_input =~ /(?<!\\)\$^W/   ? $origCarW : 0); # $^W can only be 0 or 1

        ($@, $/, $\, $,, $!, $^E, $^W)
          = ($fakeAt,$fakeFs,$fakeBs,$fakeCom,$fakeBang,$fake_cE,$fake_cW);

        $actual = $use_oo
           ? Data::Dumper::Interp->new()->dvis($dvis_input)
           : dvis($dvis_input);

        mycheckspunct('$@',  $@,   $fakeAt);
        mycheckspunct('$/',  $/,   $fakeFs);
        mycheckspunct('$\\', $\,   $fakeBs);
        mycheckspunct('$,',  $,,   $fakeCom);
        # In FreeBSD a reference to $& can set errno!  So can't mycheck $! unless we save&restore it in the tests
        mychecknpunct('$!',  $!+0, $fakeBang);
        mychecknpunct('$^E', $^E+0,$fake_cE);
        mychecknpunct('$^W', $^W+0,$fake_cW);

        # Restore
        ($@, $/, $\, $,, $!, $^E, $^W)
          = ($origAt,$origFs,$origBs,$origComma,$origBang,$origCarE,$origCarW);
        $dollarat_val = $@;
      }; #// do{ $actual  = $@ };
      $actual = $@ if $@;
      $@ = $dollarat_val;

      mycheck(
        "Test case lno $lno, (use_oo=$use_oo) dvis input "
                              . $quotes[0].show_white($dvis_input).$quotes[1],
        $expected,
        $actual);
    }

    for my $useqq (0, 1, "utf8", "unicode", "unicode:controlpic",
                   "unicode:qq", "unicode:qq=()", "qq",
                  ) {
      my $input = $expected.$dvis_input.'qqq@_(\(\))){\{\}\""'."'"; # gnarly
      # Now Data::Dumper (version 2.174) forces "double quoted" output
      # if there are any Unicode characters present.
      # So we can not test single-quoted mode in those cases
      next
        if !$useqq && $input =~ tr/\0-\377//c;
      my $exp = doquoting($input, $useqq);
      my $act = Data::Dumper::Interp->new()->Useqq($useqq)->vis($input);
      oops "\n\nUseqq ",u($useqq)," bug:\n"
         ."     Input ".displaystr($input)."\n"
         ."  Expected ".displaystr($exp)."\n"
         ."       Got ".displaystr($act)."\n"
        unless $exp eq $act;
    }
  }
 };
} # get_closure()
diag "##DEBUG at line ",__LINE__;
sub f($) {
  get_closure(1);
  my $code = get_closure(0);
  get_closure(1);
  get_closure(1);
  $code->(@_);
  no warnings 'once';
  oops "Punct save/restore imbalance" if @Data::Dumper::save_stack != 0;
}
sub g($) {
  local $_ = 'SHOULD NEVER SEE THIS';
  goto &f;
}
diag "##DEBUG at line ",__LINE__;
confess "Non-zero CHILD_ERROR ($?)" if $? != 0;
&g(42,$toplex_ar);
diag "##DEBUG at line ",__LINE__;


#print "Tests passed.\n";
#say "stderrstring:$stderr_string";

ok(1, "The whole shebang");
done_testing();
exit 0;

BEGIN{ diag "### BEGIN DEBUG at line ",__LINE__; }
# End Tester
