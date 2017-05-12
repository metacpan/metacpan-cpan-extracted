package Bolts::Blueprint::BuiltInjector;
$Bolts::Blueprint::BuiltInjector::VERSION = '0.143171';
# ABSTRACT: An injector-oriented builder using a subroutine

use Moose;

with 'Bolts::Blueprint::Role::Injector';

use Carp ();


has builder => (
    isa         => 'CodeRef',
    reader      => 'the_builder',
    traits      => [ 'Code' ],
    handles     => {
        'call_builder' => 'execute_method',
    },
);


sub builder {
    my ($self, $bag, $name, %params) = @_;
    $self->call_builder($bag, $name, %params);
}


sub exists { 1 }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Blueprint::BuiltInjector - An injector-oriented builder using a subroutine

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing => (
        ...
        parameters => {
            thing => builder {
                my ($self, $bag, $name, %params) = @_;
                return MyApp::Thing->new(%params);
            },
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        ...
        injectors => [
            $meta->locator->acquire('injector', 'parameter_name', {
                key       => 'thing',
                blueprint => $meta->locator->acquire('blueprint', 'built_injector', {
                    builder => sub {
                        my ($self, $bag, $name, %params) = @_;
                        return MyApp::Thing->new(%params);
                    },
                }),
            }),
        ],
    );

=head1 DESCRIPTION

This is a blueprint for using a subroutine to fill in an injected artifact dependency.

This differs from L<Bolts::Blueprint::Built> in that it implements L<Bolts::Blueprint::Role::Injector>, which tags this has only accepting named parameters to the builder method, which is required during injection.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 ATTRIBUTES

=head2 builder

B<Required.> This is the subroutine to execute to construct the artifact. The reader for this attribute is named C<the_builder>.

=head1 METHODS

=head2 builder

This executes the subroutine in the C<builder> attribute.

=head2 exists

Always returns true.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
