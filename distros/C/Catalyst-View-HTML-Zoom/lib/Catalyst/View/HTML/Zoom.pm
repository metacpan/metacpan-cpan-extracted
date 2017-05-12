package Catalyst::View::HTML::Zoom;
BEGIN {
  $Catalyst::View::HTML::Zoom::VERSION = '0.003';
}
# ABSTRACT: Catalyst view to HTML::Zoom

use Moose;
use Class::MOP;
use HTML::Zoom;
use Path::Class ();
use namespace::autoclean;

extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has template_extension => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_template_extension',
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => 'text/html; charset=utf-8',
);

has root => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_root {
    shift->_application->config->{root};
}

sub process {
    my ($self, $c) = @_;    
    my $template_path_part = $self->_template_path_part_from_context($c);
    if(my $out = $self->render($c, $template_path_part)) {
        $c->response->body($out);
        $c->response->content_type($self->content_type)
          unless ($c->response->content_type);
        return 1;
    } else {
        $c->log->error("The template: $template_path_part returned no response");
        return 0;
    }
}

sub _template_path_part_from_context {
    my ($self, $c) = @_;
    my $template_path_part = $c->stash->{template} || $c->action->private_path;
    if ($self->has_template_extension) {
        my $ext = $self->template_extension;
        $template_path_part = $template_path_part . '.' . $ext
          unless $template_path_part =~ /\.$ext$/ || ref $template_path_part;
    }
    return $template_path_part;
}

sub render {
    my ($self, $c, $template_path_part, $args, $code) = @_;
    my $vars =  {$args ? %{ $args } : %{ $c->stash }};
    my $zoom = $self->_build_zoom_from($template_path_part);
    my $renderer = $self->_build_renderer_from($c, $code);
    return $renderer->($zoom, $vars)->to_html;
}

sub _build_renderer_from {
    my ($self, $c, $code) = @_;
    if($code = $code ? $code : $c->stash->{zoom_do}) {
        $self->_build_renderer_from_coderef($code);
    } else {
        $self->_build_renderer_from_zoomer_class($c);
    }
}

sub _build_renderer_from_coderef {
    my ($self, $code) = @_;
    return sub {
        my ($zoom, $vars) = @_;
        return $code->($zoom, %$vars);
    };
}

sub _build_renderer_from_zoomer_class {
    my ($self, $c) = @_;
    my $zoomer_class = $self->_zoomer_class_from_context($c);
    my $zoomer = $self->_build_zoomer_from($zoomer_class);
    my $action = $self->_target_action_from_context($c);
    return sub {
        my ($zoom, $vars) = @_;
        local $_ = $zoom;       
        return $zoomer->$action($vars);
    };
}

sub _build_zoom_from {
    my ($self, $template_path_part) = @_;
    if(ref $template_path_part) {
        return $self->_build_zoom_from_html($$template_path_part);
    } else {
        my $template_abs_path = $self->_template_abs_path_from($template_path_part);
        return $self->_build_zoom_from_file($template_abs_path);
    }
}

sub _build_zoom_from_html {
    my ($self, $html) = @_;
    $self->_debug_log("Building HTML::Zoom from direct HTML");
    HTML::Zoom->from_html($html);
}

sub _build_zoom_from_file {
    my ($self, $file) = @_;
    $self->_debug_log("Building HTML::Zoom from file $file");
    HTML::Zoom->from_file($file);
}

sub _template_abs_path_from {
    my ($self, $template_path_part) = @_;
    Path::Class::dir($self->root, $template_path_part);
}

sub _zoomer_class_from_context {
    my ($self, $c) = @_;
    my $controller = $c->controller->meta->name;
    $controller =~ s/^.*::Controller::(.*)$/$1/;
    my $zoomer_class = do {
        $c->stash->{zoom_class} ||
          join('::', ($self->meta->name, $controller));
    };
    $zoomer_class = ref($self) . $zoomer_class
      if $zoomer_class=~m/^::/;
    $self->_debug_log("Using View Class: $zoomer_class");
    Class::MOP::load_class($zoomer_class);
    return $zoomer_class;
}

sub _build_zoomer_from {
    my ($self, $zoomer_class) = @_;
    my $key = $zoomer_class;
    $key =~s/^.+::(View)/$1/;
    my %args = %{$self->_application->config->{$key} || {}};
    return $zoomer_class->new(%args);
}

sub _target_action_from_context {
    my ($self, $c) = @_;
    return $c->stash->{zoom_action}
      || $c->action->name;
}

sub _debug_log {
    my ($self, $message) = @_;
    $self->_application->log->debug($message)
      if $self->_application->debug;
}

__PACKAGE__->meta->make_immutable;



__END__
=pod

=head1 NAME

