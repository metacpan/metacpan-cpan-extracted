package Dancer2::Template::Mason2;

BEGIN {
    $Dancer2::Template::Mason2::VERSION = '0.01';
}

use Moo;
use Carp qw( croak );
use Dancer2::Core::Types;
use Mason;

with 'Dancer2::Core::Role::Template';

has '+engine' => ( isa => InstanceOf ['Mason::Interp'], );
has '+default_tmpl_ext' => ( default => sub { 'mc' } );

sub _build_engine {
    my ( $self ) = @_;

    my %config = (
        autoextend_request_path => 0,
        %{ $self->config },
    );

    $config{'comp_root'} ||= $self->views;
    $config{'data_dir'}  ||= $self->settings->{'appdir'};

    return Mason->new( %config );
}

sub render {
    my ( $self, $template, $tokens ) = @_;

    my $root_dir = $self->views;
    $template =~ s/^\Q$root_dir//;    # cut the leading path
    $template =~ y|\\|/|;             # convert slashes on Windows

    my $content = $self->engine->run( $template, %$tokens )->output;
    return $content;
}

1;

__END__

=encoding utf-8

=head1 NAME

Dancer2::Template::Mason2 - Mason 2.x engine for Dancer2

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In C<config.yml>

  template: "mason2"

In C<MyApp.pm>

  get '/foo' => sub {
      template foo => {
          title => 'bar',
      };
  };

In C<views/foo.mc>

  <%args>
  $.title
  </%args>

  <h1><% $.title %></h1>
  <p>Hello World!</p>

=head1 DESCRIPTION

Dancer2::Template::Mason2 is a template engine that allows you
to use L<Mason 2.x|Mason> with L<Dancer2>.

In order to use this engine, set the template to 'mason2' in
the Dancer2 configuration file:

  template: "mason2"

The default template extension is '.mc'.

=head1 CONFIGURATION

Paramters can also be passed to C<< Mason->new() >> via the
configuration file like so:

  engines:
    mason2:
       data_dir: /path/to/data_dir

C<comp_root> defaults to the C<views> configuration setting or,
if it is undefined, to the C</views> subdirectory of the application.

C<data_dir> defaults to C</data> subdirectory in the project root
directory.

=head1 SEE ALSO

L<Dancer2>, L<Mason>

=head1 AUTHOR

David Betz E<lt>hashref@gmail.comE<gt>

=head1 LICENSE

Copyright (C) David Betz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
