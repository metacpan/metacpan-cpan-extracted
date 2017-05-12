package MyDBIC::Base::DBIC;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );

use base 'DBIx::Class';

__PACKAGE__->load_components(qw( RDBOHelpers Core ));

sub schema_class_prefix { 'MyDBIC::Schema' }

1;
