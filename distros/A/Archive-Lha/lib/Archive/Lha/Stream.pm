package Archive::Lha::Stream;

use strict;
use warnings;
use Carp;

sub new {
  my ($class, %options) = @_;

  my @available = qw( file string hex );
  foreach my $name ( @available ) {
    if ( $options{$name} ) {
      my $package = 'Archive::Lha::Stream::'.ucfirst($name);
      eval "require $package;";
      croak "Can't load stream: $@" if $@;
      return $package->new( %options );
    }
  }
  croak "Can't load stream: available streams are " .
         (join ', ', @available);
}

1;

__END__

=head1 NAME

Archive::Lha::Stream

=head1 SYNOPSIS

  # if you want to read from an archive file
  my $stream = Archive::Lha::Stream->new( file => 'some.lzh' );

  # if you want to read from a string on memory
  my $stream = Archive::Lha::Stream->new( string => $content_of_lzh );
  # just for debugging: you can pass an arrayref of hex strings
  my $stream = Archive::Lha::Stream->new( hex => [qw(5D 00 ...)]' );

=head1 DESCRIPTION

This is a factory class to create a proper stream object. Available stream types are file, string, hex.

=head1 METHODS

=head2 new

takes a hash as an argument and returns a delegated stream object. See SYNOPSIS for the required option.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
