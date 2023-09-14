package Connector::Builtin::Inline;

use strict;
use warnings;
use English;
use Data::Dumper;

use Moose;

extends 'Connector::Builtin::Memory';

has '+_config' => (
    init_arg => 'data',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 Name

Connector::Builtin::Inline

=head1 Description

Inherits from Memory and loads the structure given to I<data> as
innitial value.

=head1 Parameters

=over

=item LOCATION

Not used / required.

=item data

The payload of the connector, can be HashRef, ArrayRef or any scalar.

=back
