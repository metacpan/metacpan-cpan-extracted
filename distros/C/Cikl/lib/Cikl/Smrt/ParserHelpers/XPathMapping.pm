package Cikl::Smrt::ParserHelpers::XPathMapping;

use strict;
use warnings;
use Mouse;
use Mouse::Util::TypeConstraints;


has 'event_field' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'xpath' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

__PACKAGE__->meta->make_immutable;

1;

