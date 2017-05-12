# $Id: Plurality.pm 60 2008-09-02 12:11:49Z johntrammell $
# $URL: https://algorithm-voting.googlecode.com/svn/tags/rel-0.01-1/lib/Algorithm/Voting/Plurality.pm $

package Algorithm::Voting::Plurality;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
use List::Util 'sum';
use Params::Validate qw/ validate validate_pos ARRAYREF /;

__PACKAGE__->mk_accessors(qw/ tally /);

=pod

=head1 NAME

Algorithm::Voting::Plurality - use "Plurality" to decide the sole winner

=head1 SYNOPSIS

    # construct a "ballot box"
    use Algorithm::Voting::Ballot;
    use Algorithm::Voting::Plurality;
    my $box = Algorithm::Voting::Plurality->new();

    # add ballots to the box
    $box->add( Algorithm::Voting::Ballot->new('Ralph') );
    $box->add( Algorithm::Voting::Ballot->new('Fred') );
    # ... 
    $box->add( Algorithm::Voting::Ballot->new('Ralph') );

    # and print the result
    print $box->as_string;

=head1 DESCRIPTION

From L<http://en.wikipedia.org/wiki/Plurality_voting_system>:

=over 4

The plurality voting system is a single-winner voting system often used to
elect executive officers or to elect members of a legislative assembly which is
based on single-member constituencies.

The most common system, used in Canada, India, the UK, and the USA, is simple
plurality, first past the post or winner-takes-all, a voting system in which a
single winner is chosen in a given constituency by having more votes than any
other individual representative.

=back

And from L<http://en.wikipedia.org/wiki/Plurality>:

=over 4

In voting, a plurality vote is the largest number of votes to be given any
candidate or proposition when three or more choices are possible. The candidate
or proposition receiving the largest number of votes has a plurality. The
concept of "plurality" in voting can be contrasted with the concept of
"majority". Majority is "more than half". Combining these two concepts in a
sentence makes it clearer, "A plurality of votes is a total vote received by a
candidate greater than that received by any opponent but less than a majority
of the vote."

=back

=head1 METHODS

=head2 Algorithm::Voting::Plurality->new(%args)

Constructs a "ballot box" object that will use the Plurality criterion to
decide the winner.  Optionally, specify a list of candidates; any ballot added
to the box that does not indicate one of the listed candidates throws an
exception.

Example:

    # construct a ballot box that accepts only three candidates
    my @c = qw( John Barack Ralph );
    my $box = Algorithm::Voting::Plurality->new(candidates => \@c);

=cut

sub new {
    my $class = shift;
    my %valid = (
        candidates => { type => ARRAYREF, optional => 1 },
    );
    my %args = validate(@_, \%valid);
    my $self = bless \%args, $class;
    $self->tally({});
    return $self;
}

=head2 $box->candidates

Returns a list containing the candidate names used in the construction of the
ballot box.  If no candidates were specified at construction of the box, the
empty list is returned.

=cut

sub candidates {
    my $self = shift;
    if ($self->{candidates}) {
        return @{ $self->{candidates} };
    }
    return ();
}

=head2 $box->add($ballot)

Add C<$ballot> to the box.  C<$ballot> can be any object that we can call
method C<candidate()> on.

=cut

sub add {
    my $self = shift;
    my %valid = ( can => [ 'candidate' ], );
    my ($ballot) = validate_pos(@_, \%valid);
    $self->validate_ballot($ballot);
    $self->increment_tally($ballot->candidate);
    return $self->count;
}

=head2 $box->increment_tally($candidate)

Increments the tally for C<$candidate> by 1.

=cut

sub increment_tally {
    my ($self, $candidate) = @_;
    $self->tally->{$candidate} += 1;
    return $self->tally->{$candidate};
}

=head2 $box->validate_ballot($ballot)

If this election is limited to a specific list of candidates, this method will
C<die()> if the candidate on C<$ballot> is not one of them.

=cut

sub validate_ballot {
    my ($self, $ballot) = @_;
    # if this ballot box has a list of "valid" candidates, verify that the
    # candidate on this ballot is one of them.
    if ($self->candidates) {
        unless (grep { $_ eq $ballot->candidate } $self->candidates) {
            die "Invalid ballot: candidate '@{[ $ballot->candidate ]}'",
                " is not on the candidate list";
        }
    }
}

=head2 count

Returns the total number of ballots cast so far.

=cut

sub count {
    my $self = shift;
    return sum values %{ $self->tally() };
}

=head2 result

The result is a "digested" version of the ballot tally, ordered by the number
of ballots cast for a candidate.

This method returns a list of arrayrefs, each of the form C<[$n, @candidates]>,
and sorted by decreasing C<$n>.  Candidates "tied" with the same number of
votes are lumped together.

For example, an election with three candidates A, B, and C, getting 100, 200,
and 100 votes respectively, would generate a result structure like this:

    [
        [ 200, "B" ],
        [ 100, "A", "C" ],
    ]

=cut

sub result {
    my $self = shift;
    # %rev is a "reverse" hash, in the sense that the key is the number of
    # votes, and the value is an arrayref containing the candidates who got
    # that number of votes.
    my %rev;
    foreach my $cand (keys %{ $self->tally }) {
        my $votes = $self->tally->{$cand};
        push @{ $rev{$votes} }, $cand;
    }
    return
        map { [ $_, @{$rev{$_}} ] }
        sort { $b <=> $a } keys %rev;
}

=head2 $box->as_string

Returns a string containing the election results.

=cut

sub as_string {
    my $self = shift;
    my $pos = 0;
    my $count = $self->count;
    my $string;
    foreach my $r ($self->result) {
        $pos++;
        my ($n, @cand) = @$r;
        my $pct = sprintf '%.2f%%', 100 * $n / $count;
        $string .= sprintf "%3d: ", $pos;
        $string .= "@cand, $n votes ($pct)\n";
    }
    return $string;
}

1;

