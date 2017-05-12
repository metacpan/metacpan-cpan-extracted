package Bolts::Meta::Class::Trait::Locator;
$Bolts::Meta::Class::Trait::Locator::VERSION = '0.143171';
# ABSTRACT: Metaclass role for objects that have a meta locator

use Moose::Role;

use Bolts::Meta::Locator;


has locator => (
    is          => 'rw',
    does        => 'Bolts::Role::Locator',
    lazy_build  => 1,
);

sub _build_locator {
    $Bolts::GLOBAL_FALLBACK_META_LOCATOR->new;
}


sub acquire     { shift->locator->acquire(@_) }
sub acquire_all { shift->locator->acquire_all(@_) }
sub resolve     { shift->locator->resolve(@_) }
sub get         { shift->locator->get(@_) }

with 'Bolts::Role::Locator';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Meta::Class::Trait::Locator - Metaclass role for objects that have a meta locator

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This is another handy feature for use when constructing and managing a bag of artifacts. It provides a meta locator to the class for looking up standard Bolts objects like blueprints, scopes, injectors, inferrers, etc.

=head1 ROLES

=over

=item *

L<Bolts::Role::Locator>

=back

=head1 ATTRIBUTES

=head2 locator

This returns an implementation of L<Bolts::Role::Locator> containing the needed standard Bolts objects.

Defaults to a new object from L<Bolts/$Bolts::GLOBAL_FALLBACK_META_LOCATOR>, which defaults to L<Bolts::Meta::Locator>.

=head2 acquire

Delegated to the C<acquire> method of L</locator>.

=head2 acquire_all

Delegated to the C<acquire_all> method of L</locator>.

=head2 resolve

Delegated to the C<resolve> method of L</locator>.

=head2 get

Delegated to the C<get> method of L</locator>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
