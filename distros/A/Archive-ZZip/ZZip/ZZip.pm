package Archive::ZZip;

use strict;

use Exporter qw( import );

$Archive::ZZip::VERSION = "0.13";
our @ISA = qw(Exporter DynaLoader);

@Archive::ZZip::EXPORT_OK = ();

require DynaLoader;
bootstrap Archive::ZZip $Archive::ZZip::VERSION;


1;

__END__


=head1 NAME

Archive::ZZip - Perl bindings for zziplib.

=head1 SYNOPSIS

  use Archive::ZZip;

  my $zip = Archive::ZZip->new("./latest.zip");

  my $file = $dir->openFile("framework/dhtmlHistory.js");
  while (my $buf = $file->read()) {
    print $buf;
  }


=head1 DESCRIPTION

Provides bindings for zziplib, whose homepage is at http://zziplib.sourceforge.net/.

=head1  METHODS

=head2 Archive::ZZip::new(file_name)

=over

Opens the zip file. Returns a handle to the
central directory.

  my $zip = Archive::ZZip->new('test.zip');

=back

=head2 Archive::ZZip::openFile(file_name)

=over

Opens the file inside the zip. Returns a handle to the
file.

  my $file = $zip->openFile( 'test.zip');

=back

=head2  Archive::ZZip::File::read(buffer, amount)

=over

Attempts to read amount bytes and returns a buffer containing what was read.
Pass undef for the buffer to have it automatically create one.

  my $buf = $file->read(undef, 1024);
  my $buf = $file->read();
  $file->read($buf, 1024);

=back

=head2 Archive::ZZip::read()

=over

Returns the next entry in the central directory.

  my $entry = $zip->read();
  my $name = $entry->{'name'};
  my $level = $entry->{'compression_level'};
  my $us = $entry->{'uncompressed_size'};
  my $cs = $entry->{'compressed_size'};

=back

=head1 AUTHOR

Vincent Spader, E<lt>vspader@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

