package Acme::Signature::Arity;
# ABSTRACT: find out how a piece of code expects to be called

use strict;
use warnings;

our $VERSION = '0.003';
our $AUTHORITY;

use B;
use List::Util qw(min);
use experimental qw(signatures);

use parent qw(Exporter);

=head1 NAME

Acme::Signature::Arity - provides reliable, production-ready signature introspection

=head1 DESCRIPTION

You'll know if you need this.

If you're just curious, perhaps start with L<https://www.nntp.perl.org/group/perl.perl5.porters/2021/11/msg262009.html>.

No part of this is expected to work in any way when given a sub that has a prototype.
There are other tools for those: L<Sub::Util>.

For subs that don't have a prototype, this is I<also> not expected to work. It might help
demonstrate where to look if you wanted to write something proper, though.

=cut

our @EXPORT_OK = qw(arity min_arity max_arity coderef_ignoring_extra);
our @EXPORT = qw(min_arity max_arity);

=head1 Exported functions

=head2 arity

Returns the C<UNOP_aux> details for the first opcode for a coderef CV.
If that code uses signatures, this might give you some internal details
which mean something about the expected parameters.

Expected return information, as a list:

=over 4

=item * number of required scalar parameters

=item * number of optional scalar parameters (probably because there are defaults)

=item * a character representing the slurping behaviour, might be '@' or '%', or nothing (undef?) if it's
just a fixed list of scalar parameters

=back

This can also throw exceptions. That should only happen if you give it something that isn't
a coderef, or if internals change enough that the entirely-unjustified assumptions made by
this module are somehow no longer valid. Maybe they never were in the first place.

=cut

sub arity ($code) {
    die 'only works on coderefs' unless ref($code) eq 'CODE';
    my $cv = B::svref_2object($code);
    die 'probably not a coderef' unless $cv->isa('B::CV');
    my $next = $cv->START->next;
    # we pretend sub { } is sub (@) { }, for convenience
    return (0, 0, '@') unless $next and $next->isa('B::UNOP_AUX');
    return $next->aux_list($cv);
}

=head2 max_arity

Takes a coderef, returns a number or C<undef>.

If the code uses signatures, this tells you how many parameters you could
pass when calling before it complains - C<undef> means unlimited.

Should also work when there are no signatures, just gives C<undef> again.

=cut

sub max_arity ($code) {
    my ($scalars, $optional, $slurp) = arity($code);
    return undef if $slurp;
    return $scalars
}

=head2 min_arity

Takes a coderef, returns a number or C<undef>.

If the code uses signatures, this tells you how many parameters you need to
pass when calling - 0 means that no parameters are required.

Should also work when there are no signatures, returning 0 in that case.

=cut

sub min_arity ($code) {
    my ($scalars, $optional, $slurp) = arity($code);
    return $scalars - $optional;
}

=head2 coderef_ignoring_extra

Given a coderef, returns a coderef (either the original or wrapped)
which won't complain if you try to pass more parameters than it was expecting.

This is intended for library authors in situations like this:

 $useful_library->each(sub ($item) { say "item here: $item" });

where you later want to add optional new parameters, and don't trust your users
to include the mandatory C<< , @ >> signature definition that indicates excess
parameters can be dropped.

Usage - let's say your first library version looked like this:

 sub each ($self, $callback) {
  my $code = $callback;
  for my $item ($self->{items}->@*) {
   $code->($item);
  }
 }

and you later want to pass the index as an extra parameter, without breaking existing code
that assumed there would only ever be one callback parameter...

 sub each ($self, $callback) {
  my $code = coderef_ignoring_extra($callback);
  for my $idx (0..$#{$self->{items}}) {
   $code->($self->{items}{$idx}, $idx);
  }
 }

Your library is now at least somewhat backwards-compatible, without sacrificing too
many signature-related arity checking features: code expecting the new version
will still complain if required parameters are not provided.

=cut

sub coderef_ignoring_extra ($code) {
    my ($scalars, $optional, $slurp) = arity($code);
    # If we're accepting unlimited parameters, no need to do any more work
    return $code if $slurp;

    my $max_index = $scalars - 1;
    return sub (@args) {
        # Some parameters may be optional, so we allow shorter lists as well
        $code->(@args ? @args[0 .. min($#args, $max_index)] : ());
    }
}

1;

__END__

=head1 AUTHOR

C<< TEAM@cpan.org >>

=head1 WARRANTY

None, it's an Acme module, you shouldn't even be reading this.

