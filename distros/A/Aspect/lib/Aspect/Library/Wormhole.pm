package Aspect::Library::Wormhole;

use strict;
use Aspect::Modular         ();
use Aspect::Advice::Before  ();
use Aspect::Pointcut::And   ();
use Aspect::Pointcut::Call  ();
use Aspect::Pointcut::Cflow ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Modular';

sub get_advice {
	my $self = shift;
	Aspect::Advice::Before->new(
		lexical  => $self->lexical,
		pointcut => Aspect::Pointcut::And->new(
			Aspect::Pointcut::Call->new( $_[1] ),
			Aspect::Pointcut::Cflow->new( source => $_[0] ),
		),
		code => sub {
			$_->args( $_->args, $_->source->self );
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Wormhole - A wormhole between call frames

=head1 SYNOPSIS

  package A;
  sub new { bless {}, shift }
  sub a { B->new->b }
  
  package B;
  sub new { bless {}, shift }
  sub b { C->new->c }
  
  package C;
  sub new { bless {}, shift }
  sub c { ref pop }
  
  package main;
  
  print ref A->new->a; # without aspect, prints C
  
  use Aspect::Library::Wormhole;
  aspect Wormhole => 'A::a', 'C::c';
  print ref A->new->a; # with aspect, prints A

=head1 DESCRIPTION

A reusable aspect for passing objects down a call flow, without adding
extra arguments to the frames between the source and the target. It is a
tool for acquiring implicit context.

Suppose C<A::a()> calls C<B::b()> calls C<C::c()>... until C<Z::z()>.

All is well, until one day you get a requirement with a crosscutting
implication- C<Z::Z()> requires one extra argument. It requires an
instance of the class C<A>. The very same instance on which the method
C<a()> was called, high up the call chain of C<Z::z()>.

Without this aspect you can either add a global C<$Current_A> (very
problematic), or make C<A::a()> send C<B::b()> its C<$self>, make
C<B::b()> pass it on to C<C::c()>, and so on until C<Z::z()>. You are
forced to add many arguments to many methods.

Show me a developer who has never encountered this situation: you need
to add an argument to a long call flow, just because someone at the
bottom needs it, yet only someone on the top has it. The monkey code
required I<on each call frame> in the call flow, I<for each argument>
that I<each target> requires, is suffering from B<EEK>- Extraneous
Embedded Knowledge (L<http://citeseer.ist.psu.edu/254612.html>).

The code for the frames between the two ends of the wormhole, knows more
about the world than it should. This extraneous knowledge is embedded in
each method on the call flow, and there is no easy way to remove it.

This aspect removes the EEK by allowing you to setup a wormhole between
the source and target frames in the call flow. The only effect the
wormhole has on the call flow, is that the target gets called with one
extra argument: the calling source object. Thus the target acquires
implicit context.

So this wormhole:

  aspect Wormhole => 'A::a', 'Z::z';

Means: before the method C<Z::z()> is called, I<if> C<A::a()> exists in
the call flow, I<then> append one argument to the argument list of
C<Z::z()>. The argument appended is the calling C<A> object.

No method in the call flow is required to pass the source object, but
C<Z::z()> will still receive it.

  +--------+                                       +--------+
  | source |    +--------+    +--------+           | target |
  +--------+--> | B::b() |--> | C::c() |--> ...--> +--------+
  | A::a() |    +--------+    +--------+           | Z::z() |
  +--------+                                       +--------+
      .                                                ,
      |                                               /|\
      |                                              / | \
      |                                                |
      +------------- The Bajoran Wormhole -------------+

=head1 USING

The aspect constructor takes two pointcut specs, a source and a target.
The spec can be a string (full sub name), a regex (sub will match if
rexep matches), or a coderef (called with sub name, will match if returns
true).

For example, this will append a calling C<Printer> to any call to a sub
defined on C<Page>, if it is in the call flow of C<Printer::print>:

  aspect Wormhole => 'Printer::Print', qr/^Page::/;

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
