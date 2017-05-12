package Dancer::Template::Mustache;
BEGIN {
  $Dancer::Template::Mustache::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Wrapper for the Mustache template system
$Dancer::Template::Mustache::VERSION = '0.3.0';
use strict;
use warnings;

use Template::Mustache;
use FindBin;

require Dancer;

use Moo;

require Dancer::Config;
Dancer::Config->import( 'setting' );

extends 'Dancer::Template::Abstract';

sub _build_name { 'Dancer::Template::Mustache' }

sub default_tmpl_ext { "mustache" };

has _engine => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Template::Mustache->new( %{ $_[0]->config } );
    },
);

has _template_path => (
    is => 'ro',
    lazy => 1,
    default => sub {
        setting( 'views' ) || $FindBin::Bin . '/views'
    },
);

sub render {
    my ($self, $template, $tokens) = @_;

    my $_template_path = $self->_template_path;

    local $Template::Mustache::template_path = $_template_path;

    # remove the views part
    $template =~ s#^\Q$_template_path\E/?##;

    local $Template::Mustache::template_file = $template;
    
    return $self->_engine->render($tokens);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Template::Mustache - Wrapper for the Mustache template system

=head1 VERSION

version 0.3.0

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
    {{ content }}
    </body>

=head1 SEE ALSO

The Mustache templating system: L<http://mustache.github.com/>

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
