package Dancer2::Template::Obj2HTML;
$Dancer2::Template::Obj2HTML::VERSION = '0.12';

use strict;
use warnings;

use Moo;
use JSON;
use HTML::Obj2HTML;
with 'Dancer2::Core::Role::Template';

has page_loc => (
    is      => 'rw',
    default => sub {'dofiles/pages'},
);

has component_loc => (
    is      => 'rw',
    default => sub {'dofiles/components'},
);

has template_loc => (
    is      => 'rw',
    default => sub {'dofiles/templates'},
);

has extension => (
    is      => 'rw',
    default => sub {'.view'}
);

sub BUILD {
  my $self     = shift;
  my $settings = $self->config;

  $settings->{$_} and $self->$_( $settings->{$_} )
    for qw/ page_loc component_loc template_loc extension /;

  HTML::Obj2HTML::import(components => $self->component_loc);
}

sub render {
  my ($self, $content, $tokens) = @_;

  my $was_template = 0;
  if ($tokens->{content}) {
    $was_template = 1;
    if (!ref $tokens->{content}) {
      HTML::Obj2HTML::set_snippet("content", [ raw => $tokens->{content} ]);
    } elsif (ref $tokens->{content} eq "ARRAY") {
      HTML::Obj2HTML::set_snippet("content", $tokens->{content} );
    }
    delete($tokens->{content});
  }

  if (ref $content eq "ARRAY") {
    return HTML::Obj2HTML::gen($content, $tokens);
  } elsif (!ref $content) {
    if ($was_template) {
      return HTML::Obj2HTML::gen(HTML::Obj2HTML::fetch($self->{settings}->{appdir} . $self->template_loc . "/" . $content . $self->extension, $tokens));
    } else {
      return HTML::Obj2HTML::gen(HTML::Obj2HTML::fetch($self->{settings}->{appdir} . $self->page_loc . "/" . $content . $self->extension, $tokens));
    }
  }
}

sub view_pathname {
  my ( $self, $view ) = @_;
  return $view;
}
sub layout_pathname {
  my ( $self, $layout ) = @_;
  return $layout;
}

1;
__END__

=pod

=head1 NAME

Dancer2::Template::Obj2HTML - Templating system based on HTML::Obj2HTML

=head1 SYNOPSYS

In your config.yml

    engines:
      template:
        Obj2HTML:
          page_loc: "dofiles/pages"
          component_loc: "dofiles/components"
          template_loc: "dofiles/templates"
          extension: ".view"

In your router:

    template \@content;
    template path/to/file

=head1 DESCRIPTION

Templating system for Dancer2 using HTML::Obj2HTML, primarily intended as the
target templating system for Dancer2::Plugin::DoFile

There is very little logic behind this templating system, aside processing
the templates as Obj2HTML content (i.e. array and hash references that define
the HTML in an easily manipulatable way).

Note that the default location for files is in "dofiles/", not "layouts/", but
a simple configuration change will fix that for you, if that's what you want to
do. The reason WHY it's "dofiles/" is simply to keep together all the
Plugin::DoFile and Template::Obj2HTML assets.

=head1 AUTHOR

Pero Moretti

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Pero Moretti.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
