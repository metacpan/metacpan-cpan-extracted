# Connector::Builtin
#
# Proxy class for builtin connector modules
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Builtin;

use strict;
use warnings;
use English;
use Moose;

extends 'Connector';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 NAME

Connector::Builtin

=head 1 DESCRIPTION

This is the base class for all Connector::Builtin implementations.
