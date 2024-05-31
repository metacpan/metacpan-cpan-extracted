package Archive::SevenZip::Entry;
use strict;
use warnings;

use Archive::Zip::Member;
use Time::Piece; # for strptime
use File::Basename ();
use Path::Class ();

our $VERSION= '0.20';

=head1 NAME

Archive::SevenZip::Entry - a member of an archive

=head1 SYNOPSIS

  use POSIX 'strftime';
  for my $entry ( $ar->list ) {
      print $entry->fileName,"\n";
      print strftime('%Y-%m-%d %H:%M', gmtime($entry->lastModTime)),"\n";
      my $content = $entry->slurp();
      print $content;
  };

=cut

sub new {
    my( $class, %options) = @_;

    bless \%options => $class
}

=head1 METHODS

=over 4

=item C<< ->archive >>

  my $ar = $entry->archive();

Returns the containing archive as an L<Archive::SevenZip> object.

=cut

sub archive {
    $_[0]->{_Container}
}

=item C<< ->fileName >>

  my $fn = $entry->fileName();

Returns the stored path

=cut

sub fileName {
    my( $self ) = @_;

    my $res = $self->{Path};

    # Normalize to unixy path names
    $res =~ s!\\!/!g;
    # If we're a directory, append the slash:
    if( exists $self->{Folder} and $self->{Folder} eq '+') {
        $res .= '/';
    };

    $res
}

=item C<< ->basename >>

  my $fn = $entry->basename();

Returns the stored filename without a directory

=cut

# Class::Path API
sub basename {
    Path::Class::file( $_[0]->{Path} )->basename
}

=item C<< ->components >>

  my @parts = $entry->components();

Returns the stored filename as an array of directory names and the file name

=cut

sub components {
    my $cp = file( $_[0]->{Path} );
    $cp->components()
}

=item C<< ->lastModTime >>

  my $epoch = $entry->lastModTime();
  print strftime('%Y-%m-%d %H:%M', $epoch),"\n";

Returns the time of last modification of the stored file as number of seconds

=cut

sub lastModTime {
    (my $dt = $_[0]->{Modified}) =~ s/\.\d+$//;
    Time::Piece->strptime($dt, '%Y-%m-%d %H:%M:%S')->epoch;
}

sub lastModFileDateTime {
    Archive::Zip::Member::_unixToDosTime($_[0]->lastModTime())
}

sub crc32 {
    hex( $_[0]->{CRC} );
}

sub crc32String {
    lc $_[0]->{CRC};
}

sub desiredCompressionMethod {
    $_[0]->{Method}
}

=item C<< ->uncompressedSize >>

  my $size = $entry->uncompressedSize();

Returns the uncompressed size of the stored file in bytes

=cut

sub uncompressedSize {
    $_[0]->{Size}
}

sub dir {
    # We need to return the appropriate class here
    # so that further calls to (like) dir->list
    # still work properly
    die "->dir Not implemented";
}

=item C<< ->open $binmode >>

  my $fh = $entry->open(':raw');

Opens a filehandle for the uncompressed data

=cut

sub open {
    my( $self, $mode, $permissions )= @_;
    $self->archive->openMemberFH( membername => $self->fileName, binmode => $mode );
}

=item C<< ->fh $binmode >>

  my $fh = $entry->fh(':raw');

Opens a filehandle for the uncompressed data

=cut

{ no warnings 'once';
*fh = \&open; # Archive::Zip API
}

=item C<< ->slurp %options >>

  my $content = $entry->slurp( iomode => ':raw');

Reads the content

=cut

# Path::Class API
sub slurp {
    my( $self, %options )= @_;
    my $fh = $self->archive->openMemberFH( membername => $self->fileName, binmode => $options{ iomode } );
    local $/;
    <$fh>
}

# Archive::Zip API
#externalFileName()

# Archive::Zip API
#fileName()

# Archive::Zip API
#lastModFileDateTime()

# Archive::Zip API
#lastModTime()

=item C<< ->extractToFileNamed $name >>

  $entry->extractToFileNamed( '/tmp/foo.txt' );

Extracts the data

=back

=cut

# Archive::Zip API
sub extractToFileNamed {
    my($self, $target) = @_;
    $self->archive->extractMember( $self->fileName, $target );
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/archive-sevenzip>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-SevenZip>
or via mail to L<archive-sevenzip-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2024 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
