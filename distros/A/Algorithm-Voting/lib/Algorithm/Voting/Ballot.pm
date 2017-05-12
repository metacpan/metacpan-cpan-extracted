# $Id: Ballot.pm 60 2008-09-02 12:11:49Z johntrammell $
# $URL: https://algorithm-voting.googlecode.com/svn/tags/rel-0.01-1/lib/Algorithm/Voting/Ballot.pm $

package Algorithm::Voting::Ballot;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Params::Validate 'validate';

__PACKAGE__->mk_accessors(qw/ candidate /);

=pod

=head1 NAME

Algorithm::Voting::Ballot - represents a ballot to cast in a race

=head1 SYNOPSIS

    use Algorithm::Voting::Ballot;
    my $ballot = Algorithm::Voting::Ballot->new('Pedro');

Or equivalently:

    use Algorithm::Voting::Ballot;
    my $ballot = Algorithm::Voting::Ballot->new(candidate => 'Pedro');

=head1 DESCRIPTION

Instances of this class contain the information specified on a ballot.  Expect
this class to gain complexity as more complicated voting systems (e.g. IRV,
Condorcet) are implemented.

=head1 METHODS

=head2 Algorithm::Voting::Ballot->new()

Constructs a new ballot object.  Currently only suitable for indicating a
single candidate, e.g. for Plurality ballots.

    # vote for Pedro
    my $ballot = Algorithm::Voting::Ballot->new('Pedro')

=cut

sub new {
    my $class = shift;
    if (@_ == 1) {
        return $class->new(candidate => $_[0]);
    }
    my %valid = (
        candidate => 0,
    );
    my %args = validate(@_, \%valid);
    return bless \%args, $class;
}

=head2 $ballot->candidate()

Returns a scalar (presumably a string, although this is not enforced)
containing the candidate for whom this ballot is cast.

=cut

1;

