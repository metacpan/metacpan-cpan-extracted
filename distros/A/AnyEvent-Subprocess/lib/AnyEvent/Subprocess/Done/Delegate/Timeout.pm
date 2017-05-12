package AnyEvent::Subprocess::Done::Delegate::Timeout;
BEGIN {
  $AnyEvent::Subprocess::Done::Delegate::Timeout::VERSION = '1.102912';
}
# ABSTRACT: done delegate for a job that can time out
use Moose;
use namespace::autoclean;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'timed_out' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Done::Delegate::Timeout - done delegate for a job that can time out

=head1 VERSION

version 1.102912

=head1 ATTRIBUTES

=head2 timed_out

True if the job was killed because it ran out of time.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