Catalyst::View::HTML::Zoom - Catalyst view to HTML::Zoom

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    package MyApp::View::HTML;
    use Moose;
    extends 'Catalyst::View::HTML::Zoom';

    package MyApp::Controller::Wobble;
    use Moose; BEGIN { extends 'Catalyst::Controller' }
    sub dance : Local {
        my ($self, $c) = @_;
        $c->stash( shaking => 'hips' );
    }

    package MyApp::View::HTML::Wobble;
    use Moose;
    sub dance {
        my ($self, $stash) = @_;
        $_->select('#shake')->replace_content($stash->{shaking});
    }

    #root/wobble/dance
    <p>Shake those <span id="shake" />!</p>

    GET /wobble/dance => "<p>Shake those <span id="shake">hips</span>!</p>";

=head1 DESCRIPTION

This is our first pass attempt at bringing L<HTML::Zoom> to L<Catalyst>.  You
should be familiar with L<HTML::Zoom> before using this.  Additionally, as this
is an early attempt to envision how this will work we say:

L<"Danger, Will Robinson!"|http://en.wikipedia.org/wiki/Danger,_Will_Robinson>

=head1 ATTRIBUTES

The following is a list of configuration attributes you can set in your global
L<Catalyst> configuration or locally as in:

    package MyApp::View::HTML;
    use Moose;
    extends 'Catalyst::View::HTML::Zoom';

    __PACKAGE__->config({
        content_type => 'text/plain',
    });

=head2 template_extension

Optionally set the filename extension of your zoomable templates.  Common
values might be C<html> or C<xhtml>.  Should be a scalar.

=head2 content_type

Sets the default C<content-type> of the response body.  Should be a scalar.

=head2 root

Used at the prefix path for where yout templates are stored.  Defaults to
C<< $c->config->{root} >>.  Should be a scalar.

=head1 METHODS

This class contains the following methods available for public use.

=head2 process 

args: ($c)

Renders the template specified in C<< $c->stash->{template} >> or 
C<< $c->namespace/$c->action >> (the private name of the matched action). Stash
contents are passed to the underlying view object.

Output is stored in C<< $c->response->body >> and we set the value of 
C<< $c->response->content_type >> to C<text/html; charset=utf-8> or whatever you
configured as the L</content_type> attribute unless this header has previously
been set.

=head2 render

args: ($c, $template || \$template, ?\%args, ?$coderef)

Renders the given template and returns output.

If C<$template> is a simple scalar, we assume this is a path part that combines
with the value of L</root> to discover a file that lives on your local
filesystem.

However, if C<$template> is a ref, we assume this is a scalar ref containing 
some html you wish to render directly.

If C<\%args> is not defined we use the value of C<$c->stash>.

If C<$coderef> is defined and is a subroutine reference, we use is the same way
we use L<zoom_do>.

=head1 STASH KEYS

This View uses the following stash keys as hints to the processor.  Currently
these keys are passed on in the stash to the underlying templates.

=head2 template

This overrides which template file is parsed by L<HTML::Zoom>.  If the value 
is a plain scalar then we assume it is a file off the template L</root>.  If it
is a scalar ref, we assume it is the actual body of the template we wish to
parse.

If this value is not set, we infer a template via C<< $c->action->private_path >>

=head2 zoom_class

This is the View class which is responsible for containing actions that converts
a L</template> into a rendered body suitable for returning to a user agent.  By
default we infer from the controller name such that if your controller is called
C<MyApp::Web::Controller::Foo> and your base View class is C<MyApp::Web::View::HTML>,
the C<zoom_class> is called C<MyApp::Web::View::HTML::Foo>.

If you override this default you can either give a full package name, such as
C<MyApp::CommonStuff::View::Foo> or a relative package name such as C<::Foo>, in
which case we will automatically prefix the base View (like C<MyApp::Web::View::HTML>)
to create a full path (C<MyApp::Web::View::HTML::Foo>).

=head2 zoom action

This refers to a method name in your L</zoom_class> which does the actual work of
processing a template into something we return as the body of an HTTP response.

    package MyApp::View::HTML::Foo;

    sub fill_name {
        my ($self, $args) = @_;
        $_->select("#name")->replace_content($args->{name});
    }

=head2 zoom_do

This is a subroutine reference which is optionally used to provide L<HTML::Zoom>
directives directly in a controller.  Useful for simple templates and rapid 
prototyping.

    sub example_zoom_do :Local {
        my ($self, $c) = @_;
        $c->stash(
            name => 'John',
            zoom_do => sub {
                my ($zoom, %args) = @_;
                $zoom->select("#name")->replace_content($args{name});
            },
        );
    }

If this key is not defined, we assume you want to use a class as above.

=head1 WARNING: VOLATILE!

This is the first version of a Catalyst view to L<HTML::Zoom> - and we might 
have got it wrong. Please be aware that this is still in early stages, and the
API is not at all stable. You have been warned (but encouraged to break it and 
submit bug reports and patches :).

=head1 THANKS

Thanks to Thomas Doran for the initial starting point.

=head1 AUTHOR

Oliver Charles <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

