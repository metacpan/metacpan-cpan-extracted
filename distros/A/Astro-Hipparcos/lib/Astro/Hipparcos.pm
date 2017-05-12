package Astro::Hipparcos;

use 5.008;
use strict;
use warnings;
use Carp 'croak';
use File::Spec;

our $VERSION = '0.09';

use constant LINE_LENGTH => 451; # I wish they were using a modern file format.

require XSLoader;
XSLoader::load('Astro::Hipparcos', $VERSION);

sub new {
  my $class = shift;
  my $file = shift;
  croak("Need catalog file") if not defined $file;
  if (not -e $file) {
    open my $fh, '>', $file or die "Could not open file '$file' for writing: $!";
    close $fh;
  }
  open my $fh, '+<', $file or die "Could not open file '$file' for reading/writing: $!";
  my $self = bless {
    fh => $fh,
    filename => $file,
    filesize => (-s $file),
    abs_file => File::Spec->rel2abs($file),
  } => $class;
  return $self;
}

sub get_record {
  my $self = shift;
  my $recno = shift;
  my $line;
  local $/ = "\012"; # database uses unix newlines
  my $fh = $self->{fh};
  if (not $recno) {
    $line = <$fh>;
    return if not defined $line;
  }
  else {
    my $line_start = LINE_LENGTH*($recno-1);
    my $line_end = $line_start+LINE_LENGTH;
    return() if $line_end > $self->{filesize};
    seek $fh, $line_start, 0
      or die "Could not seek to pos '$line_start' of file '$self->{filename}': $!";
    $line = <$fh>;
    return if not defined $line;
  }
  my $record = Astro::Hipparcos::Record->new();
  $record->ParseRecord($line);
  return $record;
}

sub append_record {
  my $self = shift;
  my $record = shift;
  croak("Need Astro::Hipparcos::Record as first argument to append_record")
    unless ref($record) and $record->isa("Astro::Hipparcos::Record");

  my $fh = $self->{fh};
  my $orig_pos = tell($fh);
  seek $fh, 0, 2 or die "Could not seek to end of file: $!";
  print $fh $record->get_line();
  $self->{filesize} = (-s $self->{abs_file});
  seek $fh, $orig_pos, 0 or die "Could not seek to previous position: $!";
  return 1;
}

1;
__END__

=head1 NAME

Astro::Hipparcos - Perl extension for reading the Hipparcos star catalog

=head1 SYNOPSIS

  use Astro::Hipparcos;
  my $catalog = Astro::Hipparcos->new("thefile.dat");
  while (defined(my $record = $catalog->get_record())) {
    print $record->get_HIP(), "\n"; # print record id
  }
  
  # the twelth record (i.e. first is 1, NOT 0)
  my $specific_record = $catalog->get_record(12);

=head1 DESCRIPTION

This is an extension for reading the Hipparcos star catalog.

=head1 METHODS

=head2 new

Given a file name, returns a new Astro::Hipparcos catalog
object.

=head2 get_record

Returns the next record (line) from the catalog as an L<Astro::Hipparcos::Record>
object.

=head2 append_record

Appends a record to an existing (or new) catalog. Can be used to select
subsamples of the full record and write them to new data files.
Confer the example in this distribution F<examples/simple_selection.pl>.

=head1 SEE ALSO

For an example what you can produce with this little tool,
have a look at L<http://steffen-mueller.net/hipparcos/hipparcos.eps.bz2>.
This is implemented in the F<examples/draw_hammer_proj.pl> example in this
distribution.

L<Astro::Hipparcos::Record>

L<http://en.wikipedia.org/wiki/Hipparcos_Catalogue>

At the time of this writing, you could obtain a copy of the Hipparcos catalogue
from L<ftp://adc.gsfc.nasa.gov/pub/adc/archives/catalogs/1/1239/> (hip_main.dat.gz).

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
