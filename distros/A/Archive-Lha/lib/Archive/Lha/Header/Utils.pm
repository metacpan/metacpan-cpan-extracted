package Archive::Lha::Header::Utils;

use strict;
use warnings;
use Carp;
use Time::Local ();
use POSIX ();
eval { require Archive::Lha::Decode::Base };  # bootstrap XS functions
use Exporter::Lite;

our @EXPORT = qw(
  _int _short _dostime2utime dostime_fields _os_id _extended_header _extended_header_buf
);

sub _int   { unpack 'V', ( pack 'aaaa', @_ ) }
sub _short { unpack 'v', ( pack 'aa',   @_ ) }

# Fast variants that operate directly on a raw buffer + offset
sub _int_at   { unpack 'V', substr($_[0], $_[1], 4) }
sub _short_at { unpack 'v', substr($_[0], $_[1], 2) }

# Decode DOS timestamp into (sec, min, hour, mday, mon_0based, year_since_1900)
sub dostime_fields {
  return (0) x 6 unless @_ && $_[0];
  my $v = $_[0];
  return (
    ($v & 0x1F) * 2,
    ($v >>  5) & 0x3F,
    ($v >> 11) & 0x1F,
    ($v >> 16) & 0x1F,
    (($v >> 21) & 0x0F) - 1,
    (($v >> 25) & 0x7F) + 80,
  );
}

sub _dostime2utime {
  return 0 unless @_ && $_[0];
  return Archive::Lha::Header::Utils::dostime2utime($_[0])
    if defined &Archive::Lha::Header::Utils::dostime2utime;
  my $v = $_[0];
  my @t = (
    ($v & 0x1F) * 2,
    ($v >>  5) & 0x3F,
    ($v >> 11) & 0x1F,
    ($v >> 16) & 0x1F,
    (($v >> 21) & 0x0F) - 1,
    (($v >> 25) & 0x7F) + 80,
  );
  eval { Time::Local::timegm(@t) } // 0;
}

sub _os_id {
  my $hex = ref $_[0] ? ord($_[0]) : ord(substr($_[0], 0, 1));

  return [ M => 'MS-DOS' ]    if $hex == 0x4D;
  return [ w => 'WinNT' ]     if $hex == 0x57;
  return [ w => 'Win95' ]     if $hex == 0x77;
  return [ g => 'generic' ]   if $hex == 0x00;
  return [ U => 'UNIX' ]      if $hex == 0x55;
  return [ m => 'Macintosh' ] if $hex == 0x6D;
  return [ J => 'Java VM' ]   if $hex == 0x4A;
  return [ 2 => 'OS/2' ]      if $hex == 0x32;
  return [ 9 => 'OS/9' ]      if $hex == 0x39;
  return [ K => 'OS/68K' ]    if $hex == 0x4B;
  return [ 3 => 'OS/386' ]    if $hex == 0x33;
  return [ H => 'Human68K' ]  if $hex == 0x48;
  return [ C => 'CP/M' ]      if $hex == 0x43;
  return [ F => 'FLEX' ]      if $hex == 0x46;
  return [ R => 'Runser' ]    if $hex == 0x52;
  return [ T => 'TownsOS' ]   if $hex == 0x54;
  return [ X => 'XOSK' ]      if $hex == 0x58;
  return [ a => 'Amiga' ];
}

# Legacy: called with a list of single chars
sub _extended_header {
  my $buf = join '', @_;
  return _extended_header_buf($buf, 0, length($buf));
}

# Fast: called with a raw buffer, offset, and length
sub _extended_header_buf {
  my ($buf, $from, $len) = @_;
  my $to   = $from + $len;
  my $next = unpack 'v', substr($buf, $to - 2, 2);

  my %hash;
  my $type = ord(substr($buf, $from, 1));

  if ( $type == 0x00 ) {
    $hash{additional_crc} = unpack 'v', substr($buf, $from + 1, 2);
  }
  elsif ( $type == 0x01 ) {
    my $name = substr($buf, $from + 1, $len - 3);
    $name =~ s/\0.*//s;
    $hash{filename} = $name;
  }
  elsif ( $type == 0x02 ) {
    my $dir = substr($buf, $from + 1, $len - 3);
    $dir =~ s/\0.*//s;
    $hash{directory} = $dir;
  }
  elsif ( $type == 0x50 ) {
    $hash{unix_perm} = unpack 'v', substr($buf, $from + 1, 2);
  }
  elsif ( $type == 0x51 ) {
    $hash{unix_gid} = unpack 'v', substr($buf, $from + 1, 2);
    $hash{unix_uid} = unpack 'v', substr($buf, $from + 3, 2);
  }
  elsif ( $type == 0x52 ) {
    $hash{unix_group} = substr($buf, $from + 1, $len - 3);
  }
  elsif ( $type == 0x54 ) {
    $hash{timestamp}         = unpack 'V', substr($buf, $from + 1, 4);
    $hash{timestamp_is_unix} = 1;
  }
  elsif ( $type == 0x39 || $type == 0x3F || $type == 0x40 || $type == 0x41
       || $type == 0x42 || $type == 0x46 || $type == 0x7D || $type == 0x7E ) {
    # known but ignored header types
  }
  else {
    warn sprintf "Unknown extended header type: %02x\n", $type;
  }

  return ($next, \%hash);
}

1;

__END__

=head1 NAME

Archive::Lha::Header::Utils

=head1 DESCRIPTION

This is used internally to export several undocumented utility functions.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
