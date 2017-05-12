package TestDBIx::Error;

use Moose;
use strict;
use warnings;

extends "DBIx::Error";

__PACKAGE__->define_exception_classes (
  "TS000" => "General",
  "TS001" => "Specific",
);

__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
