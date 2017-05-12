package Algorithm::Paxos::Role::Proposer;
{
  $Algorithm::Paxos::Role::Proposer::VERSION = '0.001';
}
use 5.10.0;
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: A Proposer role for the Paxos algorithm

use Try::Tiny;
use Algorithm::Paxos::Exception;

has acceptors => (
    isa     => 'ArrayRef',
    writer  => '_set_acceptors',
    traits  => ['Array'],
    handles => {
        acceptors      => 'elements',
        acceptor_count => 'count',
    }
);

sub is_quorum {
    my ( $self, @replies ) = @_;
    my @successes = grep {defined} @replies;
    return @successes > ( $self->acceptor_count / 2 );
}

sub highest_proposal_id {
    my ( $self, @replies ) = @_;
    my @successes = grep {defined} @replies;
    return ( sort @successes )[0];
}

sub new_proposal_id { state $i++ }

sub prospose {
    my ( $self, $value ) = @_;
    my $n = $self->new_proposal_id;

    my @replies = map {
        try { $self->prepare($n) }
        catch { warn $_; undef }
    } $self->acceptors;

    if ( $self->is_quorum(@replies) ) {
        my $v = $self->highest_proposal_id(@replies);
        $v ||= $value;
        $_->accept( $n, $v ) for $self->acceptors;
        return $n;
    }
    throw("Proposal failed to reach quorum");
}

1;


=pod

=head1 NAME

Algorithm::Paxos::Role::Proposer - A Proposer role for the Paxos algorithm

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package MyApp::PaxosBasic;
    use Moose;
    
    with qw(Algorithm::Paxos::Role::Proposer);
    
    1;
    __END__

=head1 DESCRIPTION

From L<Wikipedia|http://en.wikipedia.org/wiki/Paxos_algorithm>

    A Proposer advocates a client request, attempting to convince the
    Acceptors to agree on it, and acting as a coordinator to move the protocol
    forward when conflicts occur.

=head1 METHODS

=head2 acceptors ( ) : @acceptors

Returns a list of the acceptors.

=head2 acceptor_count ( ) : $count

Returns count of the number of acceptors.

=head2 is_quorum ( @replies ) : $bool

Takes a list of IDs and sees if they meet a quorum.

=head2 highest_proposal_id ( @replies ) : $id 

Takes a list of replies and returns the highest proposal id from the list.

=head2 new_proposal_id ( ) : $id

Generates a new proposal id. The default implementation is an increasing
integer (literally C<$i++>).

=head2 prospose ( $value ) : $id

Propose is the main interface between clients and the Paxos cluster/node.
Propose takes a single value (the proposal) and returns the ID that is
assigned to that proposal. If the proposal fails an exception is thrown.

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

