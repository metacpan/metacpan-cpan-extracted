package Data::Object::Template;

use Template::Tiny ();

use Data::Object::Class;

with 'Data::Object::Role::Proxyable';

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  my $origin = $self->origin;

  $self->{source} = $origin->new(TRIM => 1);

  return $self;
}

sub BUILDPROXY {
  my ($class, $method, @args) = @_;

  my $self = shift @args;
  my $source = $self->source;

  unless ($class->can($method) || $source->can($method)) {
    return;
  }
  return sub {
    my $return = $source->$method(@args);

    UNIVERSAL::isa($return, ref($source)) ? $class->new($return) : $return;
  };
}

# METHODS

sub origin {
  return 'Template::Tiny';
}

sub source {
  my ($self) = @_;

  return $self->{source};
}

sub render {
  my ($self, $template, $data) = @_;

  my $source = $self->source;

  my $content = '';

  $source->process(\$template, $data, \$content);

  return $content;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Template

=cut

=head1 ABSTRACT

Data-Object Template Class

=cut

=head1 SYNOPSIS

  use Data::Object::Template;

  my $template = Data::Object::Template->new;

  $template->render($string, $vars);

=cut

=head1 DESCRIPTION

Data::Object::Template provides methods for rendering templates and
encapsulates the behavior of L<Template::Tiny>.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 buildproxy

  # given $template

  $template->BUILDPROXY(...);

  # ...

The BUILDPROXY method handles resolving missing-methods via autoloaded. This
method is never called directly.

=cut

=head2 origin

  # given $template

  $template->origin();

  # ...

The origin method returns the package name of the proxy used.

=cut

=head2 source

  # given $source

  $template->source();

  # Template::Tiny

The source method returns the underlying proxy object used.

=cut

=head2 render

  # given $template

  $template->render($content, $variables);

  # ...

The render method renders the given template interpolating the given variables.

=cut
