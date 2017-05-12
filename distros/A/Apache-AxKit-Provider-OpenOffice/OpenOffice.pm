package Apache::AxKit::Provider::OpenOffice;

use strict;
use vars qw($VERSION @ISA);

use AxKit;
use Apache::AxKit::Provider::File;
use Archive::Zip qw(:ERROR_CODES);
use Apache::Request;
use IO::File;

$VERSION = '1.02';

@ISA = ('Apache::AxKit::Provider::File');

Archive::Zip::setErrorHandler(\&_error_handler);

sub _error_handler {
    my $error = shift;
    AxKit::Debug(3, $error);
}

sub get_fh {
    my $self = shift;
    my $zip = Archive::Zip->new();
    if ($zip->read($self->{file}) != AZ_OK) {
        throw Apache::AxKit::Exception::IO (-text => "Couldn't read OpenOffice file '$self->{file}'");
    }
    my $r = $self->apache_request;
    my $member;
    
    my $path_info = $r->path_info;
    $path_info =~ s|^/||;


    if ($path_info) {
        AxKit::Debug(7, "[OpenOffice]: path info found in get_fh: $path_info" );

        # probably need to get smarter here at some point...
        return \"" if $path_info =~ /office\.dtd/;

        $member = $zip->memberNamed($path_info);
    }
    else {
        $member = $zip->memberNamed('content.xml') || $zip->memberNamed('Content.xml');
    }
    my $fh = IO::File->new_tmpfile;
    $member->extractToFileHandle($fh);
    seek($fh, 0, 0);
    return $fh;
}

sub get_strref {
    my $self = shift;

    my $zip = Archive::Zip->new();
    if ($zip->read($self->{file}) != AZ_OK) {
        throw Apache::AxKit::Exception::IO (-text => "Couldn't read OpenOffice file '$self->{file}'");
    }
    my $r = $self->apache_request;
    my $member;
    
    my $path_info = $r->path_info;
    $path_info =~ s|^/||;

    if ($path_info) {
        AxKit::Debug(7, "[OpenOffice]: path info found in get_strref: $path_info" );
        # probably need to get smarter here at some point...
        return \"" if $path_info eq 'office.dtd';

        $member = $zip->memberNamed($path_info);
    }
    else {
        $member = $zip->memberNamed('content.xml') || $zip->memberNamed('Content.xml');
    }
    my ($data, $status) = $member->contents();
    if ($status != AZ_OK) {
        throw Apache::AxKit::Exception::Error(
                -text => "Contents.xml could not be retrieved from $self->{file}"
                );
    }

    if ( $path_info =~ /\.(png|gif|jpg)$/ ) {
        my $image_type = $1;
        $r->content_type( 'image/' . $image_type );
        $r->send_http_header();
        $r->print( $data );
        throw Apache::AxKit::Exception::Declined(
                -text => "[OpenOffice] Image detected, skipping further processing."
                );
    }

    return \$data;
}

sub __process {
    my $self = shift;
    
    my $xmlfile = $self->key;

    unless ($self->exists()) {
        AxKit::Debug(5, "file '$xmlfile' does not exist or is not readable");
        return 0;
    }

    if ( $self->_is_dir ) {
        # else
        AxKit::Debug(5, "'$xmlfile' is a directory");
        return 0;
    }

    return 1;
}


1;
__END__

=head1 NAME

Apache::AxKit::Provider::OpenOffice - OpenOffice package file provider

=head1 SYNOPSIS

in httpd.conf:

 <Files *.sxw>
   AddHandler axkit .sxw
   AxAddPlugin Apache::AxKit::Plugin::OpenOffice
   AxContentProvider Apache::AxKit::Provider::OpenOffice
   AxAddProcessor text/xsl oo2html.xsl
 </Files>

=head1 DESCRIPTION

This provider extracts out the contents of OpenOffice 1.x or StarOffice 6.x SXW
files.

=head1 AUTHOR

Matt Sergeant, axkit.com Ltd, matt@axkit.com
Kip Hampton, axkit.com Ltd, kip@axkit.com

=head1 LICENSE

This is free software. You may distribute it under the same terms as Perl.

=head1 SEE ALSO

L<AxKit>, L<Apache::AxKit::Provider>, L<Apache::AxKit::Plugin::OpenOffice>

=cut
