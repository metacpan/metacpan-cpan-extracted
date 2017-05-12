package Attribute::Curried;

use 5.006;
use strict;
use Attribute::Handlers;

our $VERSION = '0.02';


sub UNIVERSAL::Curry :ATTR(CODE) {
    my ($package, $symbol, $code, $name, $n) = @_;
    $n = $n->[0] if ref $n;
    local($^W) = 0;
    no strict 'refs';
    my $subname = $package . '::' . *{$symbol}{NAME};

    if ($symbol eq 'ANON') {
 	return;
    }
    unless (defined($n) && $n > 1) {
	warn "Usage: \"sub $subname :Curry(ARGS)\", ARGS > 1";
	return;
    }
    undef *{$subname};	# to quiet warnings about prototypes
    *{$subname} = _curry($n, $code);
}

sub _curry {
    my ($n, $func, @args) = @_;
    return sub {
	my $narg = @_ + @args;
	if ($narg > $n) {
 	    die "$narg args to curried function (expects $n).";
	} elsif ($narg < $n) {
 	    return _curry($n, $func, @args, @_);
	} else {
 	    return &$func(@args, @_);
	}
    }
}

1;
__END__


=head1 NAME

Attribute::Curried -- Functional goodness for Perl.

=head1 SYNOPSIS

  use Attribute::Curried;

  sub bracket :Curry(3) {
      $_[1].$_[0].$_[2]
  }

  sub flip :Curry(3) {
      &{$_[0]}(@_[2,1]);
  }

  my @xs = map { bracket $_ } 1..3;
  my $i = 0;
  my @ys = map { ++$i == 2 ? $_ : flip $_ } @xs;
  print join(', ', map { &$_('<', '>') } @ys), "\n";
  # prints '>1<, <2>, >3<'

=head1 DESCRIPTION

Currying is a powerful technique familiar to programmers in functional
languages like Lisp and Haskell.  When called with less arguments than
it needs, a curried function will return a new function that
"remembers" the arguments passed so far, i.e. a closure.  Once the
function has enough arguments, it will perform its operation and
return a value.

The typical Scheme example is something like this:

  (define add (lambda (a) (lambda (b) (+ a b))))
  (define add2 (add 2))
  (map add2 (list 1 2 3))
  ;; => (list 3 4 5)

Using C<Attribute::Curried>, the Perl equivalent looks like this:

  sub add :Curry(2) { $_[0] + $_[1] }
  *add2 = add(2);
  map { add2($_) } 1..3;
  # => (3, 4, 5)

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

Bug reports welcome, patches even more welcome.

=head1 COPYRIGHT

Copyright (C) 2002, 2009 Sean O'Rourke.  All rights reserved, some
wrongs reversed.  This module is distributed under the same terms as
Perl itself.  Let me know if you actually find it useful.
