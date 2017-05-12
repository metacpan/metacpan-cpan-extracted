package Archive::ByteBoozer2;

=head1 NAME

Archive::ByteBoozer2 - Perl interface to David Malmborg's C<ByteBoozer 2.0>, a data cruncher for Commodore files

=head1 SYNOPSIS

  use Archive::ByteBoozer2 qw(:all);

  # Crunch file:
  crunch($file_name);

  # Crunch file and make executable with start address $xxxx:
  ecrunch($file_name, $address);

  # Crunch file and relocate data to hex address $xxxx:
  rcrunch($file_name, $address);

=head1 DESCRIPTION

David Malmborg's C<ByteBoozer 2.0> is a data cruncher for Commodore files written in C. C<ByteBoozer 2.0> is very much the same as C<ByteBoozer 1.0>, but it generates smaller files and decrunches at about 2x the speed. An additional effort was put into keeping the encoder at about the same speed as before. Obviously it is incompatible with the version C<1.0>.

In Perl the following operations are implemented via C<Archive::ByteBoozer2> package:

=over

=item *
Compressing a file.

=item *
Compressing a file and making an executable with start address C<$xxxx>.

=item *
Compressing a file and relocating data to hex address C<$xxxx>.

=back

Compressed data is by default written into a file named with C<.b2> suffix. Target file must not exist. If you want an executable, use C<ecrunch>. If you want to decrunch yourself, use C<crunch> or C<rcrunch>. The decruncher should be called with C<X> and C<Y> registers loaded with a hi- and lo-byte address of the crunched file in a memory.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

use base qw(Exporter);
our %EXPORT_TAGS = ();
$EXPORT_TAGS{crunch} = [ qw(&crunch) ];
$EXPORT_TAGS{ecrunch} = [ qw(&ecrunch) ];
$EXPORT_TAGS{rcrunch} = [ qw(&rcrunch) ];
$EXPORT_TAGS{all} = [ @{$EXPORT_TAGS{crunch}}, @{$EXPORT_TAGS{ecrunch}}, @{$EXPORT_TAGS{rcrunch}} ];
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };
our @EXPORT = qw();

our $VERSION = '0.03';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head2 crunch

Crunch file:

  crunch($file_name);

=cut

sub crunch {
  my ($file_name) = @_;

  _crunch($file_name, 0, 0, 0);
}

=head2 ecrunch

Crunch file and make executable with start address C<$xxxx>:

  ecrunch($file_name, $address);

=cut

sub ecrunch {
  my ($file_name, $address) = @_;

  _crunch($file_name, $address, 1, 0);
}

=head2 rcrunch

Crunch file and relocate data to hex address C<$xxxx>:

  rcrunch($file_name, $address);

=cut

sub rcrunch {
  my ($file_name, $address) = @_;

  _crunch($file_name, $address, 0, 1);
}

sub _crunch {
  my ($file_name, $address, $is_executable, $is_relocated) = @_;

  unless ($address =~ m/^\d+$/ && $address >= 0x0000 && $address <= 0xffff) {
    die qq{Don't understand, aborting...};
  }

  my $file = _read_file($file_name);
  my $bb_file = _crunch_file($file, $address, $is_executable, $is_relocated);
  _write_file($bb_file, $file);

  printf qq{B2: "%s" -> "%s"\n}, file_name($file), file_name($bb_file);

  free_file($file, $bb_file);
}

sub _read_file {
  my ($file_name) = @_;

  my $file = alloc_file();
  unless (read_file($file, $file_name)) {
    free_file($file);
    die qq{Error: Open file "$file_name" failed, aborting...};
  }

  return $file;
}

sub _crunch_file {
  my ($file, $address, $is_executable, $is_relocated) = @_;

  my $bb_file = alloc_file();
  unless (crunch_file($file, $bb_file, $address, $is_executable, $is_relocated)) {
    free_file($file, $bb_file);
    die qq{Error: Crunch data failed, aborting...};
  }

  return $bb_file;
}

sub _write_file {
  my ($bb_file, $file) = @_;

  my $file_name = file_name($file);
  unless (write_file($bb_file, $file_name)) {
    my $file_name = file_name($bb_file);
    free_file($file, $bb_file);
    die qq{Error: Write file "$file_name" failed, aborting...};
  }
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Archive::ByteBoozer2> exports nothing by default.

You are allowed to explicitly import the C<crunch>, C<ecrunch>, and C<rcrunch> subroutines into the caller's namespace either by specifying their names in the import list (C<crunch>, C<ecrunch>, C<rcrunch>) or by using the module with the C<:all> tag.

=head1 SEE ALSO

L<Archive::ByteBoozer>

=head1 AUTHOR

Pawel Krol, E<lt>djgruby@gmail.comE<gt>.

=head1 VERSION

Version 0.03 (2016-03-31)

=head1 COPYRIGHT AND LICENSE

C<ByteBoozer 2.0> cruncher/decruncher:

Copyright (C) 2016 David Malmborg.

C<Archive::ByteBoozer2> Perl interface:

Copyright (C) 2016 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;
