package Beagle::Role::File;
use Beagle::Util;
use Any::Moose 'Role';
requires('path');

sub full_path {
    my $self = shift;
    return catfile( $self->root, $self->path );
}

sub size {
    my $self = shift;
    return file_size( encode( locale_fs => $self->full_path ) );
}

sub content {
    my $self = shift;
    local $/;
    open my $fh, '<', encode( locale_fs => $self->full_path ) or die $!;
    binmode $fh;
    return <$fh>;
}

no Any::Moose 'Role';
1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

