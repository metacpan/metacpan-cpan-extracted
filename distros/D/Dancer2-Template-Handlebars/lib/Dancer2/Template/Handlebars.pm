package Dancer2::Template::Handlebars 0.4;

# ABSTRACT: Dancer2 wrapper for Handlebars templating engine

use strict;
use warnings;

use Text::Handlebars;
use Module::Runtime qw/ use_module /;

use Moo;
use Try::Tiny;
with 'Dancer2::Core::Role::Template';

has '+default_tmpl_ext' => ( default => sub { 'hbs' }, );

has helpers => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_helpers',
);

has _engine => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Text::Handlebars->new( helpers => $self->helpers, );
    },
);

has _config => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return $_[0]->settings->{engines}->{handlebars} || {};
    }
);

sub _build_helpers {
    my $self = shift;

    my %helpers;

    if ( my $h = $self->_config->{helpers} ) {
        for my $module ( ref $h ? @$h : $h ) {
            my %h = try {
                use_module($module)->HANDLEBARS_HELPERS
            }
            catch {
                die "couldn't import helper functions from $module: $_";
            };

            @helpers{ keys %h } = values %h;
        }
    }

    return \%helpers;
}

sub render {
    my ( $self, $template, $tokens ) = @_;

    my $method = 'render';

    if ( ref $template ) {    # it's a ref to a string
        $template = $$template;
        $method .= '_string';
    }

    return $self->_engine->$method( $template, $tokens );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::Handlebars - Dancer2 wrapper for Handlebars templating engine

=head1 VERSION

version 0.4

=head1 SYNOPSIS

in your Dancer2 app config.yml:

    template: "handlebars"

...and if you want to add custom helpers:

    engines:
        handlebars:
            helpers:
                - MyApp::HandlebarsHelpers

=head1 HELPERS

You can create custom modules full of helpers to use in your Handlebars templates. For
more details on creating these, see L<Dancer2::Template::Handlebars::Helpers>.

Handlebars comes with helpers C<with>, C<each>, C<if>, and C<unless>.

=head1 GRATEFUL THANKS

...to Yanick, for his prior work on L<Dancer::Template::Handlebars> and
L<Dancer2::Template::Mustache>. Most all of the code you see in this
module is his work, or very, very close to his original code; I
merely remixed it, and got tests working for my own purposes.

=head1 SEE ALSO

L<http://handlebarsjs.com>

L<Text::Handlebars>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Dancer2::Template::Handlebars

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Dancer2-Template-Handlebars>

=item * Gitlab

L<https://gitlab.com/GeekRuthie/dancer2-template-handlebars>

=item * Gitlab issues tracker

L<https://gitlab.com/GeekRuthie/dancer2-template-handlebars/-/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Template-Handlebars>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
