package Catalyst::Exception::InvalidArrayLength;

use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::Exception::StructuredParameter';

has 'pointer' => (is=>'ro', required=>1);
has 'max' => (is=>'ro', required=>1);
has 'attempted' => (is=>'ro', required=>1);

sub error {
  return "Pointer '@{[ $_[0]->pointer ]}' has array length of '@{[ $_[0]->attempted ]}' but maximum is '@{[ $_[0]->max ]}'.";
}

__PACKAGE__->meta->make_immutable;
