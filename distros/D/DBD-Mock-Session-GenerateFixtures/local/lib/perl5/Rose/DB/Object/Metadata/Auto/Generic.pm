package Rose::DB::Object::Metadata::Auto::Generic;

use strict;

use Rose::DB::Object::Metadata::Auto;
our @ISA = qw(Rose::DB::Object::Metadata::Auto);

our $VERSION = '0.1';

sub auto_generate_unique_keys { wantarray ? () : [] }

1;
