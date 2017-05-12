package Cikl::Smrt::ParserHelpers::XPathRegexMapping;

use strict;
use warnings;
use Mouse;
use Mouse::Util::TypeConstraints;


has 'event_fields' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  required => 1
);

has 'xpath' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'regex' => (
  is => 'ro',
  isa => 'RegexpRef',
  required => 1
);

sub BUILD {
  my $self = shift;

  if ( $#{$self->event_fields} == -1 ) {
    die 'event_fields: at least one field name required!';
  }
}

__PACKAGE__->meta->make_immutable;

1;


