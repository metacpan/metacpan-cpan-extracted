package Apache::ExtDirect::Router;

use 5.012000;
use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use CGI;
use File::Basename qw(basename);
use IO::Handle;

use Apache2::Const -compile => qw(OK SERVER_ERROR DECLINED);

use RPC::ExtDirect ();
use RPC::ExtDirect::Router;

### PACKAGE GLOBAL VARIABLE ###
#
# Debugging; off by default
#

our $DEBUG = 0;

### PUBLIC MOD_PERL HANDLER ###
#
# Handle Ext.Direct routing requests
#

sub handler {
    my ($r) = @_;

    local $RPC::ExtDirect::Router::DEBUG = $DEBUG;

    # If anything but POST method is used, throw an error
    return Apache2::Const::DECLINED
        if $r->method ne 'POST';

    my $cgi = CGI->new($r);

    my $router_input = Apache::ExtDirect::Router->_extract_post_data($cgi);

    # If input is undefined, extraction have failed
    return Apache2::Const::SERVER_ERROR
        unless defined $router_input;

    # Routing requests is safe
    my $result = RPC::ExtDirect::Router->route($router_input, $cgi);

    # Router returns PSGI array with fixed items
    my $content_type   = $result->[1]->[1];
    my $content_length = $result->[1]->[3];
    my $http_body      = $result->[2]->[0];

    $r->content_type($content_type);
    $r->headers_out->{'Content-Length'} = $content_length;

    $r->print($http_body);

    return Apache2::Const::OK;
}

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Extract Ext.Direct request information from POST body
#

my @STANDARD_KEYWORDS
    = qw(action method extAction extMethod extTID extUpload extType);
my %STANDARD_KEYWORD = map { $_ => 1 } @STANDARD_KEYWORDS;

sub _extract_post_data {
    my ($class, $cgi) = @_;

    # The smartest way to tell if a form was submitted that *I* know of
    # is to look for 'extAction' and 'extMethod' keywords in CGI params.
    my %keyword = map { $_ => 1 } $cgi->param();
    my $is_form = exists $keyword{ extAction } &&
                  exists $keyword{ extMethod };

    # If form is not involved, it's easy: just return POSTDATA (or undef)
    if ( !$is_form ) {
        my $postdata = $cgi->param('POSTDATA') || join '', $cgi->keywords;
        return $postdata ne '' ? $postdata
               :                 undef
               ;
    };

    # If any files are attached, extUpload will contain 'true'
    my $has_uploads = $cgi->param('extUpload') eq 'true';

    # Here file uploads data is stored
    my @_uploads = ();

    # Now if the form IS involved, it gets a little bit complicated
    PARAM:
    for my $param ( keys %keyword ) {
        # Defang CGI's idiosyncratic way to return multi-valued params
        my @values = $cgi->param( $param );
        $keyword{ $param } = @values == 0 ? undef
                           : @values == 1 ? $values[0]
                           :                [ @values ]
                           ;

        # Try to see if $param is a field with associated file upload
        # Skip the standard ones first, of course
        next PARAM if $STANDARD_KEYWORD{ $param } || !$has_uploads;

        # Look for file uploads in this field
        my @field_uploads = $class->_parse_uploads($cgi, $param);

        # Found some, add them to general stash and kill the field
        if ( @field_uploads ) {
            push @_uploads, @field_uploads;
            delete $keyword{ $param };
        };
    };

    # Remove extType because it's meaningless later on
    delete $keyword{ extType };

    # Fix TID so that it comes as number (JavaScript is picky)
    $keyword{ extTID } += 0 if exists $keyword{ extTID };

    # Now add files to hash, if any
    $keyword{ '_uploads' } = \@_uploads if @_uploads;

    return \%keyword;
}

### PRIVATE INSTANCE METHOD ###
#
# Parses CGI form input field looking for file uploads
#

sub _parse_uploads {
    my ($class, $cgi, $param) = @_;

    # CGI returns "lightweight file handles", or undef
    my @file_handles = $cgi->upload($param);

    # Empty list means no uploads for this field
    return unless grep { defined $_ } @file_handles;

    # Despite what CGI documentation says, the values returned
    # as "file names" are actually some kind of key handles
    my @file_keys = $cgi->param($param);

    # Here file uploads get collected
    my @uploads = ();

    # Collect the info we need to repackage it in consistent way
    FILE:
    for my $key ( @file_keys ) {
        # First take a closer look at this "blah-blah handle"
        my $file_handle = shift @file_handles;

        # undef would mean there was upload error (timeout perhaps)
        # Following HTTP POST logic, when one upload breaks that
        # would mean all subsequent uploads in this POST are also
        # broken.
        # We can't do anything about it anyway so just stop trying.
        last FILE unless defined $file_handle;

        # In CGI.pm < 3.41, "lightweight handle" object doesn't support
        # returning IO::Handle so we do it manually to avoid problems
        my $io_handle = IO::Handle->new_from_fd(fileno $file_handle, '<');

        # We also need a lot of info about the file (if provided)
        my $upload_info = $cgi->uploadInfo($key);
        my $temp_file   = $cgi->tmpFileName($key);
        my $file_type   = $upload_info->{'Content-Type'};
        my $file_name   = $class->_get_file_name($upload_info);
        my $file_size   = $class->_get_file_size($io_handle);
        my $base_name   = basename($file_name);

        # Now instead of "blah-blah handle" we have hashref full of info
        push @uploads, {
            type     => $file_type,
            size     => $file_size,
            path     => $temp_file,
            handle   => $io_handle,
            basename => $base_name,
            filename => $file_name,
        };
    };

    return @uploads;
}

### PRIVATE INSTANCE METHOD ###
#
# Tries hard to extract file name from multipart form guts
#

sub _get_file_name {
    my ($class, $upload_info) = @_;

    # Pluck file name from Content-Disposition string
    my ($file_name)
        = $upload_info->{'Content-Disposition'} =~ /filename="(.*?)"/;

    # URL unescape it
    $file_name =~ s/%([\dA-Fa-f]{2})/pack("C", hex $1)/eg;

    return $file_name;
}

### PRIVATE INSTANCE METHOD ###
#
# Enquiries IO::Handle supplied by CGI for file size
#

sub _get_file_size {
    my ($class, $handle) = @_;

    # Fall through in case $handle is invalid
    return unless $handle;

    return ($handle->stat)[7];
}

1;

__END__

=pod

=head1 NAME

Apache::ExtDirect::Router - Apache handler for Ext.Direct remoting requests

=head1 DESCRIPTION

This module is not intended to be used directly. See L<Apache::ExtDirect>
for more information.

=head1 AUTHOR

Alexander Tokarev, E<lt>tokarev@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alexander Tokarev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic>.

=cut

