# Data::Hopen::G::Node - base class for hopen nodes
package Data::Hopen::G::Node;
use Data::Hopen;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000021';

sub outputs;

use parent 'Data::Hopen::G::Runnable';
use Class::Tiny qw(outputs);

=head1 NAME

Data::Hopen::G::Node - The base class for all hopen nodes

=head1 VARIABLES

=head2 outputs

Hashref of the outputs from the last time this node was run.  Default C<{}>.

=cut

=head1 FUNCTIONS

=head2 outputs

Custom accessor for outputs, which enforces the invariant that outputs must
be hashrefs.

=cut

sub outputs {
    my $self = shift;
    croak 'Need an instance' unless $self;
    if (@_) {                               # Setter
        croak "Cannot set `outputs` of @{[$self->name]} to non-hashref " .
                ($_[0] // '(undef)')
            unless ref $_[0] eq 'HASH';
        return $self->{outputs} = shift;
    } elsif ( exists $self->{outputs} ) {   # Getter
        return $self->{outputs};
    } else {                                # Default
        return +{};
    }
} #outputs()

#DEBUG: sub BUILD { use Data::Dumper; say __PACKAGE__,Dumper(\@_); }
1;
__END__
# vi: set fdm=marker: #
