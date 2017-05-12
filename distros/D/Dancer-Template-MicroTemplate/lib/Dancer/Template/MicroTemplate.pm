package Dancer::Template::MicroTemplate;

# ABSTRACT: Text::MicroTemplate engine for Dancer

use strict;
use warnings;

use Text::MicroTemplate::File;

use vars '$VERSION';
use base 'Dancer::Template::Abstract';

$VERSION = '1.0.0';

my $_engine;

sub init {
    my $self = shift;

    my %mt_cfg = (%{ $self->config });

    $_engine = Text::MicroTemplate::File->new(%mt_cfg);
}

sub render($$$) {
    my ($self, $template, $tokens) = @_;

    die "'$template' is not a regular file"
        if ref($template) || (!-f $template);

    my $content = "";
    $content = $_engine->render_file($template, $tokens)->as_string;
    return $content;
}

1;

=head1 NAME

Dancer::Template::MicroTemplate - Text::MicroTemplate engine for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Text::MicroTemplate> module.

In order to use this engine, set the following setting as the following:

    template: micro_template

This can be done in your config.yml file or directly in your app code with the
C<set> keyword.

=head1 SEE ALSO

L<Dancer>, L<Text::MicroTemplate>

=head1 AUTHOR

This module has been written by Franck Cuny and James Aitken

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
