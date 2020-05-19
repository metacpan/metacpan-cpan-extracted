# Data::Hopen::G::OutputOp - operation with a fixed output
package Data::Hopen::G::OutputOp;
use Data::Hopen;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000018';

use parent 'Data::Hopen::G::Op';
use Class::Tiny qw(output);

# Docs {{{1

=head1 NAME

Data::Hopen::G::OutputOp - operation with a fixed output

=head1 SYNOPSIS

This is a L<Data::Hopen::G::Op> that simply outputs a fixed value you
provide.  Usage:

    my $op = Data::Hopen::G::OutputOp(output => { foo => 42, bar => 1337 });

=head1 MEMBERS

=head2 output

A hashref that will be the output.

=cut

# }}}1

=head1 FUNCTIONS

=head2 _run

Implementation of L<Data::Hopen::G::Runnable/run>.

=cut

sub _run {
    my $self = shift or croak 'Need an instance';
    croak 'output is not a hashref' unless ref $self->output eq 'HASH';
    return $self->output;
} #_run()

1;
__END__
# vi: set fdm=marker: #
