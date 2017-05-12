package Archive::Rgssad;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Archive::Rgssad::Entry;
use Archive::Rgssad::Keygen 'keygen';

=head1 NAME

Archive::Rgssad - Provide an interface to rgssad and rgss2a archive files.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

    use Archive::Rgssad;

    my $rgssad = Archive::Rgssad->new('Game.rgssad');
    for my $entry ($rgssad->entries) {
      ...
    }

=head1 SUBROUTINES/METHODS

=head2 Constructor

=over 4

=item new([$io])

Create an empty rgssad archive. If an additional argument is passed, call
C<load> to load the entries from it.

=back

=cut

sub new {
  my $class = shift;
  my $self = {
    magic   => "RGSSAD\x00\x01",
    seed    => 0xDEADCAFE,
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

  my @entries = ();
  my $key = $self->{seed};

  $fh->read($_, 8);
  until ($fh->eof) {
    my $entry = Archive::Rgssad::Entry->new;
    my ($buf, $len);

    $fh->read($buf, 4);
    $len = unpack('V', $buf) ^ keygen($key);

    $fh->read($buf, $len);
    $buf ^= pack('C*', map { $_ & 0xFF } keygen($key, $len));
    $entry->path($buf);

    $fh->read($buf, 4);
    $len = unpack('V', $buf) ^ keygen($key);

    $fh->read($buf, $len);
    $_ = $key;
    $buf ^= pack('V*', keygen($_, ($len + 3) / 4));
    $entry->data(substr($buf, 0, $len));

    push @entries, $entry;
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

  my $key = $self->{seed};

  $fh->write($self->{magic}, 8);
  for my $entry ($self->entries) {
    my ($buf, $len);

    $len = length $entry->path;
    $fh->write(pack('V', $len ^ keygen($key)), 4);

    $buf = $entry->path ^ pack('C*', map { $_ & 0xFF } keygen($key, $len));
    $fh->write($buf, $len);

    $len = length $entry->data;
    $fh->write(pack('V', $len ^ keygen($key)), 4);

    $_ = $key;
    $buf = $entry->data ^ pack('V*', keygen($_, ($len + 3) / 4));
    $fh->write($buf, $len);
  }

  $fh->close;
}

=head2 Manipulate Entries

=over 4

=item entries

Return all entries.

=cut

sub entries {
  my $self = shift;
  return @{$self->{entries}};
}

=item get($path)

Return all entries with specified path. In scalar context, just return the
first one.

=cut

sub get {
  my $self = shift;
  my $arg = shift;
  my @ret = grep { $_->path eq $arg } $self->entries;
  return wantarray ? @ret : $ret[0];
}

=item add($path => $data, ...)

=item add($entry, ...)

Add new entries like $entry or Archive::Rgssad::Entry->new($path, $data).

=cut

sub add {
  my $self = shift;
  while (@_ > 0) {
    $_ = shift;
    if (ref eq 'Archive::Rgssad::Entry') {
      push @{$self->{entries}}, $_;
    } else {
      push @{$self->{entries}}, Archive::Rgssad::Entry->new($_, shift);
    }
  }
}

=item remove($path)

=item remove($entry)

If an entry is passed, remove the entries with the same path and data.
Otherwise, remove all entries with specified path.

=back

=cut

sub remove {
  my $self = shift;
  my $arg = shift;
  if (ref($arg) eq 'Archive::Rgssad::Entry') {
    $self->{entries} = [grep { $_->path ne $arg->path ||
                               $_->data ne $arg->data } $self->entries];
  } else {
    $self->{entries} = [grep { $_->path ne $arg } $self->entries];
  }
}

=head1 AUTHOR

Zejun Wu, C<< <watashi at watashi.ws> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::Rgssad


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/watashi/perl-archive-rgssad>

=back


=head1 ACKNOWLEDGEMENTS

A special thanks to leexuany, who shared his discovery about the rgssad format and published the decryption algorithm.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zejun Wu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Archive::Rgssad
