package Archive::Any::Plugin;
our $VERSION = '0.0946';
use strict;
use warnings;

use Module::Find;
use Cwd;

sub _extract {
    my ( $self, $file, $dir ) = @_;

    my $orig_dir;
    if ( defined $dir ) {
        $orig_dir = getcwd;
        chdir $dir;
    }

    $self->extract($file);

    if ( defined $dir ) {
        chdir $orig_dir;
    }

    return 1;
}

1;

# ABSTRACT: Anatomy of an Archive::Any plugin.

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Any::Plugin - Anatomy of an Archive::Any plugin.

=head1 VERSION

version 0.0946

=head1 SYNOPSIS

Explains what is required for a working plugin to Archive::Any.

=head1 PLUGINS

Archive::Any requires that your plugin define three methods, all of which are
passed the absolute filename of the file.  This module uses the source of
Archive::Any::Plugin::Tar as an example.

=over 4

=item B<Subclass Archive::Any::Plugin>

 use base 'Archive::Any::Plugin';

=item B<can_handle>

This returns an array of mime types that the plugin can handle.

 sub can_handle {
    return(
           'application/x-tar',
           'application/x-gtar',
           'application/x-gzip',
          );
 }

=item B<files>

Return a list of items inside the archive.

 sub files {
    my( $self, $file ) = @_;
    my $t = Archive::Tar->new( $file );
    return $t->list_files;
 }

=item B<extract>

This method should extract the contents of $file to the current directory.
L<Archive::Any::Plugin> handles negotiating directories for you.

 sub extract {
    my ( $self, $file ) = @_;

    my $t = Archive::Tar->new( $file );
    return $t->extract;
 }

=back

=head1 SEE ALSO

Archive::Any

=head1 AUTHORS

=over 4

=item *

Clint Moore

=item *

Michael G Schwern (author emeritus)

=item *

Olaf Alders (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael G Schwern, Clint Moore, Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
