package AWS::Lambda::Quick::CreateZip;
use Mo qw( default required );

our $VERSION = '1.0002';

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Path::Tiny qw( path );

has src_filename => required => 1;
has zip_filename => required => 1;

has extra_files => default => [];

has _src_path => sub { path( shift->src_filename ) };
has _src_dir  => sub { shift->_src_path->parent };
has _zip_class  => default => 'Archive::Zip';
has _zip        => sub { shift->_zip_class->new };
has _script_src => sub { shift->_src_path->slurp_raw };

# this is the same src as in script src but the first occurance of
# "use AWS::Lambda::Quick" is prepended with
# "$INC{'AWS/Lambda/Quick.pm'}=1" to prevent it actually being loaded
# from disk.  Note this happens on just one line to avoid screwing
# with line numebrs that could mess with error messages
has _converted_src => sub {
    my $self = shift;
    my $src  = $self->_script_src;
    $src =~ s{(?=use AWS::Lambda::Quick(?:\s|[;(]))}
             {BEGIN{\$INC{'AWS/Lambda/Quick.pm'}=1} };
    return $src;
};

### methods for interfacing with Archive::Zip
### no code outside this section should directly interact with the
### zip file

sub _add_string {
    my $self     = shift;
    my $string   = shift;
    my $filename = shift;

    my $zip           = $self->_zip;
    my $string_member = $zip->addString( $string, $filename );
    $string_member->desiredCompressionMethod(COMPRESSION_DEFLATED);
    return ();
}

sub _add_path {
    my $self = shift;
    my $path = path(shift);

    if ( $path->is_absolute ) {
        die "Cannot add absolute path! $path";
    }
    my $abs_path = path( $self->_src_dir, $path );

    # silently ignore files that don't exist.  This allows you
    # to say put extra_files => [qw( lib )] in your file and not
    # worry if that file exists or not
    return unless -e $abs_path;

    $self->_zip->addFileOrDirectory(
        {
            name             => $abs_path->stringify,
            zipName          => $path->stringify,
            compressionLevel => COMPRESSION_DEFLATED,
        }
    );

    # was that a directory?  Add the contents recursively
    return () unless -d $abs_path;
    my $iter = $abs_path->iterator;
    while ( my $next = $iter->() ) {
        my $child = $path->child( $next->basename );
        $self->_add_path($child);
    }

    return ();
}

sub _write_zip {
    my $self = shift;
    unless ( $self->_zip->writeToFileNamed( $self->zip_filename->stringify )
        == AZ_OK ) {
        die 'write error';
    }
    return ();
}

### logic for building the zip file contents ###

sub _build_zip {
    my $self = shift;
    $self->_add_string( $self->_converted_src, 'handler.pl' );
    $self->_add_path($_) for @{ $self->extra_files };
    return ();
}

sub create_zip {
    my $self = shift;
    $self->_build_zip;
    $self->_write_zip;
    return ();
}

1;

__END__

=head1 NAME

AWS::Lambda::Quick::CreateZip - lambda function zipping for AWS::Lambda::Quick

=head1 DESCRIPTION

No user servicable parts.  See L<AWS::Lambda::Quick> for usage.

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Mark Fowler 2019.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AWS::Lambda::Quick>

=cut

