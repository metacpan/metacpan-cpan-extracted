package Algorithm::Paxos::Role::Learner;
{
  $Algorithm::Paxos::Role::Learner::VERSION = '0.001';
}
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: A Learner role for the Paxos algorithm

has proposals => (
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { +{} },
    handles => {
        learn          => 'set',
        proposal_ids   => 'keys',
        proposal_count => 'count',
        proposal       => 'get',
    }
);

sub latest_proposal {
    my $self = shift;
    my ($last) = reverse sort $self->proposal_ids;
    return unless $last;
    $self->get_proposal($last);
}

1;


=pod

=head1 NAME

Algorithm::Paxos::Role::Learner - A Learner role for the Paxos algorithm

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package MyApp::PaxosBasic;
    use Moose;
    
    with qw(Algorithm::Paxos::Role::Learner);
    
    1;
    __END__

=head1 DESCRIPTION

From L<Wikipedia|http://en.wikipedia.org/wiki/Paxos_algorithm>

    Learners act as the replication factor for the protocol. Once a Client
    request has been agreed on by the Acceptors, the Learner may take action
    (i.e.: execute the request and send a response to the client). To improve
    availability of processing, additional Learners can be added.

=head1 METHODS

=head2 learn ( $id, $value ) 

This is the main interface between Acceptors and Leaners. When a value is
choosen by the cluster, C<learn> is passed the id and value and is recorded in
stable storage. The default implementation stores everything in an in-memory
HashRef.

=head2 proposal_ids ( ) : @ids

Returns a list of proposal ids.

=head2 proposal_count ( ) : $count

Returns the number of proposals to date.

=head2 latest_proposal ( ) : $value

Returns the value of the proposal with the greatest id.

=meethod proposal ( $id ) : $value

Returns the value stored for C<$id>.

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

