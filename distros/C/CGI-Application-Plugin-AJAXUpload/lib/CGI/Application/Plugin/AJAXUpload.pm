package CGI::Application::Plugin::AJAXUpload;

use warnings;
use strict;
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT);
use Perl6::Slurp;
use Readonly;
use Data::FormValidator;

@EXPORT = qw(
    ajax_upload_httpdocs
    ajax_upload_setup
    ajax_upload_default_profile
    _ajax_upload_rm
    _ajax_upload_compile_messages
);

use version; our $VERSION = qv('0.0.3');

# Module implementation here

Readonly my $FIELD_NAME => 'file';
Readonly my $MAX_UPLOAD => 512*1024;

sub ajax_upload_httpdocs {
    my $self = shift;
    my $httpdocs = shift;
    if ($httpdocs) {
        $self->{__CAP__AJAXUPLOAD_HTTPDOCS} = $httpdocs;
        return;
    }
    return $self->{__CAP__AJAXUPLOAD_HTTPDOCS};
}

sub ajax_upload_setup {
    my $self = shift;
    my %args = @_;

    my $upload_subdir = $args{upload_subdir} || '/img/uploads';
    my $dfv_profile = $args{dfv_profile};
    if (!$dfv_profile) {
        $dfv_profile = $self->ajax_upload_default_profile();
    }
    my $run_mode = $args{run_mode} || 'ajax_upload_rm';

    $self->run_modes(
        $run_mode => sub {
            my $c = shift;
            $c->header_props(
                -type=>'text/javascript',
                -encoding=>'utf-8',
                -charset=>'utf-8'
            );
            my $r = eval {
                $c->_ajax_upload_rm($upload_subdir, $dfv_profile);
            };
            if ($@) {
                carp $@;
                return $c->to_json({status=> 'Internal Error'});
            }
            return $r;
        }
    );

    return;
}

sub _ajax_upload_rm {
    use autodie qw(open close);
    my $self = shift;
    my $upload_subdir = shift;
    my $dfv_profile = shift;
    my $httpdocs_dir = $self->ajax_upload_httpdocs;  

    return $self->to_json({status => 'No document root specified'})
        if not defined $httpdocs_dir;

    my $full_upload_dir = "$httpdocs_dir/$upload_subdir";
    my $query = $self->query;

    my $lightweight_fh  = $query->upload('file');
    return $self->to_json({status=>'No file handle obtained'})
        if !defined $lightweight_fh;
        
    my $fh = $lightweight_fh->handle;
    return $self->to_json({status => 'No file handle promoted'})
        if not $fh;

    my $value = slurp $fh;
    close $fh;
    my $filename = $query->param('file');
    my $info = $query->uploadInfo($filename);
    return $self->to_json({status => 'No file name obtained'})
        if not $filename;
    $filename = "$filename"; # force $filename to be a strict string

    my $mime_type = 'text/plain';
    if ($info and exists $info->{'Content-Type'}) {
        $mime_type = $info->{'Content-Type'};
    }
    
    my $data = {
        value => $value,
        file_name => $filename,
        mime_type   => $mime_type,
        data_size => length $value,
    };
    my $results = Data::FormValidator->check($data, $dfv_profile);
    return $self->_ajax_upload_compile_messages($results->msgs)
        if ! $results->success;

    $value = $results->valid('value');
    $filename = $results->valid('file_name');

    if ($query->param('validate')) {

        return $self->to_json({status => 'Document root is not a directory'})
            if not -d $httpdocs_dir;

        return $self->to_json({status => 'Upload folder is not a directory'})
            if not -d $full_upload_dir;

        return $self->to_json({status => 'Upload folder is not writeable'})
            if not -w $full_upload_dir;
        
        return $self->to_json({status => 'No data uploaded'})
            if not $value;

    }

    open $fh, '>', "$full_upload_dir/$filename";
    print {$fh} $value;
    close $fh;

    return $self->to_json({
        status=>'UPLOADED',
        image_url=>"$upload_subdir/$filename"
    });
}

sub _ajax_upload_compile_messages {
    my $self = shift;
    my $msgs = shift;
    my $text = '';
    foreach my $key (keys  %$msgs) {
        $text .= "$key: $msgs->{$key}, ";
    }
    return $self->to_json({status=>$text});
}

sub ajax_upload_default_profile {
    return {
        required=>[qw(value file_name mime_type data_size)],
        untaint_all_constraints=>1,
        constraint_methods => {
            value=>qr{\A.+\z}xms,
            file_name=>qr/^[\w\.\-\_]{1,30}$/,
            data_size=>sub {
                my ($dfv, $val) = @_;
                $dfv->set_current_constraint_name('data_size');
                return $val < $MAX_UPLOAD;
            },
            mime_type=>qr{
                \A
                image/
                (?:
                    jpeg|png|gif
                )
                \z
            }xms,
        },
        msgs => {
            format => '%s',
        },
    };
}

1; # Magic true value required at end of module
__END__

=head1 NAME

CGI::Application::Plugin::AJAXUpload - Run mode to handle a file upload and return a JSON response

=head1 VERSION

