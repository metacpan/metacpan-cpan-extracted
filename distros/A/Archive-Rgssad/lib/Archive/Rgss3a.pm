package Archive::Rgss3a;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Archive::Rgssad;
use Archive::Rgssad::Entry;
use Archive::Rgssad::Keygen 'keygen';

our @ISA = qw(Archive::Rgssad);

=head1 NAME

Archive::Rgss3a - Provide an interface to rgss3a archive files.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

    use Archive::Rgss3a;

    my $rgss3a = Archive::Rgss3a->new('Game.rgss3a');
    for my $entry ($rgss3a->entries) {
      ...
    }

=head1 SUBROUTINES/METHODS

=head2 Constructor

=over 4

=item new([$io])

Create an empty rgss3a archive. If an additional argument is passed, call
C<load> to load the entries from it.

=back

=cut

sub new {
  my $class = shift;
  my $self = {
    magic   => "RGSSAD\x00\x03",
    entries => []
  };
  bless $self, $class;
  $self->load(shift) if @_;
  return $self;
}

=head2 Load and Save

=over 4

=item load($io)

Load entries from C<$io>, which should be either a readable instance of
IO::Handle or its subclasses or a valid filepath.

=cut

sub load {
  my $self = shift;
  my $file = shift;
  my $fh = ref($file) eq '' ? IO::File->new($file, 'r') : $file;
  $fh->binmode(1);

  $fh->read($_, 8);
  $fh->read($_, 4);
  my $key = unpack('V');
  {
    use integer;
    $key = ($key * 9 + 3) & 0xFFFFFFFF;
  }

  my @headers = ();
  while (1) {
    $fh->read($_, 16);
    my @header = map { $_ ^ $key } unpack('V*');
    last if $header[0] == 0;

    $fh->read($_, $header[3]);
    $_ ^= pack('V', $key) x (($header[3] + 3) / 4);
    push @header, substr($_, 0, $header[3]);
    push @headers, \@header;
  }

  my @entries = ();
  for my $header (@headers) {
    my ($off, $len, $key) = @$header;
    my $path = $header->[-1];
    my $data = '';
    $fh->seek($off, 0);
    $fh->read($data, $len);
    $data ^= pack('V*', keygen($key, ($len + 3) / 4));
    push @entries, Archive::Rgssad::Entry->new($path, substr($data, 0, $len));
  }

  $self->{entries} = \@entries;
  $fh->close;
}

=item save($io)

Save the entries to C<$io>, which should be either a writable instance of
IO::Handle or its subclasses or a valid filepath.

=back

=cut

sub save {
  my $self = shift;
  my $file = shift;
  my $fh = ref($file) eq '' ? IO::File->new($file, 'w') : $file;
  $fh->binmode(1);

  $fh->write($self->{magic}, 8);
  my $key = 0;
  $fh->write(pack('V', $key), 4);
  {
    use integer;
    $key = ($key * 9 + 3) & 0xFFFFFFFF;
  }

  my $off = 12;
  for my $entry ($self->entries) {
    $off += 16 + length $entry->path;
  }
  $off += 16;

  for my $entry ($self->entries) {
    my $len = length $entry->path;
    my $path = $entry->path;
    $path ^= pack('V', $key) x (($len + 3) / 4);
    $path = substr($path, 0, $len);
    $fh->write(pack('V*', map { $_ ^ $key } ($off, length $entry->data, 0, $len)), 16);
    $fh->write($path, $len);
    $off += length $entry->data;
  }
  $fh->write(pack('V*', map { $_ ^ $key } (0, 0, 0, 0)), 16);

  for my $entry ($self->entries) {
    my $key = 0;
    my $len = length $entry->data;
    my $data = $entry->data;
    $data ^= pack('V*', keygen($key, ($len + 3) / 4));
    $data = substr($data, 0, $len);
    $fh->write($data, $len);
  }

  $fh->close;
}

=head2 Manipulate Entries

See C<Archive::Rgssad>.

=cut

=head1 AUTHOR

Zejun Wu, C<< <watashi at watashi.ws> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::Rgss3a


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/watashi/perl-archive-rgssad>

=back


=head1 ACKNOWLEDGEMENTS

A special thanks to fux2, who shared his discovery about the rgss3a format and published the decryption algorithm.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zejun Wu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Archive::Rgss3a
