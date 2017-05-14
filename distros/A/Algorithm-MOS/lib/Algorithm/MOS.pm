#!/usr/bin/perl
use strict;
use warnings;
package Algorithm::MOS;
# ABSTRACT: Algorithm::MOS - Calculate MOS (Mean Opinion Score)

use Carp;

use parent 'Exporter';
our @EXPORT = ('calc_mos');

sub mos {
    my ( $average, $jitter, $packet_loss ) = @_
        or croak 'mos( average, jitter, packet_loss )';

    my $r_value;
    my $ret_val;

    # Take the average latency, add jitter, but double the impact to latency
    # then add 10 for protocol latancies
    my $effective_latency = ( $average + $jitter * 2 + 10 );

    # Implement a basic curve - deduct 4 for the r_value at 160ms of latency
    # (round trip). Anything over that gets a much more agressive deduction
    if ($effective_latency < 160) {
        $r_value = 93.2 - ($effective_latency / 40);
    }
    else {
        $r_value = 93.2 - ($effective_latency - 120) / 10;
    }

    # Now, let's deduct 2.5 r_value per percentage of packet_loss
    $r_value = $r_value - ($packet_loss * 2.5);

    # Convert the r_value into an MOS value. (this is a known formula)
    $ret_val = 1 + 
        (0.035) *
        $r_value +
        (0.000007) *
        $r_value *
        ($r_value - 60) *
        (100 - $r_value);
    $ret_val = sprintf( "%.3f", $ret_val);

    return $ret_val;
}

1;

__END__

=pod

=head1 NAME

Algorithm::MOS - Algorithm::MOS - Calculate MOS (Mean Opinion Score)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Algorithm::MOS;
    my $result = mos( $average, $jitter, $packet_loss );
    print $result, "\n";

=head1 DESCRIPTION

More to come.

=head1 AUTHOR

Adam Balali <adamba@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Adam Balali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
