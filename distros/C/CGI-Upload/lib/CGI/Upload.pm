package CGI::Upload;
use strict;
use warnings;

use Carp;
use File::Basename;
use File::MMagic;
use HTTP::BrowserDetect;
use IO::File;

use vars qw/ $AUTOLOAD $VERSION @ISA @EXPORT_OK /;

require Exporter;

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ file_handle file_name file_type mime_magic mime_type query /;

$VERSION = '1.13';


sub AUTOLOAD {
    my ( $self, $param ) = @_;

    #   Parse method name from $AUTOLOAD variable

    my $property = $AUTOLOAD;
    $property =~ s/.*:://;

    my @properties = qw/ file_handle file_name file_type mime_type /;

    unless ( grep { $property eq $_ } @properties ) {
        croak( __PACKAGE__, '->AUTOLOAD : Unsupported object method within module - ', $property );
    }

    #   Return undef if the requested parameter does not exist within 
    #   CGI object

    my $cgi = $self->query;
    return unless defined $cgi->param( $param );

    #   The determination of all information about the uploaded file is 
    #   performed by a private subroutine called _handle_file - This subroutine 
    #   returns a hash of all information determined about the uploaded file 
    #   which is be cached for subsequent requests.

    $self->{'_CACHE'}->{$param} = $self->_handle_file( $param ) unless exists $self->{'_CACHE'};

    #   Return the requested property of the uploaded file

    return $self->{'_CACHE'}->{$param}->{$property};
}


sub DESTROY {}


sub _handle_file {
    my ( $self, $param ) = @_;
    my $cgi = $self->query;

    #   Determine and set the appropriate file system parsing routines for the 
    #   uploaded path name based upon the HTTP client header information.

    my $client_os = $^O;
    my $browser = HTTP::BrowserDetect->new;
    $client_os = 'MSWin32' if $browser->windows;
    $client_os = 'MacOS' if $browser->mac;
    fileparse_set_fstype($client_os);
    my @file = fileparse( scalar($cgi->param( $param )), '\.[^.]*' );

    #   Return an undefined value if the file name cannot be parsed from the 
    #   file field form parameter.

    return unless $file[0];

    #   Determine whether binary mode is required in the handling of uploaded 
    #   files - 
    #   Binary mode is deemed to be required when we (the server) are running one one 
    #   of these platforms: for Windows, OS/2 and VMS 

    my $binmode = $^O =~ /OS2|VMS|Win|DOS|Cygwin/i;

    #   Pass uploaded file into temporary file handle - This is somewhat 
    #   redundant given the temporary file generation within CGI.pm, however is 
    #   included to reduce dependence upon the CGI.pm module.  

    my $buffer;
    my $fh = IO::File->new_tmpfile;
    binmode( $fh ) if $binmode;


    # it seems that in CGI::Simple for every call to ->upload it somehow resets
    # the file handle. or I don't really know what is the problem with this code:
    # while ( read( $cgi->upload( $param ) , $buffer, 1024 ) ) {
    my $ourfh = $cgi->upload( $param );
    while ( read( $ourfh , $buffer, 1024 ) ) {
        $fh->write( $buffer, length( $buffer ) );
    }

    #   Hold temporary file open, move file pointer to start - As the temporary 
    #   file handle returned by the IO::File::new_tmpfile method is only 
    #   accessible via this handle, the file handle must be held open for all 
    #   operations.

    $fh->seek( 0, 0 );

    #   Retrieve the MIME magic file, if this has been defined, and construct 
    #   the File::MMagic object for the identification of the MIME type of the 
    #   uploaded file.

    my $mime_magic = $self->mime_magic;
    my $magic = length $mime_magic ? File::MMagic->new( $mime_magic ) : File::MMagic->new;

    my $properties = {
        'file_handle'   =>  $fh,
        'file_name'     =>  $file[0] . $file[2],
        'file_type'     =>  lc substr( $file[2], 1 ),
        'mime_type'     =>  $magic->checktype_filehandle($fh)
    };

    #   Hold temporary file open, move file pointer to start - As the temporary 
    #   file handle returned by the IO::File::new_tmpfile method is only 
    #   accessible via this handle, the file handle must be held open for all 
    #   operations.
    #
    #   The importance of this operation here is due to the MIME type 
    #   identification routine of File::MMagic on the open file handle 
    #   (File::MMagic->checktype_filehandle), which may or may not reset the 
    #   file pointer following its operation.

    $fh->seek( 0, 0 );
    
    return $properties;
}


sub mime_magic {
    my ( $self, $magic ) = @_;

    #   If a filename is passed to this subroutine as an argument, this filename 
    #   is taken to be the file containing file MIME types and magic numbers 
    #   which File::MMagic uses for determining file MIME types.
    
    $self->{'_MIME'} = $magic if defined $magic;
    return $self->{'_MIME'};
}


sub new {
    my ( $class, $args ) = @_;

    if ($args and 'HASH' ne ref $args) {
        croak( __PACKAGE__, 'Argument to new should be a HASH reference');
    }
    my $query;
    my $module = "CGI";  # default module is CGI.pm if for nothing else for backword compatibility
    
    if ($args and $args->{query}) {
        $module = $args->{query};
    }

    if (ref $module) { # an object was passed to us
        $query = $module;
        $module = ref $module;
    } else { # assuming a name of a module was passed to us
    
        # load the requested module
        (my $file = $module) =~ s{::}{/}g;
        $file .= ".pm";
        require $file;


        if ("CGI::Simple" eq $module) {
            $CGI::Simple::DISABLE_UPLOADS = 0;
        } 
        $query = new $module;
    }
            
    if ($module eq "CGI::Simple" and $CGI::Simple::VERSION < '0.075') {
        die "CGI::Simple must be at least version 0.075\n";
    }

    my $self = bless {
#        '_CACHE'    =>  {},
        '_CGI'      =>  $query,
        '_MIME'     =>  ''
    }, $class;
    return $self;
}


