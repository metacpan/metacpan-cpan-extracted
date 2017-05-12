package Bolts::Role::SelfLocator;
$Bolts::Role::SelfLocator::VERSION = '0.143171';
# ABSTRACT: Makes a Moose object into a locator

use Moose::Role;

with 'Bolts::Role::RootLocator';


sub root { $_[0] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Role::SelfLocator - Makes a Moose object into a locator

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

Any Moose object can turned into a L<Bolts::Role::Locator> easily just by implementing this role.

=head1 ROLES

=over

=item *

L<Bolts::Role::Locator>

=back

=head1 METHODS

=head2 root

Returns the invocant.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
