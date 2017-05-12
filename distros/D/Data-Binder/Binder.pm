# Data::Binder - a map of keys to potential values for simple unification

#----------------------------------------------------------------------------
#
# Copyright (C) 1998-2003 Ed Halley
# http://www.halley.cc/ed/
#
#----------------------------------------------------------------------------

package Data::Binder;
use vars qw($VERSION);
$VERSION = 1.00;

=head1 NAME

Data::Binder - a map of keys to potential values for simple unification

=head1 SYNOPSIS

    $binder = new Data::Binder(city => 'Denver', altitude => 5280);
    if ($binder->bindable(city => 'Denver', population => 2000000))
        { ... }
    if ($binder->bind(city => 'Dallas', altitude => 750))
        { ... }
    if ($binder->bound())
        { ... }

=head1 ABSTRACT

A Binder is a special map of keys to potential values; it supports
non-conflicting unification against other Binders or terms.  Each key
term in the Binder may be unbound (associated with an undef value), or
bound to a defined scalar value.  Unbound keys may be bound to anything,
and bound keys may only be bound to identical values.  Attempts to bind a
new set of values succeeds completely or fails without changes.

Binders are useful in unifying a simple set of arguments to values, such
as in languages like Prolog.  Bind any lowercase arguments to themselves,
and uppercase "variable" arguments to the caller's values.  If that is
not successful, then the rule is inappropriate.

They are also useful when a number of multi-faceted objects or strategies
need to be tested against a single opportunity, but the available facets
for each object or strategy are not always the same.  Describe the facets
with a hash, and the opportunity with a binder; inappropriate facet
values will fail the unification.

=cut

#----------------------------------------------------------------------------

use warnings;
use strict;
use Carp;

#----------------------------------------------------------------------------

# $terms = $binder->_terms();
# Returns a clone of the current set of terms and values for this binder.
# Used internally to support atomicity in successful binding operations.
#
sub _terms
{
    my $self = shift;
    my $binding = { };
    $binding->{$_} = $self->{terms}{$_} foreach (keys %{$self->{terms}});
    return $binding;
}

=head1 METHODS

=head2 new()

    my $binder = new Data::Binder(city => 'Denver', altitude => 5280);

Create a new binder, optionally with any number of key-value
associations.  Values may be C<undef>, which indicate that the key is
present but unbound.

=cut

# $binder = new Data::Binder( 'key' => value, ... );
#
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = { terms => { } };
    bless $self, $class;
    $self->put(@_) if @_;
    return $self;
}

=head2 put()

    $binder->put(population => undef);

Forcefully assert new key-value associations into the binder.  Replaces
any existing value with the given value.  Values may be C<undef>, which
indicate that the key is present but unbound.

=cut

# $binder->put( 'key' => value, ... );
#
sub put
{
    my $self = shift;
    carp "arguments not even for term => value pairs" if (@_ % 2);
    while (@_ >= 2)
    {
	my ($term, $value) = (shift, shift);
	$self->{terms}{$term} = $value;
    }
    return $self;
}

=head2 bindable()

    if ( $binder->bindable( city => 'Denver', $another_binder, ... ) )
        { ... }

Check whether all arguments are compatible with existing values in the
binder.  If given another binder reference, that binder's key-value pairs
are tested in an arbitrary order.  Everything else is assumed to be
key-value pairs, and the pairs are tested in the order given; specifying
the least likely bindable pairs first is a useful optimization.

Our C<< term => undef >> can bind with any given C<< term => undef >>.

Our C<< term => undef >> can bind with any given C<< term => value >>.

Our C<< term => value >> can bind with any B<equal> given C<< term => value >>.

Our C<< term => value >> cannot bind with a given C<< term => different >>.

If any argument is unbindable, the returned value is C<undef>.  If all
arguments are bindable to this binder's pairs, the returned value is not
C<undef>.  In no case is any binder actually modified at any time.

=cut

