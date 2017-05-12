#!/usr/bin/perl

use Alias qw(alias const attr);

my $TNUM = 0;

sub T { ++$TNUM; my $res = shift; print $res ? "ok $TNUM\n" : "not ok $TNUM\n" };

print "1..34\n";

$TEN = "";
$ten = 10;
$TWENTY = 20;
alias TEN => $ten, TWENTY => \*ten;
print '#\\$TEN is ', \$TEN, "\n";
print '#\\$ten is ', \$ten, "\n";
T(\$TEN eq \$ten);
T($TEN eq $TWENTY);

const _TEN_ => \10;

eval { $_TEN_ = 20 };
T($@);

$dyn = "abcd";
{
  local $dyn;
  alias dyn => "pqrs";
  T($dyn eq "pqrs");
}
T($dyn eq "abcd");

my($lex) = 'abcd';
$closure = sub { return "$lex"; };
alias NAMEDCLOSURE => \&$closure;
$lex = 'pqrs';
T(NAMEDCLOSURE() eq "pqrs");

package Foo;

# "in life", my moma always said, "you gotta pass those tests 
# before you can be o' some use to yerself" :-)
*T = \&main::T;    

use Alias;

sub new { bless { foo => 1, 
		  bar => [2,3], 
		  buz => { a => 4}, 
		  fuz => *easy, 
                  privmeth => sub { "private" },
                  easymeth => sub { die "to recurse or to die, is the question" },
		}, 
		$_[0]; 
}

sub easy { "gulp" }
sub easymeth {
  my $s = attr shift;  # localizes $foo, @bar, and %buz with hash values
  T(defined($s) and ref($s) eq 'Foo');
  T(defined (*fuz) and ref(\*fuz) eq ref(\*easy));
  print '#easy() is ', easy(), "\n";
  print '#fuz() is ', fuz(), "\n";
  T(easy() eq fuz());
  eval { $s->easymeth };       # should fail
  print "#\$\@ is: $@\n";
  T($@);
  join '|', $foo, @bar, %buz, $s->privmeth;
}
$foo = 6;
@bar = (7,8);
%buz = (b => 9);
T(Foo->new->easymeth eq '1|2|3|a|4|private');
T(join('|', $foo, @bar, %buz) eq '6|7|8|b|9');

eval { fuz() };   # the local subroutine shouldn't be here now
print "# after fuz(): $@";
T($@);

eval { Foo->new->privmeth };   # private method shouldn't exist either
print "# after Foo->new->privmeth: $@";
T($@);

package Bar;
*T = \&main::T;    

use Alias;

$Alias::KeyFilter = "_";
$Alias::AttrPrefix = "s";
$Alias::Deref = "";

sub new {
  my $s = { _foo => 1,
	    _bar => [2,3], 
	    buz => { a => 4}, 
	    fuz => *easy, 
	    _privmeth => sub { "private" },
	    _easymeth => sub { "recursion" },
	  };
  $s->{_this} = $s;
  return bless $s, $_[0]; 
}

sub easy { "gulp" }
sub s_easymeth {
  my $s = attr shift;  # localizes $s_foo, @s_bar, and %s_buz
  T($s and ref($s) eq 'Bar');
  print "# |$s_this|$s|\n";
  T(defined($s_this) and $s_this eq $s);
  T(not defined &fuz);
  T(not defined &s_fuz);
  T(not scalar (keys %s_buz));
  T($s->s_easymeth eq "recursion");
  join '|', $s_foo, @s_bar, %buz, $s->s_privmeth;
}

$s_foo = 6;
@s_bar = (7,8);
%s_buz = ();
%buz = (b => 9);
T(Bar->new->s_easymeth eq '1|2|3|b|9|private');
T(join('|', $s_foo, @s_bar) eq '6|7|8');

{
  local $Alias::Deref = 1;
  my $s = attr(Bar->new);
  T(!$s_this and \%s_this eq $s);
}

eval { Bar->new->s_privmeth };   # private method shouldn't exist either
print "# after Bar->new->s_privmeth: $@";
T($@);

package Baz;
*T = \&main::T;

use Alias;

$Alias::KeyFilter = sub {
                          local $_ = shift;
			  my($r) = (/^_.+_$/ ? 1 : 0);
			  print "# |$_, $r|\n";
			  return $r
			};
$Alias::AttrPrefix = sub {
                           local $_ = shift; s/^_(.+)_$/$1/;
			   return "s_$_" if /meth$/;
			   return "main::s_$_"
			 };
$Alias::Deref = sub { my($n, $v) = @_; ; my $r = $n ne "_this_"; print "# |$n, $v, $r|\n"; return $r};

sub new {
  my $s = bless { _foo_ => 1,
		  _bar_ => [2,3],
		  buz_ => { a => 4},
		  fuz_ => *easy,
		  _privmeth_ => sub { "private" },
		  _easymeth_ => sub { "recursion" },
		},
	        $_[0];
  $s->{_this_} = $s;
  $s->{_other_} = $s;
  return $s;
}

sub easy { "gulp" }
sub s_easymeth {
  my $s = attr shift;  # localizes $s_foo, @s_bar, and %s_buz
  print "# |", $::s_this, "|$s|\n";
  T($::s_this and $::s_this eq $s);
  print "# |", join(',', keys %::s_other),"|$s|\n";
  T(!$::s_other and \%::s_other eq $s);
  T(defined($s) and ref($s) eq 'Baz');
  T(not defined &::fuz_);
  T(not defined &::s_fuz);
  T(not %::s_buz);
  T($s->s_easymeth eq "recursion");
  join '|', $::s_foo, @::s_bar, %::buz_, $s->s_privmeth;
}

$::s_foo = 6;
@::s_bar = (7,8);
%::s_buz = ();
%::buz_ = (b => 9);
T(Baz->new->s_easymeth eq '1|2|3|b|9|private');
T(join('|', $::s_foo, @::s_bar) eq '6|7|8');

eval { Baz->new->s_privmeth };   # private method shouldn't exist either
print "# after Baz->new->s_privmeth: $@";
T($@);


__END__
