package Dancer::Template::Mustache;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Wrapper for the Mustache template system
$Dancer::Template::Mustache::VERSION = '1.1.0';
use 5.10.0;

use strict;
use warnings;

use Template::Mustache 1.0.2;
use FindBin;

require Dancer;

use Moo;

use Path::Tiny;

use Dancer::Config qw/ setting /;

extends 'Dancer::Template::Abstract';

sub _build_name { 'Dancer::Template::Mustache' }

sub default_tmpl_ext { "mustache" };

has _template_path => (
    is => 'ro',
    lazy => 1,
    default => sub {
        setting( 'views' ) || $FindBin::Bin . '/views'
    },
);

has caching => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->config->{cache_templates} // 1 },
);

my %file_template; # cache for the templates

sub render {
    my ($self, $template, $tokens) = @_;

    my $_template_path = $self->_template_path;

    # remove the views part
    $template =~ s#^\Q$_template_path\E/?##;

    my $mustache = $file_template{$template} ||= Template::Mustache->new(
        template_path => path( $self->_template_path, $template )
    );

    delete $file_template{$template} unless $self->caching;

    return $mustache->render($tokens); 
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Template::Mustache - Wrapper for the Mustache template system

=head1 VERSION

version 1.1.0

=head1 SYNOPSIS

    # in config.yml
   template: mustache

   # in the app
   get '/style/:style' => sub {
       template 'style' => {
           style => param('style')
       };
   };

   # in views/style.mustache
   That's a nice, manly {{style}} mustache you have there!

=head1 DESCRIPTION

This module is a L<Dancer> wrapper for L<Template::Mustache>. 

For now, the extension of the mustache templates must be C<.mustache>.

Partials are supported, as are layouts. For layouts, the content of the inner
template is sent via the usual I<content> template variable. So a typical 
mustached layout would look like:

    <body>
    {{{ content }}}
    </body>

=head1 CONFIGURATION

    engines:
      Mustache:
        cache_templates: 1

Bu default, the templates are only compiled once when first
accessed. The caching can be disabling by setting C<cache_templates>
to C<0>.

=head1 SEE ALSO

The Mustache templating system: L<http://mustache.github.com/>

L<Dancer::Template::Handlebars> - Dancer support for Handlebars, a templating system
that is a superset of Mustache.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2014, 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
