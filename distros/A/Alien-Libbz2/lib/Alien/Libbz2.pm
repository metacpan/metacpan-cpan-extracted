package Alien::Libbz2;

use strict;
use warnings;
use 5.008001;
use base 'Alien::Base';

# ABSTRACT: Build and make available bz2
our $VERSION = '0.22'; # VERSION


sub alien_helper
{
  return {
    bzip2 => sub { 'bzip2' },
  };
}

# TODO: this should eventually be correctly handled by
# Alien::Build
sub config {
  my($class, $key) = @_;
  return 'bz2' if $key eq 'name' || $key eq 'ffi_name';
  return $class->SUPER::config($key);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Libbz2 - Build and make available bz2

=head1 VERSION

version 0.22

=head1 SYNOPSIS

 use Alien::Libbz2;
 
 my $cflags = Alien::Libbz2->cflags;
 my $libs   = ALien::Libbz2->libs;

=head1 DESCRIPTION

This L<Alien> module provides the necessary compiler and linker flags needed
for using libbz2 in XS.

=head1 METHODS

=head2 cflags

 my $cflags = Alien::Libbz2->cflags;

Returns the C compiler flags.

=head2 libs

 my $libs = Alien::Libbz2->libs;

Returns the linker flags.

=head1 HELPERS

=head2 bzip2

 %{bzip2}

Returns the name of the bzip2 command.  Usually just C<bzip2>.

=head1 SEE ALSO

=over 4

=item L<Alien::bz2>

Another libbz2 L<Alien> module, but not implemented with L<Alien::Base>.

=item L<Compress::Bzip2>

=item L<Compress::Raw::Bzip2>

=item L<IO::Compress::Bzip2>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
