package Algorithm::Paxos;
{
  $Algorithm::Paxos::VERSION = '0.001';
}

# ABSTRACT: An implementation of the Paxos protocol

1;


=pod

=head1 NAME

Algorithm::Paxos - An implementation of the Paxos protocol

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package BasicPaxos;
    use Moose;
    with qw(
        Algorithm::Paxos::Role::Proposer
        Algorithm::Paxos::Role::Acceptor
        Algorithm::Paxos::Role::Learner
    );
    
    package main;
    
    my @synod = map { BasicPaxos->new() } ( 0 .. 2 );
    $_->_set_acceptors( \@synod ) for @synod;
    $_->_set_learners( \@synod ) for @synod;

=head1 DESCRIPTION

NOTE: This is Alpha level code. The algorithm works, I'm fairly certain it
works to spec it does not have anything near fully test coverage and it hasn't
been used in anything resembling a production environment yet. I'm releasing
it because I think it'll be useful and I don't want it lost on github.

From L<Wikipedia|http://en.wikipedia.org/wiki/Paxos_algorithm>

    Paxos is a family of protocols for solving consensus in a network of
    unreliable processors. Consensus is the process of agreeing on one result
    among a group of participants. This problem becomes difficult when the
    participants or their communication medium may experience failures.

This package implements a basic version of the Basic Paxos protocol and
provides an API (and hooks) for extending into a more complicated solution as
needed.

=head1 SEE ALSO 

=over 4

=item *

L<Paxos Made Simple [PDF]|http://research.microsoft.com/en-us/um/people/lamport/pubs/paxos-simple.pdf>

=item *

L<Doozer|http://xph.us/2011/04/13/introducing-doozer.html>

=item *

L<Chubby|http://research.google.com/archive/chubby.html>

=item *

L<Wikipedia|http://en.wikipedia.org/wiki/Paxos_algorithm>

=back

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

