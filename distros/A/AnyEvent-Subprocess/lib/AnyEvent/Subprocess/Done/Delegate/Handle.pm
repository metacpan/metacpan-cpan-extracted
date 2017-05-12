package AnyEvent::Subprocess::Done::Delegate::Handle;
BEGIN {
  $AnyEvent::Subprocess::Done::Delegate::Handle::VERSION = '1.102912';
}
# ABSTRACT: store leftover wbuf/rbuf from running Handle
use Moose;
use namespace::autoclean;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'rbuf' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rbuf',
);

has 'wbuf' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_wbuf',
);

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Done::Delegate::Handle - store leftover wbuf/rbuf from running Handle

=head1 VERSION

version 1.102912

=head1 ATTRIBUTES

=head2 rbuf

=head2 wbuf

Attributes to store leftover data in the handle's rbuf or wbuf.

=head1 METHODS

=head2 rbuf

=head2 wbuf

Return the residual data.

=head2 has_rbuf

=head2 has_wbuf

Check for existence of residual data.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

