package AnyEvent::Subprocess::Delegate;
BEGIN {
  $AnyEvent::Subprocess::Delegate::VERSION = '1.102912';
}
# ABSTRACT: role representing a delegate
use Moose::Role;

with 'MooseX::Clone';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Delegate - role representing a delegate

=head1 VERSION

version 1.102912

=head1 DESCRIPTION

All delegates consume this role; it provides C<name> and is a type
tag.

=head1 METHODS

=head2 clone

Returns a deep copy of the delegate.

=head1 REQUIRED ATTRIBUTES

=head2 name

The name of the delegate.  You can only have one delegate of each name
per class.

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Role::WithDelegates>

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

