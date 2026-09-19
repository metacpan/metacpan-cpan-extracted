package Dancer2::Serializer::YAML;
# ABSTRACT: Serializer for handling YAML data
$Dancer2::Serializer::YAML::VERSION = '2.2.1';
use Moo;
use Carp 'croak';
use Encode;
use Module::Runtime 'use_module';
use Sub::Defer;

with 'Dancer2::Core::Role::Serializer';

has '+content_type' => ( default => sub {'text/x-yaml'} );

# deferred helpers. These are called as class methods, but need to
# ensure YAML is loaded.

my $_from_yaml = defer_sub 'Dancer2::Serializer::YAML::from_yaml' => sub {
    use_module('YAML');
    sub { __PACKAGE__->deserialize(@_) };
};

my $_to_yaml = defer_sub 'Dancer2::Serializer::YAML::to_yaml' => sub {
    use_module('YAML');
    sub { __PACKAGE__->serialize(@_) };
};

# class definition
sub BUILD { use_module('YAML') }

sub serialize {
    my ( $self, $entity ) = @_;
    encode('UTF-8', YAML::Dump($entity));
}

sub deserialize {
    my ( $self, $content ) = @_;

    # Content reaching here is untrusted -- for an app with 'serializer: YAML'
    # (or Serializer::Mutable, which maps both text/x-yaml and text/html to
    # this class) it is the raw request body.
    #
    # YAML tags can ask the loader to build things that are not data.
    # !!perl/hash:Some::Class instantiates an arbitrary blessed object, which
    # is the entry point for DESTROY/AUTOLOAD gadget chains, and !!perl/code
    # asks for a string eval. Both are refused here.
    #
    # These are set explicitly rather than left to YAML.pm's defaults so the
    # behaviour does not depend on which YAML.pm the user resolved: LoadBlessed
    # only defaults to 0 from YAML 1.30, and the variable itself only exists
    # from 1.25 (which is why cpanfile floors YAML -- see the note there).
    #
    # UseCode must be zeroed as well: YAML::Loader::Base decides on code
    # loading with a plain OR -- load_code($YAML::LoadCode || $YAML::UseCode) --
    # so LoadCode = 0 alone is defeated by an ambient $YAML::UseCode = 1, and
    # the !!perl/code string eval is not gated on LoadBlessed at all.
    local $YAML::LoadBlessed = 0;
    local $YAML::LoadCode    = 0;
    local $YAML::UseCode     = 0;

    YAML::Load(decode('UTF-8', $content));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Serializer::YAML - Serializer for handling YAML data

=head1 VERSION

version 2.2.1

=head1 DESCRIPTION

This is a serializer engine that allows you to turn Perl data structures into
YAML output and vice-versa.

=head1 ATTRIBUTES

=head2 content_type

Returns 'text/x-yaml'

=head1 METHODS

=head2 serialize($content)

Serializes a data structure to a YAML structure.

=head2 deserialize($content)

Deserializes a YAML structure to a data structure.

=head1 FUNCTIONS

=head2 fom_yaml($content)

This is an helper available to transform a YAML data structure to a Perl data structures.

=head2 to_yaml($content)

This is an helper available to transform a Perl data structure to YAML.

Calling this function will B<not> trigger the serialization's hooks.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
