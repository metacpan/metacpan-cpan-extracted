use strict;
use warnings;
package inc::Metadata;

use Moose;
extends 'Dist::Zilla::Plugin::RemovePrereqs';

use MooseX::Types::Moose qw(ArrayRef Str);
use namespace::autoclean;

has '+modules_to_remove' => (
    isa => ArrayRef[Str],       # fix type to allow non-ascii chars in module name
);

__PACKAGE__->meta->make_immutable;
