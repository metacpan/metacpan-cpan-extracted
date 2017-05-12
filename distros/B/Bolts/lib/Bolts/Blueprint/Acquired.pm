package Bolts::Blueprint::Acquired;
$Bolts::Blueprint::Acquired::VERSION = '0.143171';
# ABSTRACT: acquire an artifact via a path and locator

use Moose;

with 'Bolts::Blueprint::Role::Injector';

use Bolts::Util qw( locator_for );


has locator => (
    is          => 'ro',
    does        => 'Bolts::Role::Locator',
    predicate   => 'has_locator',
);


has path => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_path',
    traits      => [ 'Array' ],
    handles     => {
        full_path => 'elements',
    },
);


sub builder {
    my ($self, $bag, $name) = @_;

    my @path = $self->has_path ? $self->full_path : $name;
    
    my $return;
    if ($self->has_locator) {
        $return = $self->locator->acquire(@path);
    }
    else {
        $return = locator_for($bag)->acquire(@path);
    }

    return $return;
}


sub exists { 1 }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Blueprint::Acquired - acquire an artifact via a path and locator

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar... these all use acquired blueprints
    artifact thing1; # acquired by attribute
    artifact thing2 => (
        path => [ 'thing1' ],
    );
    artifact thing3 => (
        locator => $other_loc,
        path    => [ 'other', 'thing' ],
    );

    # Or for injection
    artifact thing4 => (
        class => 'MyApp::Thing',
        parameters => {
            foo => dep('thing1'), # uses this blueprint
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        name      => 'thing',
        blueprint => $meta->locator->acquire('blueprint', 'acquired', {
            path    => [ 'myapp', 'settings', 'thing' ],
            locator => $other_loc,
        },
        scope     => $meta->locator->acquire('scope', singleton'),
    );

=head1 DESCRIPTION

A blueprint for constructing the object by acquiring it from a L<Bolts::Role::Locator>. This is handy for assembling complex bags in Bolts. It is also used as a convenient way of injecting dependencies into an artifact.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 ATTRIBUTES

=head2 locator

This is the L<Bolts::Role::Locator> to acquire an artifact from. If none is given, the blueprint will use the bag the parent artifact is in as the locator.

=head2 path

This is the path within the locator to use for acquiring the artifact. If not given, the name of the parent artifact is used instead (which is primarily useful for injected dependencies and could lead to negative consquences, like looping forever, if used otherwise).

=head2 builder

This implements the actual acquisition from the L</locator> (or the bag the parent artifact is in) and L</path> (or the name of the parent artifact).

=head2 exists

Always returns true.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
