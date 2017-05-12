
package Page;
use metaclass 'Moose::Meta::Class' => (
  attribute_metaclass => 'Continuity::Meta::Attribute::FormField'
);

use Moose;
extends 'Widget';

has name => (
  is => 'rw',
  isa => 'Str',
  label => 'Name',
);

has content => (
  is => 'rw',
  isa => 'Str',
  label => 'Content',
);

before main => sub {
  my ($self) = @_;
  $self->add_button('Edit' => sub { $self->edit });
};

sub edit {
  my ($self) = @_;
}

sub wiki2html {
  my ($self, $content) = @_;
  $content =~ s/\n\n/\n<p>\n/g;
  $content =~ s/\[([^\]]+)\]/<a href="?page=$1">$1<\/a>/g;
  return $content;
}

