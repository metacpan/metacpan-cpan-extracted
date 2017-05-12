package AnyEvent::Subprocess::Done::Delegate::State;
BEGIN {
  $AnyEvent::Subprocess::Done::Delegate::State::VERSION = '1.102912';
}
# ABSTRACT: thread state through the job/run/done lifecycle
use Moose;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'state' => ( is => 'ro', isa => 'HashRef', required => 1 );

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Done::Delegate::State - thread state through the job/run/done lifecycle

=head1 VERSION

version 1.102912

=head1 DESCRIPTION

Allows state to be passed from Job -> Run -> Done.

=head1 ATTRIBUTES

=head2 state

Returns the state received from the Run object.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

