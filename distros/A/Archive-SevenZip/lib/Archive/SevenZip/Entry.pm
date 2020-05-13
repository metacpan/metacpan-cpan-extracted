package Archive::SevenZip::Entry;
use strict;

use Time::Piece; # for strptime
use File::Basename ();
use Path::Class ();

our $VERSION= '0.12';

sub new {
    my( $class, %options) = @_;

    bless \%options => $class
}

sub archive {
    $_[0]->{_Container}
}

sub fileName {
    my( $self ) = @_;

    my $res = $self->{Path};

    # Normalize to unixy path names
    $res =~ s!\\!/!g;

    # If we're a directory, append the slash:
    if( $self->{Folder} eq '+') {
        $res .= '/';
    };

    $res
}

# Class::Path API
sub basename {
    Path::Class::file( $_[0]->{Path} )->basename
}

sub components {
    my $cp = file( $_[0]->{Path} );
    $cp->components()
}

sub lastModFileDateTime {
    0
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

sub uncompressedSize {
    $_[0]->{Size}
}

sub dir {
    # We need to return the appropriate class here
    # so that further calls to (like) dir->list
    # still work properly
    die "->dir Not implemented";
}

sub open {
    my( $self, $mode, $permissions )= @_;
    $self->archive->openMemberFH( membername => $self->fileName, binmode => $mode );
}
{ no warnings 'once';
*fh = \&open; # Archive::Zip API
}

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

Copyright 2015-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
