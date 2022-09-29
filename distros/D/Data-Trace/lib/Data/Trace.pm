package Data::Trace;

use 5.006;
use strict;
use warnings;

use FindBin();
use lib $FindBin::RealBin;

use Data::Tie::Watch;     # Tie::Watch copy.
use Data::DPath;          # All refs in a struct.
use Carp qw(longmess);    # Stack trace.

=head1 NAME

Data::Trace - Trace when a data structure gets updated.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Data::Trace;

    my $data = {a => [0, {complex => 1}]};
    sub BadCall{ $data->{a}[0] = 1 }
    Data::Trace->Trace($data);
    BadCall();  # Shows strack trace of where data was changed.

=head1 DESCRIPTION

This module provides a convienient way to find out
when a data structure has been updated.

It is a debugging/tracing aid for complex systems to identify unintentional
alteration to data structures which should be treated as read-only.

Probably can also create a variable as read-only in Moose and see where
its been changed, but this module is without Moose support.

=head1 SUBROUTINES/METHODS

=head2 Trace

 Data::Trace->Trace( \$scalar );
 Data::Trace->Trace( \@array );
 Data::Trace->Trace( \@hash );
 Data::Trace->Trace( $complex_data );

=cut

sub Trace {
    my ( $self, $data ) = @_;

    if ( not ref $data ) {
        die "Error: data must be a reference!";
    }

    my @nodes = grep { ref } Data::DPath->match( $data, "//" );

    for my $node ( @nodes ) {

        # print "Tying: $node\n";
        Data::Tie::Watch->new(
            -variable => $node,
            -store    => sub {
                my ( $self, $v ) = @_;
                $self->Store( $v );
                print "Storing here:" . longmess();
            }
        );
    }
}

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/poti1/data-trace/issues>.

Currently only detect C<STORE> operations.
Expand this to also detect C<PUSH>, C<POP>, C<DELETE>, etc.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Trace

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Data::Trace
