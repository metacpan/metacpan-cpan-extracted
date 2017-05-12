package TestApp::Object;

use Moose;
use strict;
use warnings;

has "index" => (
  is => "ro",
  isa => "Int",
);

has "entry" => (
  is => "ro",
  isa => "Str",
);

1;
