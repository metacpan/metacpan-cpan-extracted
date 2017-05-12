package Archive::Extract::Libarchive;
use strict;
use warnings;
use Cwd qw(cwd);
use Object::Tiny qw{ archive extract_path files error };
our $VERSION = '0.38';

require XSLoader;
XSLoader::load( 'Archive::Extract::Libarchive', $VERSION );

sub extract {
    my ( $self, %params ) = @_;
    my $archive = $self->archive;
    my $extract_path = $params{to} || cwd;
    eval {
        $self->{files}
            = [
            Archive::Extract::Libarchive::_extract( $archive, $extract_path )
            ];
    };
    if ($@) {
        $self->{error} = $@;
        return 0;
    }

    $self->{extract_path} = $extract_path;
    return 1;
}

1;

__END__

=head1 NAME

Archive::Extract::Libarchive - A generic archive extracting mechanism (using libarchive)

=head1 SYNOPSIS

  use Archive::Extract::Libarchive;

  # build an Archive::Extract object
  my $ae = Archive::Extract::Libarchive->new( archive => 'foo.tgz' );

  # extract to cwd()
  my $ok = $ae->extract;

  # extract to /tmp
  my $ok = $ae->extract( to => '/tmp' );

  # what if something went wrong?
  my $ok = $ae->extract or die $ae->error;
    
  # files from the archive
  my $files   = $ae->files;

  # dir that was extracted to
  my $outdir  = $ae->extract_path;
    
  # absolute path to the archive you provided
  $ae->archive;

=head1 DESCRIPTION

L<Archive::Extract> is a generic archive extraction mechanism. This module has a
similar interface to L<Archive::Extract>, but instead of using Perl modules and
external commands, it uses the libarchive C libary
(L<http://code.google.com/p/libarchive/>), which you must have installed
(libarchive-dev package for Debian/Ubuntu). It supports many different archive
formats and compression algorithms and is fast.

For example, unpacking the whole of CPAN using this module is about ten times
faster than using L<Archive::Extract>.

=head1 METHODS

=head2 $ae = Archive::Extract::Libarchive->new(archive => '/path/to/archive')

Creates a new C<Archive::Extract::Libarchive> object based on the archive file you passed
it.

=head2 $ae->extract( [to => '/output/path'] )

Extracts the archive represented by the C<Archive::Extract::Libarchive> object
to the path of your choice as specified by the C<to> argument. Defaults to
C<cwd()>.

It will return true on success, and false on failure.

On success, it will also set the follow attributes in the object:

=over 4

=item $ae->extract_path

This is the directory that the files where extracted to.

=item $ae->files

This is an array ref with the paths of all the files in the archive, relative to
the C<to> argument you specified. To get the full path to an extracted file, you
would use:

  File::Spec->catfile( $to, $ae->files->[0] );

=back

=head1 ACCESSORS

=head2 $ae->error()

Returns the last encountered error as string.

=head2 $ae->extract_path

This is the directory the archive got extracted to. See C<extract()> for
details.

=head2 $ae->files

This is an array ref holding all the paths from the archive. See C<extract()>
for details.

=head2 $ae->archive

This is the full path to the archive file represented by this
C<Archive::Extract::Libarchive> object.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or
modify it under the same terms as Perl itself.
