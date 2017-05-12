package Dancer2::Template::Xslate;

use v5.8;
use strict;
use warnings FATAL => 'all';
use utf8;

use Moo;

use Carp qw(croak);
use Dancer2::Core::Types qw(InstanceOf);
use Text::Xslate;
use File::Spec::Functions qw(abs2rel file_name_is_absolute);

our $VERSION = 'v0.1.1'; # VERSION
# ABSTRACT: Text::Xslate template engine for Dancer2

with 'Dancer2::Core::Role::Template';

has '+default_tmpl_ext' => (
    default => sub { 'tx' }
);
has '+engine' => (
    isa => InstanceOf['Text::Xslate']
);

sub _build_engine {
    my ($self) = @_;

    my %config = %{ $self->config };

    # Dancer2 injects a couple options without asking; Text::Xslate protests:
    delete $config{environment};
    if ( my $location = delete $config{location} ) {
        unless (defined $config{path}) {
            $config{path} = [$location];
        }
    }

    return Text::Xslate->new(%config);
}

sub render {
    my ($self, $tmpl, $vars) = @_;

    my $xslate = $self->engine;
    my $content = eval {
        if ( ref($tmpl) eq 'SCALAR' ) {
            $xslate->render_string($$tmpl, $vars)
        }
        else {
            my $rel_path = file_name_is_absolute($tmpl)
                ? abs2rel($tmpl, $self->config->{location})
                : $tmpl;
            $xslate->render($rel_path, $vars);
        }
    };

    $@ and croak $@;

    return $content;
}

1;
=encoding utf8

=head1 NAME

Dancer2::Template::Xslate - Text::Xslate template engine for Dancer2

=head1 SYNOPSIS

C<config.yaml>:

    template: Xslate
    engines:
      template:
        Xslate: { path: "views" }

A Dancer 2 application:

    use Dancer2;

    get /page/:number => sub {
        my $page_num = params->{number};
        template "foo.tx", { page_num => $page_num };
    };

=head1 METHODS

=over

=item render($template, $tokens)

Renders a template. C<$template> can be one of:

=over 2

=item *

a string of the path to a template file (*.tx, not *.tt like the core Dancer2
template engines)

=item *

a reference to a string containing prerendered template content

=back

=back

=head1 SEE ALSO

=over

=item L<Dancer::Template::Xslate>

Xslate rendering engine for Dancer 1.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013 Richard Simões. This module is released under the terms of the
B<MIT License> and may be modified and/or redistributed under the same or any
compatible license.
