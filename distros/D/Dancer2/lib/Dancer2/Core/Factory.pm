package Dancer2::Core::Factory;
# ABSTRACT: Instantiate components by type and name
$Dancer2::Core::Factory::VERSION = '0.400000';
use Moo;
use Dancer2::Core;
use Module::Runtime 'use_module';
use Carp 'croak';

sub create {
    my ( $class, $type, $name, %options ) = @_;

    $type = Dancer2::Core::camelize($type);
    $name = Dancer2::Core::camelize($name);
    my $component_class = "Dancer2::${type}::${name}";

    eval { use_module($component_class); 1; }
        or croak "Unable to load class for $type component $name: $@";

    return $component_class->new(%options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::Factory - Instantiate components by type and name

=head1 VERSION

version 0.400000

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
