package Data::Record::Serialize::Types;

# ABSTRACT: Types for Data::Record::Serialize

use strict;
use warnings;

our $VERSION = '0.24';

use Type::Utils -all;
use Types::Standard qw( ArrayRef Str Enum );
use Type::Library -base,
  -declare => qw[ ArrayOfStr SerializeType ];

use namespace::clean;

declare ArrayOfStr,
  as ArrayRef[ Str ];

coerce ArrayOfStr,
  from Str, q { [ $_ ] };

declare SerializeType,
  as Enum[ qw( N I S B) ];

# COPYRIGHT

1;
