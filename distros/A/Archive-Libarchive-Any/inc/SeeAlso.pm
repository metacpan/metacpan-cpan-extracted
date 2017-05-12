package inc::SeeAlso;

use Moose;
use v5.10;
with 'Dist::Zilla::Role::FileMunger';

sub munge_files
{
  my($self) = @_;
  
  my($file) = grep { $_->name =~ qr{^lib/Archive/Libarchive/(XS|FFI|Any)\.pm$} } @{ $self->zilla->files };
  
  $self->zilla->log_fatal("could not find main module")
    unless $file;
  
  state $data;
  unless(defined $data)
  {
    local $/;
    $data = <DATA>;
  }
  
  $file->content($file->content . $data);
}

1;

__DATA__

=head1 SEE ALSO

The intent of this module is to provide a low level fairly thin direct
interface to libarchive, on which a more Perlish OO layer could easily
be written.

=over 4

=item L<Archive::Libarchive::XS>

=item L<Archive::Libarchive::FFI>

Both of these provide the same API to libarchive via L<Alien::Libarchive>,
but the bindings are implemented in XS for one and via L<FFI::Sweet> for
the other.

=item L<Archive::Libarchive::Any>

Offers whichever is available, either the XS or FFI version.  The
actual algorithm as to which is picked is subject to change, depending
on with version seems to be the most reliable.

=item L<Archive::Peek::Libarchive>

=item L<Archive::Extract::Libarchive>

Both of these provide a higher level, less complete perlish interface
to libarchive.

=item L<Archive::Tar>

=item L<Archive::Tar::Wrapper>

Just some of the many modules on CPAN that will read/write tar archives.

=item L<Archive::Zip>

Just one of the many modules on CPAN that will read/write zip archives.

=item L<Archive::Any>

A module attempts to read/write multiple formats using different methods
depending on what perl modules are installed, and preferring pure perl
modules.

=back

=cut
