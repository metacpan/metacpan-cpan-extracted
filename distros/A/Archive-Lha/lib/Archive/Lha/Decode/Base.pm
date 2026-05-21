package Archive::Lha::Decode::Base;

use strict;
use warnings;
use Carp;
use Archive::Lha::Constants;
use Archive::Lha;  # to load XS

my %_params;  # keyed by subclass package name

my @_PARAM_NAMES = qw(
  NPT
  NP
  NT
  NC
  PBIT
  TBIT
  CBIT
  PT_TABLE_BIT
  PT_TABLE_SIZE
  C_TABLE_BIT
  C_TABLE_SIZE
  DICSIZE
  MAXMATCH
  THRESHOLD
);

# Install class methods for each param, looking up via %_params
for my $name (@_PARAM_NAMES) {
  no strict 'refs';
  *{"Archive::Lha::Decode::Base::$name"} = sub { $_params{ ref($_[0]) || $_[0] }{$name} };
}

sub import {
  my ($class, %options) = @_;
  my $caller = caller;

  my $dicbit        = $options{dicbit}        || 13;
  my $max_match     = $options{max_match}     || ( 1 << UCHAR_BIT );
  my $threshold     = $options{threshold}     || 3;
  my $np            = $options{np}            || $dicbit + 1;
  my $pbit          = _bit_length( $np );
  my $pt_table_bit  = $options{pt_table_bit}  || 8;
  my $c_table_bit   = $options{c_table_bit}   || 12;
  my $pt_table_size = 1 << $pt_table_bit;
  my $c_table_size  = 1 << $c_table_bit;
  my $npt  = $pt_table_size >> 1;
  my $nt   = USHORT_BIT + 3;
  my $nc   = UCHAR_MAX  + $max_match + 2 - $threshold;
  my $tbit = _bit_length( $nt );
  my $cbit = _bit_length( $nc );

  $_params{$caller} = {
    NPT           => $npt,
    NP            => $np,
    NT            => $nt,
    NC            => $nc,
    PBIT          => $pbit,
    TBIT          => $tbit,
    CBIT          => $cbit,
    PT_TABLE_BIT  => $pt_table_bit,
    PT_TABLE_SIZE => $pt_table_size,
    C_TABLE_BIT   => $c_table_bit,
    C_TABLE_SIZE  => $c_table_size,
    DICSIZE       => 1 << $dicbit,
    MAXMATCH      => $max_match,
    THRESHOLD     => $threshold,
  };

  {
    no strict 'refs';
    unless ( ${"$class\::_accessors_installed"} ) {
      ${"$class\::_accessors_installed"} = 1;
      for my $name ( qw( pt c tree bit ) ) {
        *{"$class\::$name"} = sub { shift->{$name} };
      }
    }
    push @{"$caller\::ISA"}, $class;
  }
}

sub new {
  my ($class, %options) = @_;

  my $header = $options{header};

  my $self = bless {
    blocksize     => 0,
    read          => $options{read},
    write         => $options{write},
    encoded_size  => $header->{encoded_size},
    original_size => $header->{original_size},
    crc16         => $header->{crc16} || 0,
    map { $_ => $class->$_() } @_PARAM_NAMES,
  }, $class;

  $self;
}

1;

__END__

=head1 NAME

Archive::Lha::Decode::Base

=head1 DESCRIPTION

This is a base class for lh5-7 decoder. See L<Archive::Lha::Decode> for options and examples.

=head1 METHODS

=head2 new

creates an object.

=head2 decode

decodes the archived file and returns CRC-16. See XS source for details.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
