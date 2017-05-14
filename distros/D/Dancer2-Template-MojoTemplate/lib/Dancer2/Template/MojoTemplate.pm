package Dancer2::Template::MojoTemplate;

# ABSTRACT: Mojo::Template wrapper for Dancer2

use strict;
use warnings;
use Carp;
use Moo;
use Dancer2::Core::Types;
use Mojo::Template;

with 'Dancer2::Core::Role::Template';

has '+engine' => (
	isa => InstanceOf ['Mojo::Template']
);

has "+default_tmpl_ext" => (
    default => sub { 'html.ep' },
);
 

sub _build_engine {
	my $self = shift;
	my $charset = $self->charset;
	my %config = (
		%{$self->config}
	);

	return Mojo::Template->new(%config);
}

sub render {
	my ($self, $template, $tokens) = @_;

	if (!ref $template) {
		-f $template
		  or croak "'$template' doesn't exist or not a regular file";
	}

	my $content = $self->engine->render_file($template, $tokens);

	die "Couldn't render template: $@" if $@;

	return $content;
}

1;
__END__ 
=pod
 
=head1 NAME

Dancer2::Template::MojoTemplate - Mojo::Template wrapper for Dancer2

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

To use this engine, you may configure L<Dancer2> via C<config.yaml>:

    template: 'mojo_template'
    engines:
        mojo_template:
            auto_escape: 1
            trim_mark: '-'
            prepend: 'my $t = $_[0];'
    template:   "mojo_template"

Or you may also change the rendering engine on a per-route basis by
setting it manually with C<set>:

    # code code code
    set template => 'mojo_template';
 
=head1 DESCRIPTION

This is an interface between Dancer2's template engine abstraction layer and
the L<Mojo::Template> module.

Based on the L<Dancer::Template::MojoTemplate> module.

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

L<Dancer2>, L<Mojo::Template>, L<http://mojolicio.us/>

=head1 AUTHOR

Nikita Melikhov <ver@0xff.su>
 
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nikita Melikhov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
