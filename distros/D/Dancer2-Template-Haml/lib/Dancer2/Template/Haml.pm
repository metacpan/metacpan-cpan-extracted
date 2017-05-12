package Dancer2::Template::Haml;
use 5.008005;
use strict;
use warnings FATAL => 'all';
use utf8;

use Moo;

use Dancer2::Core::Types 'InstanceOf';
use Dancer2::FileUtils 'path';

use Carp qw/croak/;

use Text::Haml;

our $VERSION = 0.04; # VERSION
# ABSTRACT: Text::Haml template engine wrapper for Dancer2

with 'Dancer2::Core::Role::Template';

has '+default_tmpl_ext' => ( default => sub { 'haml' }          );
has '+engine'           => ( isa     => InstanceOf['Text::Haml']);

sub view_pathname {
  my ($self, $view) = @_;

  $view = $self->_template_name($view);

  return (ref $self->config->{path} eq 'HASH')  # virtual path
            ? $view
            : path($self->views, $view);

}

sub layout_pathname {
  my ($self, $layout) = @_;

  $layout = $self->_template_name($layout);

  return (ref $self->config->{path} eq 'HASH')  # virtual path
            ? path('layouts', $layout)
            : path($self->views, 'layouts', $layout);
}

sub render_layout {
    my ($self, $layout, $tokens, $content) = @_;
 
    $layout = $self->layout_pathname($layout);

    $self->engine->escape_html(0);
 
    # FIXME: not sure if I can "just call render"
    $self->render( $layout, { %$tokens, content => $content } );
}
 
sub _build_engine {
    my $self = shift;

    my %haml_args = %{ $self->config };

    #$haml_args{path} //= [$haml_args{location}]; # for Perl v5.10
    $haml_args{path} = defined $haml_args{path} 
      ? $haml_args{path} 
      : [$haml_args{location}];

    return Text::Haml->new(%haml_args);
}

sub render {
    my ($self, $template, $vars) = @_;

    my $haml = $self->engine;
    my $content = $haml->render_file($template, %$vars)
      or croak $haml->error;

    # In the method layout set escape_html in 0 to insert the contents of a page
    # For all other cases set escape_html 1
    $haml->escape_html(1);

    return $content;
}

1;
__END__
=encoding utf8

=head1 NAME

Dancer2::Template::Haml - Text::Haml template engine wrapper for Dancer2

=head1 SYNOPSIS

To use this engine, you may configure L<Dancer2> via C<config.yaml>:

    template: "haml"
    engines:
      template:
        haml: 
          cache: 1
          cache_dir: "./.text_haml_cache"

Or you may also change the rendering engine by setting it manually with C<set> keyword:
 
  set template => 'haml';
  set engines => {
        template => {
          Haml => {
            cache => 1,
            cache_dir => './.text_haml_cache'
          },
        },
  };

Example:

C<views/index.haml>:

  %h1= $foo

C<views/layouts/main.haml>:

  !!! 5
  %html
    %head
      %meta(charset = $settings->{charset})
      %title= $settings->{appname}
    %body
      %div(style="color: green")= $content
      #footer
        Powered by
        %a(href="https://metacpan.org/release/Dancer2") Dancer #{$dancer_version}

A Dancer 2 application:

  use Dancer2;

  get '/' => sub {
    template 'index' => {foo => 'Bar!'};
  };

=head1 DESCRIPTION
 
This is an interface between Dancer2's template engine abstraction layer and
the L<Text::Haml> module.
 
Based on the L<Dancer2::Template::Xslate> and L<Dancer::Template::Haml> modules.

You can use templates and layouts defined in __DATA__ section:

  use Dancer2;

  use Data::Section::Simple qw/get_data_section/;

  my $vpath = get_data_section;

  set layout => 'main';
  set appname => "Dancer2::With::Haml";
  set charset => "UTF-8";

  set template => 'haml';
  set engines => {
        template => {
          Haml => {
            cache => 1,
            cache_dir => './.text_haml_cache',
            path => $vpath,
          },
        },
  };

  get '/bazinga' => sub {
      template 'bazinga' => {
        text => 'Bazinga?',
        foo => 'Bar!',
      };
  };

  true;

  __DATA__
  @@ layouts/main.haml
  !!! 5
  %html
    %head
      %meta(charset = $settings->{charset})
      %title= $settings->{appname} 
    %body
      %div(style="color: green")= $content
      #footer
        Powered by
        %a(href="https://metacpan.org/release/Dancer2") Dancer #{$dancer_version}

  @@ bazinga.haml
  %strong= $text
  %p= $foo
  %em text 2 texts 3

=head1 SEE ALSO

=over

=item L<Dancer::Template::Haml>

Haml rendering engine for Dancer 1.

=back

=over 2

=item L<Text::Haml>

Haml Perl implementation

=back

=head1 DEVELOPMENT

=head2 Repository

    https://github.com/TheAthlete/Dancer2-Template-Haml

=head1 AUTHOR

Viacheslav Koval, <athlete AT cpan DOT org>

=head1 LICENSE

Copyright © 2013 by Viacheslav Koval.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
