package Algorithm::Paxos::Role::Acceptor;
{
  $Algorithm::Paxos::Role::Acceptor::VERSION = '0.001';
}
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: An Acceptor role for the Paxos algorithm

use Algorithm::Paxos::Exception;

has [qw(last_prepared_id last_accepted_id)] => (
    isa     => 'Str',
    is      => 'rw',
    default => 0
);

has learners => (
    isa     => 'ArrayRef',
    writer  => '_set_learners',
    traits  => ['Array'],
    default => sub { [] },
    handles => { learners => 'elements', }
);

sub _latest_proposal {
    my $self = shift;
    my ($learner) = $self->learners;
    $learner->latest_proposal;
}

sub prepare {
    my ( $self, $id ) = @_;
    my $last = $self->last_accepted_id;
    throw("Prepared id does not exceed lastest prepared id.") if $id < $last;
    $self->last_prepared_id($id);
    return 0 unless $self->proposal_count;
    return $self->last_accepted_id;
}

sub accept {
    my ( $self, $id, $value ) = @_;
    my $last = $self->last_prepared_id;
    throw("Proposal id exceeds lastest prepared id.")
        if $id < $last;
    $_->learn( $id => $value ) for $self->learners;
    return ( $id, $value );
}

1;


=pod

=head1 NAME

Algorithm::Paxos::Role::Acceptor - An Acceptor role for the Paxos algorithm

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package MyApp::PaxosBasic;
    use Moose;
    
    with qw(Algorithm::Paxos::Role::Acceptor);
    
    1;
    __END__

=head1 DESCRIPTION

From L<Wikipedia|http://en.wikipedia.org/wiki/Paxos_algorithm>

    The Acceptors act as the fault-tolerant "memory" of the protocol. Acceptors
    are collected into groups called Quorums. Any message sent to an Acceptor must
    be sent to a Quorum of Acceptors. Any message received from an Acceptor is
    ignored unless a copy is received from each Acceptor in a Quorum.

=head1 METHODS

=head2 last_prepared_id ( ) : $id 

Internal method used by the algorithm. Returns the last id for a prepared
proposal.

=head2 last_accepted_id ( ) : $id

Internal method used by the algorithm. Returns the last id for an accepted
proposal.

=head2 learners ( ) : @learners

Returns a list of learners.

=head2 prepare ( $id ) : $id 

One of the two required methods for an Acceptor. When a proposal is made, the
first step is to ask acceptors to prepare. If the proposed ID is too low
(meaning another proposal is already in process) an exception will be thrown.
If the proposal is new the ID returned is 0. If there is a pending proposal
the ID for that proposal is returned.

=head2 accept ( $id, $value ) : $id, $value

One of two required methods for an Acceptor. After a quorum is reached a
proposal is then accepted and submitted to the learners. If all the learners
return clean the proposal id and value are returned. If the ID for the
proposal exceeds the allowed value (ie we're trying to accept an ID that is
lower than a prepared ID) we throw an exception.

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

