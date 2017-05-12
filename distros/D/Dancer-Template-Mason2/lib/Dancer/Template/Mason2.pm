package Dancer::Template::Mason2;
$Dancer::Template::Mason2::VERSION = '0.05';
use Dancer::Config 'setting';
use File::Basename;
use FindBin;
use Mason;
use strict;
use warnings;
use base 'Dancer::Template::Abstract';

my $_engine;
my $root_dir;

sub init {
    my $self = shift;
    my $config = $self->config || {};

    $root_dir = $config->{comp_root} ||= setting('views') || $FindBin::Bin . '/views';
    $config->{data_dir} ||= dirname($root_dir) . "/data";
    $config->{autoextend_request_path} = 0 if !exists( $config->{autoextend_request_path} );

    $_engine = Mason->new(%$config);
}

sub default_tmpl_ext { "mc" }

sub render {
    my ( $self, $template, $tokens ) = @_;

    $template =~ s/^\Q$root_dir//;    # cut the leading path
    $template =~ y|\\|/|;             # convert slashes on Windows

    my $content = $_engine->run( $template, %$tokens )->output;
    return $content;
}

sub view {
    my ( $self, $view ) = @_;

    my $views_dir = Dancer::App->current->setting('views');
    my $tmpl_ext  = $self->config->{extension} || $self->default_tmpl_ext();
    my $view_path = sprintf( '%s/%s.%s', $views_dir, $view, $self->default_tmpl_ext );
    return $view_path;
}

sub view_exists { return 1; }

1;

__END__

=pod

=head1 NAME

Dancer::Template::Mason2 - Mason 2.x wrapper for Dancer

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  # in 'config.yml'
  template: 'mason2'

  # in the app
 
  get '/foo', sub {
    template 'foo' => {
        title => 'bar'
    };
  };

Then, in C<views/foo.mc>:

    <%args>
    $.title
    </%args>

    <h1><% $.title %></h1>

    <p>Mason says hi!</p>

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Mason 2.x|Mason> templating system.

In order to use this engine, set the template to 'mason2' in the configuration
file:

    template: mason2

The default template extension is ".mc".

=head1 CONFIGURATION

Parameters can also be passed to C<< Mason->new >> via the configuration file,
like so:

    engines:
        mason2:
            data_dir: /path/to/data_dir

C<comp_root>, if not specified, defaults to the C<views> configuration setting
or, if it's undefined, to the C</views> subdirectory of the application.

C<data_dir>, if not specified, defaults to a C</data> subdirectory alongside
the C<comp_root>.

=head1 SEE ALSO

L<Dancer>, L<Mason>, L<Dancer::Template::Mason>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
