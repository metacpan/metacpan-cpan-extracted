# Data::Hopen::G::NoOp - null operation.  Used for testing.
package Data::Hopen::G::NoOp;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000017';

use parent 'Data::Hopen::G::Op';
use Class::Tiny;

# Docs {{{1

=head1 NAME

Data::Hopen::G::NoOp - a no-op

=head1 SYNOPSIS

An C<NoOp> is a concrete L<Data::Hopen::G::Op> that returns C<{}>.
It is mostly used for testing.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _run

Return C<{}>.  All arguments are ignored.
Usage: C<< my $hrOutputs = $op->run; >>.

=cut

sub _run {
    return {};
} #run()

1;
__END__
# vi: set fdm=marker: #
