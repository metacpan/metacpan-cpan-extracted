use strict;
use warnings;
package AnyEvent::OWNet::Constants;
$AnyEvent::OWNet::Constants::VERSION = '1.163170';
# ABSTRACT: Module to export constants for 1-wire File System daemon protocol


my %constants =
  (
   OWNET_BUS_RET     => 0x00000002,
   OWNET_PERSISTENT  => 0x00000004,
   OWNET_ALIAS       => 0x00000008,
   OWNET_SAFEMODE    => 0x00000010,
   OWNET_NET         => 0x00000100,

   OWNET_CENTIGRADE  => 0x00000000,
   OWNET_FAHRENHEIT  => 0x00010000,
   OWNET_KELVIN      => 0x00020000,
   OWNET_RANKINE     => 0x00030000,
   OWNET_TEMP_MASK   => 0x00030000,

   OWNET_MILLIBAR      => 0x00000000,
   OWNET_ATMOSPHERE    => 0x00040000,
   OWNET_MM_MERCURY    => 0x00080000,
   OWNET_IN_MERCURY    => 0x000C0000,
   OWNET_PSI           => 0x00100000,
   OWNET_PASCAL        => 0x00140000,
   OWNET_PRESSURE_MASK => 0x001C0000,

   OWNET_DISP_F_I    => 0x00000000, # f.i    e.g. /10.67C6697351FF
   OWNET_DISP_FI     => 0x01000000, # fi     e.g. /1067C6697351FF
   OWNET_DISP_F_I_C  => 0x02000000, # f.i.c  e.g. /10.67C6697351FF.8D
   OWNET_DISP_F_IC   => 0x03000000, # f.ic   e.g. /10.67C6697351FF8D
   OWNET_DISP_FI_C   => 0x04000000, # fi.c   e.g. /10.67C6697351FF8D
   OWNET_DISP_FIC    => 0x05000000, # fic    e.g. /1067C6697351FF8D
   OWNET_DISP_MASK   => 0x07000000,

   OWNET_MSG_NOP         => 0x1, # deprecated
   OWNET_MSG_READ        => 0x2,
   OWNET_MSG_WRITE       => 0x3,
   OWNET_MSG_DIR         => 0x4,
   OWNET_MSG_SIZE        => 0x5, # deprecated
   OWNET_MSG_PRESENT     => 0x6,
   OWNET_MSG_DIRALL      => 0x7,
   OWNET_MSG_GET         => 0x8,
   OWNET_MSG_DIRALLSLASH => 0x9,
   OWNET_MSG_GETSLASH    => 0xa,

   OWNET_DEFAULT_DATA_SIZE => 0x80e8,
  );

$constants{OWNET_DEFAULT_FLAGS} =
  $constants{OWNET_NET} | $constants{OWNET_BUS_RET} |
  $constants{OWNET_ALIAS} | $constants{OWNET_PERSISTENT};

sub import {
  no strict qw/refs/; ## no critic
  my $pkg = caller(0);
  foreach (keys %constants) {
    my $v = $constants{$_};
    *{$pkg.'::'.$_} = sub () { $v };
  }
  *{$pkg.'::ownet_temperature_units'} = \&ownet_temperature_units;
  *{$pkg.'::ownet_pressure_units'} = \&ownet_pressure_units;
  *{$pkg.'::ownet_display_format'} = \&ownet_display_format;
}


sub ownet_temperature_units {
  my $flag = shift;
  [qw/C F K R/]->[($flag & $constants{OWNET_TEMP_MASK}) >> 16]
}


sub ownet_pressure_units {
  my $flag = shift;
  [qw/mbar atm mmHg
      inHg psi Pa/]->[($flag & $constants{OWNET_PRESSURE_MASK}) >> 18]
}


sub ownet_display_format {
  my $flag = shift;
  [qw/f.i fi f.i.c
      f.ic fi.c fic/]->[($flag & $constants{OWNET_DISP_MASK}) >> 24]
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::OWNet::Constants - Module to export constants for 1-wire File System daemon protocol

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  use AnyEvent::OWNet::Constants;

=head1 DESCRIPTION

Module to export constants for owfs daemon protocol.

=head1 C<FUNCTIONS>

=head2 C<ownet_temperature_units( $flags )>

Returns the temperature units for the given flags from an
L<AnyEvent::OWNet::Response> flags attribute.

=head2 C<ownet_pressure_units( $flags )>

Returns the pressure units for the given flags from an
L<AnyEvent::OWNet::Response> flags attribute.

=head2 C<ownet_display_format( $flags )>

Returns the display format from the given flags of an
L<AnyEvent::OWNet::Response> flags attribute.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
