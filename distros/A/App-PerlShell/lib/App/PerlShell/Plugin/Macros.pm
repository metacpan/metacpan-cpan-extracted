package App::PerlShell::Plugin::Macros;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Pod::Usage;
use Pod::Find qw( pod_where );

use Exporter;

our @EXPORT = qw(
  Macros
  D2B
  D2H
  H2B
  H2D
  H2S
  S2H
);

our @ISA = qw ( Exporter );

sub Macros {
    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

########################################################

sub D2B {
    my ( $dec, $pad ) = @_;

    if ( not defined $dec ) {
        _help( "MACROS/D2B - convert decimal number to binary" );
        return;
    }

    my $ret;
    if ( $dec =~ /^\d+$/ ) {
        $ret = sprintf "%b", $dec;
        if ( defined $pad ) {
            if ( $pad =~ /^\d+$/ ) {
                $pad = "0" x ( $pad - length($ret) );
                $ret = $pad . $ret;
            } else {
                warn "Ignoring not a number pad `$pad'\n";
            }
        }
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        warn "Not a decimal number `$dec'\n";
    }
}

sub D2H {
    my ($dec) = @_;

    if ( not defined $dec ) {
        _help( "MACROS/D2H - convert decimal number to hex" );
        return;
    }

    my $ret;
    if ( $dec =~ /^\d+$/ ) {
        $ret = sprintf "%x", $dec;
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        warn "Not a decimal number `$dec'\n";
    }
}

sub H2B {
    my ( $hex, $pad ) = @_;

    if ( not defined $hex ) {
        _help( "MACROS/H2B - convert hex number to binary" );
        return;
    }

    my $ret;
    if ( $hex =~ /^(?:0x)?[0-9a-fA-F]+$/ ) {
        $ret = sprintf "%b", $hex;
        if ( defined $pad ) {
            if ( $pad =~ /^\d+$/ ) {
                $pad = "0" x ( $pad - length($ret) );
                $ret = $pad . $ret;
            } else {
                warn "Ignoring not a number pad `$pad'\n";
            }
        }
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        warn "Not a hex number `$hex'\n";
    }
}

sub H2D {
    my ($hex) = @_;

    if ( not defined $hex ) {
        _help( "MACROS/H2D - convert hex number to decimal" );
        return;
    }

    my $ret;

    # passed as number
    if ( $hex =~ /^\d+$/ ) {
        if ( !defined wantarray ) {
            print "$hex\n";
        }
        return $hex;
    }

    # passed as string
    if ( $hex =~ /^(?:0x)?[0-9a-fA-F]+$/ ) {
        $ret = hex($hex);
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        warn "Not a hex number `$hex'\n";
    }
}

sub H2S {
    my ($pack) = @_;

    if ( not defined $pack ) {
        _help( "MACROS/H2S - convert hex to string" );
        return;
    }

    my $ret;
    $ret = pack "H*", $pack;
    if ( !defined wantarray ) {
        print "$ret\n";
    }
    return $ret;
}

sub S2H {
    my ($str) = @_;

    if ( not defined $str ) {
        _help( "MACROS/S2H - convert string to hex" );
        return;
    }

    my $ret;
    for ( split //, $str ) {
        $ret .= sprintf "%0.2x", ord $_;
    }
    if ( !defined wantarray ) {
        print "$ret\n";
    }
    return $ret;
}

sub _help {
    my ($section) = @_;

    pod2usage(
        -verbose  => 99,
        -exitval  => "NOEXIT",
        -sections => $section,
        -input    => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

1;

__END__

=head1 NAME

Macros - Provides useful macros for conversions

=head1 SYNOPSIS

 use App::PerlShell::Plugin::Macros;

=head1 DESCRIPTION

This module provides useful macros for conversions.

=head1 COMMANDS

=head2 Macros - provide help

Provides help.

=head1 MACROS

=head2 D2B - convert decimal number to binary

 [$binary =] D2B "decimalNumber" [, padding]

Creates B<$binary> variable as binary representation of B<decimalNumber>.  
Without optional return variable simply prints output.  Optional padding 
is total number of bits for return number.

=head2 D2H - convert decimal number to hex

 [$hex =] D2H "decimalNumber"

Creates B<$hex> variable as hex representation of B<decimalNumber>.  
Without optional return variable simply prints output.

=head2 H2B - convert hex number to binary

 [$binary =] H2B "hexNumber" [, padding]

Creates B<$binary> variable as binary representation of B<hexNumber>.  
Without optional return variable simply prints output.  Optional padding 
is total number of bits for return number.

=head2 H2D - convert hex number to decimal

 [$dec =] H2D "hexNumber"

Creates B<$dec> variable as decimal representation of B<hexNumber>.  
Without optional return variable simply prints output.

=head2 H2S - convert hex to string

 [$pack_string =] H2S "hex_string"

Creates B<$pack_string> variable from B<hex_string>.  
Without optional return variable simply prints output.

=head2 S2H - convert string to hex

 [$hex =] S2H "pack_string"

Creates B<$hex> variable as hex representation of B<pack_string>.  
Without optional return variable simply prints output.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2013, 2018 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
