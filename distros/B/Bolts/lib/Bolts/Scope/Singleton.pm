package Bolts::Scope::Singleton;
$Bolts::Scope::Singleton::VERSION = '0.143171';
# ABSTRACT: For artifacts that are reused for the lifetime of the bag

use Moose;

use Hash::Util::FieldHash 'fieldhash';

with 'Bolts::Scope';

fieldhash my %singleton;


sub get {
    my ($self, $bag, $name) = @_;

    return unless defined $singleton{$bag};
    return unless defined $singleton{$bag}{$name};
    return $singleton{$bag}{$name};
}

sub put {
    my ($self, $bag, $name, $artifact) = @_;

    $singleton{$bag} = {} unless defined $singleton{$bag};
    $singleton{$bag}{$name} = $artifact;
    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Scope::Singleton - For artifacts that are reused for the lifetime of the bag

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This scope does not define a true singleton, but a singleton for the lifetime of the bag it is associated with, which might be the same thing.

=head1 ROLES

=over

=item *

L<Bolts::Scope>

=back

=head1 METHODS

=head2 get

If the named artifact has ever been stored for this bag, it will be returned by this method.

=head2 put

Puts the named artifact into the singleton cache for the bag. Once there, it will stay there for as long as the object exists.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
