package Beagle::Backend::fs;
use Any::Moose;
use Beagle::Util;

extends 'Beagle::Backend::base';

sub create {
    my $self   = shift;
    my $object = shift;
    return unless -e $self->encoded_root;
    my %args = (@_);
    $self->_save( $object, %args );
}

sub update {
    my $self         = shift;
    my $object       = shift;

    my $path = $object->path;
    return unless $path;

    if (   $object->can('original_path')
        && $object->original_path
        && $object->original_path ne $object->path )
    {
        my $full_path =
          encode( locale_fs => catfile( $self->root, $object->path ) );
        my $parent = parent_dir($full_path);
        make_path($parent) unless -e $parent;

        rename(
            encode( locale_fs => $object->original_path ),
            encode( locale_fs => $object->path )
        ) or return;
        $object->original_path( $object->path );
    }

    my %args = @_;
    return $self->_save( $object, %args );
}

sub delete {
    my $self   = shift;
    my $object = shift;
    my %args   = @_;

    my $path = $object ? $object->path : $args{path};
    return unless $path;

    my $full_path = encode( locale_fs => catfile( $self->root, $path ) );
    return unless -e $full_path;

    if ( -f $full_path ) {
        unlink $full_path or return;
    }
    else {
        remove_tree($full_path) or return;
    }
    return 1;
}

sub _save {
    my $self   = shift;
    my $object = shift;
    my %args   = @_;

    my $path = $object->path;
    return unless $path;

    my $full_path = encode( locale_fs => catfile( $self->root, $path ) );

    my $parent = parent_dir($full_path);
    make_path($parent) unless -e $parent;

    if ( $object->can('content_file') && $object->content_file ) {
        require File::Copy;
        File::Copy::copy( encode( locale_fs => $object->content_file ),
            $full_path )
          or die $!;
    }
    else {
        my $string = $object->serialize;
        open my $fh, '>', $full_path or die $!;
        binmode $fh;
        unless ( $object->can('is_raw') && $object->is_raw ) {
            $string = encode_utf8 $string;
        }
        print $fh $string;
        close $fh;
    }

    return 1;
}

sub updated {
    my $self = shift;
    my $updated = 0;

    require File::Find;
    File::Find::find(
        sub {
            return unless -f && $_ !~ /^\./;
            my $mt = (stat)[9];
            $updated = $mt if $updated < $mt;
        },
        $self->encoded_root
    );
    return $updated;
}

sub commit { 1 }

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

