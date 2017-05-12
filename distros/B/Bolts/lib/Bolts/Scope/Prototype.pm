package Bolts::Scope::Prototype;
$Bolts::Scope::Prototype::VERSION = '0.143171';
# ABSTRACT: For artifacts that are constructed at every request

use Moose;

with 'Bolts::Scope';


sub get {}
sub put {}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Scope::Prototype - For artifacts that are constructed at every request

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This is a lifecycle scope for objects that should be constructed from their blueprints on every aquisition.

=head1 ROLES

=over

=item *

L<Bolts::Scope>

=back

=head1 METHODS

=head2 get

No-op. This will always return C<undef>.

=head2 put

No-op. This will never store anything.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
