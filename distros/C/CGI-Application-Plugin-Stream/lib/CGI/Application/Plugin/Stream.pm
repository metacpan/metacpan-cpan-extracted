package CGI::Application::Plugin::Stream;

use 5.006;
use strict;
use warnings;

use CGI::Application 3.21;
use File::Basename;
require Exporter;
use vars (qw/@ISA @EXPORT_OK/);
@ISA = qw(Exporter);

@EXPORT_OK = qw(stream_file);

our $VERSION = '2.12';

sub stream_file {
    my ( $self, $file_or_fh, $bytes ) = @_;
    $bytes ||= 1024;
    my ($fh, $basename);
    my  $size = (stat( $file_or_fh ))[7];

    # If we have a file path
    if ( ref( \$file_or_fh ) eq 'SCALAR' ) {
        # They passed along a scalar, pointing to the path of the file
        # So we need to open the file
        open($fh,"<$file_or_fh"  ) || return 0;
        # Now let's go binmode (Thanks, William!)
        binmode $fh;
        $basename = basename( $file_or_fh );
    }
    # We have a file handle.
    else {
        $fh = $file_or_fh;
        $basename = 'FILE';
    }

    # Use FileHandle to make File::MMagic happy;
    # bless the filehandle into the FileHandle package to make File::MMagic happy
    require FileHandle;
    bless $fh,  "FileHandle";

    # Check what headers the user has already set and
    # don't override them.
    my %existing_headers = $self->header_props();

    # Check for a existing type header set with or without a hyphen
    unless ( $existing_headers{'-type'} ||  $existing_headers{'type'} ) {
        my $mime_type;

        eval {
            require File::MMagic;
            my $magic = File::MMagic->new();
            $mime_type = $magic->checktype_filehandle($fh);
        };
        warn "Failed to load File::MMagic module to determine mime type: $@" if $@;

        # Set Default
        $mime_type ||= 'application/octet-stream';

        $self->header_add('-type' => $mime_type);
    }


    unless ( $existing_headers{'Content_Length'}
        ||   $existing_headers{'-Content_Length'}
        ) {
        $self->header_add('-Content_Length' => $size);
    }

    unless ( $existing_headers{'-attachment'}
        ||   $existing_headers{'attachment'}
        ||   grep( /-?content(-|_)disposition/i, keys %existing_headers )
        ) {
        $self->header_add('-attachment' => $basename);
    }

    unless ( $ENV{'CGI_APP_RETURN_ONLY'} ) {
        $self->header_type( 'none' );
        print $self->query->header( $self->header_props() );
    }

    # This reads in the file in $byte size chunks
    # File::MMagic may have read some of the file, so seek back to the beginning
    my $output = "";
    seek($fh,0,0);
    while ( read( $fh, my $buffer, $bytes ) ) {
        if ( $ENV{'CGI_APP_RETURN_ONLY'} ) {
            $output .= $buffer;
        } else {
            print $buffer;
        }
    }

    print '' unless $ENV{'CGI_APP_RETURN_ONLY'}; # print a null string at the end
    close ( $fh );
    return $ENV{'CGI_APP_RETURN_ONLY'} ? \$output : 1;
}

1;
__END__
=head1 NAME

CGI::Application::Plugin::Stream - CGI::Application Plugin for streaming files

=head1 SYNOPSIS

  use CGI::Application::Plugin::Stream (qw/stream_file/);

  sub runmode {
    # ...

    # Set up any headers you want to set explicitly
    # using header_props() or header_add() as usual

    #...

    if ( $self->stream_file( $file ) ) {
      return;
    } else {
      return $self->error_mode();
    }
  }

=head1 DESCRIPTION

This plugin provides a way to stream a file back to the user.

This is useful if you are creating a PDF or Spreadsheet document dynamically to
deliver to the user.

The file is read and printed in small chunks to keep memory consumption down.

This plugin is a consumer, as in your runmode shouldn't try to do any output or
anything afterwards.  This plugin affects the HTTP response headers, so
anything you do afterwards will probably not work.  If you pass along a
filehandle, we'll make sure to close it for you.

It's recommended that you increment $| (or set it to 1), which will
autoflush the buffer as your application is streaming out the file.

=head1 METHODS

=head2 stream_file()

  $self->stream_file($fh);
  $self->stream_file( '/path/to/file',2048);

This method can take two parameters, the first the path to the file
or a filehandle and the second, an optional number of bytes to determine
the chunk size of the stream. It defaults to 1024.

It will either stream a file to the user or return false if it fails, perhaps
because it couldn't find the file you referenced.

We highly recommend you provide a file name if passing along a filehandle, as we
won't be able to deduce the file name, and will use 'FILE' by default. Example:

 $self->header_add( -attachment => 'my_file.txt' );

With both a file handle or file name, we will try to determine the correct
content type by using File::MMagic. A default of 'application/octet-stream'
will be used if File::MMagic can't figure it out.

The size will be calculated and added to the headers as well.

Again, you can set these explicitly if you want as well:

 $self->header_add(
      -type		        =>	'text/plain',
      -Content_Length	=>	42, # bytes
 );

=head1 AUTHOR

Jason Purdy, E<lt>Jason@Purdy.INFOE<gt>,
with inspiration from Tobias Henoeckl
and tremendous support from the cgiapp mailing list.

Mark Stosberg also contributed to this module.

=head1 SEE ALSO

L<CGI::Application>,
L<http://www.cgi-app.org>,
L<CGI.pm/"CREATING A STANDARD HTTP HEADER">,
L<http://www.mail-archive.com/cgiapp@lists.erlbaum.net/msg02660.html>,
L<File::Basename>,
L<perlvar/$E<verbar>>

=head1 LICENSE

Copyright (C) 2004-2005 Jason Purdy, E<lt>Jason@Purdy.INFOE<gt>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut
