package TestSchema::Result;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

use TestUtils::MakeInstanceMetaClassNonInlinableIf
  $ENV{DBIC_MOOSECOLUMNS_NON_INLINABLE};

use DBIx::Class::MooseColumns;

extends 'DBIx::Class::Core';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 )
  if $ENV{DBIC_MOOSECOLUMNS_IMMUTABLE} && !$ENV{DBIC_MOOSECOLUMNS_NON_INLINABLE};

1;
