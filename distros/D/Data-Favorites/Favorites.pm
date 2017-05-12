# Data::Favorites - tally a data stream to find recently dominant items

#----------------------------------------------------------------------------
#
# Copyright (C) 1998-2003 Ed Halley
# http://www.halley.cc/ed/
#
#----------------------------------------------------------------------------

package Data::Favorites;
use vars qw($VERSION);
$VERSION = 1.00;

=head1 NAME

Data::Favorites - tally a data stream to find recently dominant items

=head1 SYNOPSIS

    use Data::Favorites;

    my $faves = new Data::Favorites();

    $faves->tally($_)
        foreach (@history);

    $faves->decay( 2 ); # everyone loses two points

    $faves->clamp( time() - 24*60*60 ); # cull everyone older than a day

    print join("\n", $faves->favorites( 5 )), "\n";

=head1 ABSTRACT

A Favorites structure tracks the disposition of various keys.  A key's
disposition is a measurement of its relative predominance and freshness
when tallied.  This is a good way to infer favorites or other
leadership-oriented facts from a historical data stream.

More specifically, this structure measures how often and when various
keys are triggered by application-defined events.  Those keys that are
mentioned often will accumulate a higher number of tally points.  Those
keys that have been mentioned recently will have newer "freshness"
stamps.  Both of these factors are metered and will affect their
positioning in a ranking of the keys.

At any time, keys can be culled by freshness or by their current ranking,
or both.  With these approaches, dispositions can be weighed over the
whole historical record, rather than providing a simplistic "top events
in the last N events" rolling count.  Thus, highly popular event keys may
remain in the set of favorites for some time, even when the key hasn't
been seen very often recently.  Popular items can be decayed gradually
rather than cut out of a simple census window.

=cut

#------------------------------------------------------------------

use warnings;
use strict;
use Carp;

#------------------------------------------------------------------

=head1 METHODS

=head2 new()

    $faves = new Data::Favorites( );

    $faves = new Data::Favorites( \&stamper );

Create a new favorites counter object.  The counter object can tally
given elements, and also stamp the "freshness" of each element with the
numerical return from the given stamper sub.  If no sub code reference is
given, then the C<time()> built-in function is assumed by default.  It is
assumed that the sub returns a number which generally increases in value
for fresher stamps.

=cut

# $faves = new Data::Favorites( );
#
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self =
    {
	# key => { tally => 1, stamp => 1 }
	dispositions => { },
    };
    $self->{stamper} = shift if ref $_[0];
    bless($self, $class);
    return $self;
}


=head2 tally()

    $times = $faves->tally( $scalar );

    $times = $faves->tally( $scalar, $times );

Return the current number of times the given C<$scalar> has been seen, or
increment that count by a given number of times.  The first form returns
C<undef> if the C<$scalar> has never been tallied.

Items are tracked by their string form, so if the scalars are perl
references, take note that the whole favorites counter will not persist
well.  A future version may use C<Tie::RefHash> to allow for persistable
tracking of object data.

Each key in the favorites counter is marked with a timestamp via the
C<time()> function, or the stamper sub reference given during creation of
the favorites counter object.  In the case of an application-supplied
stamper function, it will receive two arguments: this favorites counter
itself, and the given scalar being tallied.

=cut

# $count = $faves->tally( $scalar );
# $count = $faves->tally( $scalar, $times );
#
sub tally
{
    my $self = shift;
    my $item = shift;

    # $faves->tally() or $faves->tally(undef) are calling errors.
    #
    carp "Called tally() with an undef key" if not defined $item;

    # $faves->tally(key) returns current tally for given key.
    # Returns undef if the key doesn't exist.
    #
    my $disp = $self->{dispositions}{$item} || { };
    return if (not exists $disp->{tally}) and (not @_);
    return $disp->{tally} if not @_;

    # $faves->tally(key, amount) boosts current tally for given key.
    # The key is fully created with the given amount if it did not exist.
    # The key's freshness stamp is also updated.
    #
    my $tally = shift;
    $self->{dispositions}{$item} = $disp;
    $disp->{stamp} =
	$self->{stamper}?
	eval { &{$self->{stamper}}($self, $item) } :
	time();
    $disp->{tally} += $tally;
    return $disp->{tally};
}


=head2 fresh()

    $stamp = $faves->fresh( $scalar );

Return the current freshness stamp for the given C<$scalar>.  Returns
C<undef> if the C<$scalar> has never been tallied.

Each key in the favorites counter is marked with a timestamp via the
C<time()> function, or the stamper sub reference given during creation of
the favorites counter object.  In the case of an application-supplied
stamper callback, it will receive two arguments: this favorites counter
itself, and the given scalar being tallied.

=cut

