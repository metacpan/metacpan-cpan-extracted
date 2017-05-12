package Bolts::Role::Initializer;
$Bolts::Role::Initializer::VERSION = '0.143171';
# ABSTRACT: Give components some control over their destiny

use Moose::Role;


requires 'init_locator';


sub initialize_value {
    my $self = shift;
    return $self->init_locator->acquire(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Role::Initializer - Give components some control over their destiny

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    package MyApp::Thing;
    use Moose;

    use MyApp::Bag;

    has init_locator => (
        is          => 'rw',
        does        => 'Bolts::Role::Locator',
        lazy        => 1,
        builder     => '_build_init_locator',
    );

    sub _build_init_locator { MyApp::Bag->new }

    with 'Bolts::Role::Initializer';

    has foo => (
        is          => 'rw',
        isa         => 'MyApp::Foo',
        traits      => [ 'Bolts::Initializer' ],
    );

    # Later...
    use Bolts::Util qw( bolts_init );
    my $thing = MyApp::Thing->new(
        foo => bolts_init('path', 'to', 'foo'),
    );

=head1 DESCRIPTION

While IOC provides an elegant way to decouple your objects and such, it is sometimes convenient to give objects more control over their setup. This role grants your class a special initializer method that can be used by initializer attributes, which can automatically find their values using an associated L<Bolts::Role::Locator> object.

For example, it can take a call like this:

    my $thing = MyApp::Thing->new(
        foo => $locator->acquire('path', 'to', 'foo'),
    );

to this:

    my $thing = MyApp::Thing->new(
        foo => bolts_init('path', 'to', 'foo'),
    );

The caller no longer has to know anything about the C<$locator>, just a common path within. Perhaps an even better way would be to move the initialization of MyApp::Thing into the locator to manage it's life cycle, scope, etc., but sometimes this is more convenient or practical or even possible.

Any attribute you want to have initialized this way should be tagged with the C<Bolts::Initializer> trait, which is defined in L<Bolts::Meta::Attribute::Trait::Initializer>. This trait modifies the attribute so that it may be initialized either by the actual value without an initializer or by looking up a value within the L</init_locator> of the object if given an initializer (a L<Bolts::Meta::Initializer> object, usually gotten by calling L<Bolts::Util/bolts_init>).

B<Caution:> This is slightly messy with bits and pieces spread out a bit more than I like. I might reorganize these pieces a bit in the future if I can find a better way to do it.

=head1 REQUIRED METHODS

=head2 init_locator

    my $locator = $self->init_locator;

This method takes no arguments and must return an object that does L<Bolts::Role::Locator>.

=head1 METHODS

=head2 initialize_value

    my $value = $self->initialize_value(@path, \%params);

This is used to perform acquisition with the initializer object. This is just delegated to the C<acquire> method of L</init_locator>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