# $bool = $binder->bindable( term => value, ... );
# $bool = $binder->bindable( $other_binder, ... );
#
sub bindable
{
    my $self = shift;
    my $binding = $self->_terms();
    while (@_)
    {
	if (ref $_[0] and ref $_[0]->{terms})
	{
	    my $other = shift;
	    unshift(@_, %{$other->{terms}});
	}
	carp "arguments not even for term => value pairs" if (@_ < 2);
	my ($term, $value) = (shift, shift);
	if (not exists $binding->{$term})
	{ $binding->{$term} = $value; }
	elsif (not defined $binding->{$term})
	{ $binding->{$term} = $value; }
	elsif (ref $value and $binding->{$term} != $value)
	{ return undef; }
	elsif (not ref $value and $binding->{$term} ne $value)
	{ return undef; }
    }
    return $binding;
}

=head2 bind()

    if ( $binder->bind( city => 'Denver', $another_binder, ... ) )
        { ... }

Just as with C<< $binder->bindable( ... ) >>, try to bind all arguments
to this binder's current key-value pairs.

If any argument is unbindable, the returned value is C<undef>, and this
binder is left unmodified.  If all arguments are bindable to this
binder's pairs, the returned value is not C<undef>, and I<all> given
key-value pairs are asserted into this binder.

=cut

# $bool = $binder->bind( term => value, ... );
#
sub bind
{
    my $self = shift;
    carp "arguments not even for term => value pairs" if (@_ % 2);
    my $binding = $self->bindable(@_);
    return undef if not $binding;
    $self->{terms} = $binding;
    return $self;
}

# $bool = $binder->bound( );
# $bool = $binder->bound( $term );
#
sub bound
{
    my $self = shift;
    my $terms = $self->{terms};
    @_ = (keys %$terms) if not @_;
    foreach (@_)
    { return undef if not defined $terms->{$_}; }
    return $self;
}

#----------------------------------------------------------------------------

1;
__END__

=head1 DESCRIPTION

A Binder internally keeps a hash for its terms, but limits the access to
the main methods only.  Just as with any Perl hash, any string can be a
key, and keys are compared only by exact matches. All keys are unique in
the Binder, but data values can be non-unique.

Keys may be associated with the C<undef> data value, which for a Binder
means that the key is declared but not bound to a given value. Such keys
must be forced with C<put()> or added in the initial C<new()>, as the
binding methods will not import new undef values.

If we adopt the hash notation of C<< {K1=>D1, K2=>D2} >> to refer to
Binders, we can describe the ways that Binders operate with a few
examples. The K1 and K2 are the map's keys, and the D1 and D2 are the
associated data values, respectively. We borrow the binding operator
(C<=~>) just to illustrate these examples. Both operands to this operator
are Binders. The left-hand operand (the Binder object) may be modified,
but the right-hand operand (passed as an argument) is never altered.

    {CITY=>undef, ALTITUDE=>undef} =~ {CITY=>"Denver", ALTITUDE=>5280}
    # Binds the CITY term to the new value "Denver", and ALTITUDE
    # to the new value 5280; the result leaves the left binder
    # identical to the right binder, with a true return value.

    {CITY=>undef, ALTITUDE=>undef} =~ {CITY=>"Denver"}
    # Binds just the CITY term to the new value "Denver"; the result
    # replaces just the old value of CITY in the left binder, with a
    # true return value.

    {CITY=>"Denver", ALTITUDE=>undef} =~ {CITY=>"Denver"}
    # Validates the existing binding of CITY to its value "Denver";
    # result leaves everything unmodified, with a true return value.

    {CITY=>"Denver", ALTITUDE=>5280} =~ {CITY=>"Denver", POP=>2000000)}
    # Validates the existing CITY value and adds a new POP term;
    # the result adds POP=>2000000 to the left binder,
    # with a true return value.

    {CITY=>"Dallas", ALTITUDE=>undef} =~ {CITY=>"Denver"}
    # Cannot bind any terms because the CITY terms conflict; the result
    # leaves everything unmodified, with an undef return value.

The whole binding operation either passes atomically, returning an
arbitrary defined "true" value overall, or it fails, returning
C<undef>. If any term in a Binder fails to bind, then none of the
elements are modified and an undef return is given. Only if all the terms
could bind without conflict, then all the terms will be bound
accordingly.

If data values are references, then they are compared only as identical
references to a single entity.  There is no provision for "deep
comparison" of reference scalars.

=head1 AUTHOR

Ed Halley, E<lt>ed@halley.ccE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 1998-2003 by Ed Halley

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