# $stamp = $faves->fresh( $scalar );
#
sub fresh
{
    my $self = shift;
    my $item = shift;

    # $faves->fresh() or $faves->fresh(undef) are calling errors.
    #
    carp "Called fresh() with an undef key" if not defined $item;

    # $faves->fresh(key) returns current tally for given key.
    # Returns undef if the key doesn't exist.
    #
    my $disp = $self->{dispositions}{$item} || { };
    return $disp->{stamp} || undef;
}


=head2 decay()

    $count = $faves->decay( );
    $count = $faves->decay( $times );

    $times = $faves->decay( $scalar );
    $times = $faves->decay( $scalar, $times );

In the first pair of forms, all present keys have their tally counts
reduced by one, or by the given number of times.  In these forms, the
returned value is the remaining count of tracked favorite keys.

In the latter pair of forms, an individual key C<$scalar> has its tally
reduced by one, or by the given number of times.  These forms return the
remaining tally count for the given C<$scalar> key.

The favorites counter will automatically remove any key in which the
tally count drops to zero or below.

=cut

# $count = $faves->decay( );
# $count = $faves->decay( $times );
# $times = $faves->decay( $scalar );
# $times = $faves->decay( $scalar, $times );
#
sub decay
{
    my $self = shift;
    my $disp = $self->{dispositions};
    my $tally = 1;
    my $item;

    # $faves->decay(key) decays one key by 1 tally
    # $faves->decay(key, amount) decays one key by given amount
    #
    if (@_ && exists $disp->{$_[0]})
    {
	$item = shift;
	$tally = shift if @_;
	if (($disp->{$item}{tally} -= $tally) <= 0)
	{
	    delete $disp->{$item};
	    return;
	}
	return $disp->{$item}{tally};
    }

    # $faves->decay() decays all keys by 1 tally
    # $faves->decay(amount) decays all keys by given amount
    # Recurses to perform actual decay on each key.
    #
    $tally = shift if @_;
    foreach $item (keys %$disp)
    {
	$self->decay($item, $tally);
    }
    return scalar keys %$disp;
}


=head2 clamp()

    $count = $faves->clamp( $stamp );

Clamps the set of favorites to only the freshest tallied elements.  This
method automatically removes any key in which the most recent tally is
more stale than the given timestamp value.  Timestamps are assumed to be
numerical; lesser values represent stamps which are more stale, while
higher values are considered more fresh.

=cut

# $count = $faves->clamp( $stamp );
#
sub clamp
{
    my $self = shift;
    my $disp = $self->{dispositions};
    my $stamp = shift || 0;

    my @items = keys %$disp;
    while (@items)
    {
	my $item = shift @items;
	delete $disp->{$item}
	    if $disp->{$item}{stamp} < $stamp;
    }

    return scalar keys %$disp;
}


=head2 favorites()

    @topfaves = $faves->favorites( );
    @topfaves = $faves->favorites( $limit );
    $count = scalar $faves->favorites( );

Returns the keys sorted by the strength of their tally counts.  Those
which have equal tally counts are compared by their most recent tally
time; the most freshly stamped is favored.  If a limit is given, the list
returned will not exceed the given length.

In a scalar context, returns the current count of the tallied keys in the
favorites counter.  If no limit argument is given, then no internal
sorting work needs to be performed to return the count.

=cut

# @faves = $faves->favorites( );
# @faves = $faves->favorites( $limit );
# $count = scalar $faves->favorites( );
#
sub favorites
{
    my $self = shift;
    my $disp = $self->{dispositions};
    return scalar keys %$disp
        if (not @_) and (not wantarray);
    my @faves = sort
    {
	($disp->{$b}{tally} <=> $disp->{$a}{tally}) ||
	($disp->{$b}{stamp} <=> $disp->{$a}{stamp})
    } keys %{$disp};
    my $limit = shift || @faves;
    $#faves = $limit-1 if @faves > $limit;
    return @faves;
}

#------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

After creating a Data::Favorites object, the caller should tally the
identifying characteristics of an ongoing historical data stream.  This
could be error codes or connecting hostnames in a network log, usernames
in a chat conversation, or any other key-worthy feature of an ongoing
stream of events.  At any time, the most predominantly occurring keys can
be determined and ranked.

With Data::Favorites, a process can discover in real-time which objects
have been selected by a user the most often, or which objects have been
most responsible for event traffic.  The map can be culled occasionally,
keeping only the most fresh objects, or only the highest counted objects.
The data can be naturally decayed, leaving only the objects with overall
strongest dispositions.

For some examples, this structure can track the top ten favorite visited
websites, or chat partners, or document files, or network connections.
These can be inferred by looking at those entities with the strongest
dispositions, according to the way they are tallied over time.  As a
historically favorite entity is triggered more or less often, its ranking
would raise or drop in the list, making room or pushing out other
entities.

A Data::Favorites object can employ an application-defined stamp function
(a coderef) to mark the tallying process.  If no function is given, then
timestamps are applied with the usual C<time()> built-in function.

=head1 AUTHOR

Ed Halley, E<lt>ed@halley.ccE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2001-2003 by Ed Halley

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
