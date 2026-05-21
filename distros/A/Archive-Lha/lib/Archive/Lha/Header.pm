package Archive::Lha::Header;

use strict;
use warnings;
use Carp;
use Archive::Lha::Header::Level0;
use Archive::Lha::Header::Level1;
use Archive::Lha::Header::Level2;

my @_parsers = (
  'Archive::Lha::Header::Level0',
  'Archive::Lha::Header::Level1',
  'Archive::Lha::Header::Level2',
);

sub new {
  my ($class, %options) = @_;

  croak "Stream is missing"       unless defined $options{stream};
  croak "Header level is missing" unless defined $options{level};

  my $level = $options{level};
  croak "Illegal header level: $level"
    unless $level =~ /^[0-2]$/;

  $_parsers[$level]->new( $options{stream} );
}

1;

__END__

=head1 NAME

Archive::Lha::Header

=head1 SYNOPSIS

  while ( defined ( my $level = $stream->search_header ) ) {
    my $header = Archive::Lha::Header->new(
      level  => $level,
      stream => $stream
    );
    $stream->seek( $header->next_header );
  }

=head1 DESCRIPTION

This is a factory class to create a proper header object. Each ::Header subclass has several public methods and several minor private properties. See L<Archive::Lha::Header::Base> for details.

=head1 METHODS

=head2 new

takes a hash as an argument and returns a delegated header object. Required options are:

=over 4

=item level

LHa header level (0 to 2). Actually Level 3 header is proposed but I don't think there's substantial implementation that supports it while creating archives.

=item stream

(a subclass of) Archive::Lha::Stream object.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
