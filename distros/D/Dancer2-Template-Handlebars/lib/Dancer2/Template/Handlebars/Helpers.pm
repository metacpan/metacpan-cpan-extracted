package Dancer2::Template::Handlebars::Helpers 1.00;

# ABSTRACT: parent class for Handlebars' helper collections

use strict;
use warnings;

use Sub::Attribute;

my %HELPERS;

sub HANDLEBARS_HELPERS {
    my $class = shift;
    %{ $HELPERS{$class} || {} };
}

sub Helper : ATTR_SUB {
    my ( $class, $sym_ref, undef, undef, $attr_data ) = @_;

    my $fname       = $class . '::' . *{$sym_ref}{NAME};
    my $helper_name = $attr_data || *{$sym_ref}{NAME};

    $HELPERS{$class}{$helper_name} = \&$fname;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::Handlebars::Helpers - parent class for Handlebars' helper collections

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    package MyApp::HandlebarsHelpers;
    use parent Dancer::Template::Handlebars::Helpers;
    sub shout :Helper {
        my( $context, $text ) = @_;
        return uc $text;
    }
    sub internal_name :Helper(whisper) {
        my( $context, $text ) = @_;
        return lc $text;
    }
    1;

and then in the Dancer2 app config.yml:

    engines:
        handlebars:
            helpers:
                - MyApp::HandlebarsHelpers

=head1 DESCRIPTION

Base class for modules containing Handlebars helper functions.
The helper functions are labelled with the C<:Helper> attribute.
A name for the helper function can be passed or, if not, will default
to the sub's name.

Behind the curtain, what the attribute does is to add the 
tagged functions to a module-wide C<%HANDLEBARS_HELPERS> variable,
which has the function names as keys and their coderefs as values.
For example, to register the functions of the SYNOPSIS
without the help of C<Dancer2::Template::Handlebars::Helpers>, one could do:

    package MyApp::HandlebarsHelpers;
    our HANDLEBARS_HELPERS = (
        shout   => \&shout,
        whisper => \&internal_name,
    );
    sub shout {
        my( $context, $text ) = @_;
        return uc $text;
    }
    sub internal_name {
        my( $context, $text ) = @_;
        return lc $text;
    }
    1;

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
