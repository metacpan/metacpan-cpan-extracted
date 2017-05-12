package Blatte::Builtins;

use strict;

BEGIN {
  @Blatte::Builtins::builtins = qw($acall $add $ameth $append $apply
                                   $aref $aset $concat $defined
                                   $divide $streq $flatten $foreach
                                   $funcall $numge $numgt $hashdel $hashkeys
                                   $hashp $hashref $hashset $hashtest
                                   $int $lc $lcfirst $numle $length $list
                                   $listp $numlt $match $max $min $mkhash
                                   $multiply $not $numeq $pop $push
                                   $random $require $use $scall $shift
                                   $smeth $split $sprintf $strge
                                   $strgt $strle $strlt $subseq $subst
                                   $substr $subtract $uc $ucfirst
                                   $unshift);
}

use vars (qw(@ISA @EXPORT), @Blatte::Builtins::builtins);

use Exporter;

@ISA = qw(Exporter);

@EXPORT = @Blatte::Builtins::builtins;

use Blatte qw(traverse true unwrapws flatten);

## Data types

$foreach = sub {
  my $fn = &unwrapws($_[1]);
  my @result = map { &$fn({}, &unwrapws($_)) } @{&unwrapws($_[2])};
  \@result;
};

$length = sub {
  my $obj = &unwrapws($_[1]);
  if (ref($obj) eq 'ARRAY') {   # xxx UNIVERSAL::isa ?
    return scalar(@$obj);
  }
  length($obj);
};

$listp = sub {
  ref(&unwrapws($_[1])) eq 'ARRAY'; # xxx UNIVERSAL::isa ?
};

