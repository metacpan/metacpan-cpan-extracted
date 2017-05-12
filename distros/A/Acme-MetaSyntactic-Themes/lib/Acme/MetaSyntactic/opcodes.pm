package Acme::MetaSyntactic::opcodes;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';

# get the list from the current perl
use Opcode qw( opset_to_ops full_opset );
__PACKAGE__->init(
    { names => join( " ", map { uc "OP_$_" } opset_to_ops(full_opset) ) } );

1;

__END__

=head1 NAME

Acme::MetaSyntactic::opcodes - The Perl opcodes theme

=head1 DESCRIPTION

The names of the Perl opcodes. They are given by the
L<Opcode> module.

=head1 CONTRIBUTORS

Abigail, Philippe Bruhat (BooK)

=head1 DEDICATION

This module is dedicated to Perl, which turned 18 years old the day
before this release was published.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-12-19

Introduced in Acme-MetaSyntactic version 0.53, with the opcodes obtained
automatically from the L<Opcode> module.

=item *

2005-10-25

Submitted by Abigail as a simple list, with the C<OP_> prefix removed.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

