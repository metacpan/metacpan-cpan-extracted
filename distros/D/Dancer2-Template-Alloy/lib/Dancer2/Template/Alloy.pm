package Dancer2::Template::Alloy;

# ABSTRACT: Template Alloy engine for Dancer2


use strict;
use warnings;

use Carp 'croak';
use Moo;
use Template::Alloy;

with 'Dancer2::Core::Role::Template';

our $VERSION = '0.002';

sub _build_engine {
    my $self = shift;

    Template::Alloy->new(
        ABSOLUTE     => 1,
        ENCODING     => $self->charset,
        INCLUDE_PATH => $self->views,
        %{ $self->config },
    );
}

sub render {
    my ( $self, $tmpl, $vars ) = @_;

    $self->engine->process( $tmpl, $vars, \my $content )
        or croak $self->engine->error;

    $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::Alloy - Template Alloy engine for Dancer2

=head1 VERSION

version 0.002

=head1 SYNOPSIS

To use this engine you may configure Dancer2 via "config.yml":

    template: "alloy"

Most configuration possible when creating a new instance of a
Template::Alloy object can be passed via the configuration.

    template: "alloy"
    engines:
      template:
        AUTO_FILTER: html

The following variables are defaulted, they can be overriden.

=over

=item * ABSOLUTE

Defaulted to 1.

=item * ENCODING

Pulled from Dancer2 C<charset>.

=item * INCLUDE_PATH

Pointed to the Dancer2 C<views>.

=back

=head1 AUTHOR

James Raspass <j.raspass@cv-library.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by CV-Library Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