This document describes CGI::Application::Plugin::AJAXUpload version 0.0.3

=head1 SYNOPSIS

    use MyWebApp;
    use CGI::Application::Plugin::JSON qw(to_json);
    use CGI::Application::Plugin::AJAXUpload;

    sub setup {
        my $c = shift;
        $c->ajax_upload_httpdocs('/var/www/vhosts/mywebapp/httpdocs');

        $c->ajax_upload_setup(
            run_mode=>'file_upload',
            upload_subdir=>'/img/uploads',
        );
        return;
    }

=head1 DESCRIPTION

This module provides a customisable run mode that handles a file upload
and responds with a JSON message like the following:

    {status: 'UPLOADED', image_url: '/img/uploads/666.png'}

or on failure

    {status: 'The image was too big.'}

This is specifically intended to provide a L<CGI::Application> based back
end for L<AllMyBrain.com|http://allmybrain.com>'s 
L<image upload extension|http://allmybrain.com/2007/10/16/an-image-upload-extension-for-yui-rich-text-editor> to the
L<YUI rich text editor|http://developer.yahoo.com/yui/editor>. However as far as
I can see it could be used as a back end for any L<CGI::Application> website that uploads files behind the scenes using AJAX. In any case this module does NOT
provide any of that client side code and you must also map the run mode onto the URL used by client-side code.
That said a working example is provided which could form the basis of
a rich text editor.  

=head1 INTERFACE 

=head2 ajax_upload_httpdocs

The module needs to know the document root because it will need to
to copy the file to a sub-directory of the document root,
and it will need to pass that sub-directory back to the client as part
of the URL. If passed a value it will store that as the document root.
If not passed a value it will return the document root.

=head2 ajax_upload_setup

This method sets up a run mode to handle a file upload
and return a JSON message providing status. It takes a number of named
parameters:

=over

=item upload_subdir

This is the sub-directory of I<httpdocs_dir> where the files will actually
be written to. It must be writeable. It defaults to '/img/uploads'.

=item dfv_profile

This is a L<Data::FormValidator> profile. The hash array that is validated
consists of the fields described below. A very basic profile is provided by
default.

=over 4

=item I<value> This is contains the actual data contained in the upload. It will
be untainted. One can of course apply filters that resize the image (assuming
it is an image) or scrub the HTML (if that is appropriate). 

=item I<file_name> This is the filename given by the browser. By default it will
be required to be no more than 30 alphanumeric, hyphen or full stop,
underscore characters; it will be untainted and passed through unmodified. One
could however specify a filter that completely ignores the filename, generates
a safe one and does other housekeeping.

=item I<mime_type> This is the file extension passed by the browser.

=item I<data_size> By default this is required to be less than 512K. 

=back 

Note that this module's handling of file upload and data validation is
somewhat different from that expected by
L<Data::FormValidator::Constraints::Upload> and 
L<Data::FormValidator::Filters::Image>. Those modules work with file handles.
The L<Data::FormValidator> profiles required  by this module are expected
to work with the data and meta data.

=item run_mode

This is the name of the run mode that will handle this upload. It defaults to
I<ajax_upload_rm>.

=back

=head2 ajax_upload_default_profile

This returns a hash reference to the default L<Data::FormValidator>
profile. It can be called as a class method.

=head2 _ajax_upload_rm

This private method forms the implementation of the run mode. It requires a
I<file> CGI query parameter that provides the file data. Optionally it also
takes a I<validate> parameter that will make other more paranoid checks.
These checks are only optional because if the system is set up correctly
they should never fail.

It takes the following actions:

=over 

=item --

It will get the filename and data associated with the upload and 
pass the data through the L<Data::FormValidator> if a profile is 
supplied.

=item --

If it fails the L<Data::FormValidator> test a failed message will be passed
back to the caller.

=item --

If the I<validate> parameter is set the setup will check. If there
is a problem a status message will be passed back to the user.

=item --

The data will then be copied to the given file, its path being the 
combination of the I<httpdocs_dir> parameter, the
I<upload_subdir> and the generated file name.

=item - 

The successful JSON message will be passed back to the client.

=back

=head1 DIAGNOSTICS

Most error messages will be passed back to the client as a JSON
message, though in a sanitised form. One error 'Internal Error' is
fairly generic and so the underlying error message is written to standard 
error. 

=head1 CONFIGURATION AND ENVIRONMENT

CGI::Application::Plugin::AJAXUpload requires no configuration files or
environment variables. However the client side code, the URL to run mode
dispatching and the general web server setup is not supplied.

=head1 DEPENDENCIES

This is using the C<to_json> method from L<CGI::Application::Plugin::JSON>.
As such that module needs to be exported before this module. Or of course you
could just define your own.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-ajaxupload@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

One really odd thing is that the content header of the AJAX reply cannot
be 'application/json' as one would expect. This module sets it to
'text/javascript' which works. There is a very short discussion on the
L<YUI forum|http://yuilibrary.com/forum/viewtopic.php?f=89&t=4743&p=16459&hilit=POST+connection#p16459>.

=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

The javascript code in the example draws heavily on the code provided
by AllMyBrain.com. 

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