sub query {
    my ( $self ) = @_;
    return $self->{'_CGI'};
}


1;


__END__

=pod

=head1 NAME

CGI::Upload - CGI class for handling browser file uploads

=head1 SYNOPSIS

 use CGI::Upload;

 my $upload = CGI::Upload->new;

 my $file_name = $upload->file_name('field');
 my $file_type = $upload->file_type('field');

 $upload->mime_magic('/path/to/mime.types');
 my $mime_type = $upload->mime_type('field');

 my $file_handle = $upload->file_handle('field');

=head1 DESCRIPTION

This module has been written to provide a simple and secure manner by which to 
handle files uploaded in multipart/form-data requests through a web browser.  
The primary advantage which this module offers over existing modules is the 
single interface which it provides for the most often required information 
regarding files uploaded in this manner.

This module builds upon primarily the B<CGI> and B<File::MMagic> modules and 
offers some tidy and succinct methods for the handling of files uploaded via 
multipart/form-data requests.

=head1 METHODS

The following methods are available through this module for use in CGI scripts 
and can be exported into the calling namespace upon request.

=over 4

=item B<new>

This object constructor method creates and returns a new B<CGI::Upload> object.  
In previously versions of B<CGI::Upload>, a mandatory argument of the B<CGI> 
object to be used was required.  This is no longer necessary due to the 
singleton nature of B<CGI> objects.

As an experiment, you can now use any kind of CGI.pm like module. The requirements
are that it has to support the ->param method and the ->upload method returning a
file handle. You can use this feature in two ways, either providing the name of
the module or an already existing object. In the former case, CGI::Upload will try
to I<require> the correct module and will I<croak> if cannot load that module.
It has been tested with CGI.pm and CGI::Simple. 

We tested it with CGI::Simple 0.075. 

It is known to break with version 0.071 of CGI::Simple so we issue our own die in such case. 

Examples:

 use CGI::Upload;
 CGI::Upload->new({ query => "CGI::Simple"});

or

 use CGI::Upload;
 use CGI::Simple;
 $CGI::Simple::DISABLE_UPLOADS = 0;   # you have to set this before creating the instance
 my $q = new CGI::Simple;
 CGI::Upload->new({ query => $q});

=item B<query>

Returns the B<CGI> object used within the B<CGI::Upload> class.  

=item B<file_handle('field')>

This method returns the file handle to the temporary file containing the file 
uploaded through the form input field named 'field'.  This temporary file is 
generated using the B<new_tmpfile> method of B<IO::File> and is anonymous in 
nature, where possible.

=item B<file_name('field')>

This method returns the file name of the file uploaded through the form input 
field named 'field' - This file name does not reflect the local temporary 
filename of the uploaded file, but that for the file supplied by the client web 
browser.

=item B<file_type('field')>

This method returns the file type of the file uploaded as specified by the 
filename extension - Please note that this does not necessarily reflect the 
nature of the file uploaded, but allows CGI scripts to perform cursory 
validation of the file type of the uploaded file.

=item B<mime_magic('/path/to/mime.types')>

This method sets and/or returns the external magic mime types file to be used 
for the identification of files via the B<mime_type> method.  By default, MIME 
identification is based upon internal mime types defined within the 
B<File::MMagic> module.

See L<File::MMagic> for further details.

=item B<mime_type('field')>

This method returns the MIME type of the file uploaded through the form input 
field named 'field' as determined by file magic numbers.  This is the best 
means by which to validate the nature of the uploaded file.

See L<File::MMagic> for further details.

=back

=head1 BUGS

Please report bugs on RT: L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Upload>

=head1 TODO

Explain why there is no 100% tests coverage...

Give inteligent error message when user forgets to add  enctype="multipart/form-data" in the upload form.

Add better MIME magic support (see request on RT)

Test if multiple file uploads are supported and fix this if they are not.

Apache::Request support

CGI::Minimal support

Example code from  Mark Stosberg (CGI::Uploader):

  if ($q->isa('CGI::Simple') ) {
           $fh = $q->upload($filename); 
           $mt = $q->upload_info($filename, 'mime' );

           if (!$fh && $q->cgi_error) {
                   warn $q->cgi_error && return undef;
           }
   }
   elsif ( $q->isa('Apache::Request') ) {
            my $upload = $q->upload($file_field);
                $fh = $upload->fh;
                $mt = $upload->type;
   }
   # default to CGI.pm behavior
   else {
           $fh = $q->upload($file_field);
           $mt = $q->uploadInfo($fh)->{'Content-Type'} if $q->uploadInfo($fh);

           if (!$fh && $q->cgi_error) {
                   warn $q->cgi_error && return undef;
           }
   }


=head1 SEE ALSO

L<CGI>, L<File::MMagic>, L<HTTP::File>


=head1 COPYRIGHT

Copyright 2002-2004, Rob Casey, rob.casey@bluebottle.com

=head1 AUTHOR

Original author: Rob Casey, rob.casey@bluebottle.com 

Current mainainer: Gabor Szabo, gabor@pti.co.il

Thanks to

Mark Stosberg for suggestions.

and to the CPAN Testers for testing.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

