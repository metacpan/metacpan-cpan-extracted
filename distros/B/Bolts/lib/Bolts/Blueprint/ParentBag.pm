package Bolts::Blueprint::ParentBag;
$Bolts::Blueprint::ParentBag::VERSION = '0.143171';
# ABSTRACT: Retrieve the artifact's parent as the artifact

use Moose;

with 'Bolts::Blueprint::Role::Injector';


sub builder {
    my ($self, $bag, $name, %params) = @_;
    return $bag;
}


sub exists { 1 }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Blueprint::ParentBag - Retrieve the artifact's parent as the artifact

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing => (
        ...
        parameters => {
            parent => self,
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        ...
        injectors => [
            $meta->locator->acquire('injector', 'parameter_name', {
                key       => 'parent',
                blueprint => $meta->locator->acquire('blueprint', 'parent_bag'),
            }),
        ],
    );

=head1 DESCRIPTION

This is a blueprint for grabing the parent itself as the artifact.

B<Warning:> If you cache this object with a scope, like "singleton", your application will leak memory. This may create a very difficult to track loop of references.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 METHODS

=head2 builder

This grabs the parent bag and returns it.

=head2 exists

Always returns true.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