$list = sub {
  if (@_ > 1) {
    [&unwrapws($_[1]), @_[2..$#_]];
  } else {
    [];
  }
};

$subseq = sub {
  my($list, $start) = (&unwrapws($_[1]), &unwrapws($_[2]));
  if ($start < 0) {
    $start += @$list;
  }
  my $len;
  if (@_ > 3) {
    $len = &unwrapws($_[3]);
  } else {
    $len = @$list - $start;
  }
  [@$list[$start .. $start + $len]];
};

$not = sub {
  !&true(&unwrapws($_[1]));
};

$defined = sub {
  defined(&unwrapws($_[1]));
};

## Array references

$aref = sub {
  &unwrapws($_[1])->[&unwrapws($_[2])];
};

$aset = sub {
  &unwrapws($_[1])->[&unwrapws($_[2])] = $_[3];
};

$push = sub {
  my $list = &unwrapws($_[1]);
  push(@$list, @_[2..$#_]);
  $list;
};

$pop = sub {
  pop(@{&unwrapws($_[1])});
};

$unshift = sub {
  my $list = &unwrapws($_[1]);
  unshift(@$list, @_[2..$#_]);
  $list;
};

$shift = sub {
  shift(@{&unwrapws($_[1])});
};

$append = sub {
  my $result = [];
  foreach my $l (@_[1..$#_]) {
    push(@$result, @$l);
  }
  $result;
};

## Hash references

$hashp = sub {
  ref(&unwrapws($_[1])) eq 'HASH'; # xxx UNIVERSAL::isa ?
};

$mkhash = sub {
  my $result = {};
  for (my $i = 1; $i <= $#_; $i += 2) {
    $result->{&unwrapws($_[$i])} = $_[$i + 1];
  }
  $result;
};

$hashref = sub {
  &unwrapws($_[1])->{&unwrapws($_[2])};
};

$hashset = sub {
  &unwrapws($_[1])->{&unwrapws($_[2])} = $_[3];
};

$hashdel = sub {
  delete &unwrapws($_[1])->{&unwrapws($_[2])};
};

$hashtest = sub {
  exists &unwrapws($_[1])->{&unwrapws($_[2])};
};

$hashkeys = sub {
  my @result = keys %{&unwrapws($_[1])};
  \@result;
};

## Perl function-calling interface

$acall = sub {
  my $name = &unwrapws($_[1]);
  my @result = &$name(@_[2..$#_]);
  \@result;
};

$scall = sub {
  my $name = &unwrapws($_[1]);
  scalar(&$name(@_[2..$#_]));
};

## Perl object interface

$ameth = sub {
  my $obj = &unwrapws($_[1]);
  my $meth = &unwrapws($_[2]);
  my @result = $obj->$meth(@_[3..$#_]);
  \@result;
};

$smeth = sub {
  my $obj = &unwrapws($_[1]);
  my $meth = &unwrapws($_[2]);
  scalar($obj->$meth(@_[3..$#_]));
};

## Arithmetic

$add = sub {
  my $result = 0;
  foreach my $num (@_[1..$#_]) {
    $result += &unwrapws($num);
  }
  $result;
};

$multiply = sub {
  my $result = 1;
  foreach my $num (@_[1..$#_]) {
    $result *= &unwrapws($num);
  }
  $result;
};

$subtract = sub {
  my $result = &unwrapws($_[1]);
  if (@_ > 2) {
    foreach my $num (@_[2..$#_]) {
      $result -= &unwrapws($num);
    }
  } else {
    $result = -$result;
  }
  $result;
};

$divide = sub {
  my $result = &unwrapws($_[1]);
  if (@_ > 2) {
    foreach my $num (@_[2..$#_]) {
      $result /= &unwrapws($num);
    }
  } else {
    $result = 1.0 / $result;
  }
  $result;
};

## Lisp-like primitives

$funcall = sub {
  my $sub = &unwrapws($_[1]);
  &$sub($_[0], @_[2..$#_]);
};

$apply = sub {
  my $sub = &unwrapws($_[1]);
  my @args = @_[2 .. ($#_ - 1)];
  if (@_ > 2) {
    my $last = $_[$#_];
    my $last_unwrapped = &unwrapws($last);
    if (ref($last_unwrapped) eq 'ARRAY') { # xxx UNIVERSAL::isa ?
      push(@args, @$last_unwrapped);
    } else {
      push(@args, $last);
    }
  }
  &$sub($_[0], @args);
};

## Strings

$flatten = sub {
  my $result = '';

  foreach my $obj (@_[1..$#_]) {
    $result .= &flatten($obj);
  }

  $result;
};

$uc = sub {
  uc(&unwrapws($_[1]));
};

$lc = sub {
  lc(&unwrapws($_[1]));
};

$ucfirst = sub {
  ucfirst(&unwrapws($_[1]));
};

$lcfirst = sub {
  lcfirst(&unwrapws($_[1]));
};

$concat = sub {
  my $result;
  foreach my $str (@_[1..$#_]) {
    $result .= &unwrapws($str);
  }
  $result;
};

$substr = sub {
  my $str = &unwrapws($_[1]);
  my $start = &unwrapws($_[2]);
  if ($#_ == 2) {
    return substr($str, $start);
  }
  my $len = &unwrapws($_[3]);
  if ($#_ == 3) {
    return substr($str, $start, $len);
  }
  substr($str, $start, $len, &unwrapws($_[4]));
};

$sprintf = sub {
  my $fmt = &unwrapws($_[1]);
  sprintf($fmt, map { &unwrapws($_) } @_[2 .. $#_]);
};

$streq = sub {
  my $first = &unwrapws($_[1]);
  for (my $i = 2; $i <= $#_; ++$i) {
    if ($first ne &unwrapws($_[$i])) {
      return undef;
    }
  }
  1;
};

$strlt = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n lt $m;
    $n = $m;
  }
  1;
};

$strle = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n le $m;
    $n = $m;
  }
  1;
};

$strgt = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n gt $m;
    $n = $m;
  }
  1;
};

$strge = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n ge $m;
    $n = $m;
  }
  1;
};

## Numbers

$random = sub {
  if ($#_ == 0) {
    return rand(1);
  }
  rand(&unwrapws($_[1]));
};

$int = sub {
  int(&unwrapws($_[$#_]));
};

$numeq = sub {
  my $first = &unwrapws($_[1]);
  for (my $i = 2; $i <= $#_; ++$i) {
    if ($first != &unwrapws($_[$i])) {
      return undef;
    }
  }
  1;
};

$max = sub {
  my $result = &unwrapws($_[1]);
  for (my $i = 2; $i <= $#_; ++$i) {
    my $n = &unwrapws($_[$i]);
    $result = $n if $n > $result;
  }
  $result;
};

$min = sub {
  my $result = &unwrapws($_[1]);
  for (my $i = 2; $i <= $#_; ++$i) {
    my $n = &unwrapws($_[$i]);
    $result = $n if $n < $result;
  }
  $result;
};

$numlt = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n < $m;
    $n = $m;
  }
  1;
};

$numle = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n <= $m;
    $n = $m;
  }
  1;
};

$numgt = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n > $m;
    $n = $m;
  }
  1;
};

$numge = sub {
  my $n = &unwrapws($_[1]);
  foreach my $m (@_[2..$#_]) {
    $m = &unwrapws($m);
    return undef unless $n >= $m;
    $n = $m;
  }
  1;
};

## Perl modules

$require = sub {
  require &unwrapws($_[1]);
};

$use = sub {
  shift;
  eval sprintf('use %s', &flatten(\@_, ''));
};

## Regular expressions

$match = sub {
  my $flags = $_[0]->{flags};
  my $str = &unwrapws($_[1]);
  my $regex = &unwrapws($_[2]);
  my @result = eval("\$str =~ /\$regex/$flags");
  \@result;
};

$subst = sub {
  my $flags = $_[0]->{flags};
  my $str = &unwrapws($_[1]);
  my $regex = &unwrapws($_[2]);
  my $replacement = &unwrapws($_[3]);
  eval("\$str =~ s/\$regex/\$replacement/$flags");
  $str;
};

$split = sub {
  my $flags = $_[0]->{flags};
  my $str = &unwrapws($_[1]);
  my $regex = &unwrapws($_[2]);
  if ($#_ == 2) {
    my @result = eval("split(/\$regex/$flags, \$str)");
    return \@result;
  }
  my $limit = &unwrapws($_[3]);
  my @result = eval("split(/\$regex/$flags, \$str, \$limit)");
  \@result;
};

1;

__END__

=head1 NAME

Blatte::Builtins - Blatte-callable intrinsics

=head1 SYNOPSIS

  package MyPackage;

  use Blatte::Builtins;

  eval(...compiled Blatte program...);

=head1 DESCRIPTION

This module defines the standard Blatte-callable intrinsic functions.

A Blatte intrinsic is simply a Perl subroutine that (a) has been
assigned (by reference) to a scalar variable (whose name begins with a
letter), and (b) takes a hash reference as its first argument, in
which named parameter values are passed.

=head1 INTRINSICS

=over 4

=item {\acall FUNCNAME ARG ...}

Calls Perl function FUNCNAME with given arguments in array context.
See also \scall.

=item {\add NUM ...}

Adds the given numbers.

=item {\ameth OBJ METHNAME ARG ...}

Calls the METHNAME method (i.e., member function) on the Perl object OBJ (a
blessed reference) with given arguments in array context.  See also \smeth.

=item {\append LIST ...}

Given one or more lists, combines their top-level elements into a
single list.

=item {\apply FN ARG1 ARG2 ... ARGn}

Calls Blatte function FN on given arguments.  If ARGn is a list, then
it's interpreted as a list of arguments.  (Use \funcall if you don't
want this behavior.)

Any named parameters passed to \apply are passed along to FN.

=item {\aref LIST N}

Returns the Nth element of LIST.  LIST is a Blatte list (which is
really a Perl ARRAY reference).  N is 0-based.

=item {\aset LIST N VAL}

Sets the Nth element of LIST to VAL.

=item {\concat STR1 STR2 ...}

Concatenates the given strings.

=item {\defined VAL}

True iff VAL is a defined value (in the Perl sense).

=item {\divide N1 N2 ...}

Divides its arguments.  If there's only one, returns its
multiplicative inverse.

=item {\flatten OBJ1 OBJ2 ...}

Renders each OBJ as a string and concatenates them.

=item {\foreach FN LIST}

Returns a list resulting from calling FN on each member of LIST.

=item {\funcall FN ARG1 ARG2 ...}

Calls Blatte function FN on the given arguments.

Any named parameters passed to \apply are passed along to FN.

=item {\hashdel HASH KEY}

Deletes from HASH the entry with the given key.  HASH is a Blatte hash
(which is a Perl hash references).

=item {\hashkeys HASH}

Returns the keys of HASH, a Blatte hash, in a Blatte list.

=item {\hashp OBJ}

True iff OBJ is a Blatte hash.

=item {\hashref HASH KEY}

Returns the element of HASH whose key is KEY.

=item {\hashset HASH KEY VALUE}

Sets the entry in HASH with key KEY to the given value.

=item {\hashtest HASH KEY}

True iff HASH contains an element with the given key.

=item {\int NUM}

Returns the integer portion of NUM.

=item {\lc STR}

Converts all letters in STR to lowercase.

=item {\lcfirst STR}

Converts the first letter of STR to lowercase.

=item {\length OBJ}

Returns of length of OBJ -- in elements, if OBJ is a list, or in
characters, if OBJ is a string.

=item {\list ARG1 ARG2 ...}

Makes a Blatte list out of the given arguments.

=item {\listp OBJ}

True iff OBJ is a Blatte list.

=item {\match [\flags=cgimosx] STR REGEX}

True if STR contains a match for the Perl regular expression REGEX.
The optional flag letters correspond to Perl's regular expression
flags.  If REGEX includes parenthesized subexpressions, the return
value is a list of the matched strings, otherwise it's the list {1}.

Blatte implements this by performing a Perl regex match in array
context.  This means you can't use the C<g> flag in scalar mode, which
is a bit of a drag.

=item {\max N1 N2 ...}

Returns the numerically largest argument.

=item {\min N1 N2 ...}

Returns the numerically smallest argument.

=item {\mkhash [KEY1 VAL1 KEY2 VAL2 ...]}

Makes a new Blatte hash (a Perl HASH reference), initializing it with
the optional key-value pairs.

=item {\multiply N1 N2 ...}

Multiplies its arguments.

=item {\not VAL}

Negates the truth value of VAL.

=item {\numeq N1 N2 ...}

True iff all arguments are numerically equal.

=item {\numge N1 N2 ...}

True iff N1 >= N2 >= ... (monotonically non-increasing).

=item {\numgt N1 N2 ...}

True if N1 > N2 > ... (monotonically decreasing).

=item {\numle N1 N2 ...}

True if N1 <= N2 <= ... (monotonically non-decreasing).

=item {\numlt N1 N2 ...}

True if N1 < N2 < ... (monotonically increasing).

=item {\pop LIST}

Removes the last element from LIST and return it.

=item {\push LIST OBJ1 OBJ2 ...}

Adds the given OBJs to the end of LIST.

=item {\random [N]}

Returns a random integer from 0 to N-1.  If N is omitted, returns a
random floating-point number in [0, 1).

=item {\require MODULE}

Does a Perl C<require>.

=item {\scall FUNCNAME ARG ...}

Calls Perl function FUNCNAME with given arguments in scalar context.
See also \acall.

=item {\shift LIST}

Removes the first element of LIST and returns it.

=item {\smeth OBJ METHNAME ARG ...}

Calls the METHNAME method (i.e., member function) on the Perl object OBJ (a
blessed reference) with given arguments in scalar context.  See also \ameth.

=item {\split [\flags=cgimosx] STR REGEX [LIMIT]}

Calls Perl's C<split> function, splitting STR at occurrences of REGEX
into a Blatte list, which is returned.  If optional LIMIT is supplied,
the result will have no more than that many elements.  The optional
\flags argument is the same as in \match.

=item {\sprintf FORMAT ARG ...}

Constructs a string out of the given C<sprintf> format and arguments.

=item {\streq S1 S2 ...}

True if S1, S2, etc. are identical strings.

=item {\strge S1 S2 ...}

True iff S1 ge S2 ge ...

=item {\strgt S1 S2 ...}

True iff S1 gt S2 gt ...

=item {\strle S1 S2 ...}

True iff S1 le S2 le ...

=item {\strlt S1 S2 ...}

True iff S1 lt S2 lt ...

=item {\subseq LIST START [LEN]}

Extracts a sublist from LIST beginning at START, LEN elements long.

If START is negative, counts backward from the end of LIST.

If LEN is omitted, all elements to the end of LIST are included.

=item {\subst [\flags=egimosx] STR REGEX REPLACEMENT}

Replaces matches in STR for REGEX with REPLACEMENT.  The optional
flags, and the syntax of REGEX and REPLACEMENT, are as in Perl's s///
operator.

Unlike Perl, STR is not modified in place.  Instead, the modified
string is returned.

=item {\substr STR START [LEN]}

Extracts a substring from STR beginning at START, LEN characters long.

If START is negative, counts backward from the end of STR.

If LEN is omitted, all characters to the end of STR are included.

=item {\subtract N1 N2 ...}

Subtracts its second and subsequent arguments from its first one.  If
only one argument is given, returns its additive inverse.

=item {\uc STR}

Converts all letters in STR to uppercase.

=item {\ucfirst STR}

Converts the first letter in STR to uppercase.

=item {\unshift LIST OBJ1 OBJ2 ...}

Adds the given OBJs to the beginning of LIST.

=item {\use MODULE}

Does a Perl C<use>.

=back

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the Blatte
distribution.

=head1 SEE ALSO

L<Blatte(3)>.
