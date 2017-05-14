package Dancer::Template::MojoTemplate;

# ABSTRACT: Mojo::Template wrapper for Dancer

use strict;
use warnings;

use Mojo::Template;
use base 'Dancer::Template::Abstract';

my $_engine;

sub default_tmpl_ext { "ep" };

sub init {
    my $self = shift;

    my %args = (
        %{$self->config},
    );

    $_engine = Mojo::Template->new(%args);
}

sub render {
    my ($self, $template, $tokens) = @_;

    my $content = eval {
        $_engine->render_file($template, $tokens)
    };

    if ($@) {
        die qq{Couldn't render template: $@};
    }

    return $content;
}

1;


=pod

=head1 NAME

Dancer::Template::MojoTemplate - Mojo::Template wrapper for Dancer

=head1 VERSION

version 0.2.0

=head1 DESCRIPTION

This is an interface between Dancer's template engine abstraction layer and
the L<Mojo::Template> module.

In order to use this engine, use the template setting:

    template: mojo_template

This can be done in your config.yml file or directly in your app code with
the B<set> keyword.

You can configure L<Mojo::Template> :

    template: 'mojo_template'
    engines:
        mojo_template:
            auto_escape: 1
            trim_mark: '-'
            prepend: 'my $t = $_[0];'

=head1 SEE ALSO

L<Dancer>, L<Mojo::Template>, L<http://mojolicio.us/>

=head1 AUTHOR

James Aitken <jaitken@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

