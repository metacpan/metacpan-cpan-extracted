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

  BUILDPROXY(Any @args) : Any

The BUILDPROXY method handles resolving missing-methods via autoloaded. This
method is never called directly.

=over 4

=item BUILDPROXY example

  # given $template

  $template->BUILDPROXY(...);

  # ...

=back

=cut

=head2 origin

  origin() : Str

The origin method returns the package name of the proxy used.

=over 4

=item origin example

  # given $template

  $template->origin();

  # ...

=back

=cut

=head2 render

  render(Str $arg1, HashRef $arg2) : Str

The render method renders the given template interpolating the given variables.

=over 4

=item render example

  # given $template

  $template->render($content, $variables);

  # ...

=back

=cut

=head2 source

  source() : Object

The source method returns the underlying proxy object used.

=over 4

=item source example

  # given $source

  $template->source();

  # Template::Tiny

=back

=cut
