package Archive::Any;

use strict;
use warnings;

our $VERSION = '0.0946';

use Archive::Any::Plugin;
use File::Spec::Functions qw( rel2abs splitdir );
use File::MMagic;
use MIME::Types qw(by_suffix);

sub new {
    my ( $class, $file, $type ) = @_;

    $file = rel2abs($file);
    return unless -f $file;

    my %available;

    my @plugins = Archive::Any::Plugin->findsubmod;
    foreach my $plugin (@plugins) {
        eval "require $plugin";
        next if $@;

        my @types = $plugin->can_handle();
        foreach my $type (@types) {
            next if exists( $available{$type} );
            $available{$type} = $plugin;
        }
    }

    my $mime_type;

    if ($type) {

        # The user forced the type.
        ($mime_type) = by_suffix($type);
        unless ($mime_type) {
            warn "No mime type found for type '$type'";
            return;
        }
    }
    else {
        # Autodetect the type.
        $mime_type = File::MMagic->new()->checktype_filename($file);
    }

    my $handler = $available{$mime_type};
    if ( !$handler ) {
        warn "No handler available for type '$mime_type'";
        return;
    }

    return bless {
        file    => $file,
        handler => $handler,
        type    => $mime_type,
    }, $class;
}

sub extract {
    my $self = shift;
    my $dir  = shift;

    return defined($dir)
        ? $self->{handler}->_extract( $self->{file}, $dir )
        : $self->{handler}->_extract( $self->{file} );
}

sub files {
    my $self = shift;
    return $self->{handler}->files( $self->{file} );
}

sub is_impolite {
    my $self = shift;

    my @files       = $self->files;
    my $first_file  = $files[0];
    my ($first_dir) = splitdir($first_file);

    return grep( !/^\Q$first_dir\E/, @files ) ? 1 : 0;
}

sub is_naughty {
    my ($self) = shift;
    return ( grep { m{^(?:/|(?:\./)*\.\./)} } $self->files ) ? 1 : 0;
}

sub mime_type {
    my $self = shift;
    return $self->{type};
}

#
# This is not really here.  You are not seeing this.
#
sub type {
    my $self = shift;
    return $self->{handler}->type();
}

# End of what you are not seeing.

1;

=pod

=encoding UTF-8

=head1 NAME

Archive::Any - Single interface to deal with file archives.

=head1 VERSION

version 0.0946

=head1 SYNOPSIS

    use Archive::Any;

    my $archive = Archive::Any->new( 'archive_file.zip' );

    my @files = $archive->files;

    $archive->extract;

    my $type = $archive->type;

    $archive->is_impolite;
    $archive->is_naughty;

=head1 DESCRIPTION

This module is a single interface for manipulating different archive formats.
Tarballs, zip files, etc.

=over 4

=item B<new>

    my $archive = Archive::Any->new( $archive_file );
    my $archive_with_type = Archive::Any->new( $archive_file, $type );

$type is optional.  It lets you force the file type in case Archive::Any can't
figure it out.

=item B<extract>

    $archive->extract;
    $archive->extract( $directory );

Extracts the files in the archive to the given $directory.  If no $directory is
given, it will go into the current working directory.

=item B<files>

    my @file = $archive->files;

A list of files in the archive.

=item B<mime_type>

    my $mime_type = $archive->mime_type();

Returns the mime type of the archive.

=item B<is_impolite>

    my $is_impolite = $archive->is_impolite;

Checks to see if this archive is going to unpack into the current directory
rather than create its own.

=item B<is_naughty>

    my $is_naughty = $archive->is_naughty;

Checks to see if this archive is going to unpack B<outside> the current
directory.

=back

=head1 DEPRECATED

=over 4

=item B<type>

    my $type = $archive->type;

Returns the type of archive.  This method is provided for backwards
compatibility in the Tar and Zip plugins and will be going away B<soon> in
favor of C<mime_type>.

=back

=head1 PLUGINS

For detailed information on writing plugins to work with Archive::Any, please
see the pod documentation for L<Archive::Any::Plugin>.

=head1 SEE ALSO

Archive::Any::Plugin

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::Any

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/module/Archive::Any>

=item * Issue tracker

L<https://github.com/oalders/archive-any/issues>

=back

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

__END__


# ABSTRACT: Single interface to deal with file archives.
