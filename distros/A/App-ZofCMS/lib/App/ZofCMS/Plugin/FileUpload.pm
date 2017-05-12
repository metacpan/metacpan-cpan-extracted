package App::ZofCMS::Plugin::FileUpload;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use File::Spec::Functions (qw/catfile  splitpath/);

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{file_upload};

    my $uploads = delete $template->{file_upload};

    $uploads = [ $uploads ]
        unless ref $uploads eq 'ARRAY';

    my $upload_counter = @$uploads == 1 ? '' : 0;
    for my $upload ( @$uploads ) {
        $self->_process_upload(
            $template,
            $query,
            $config,
            $upload_counter++,
            $upload,
        );
    }

    return 1;
}

sub _process_upload {
    my ( $self, $template, $query, $config, $upload_counter, $upload ) = @_;

    my $error_key   = "upload_error$upload_counter";
    my $filename_key = "upload_filename$upload_counter";
    my $success_key = "upload_success$upload_counter";

    $upload = {
        query   => 'zofcms_upload',
        path    => 'zofcms_upload',
        name    => '[rand]',

        %$upload,
    };

    my $cgi = $config->cgi;
    my $remote_filename = $cgi->param( $upload->{query} );

    if ( not $remote_filename and $cgi->cgi_error ) {
        $template->{t}{ $error_key } = $cgi->cgi_error;
        return;
    }

    return
        unless defined $remote_filename;

    ( $upload->{ext} ) = $remote_filename =~ /[^.]+([.].+)$/
        unless defined $upload->{ext};

    $upload->{ext} = ''
        unless defined $upload->{ext};

    if ( ref $upload->{name} eq 'CODE' ) {
        $upload->{name} = $upload->{name}->( $template, $query, $config );
    }

    if ( $upload->{name} eq '[rand]' ) {
        UNIQUE_NAME: {
            $upload->{name} = catfile(
                $upload->{path},
                do { my $x = rand() . time(); $x =~ tr/.//d; $x }
                . $upload->{ext}
            );
            redo UNIQUE_NAME if -e $upload->{name};
        }
    }
    elsif ( ref $upload->{name} eq 'SCALAR' ) {
        $upload->{name} = ( splitpath $remote_filename )[-1];
        $upload->{name} =~ s/(?<=[^.])[.].+$//;
        $upload->{name} = catfile(
            $upload->{path},
            $upload->{name} . $upload->{ext}
        );
    }
    elsif ( ref $upload->{name} eq 'SCALAR' ) {
        $upload->{name} = catfile(
            $upload->{path},
            ( $remote_filename =~ /([^.]+)(?:[.].+)?$/)[0] . $upload->{ext}
        );
    }
    else {
        $upload->{name} = catfile(
            $upload->{path},
            $upload->{name} . $upload->{ext}
        );
    }

    if ( $upload->{name_filter} ) {
        $upload->{name} =~ s/$upload->{name_filter}//g;
    }

    my $upload_info = $cgi->uploadInfo( $remote_filename );

    if ( defined $upload->{content_type} ) {
        $upload->{content_type} = [ $upload->{content_type} ]
            unless ref $upload->{content_type} eq 'ARRAY';

        unless ( grep { $upload_info->{'Content-Type'} eq $_ }
                @{ $upload->{content_type} }
        ) {
            $template->{t}{ $error_key } = 'Invalid file type';
            return;
        }
    }

    my $fh = $cgi->upload( $upload->{query} );

    if ( not $fh and $cgi->cgi_error ) {
        $template->{t}{ $error_key } = $cgi->cgi_error;
        return;
    }

    return
        unless $fh;

    my $fh_out;
    unless ( open $fh_out, '>', $upload->{name} ) {
        $template->{t}{ $error_key } = "Failed to open local file [$!]";
        return;
    }

    seek $fh, 0, 0;
    binmode $fh;
    binmode $fh_out;

    {
        local $/ = \1024;
        while ( <$fh> ) {
            print $fh_out $_;
        }
    }
    close $fh;
    close $fh_out;

    if ( ref $upload->{on_success} ) {
        $upload->{on_success}->(
            $upload->{name}, $template, $query, $config,
        );
    }

    $template->{t}{ $success_key  } = 1;
    $template->{t}{ $filename_key } = $upload->{name};
    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FileUpload - ZofCMS plugin to handle file uploads

=head1 SYNOPSIS

In your ZofCMS template:

    file_upload => {
        query   => 'uploaded_file',
    },
    plugins => [ qw/FileUpload/ ],

In your L<HTML::Template> template:

    <tmpl_if name="upload_error">
        <p class="error">Upload failed: <tmpl_var name="upload_error">
    </tmpl_if>
    <tmpl_if name="upload_success">
        <p>Upload succeeded: <tmpl_var name="upload_filename"></p>
    </tmpl_if>

    <form action="" method="POST" enctype="multipart/form-data">
    <div>
        <input type="file" name="uploaded_file">
        <input type="submit" value="Upload">
    </div>
    </form>

=head1 DESCRIPTION

The module is a ZofCMS plugin which provides means to easily handle file
uploads.

This documentation assumes you've read
L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    plugins => [ qw/FileUpload/ ],

First and obvious, you need to stick C<FileUpload> in the list of your
plugins.

=head2 C<file_upload>

    file_upload => {
        query   => 'upload',
        path    => 'zofcms_upload',
        name    => 'foos',
        ext     => '.html',
        content_type => 'text/html',
        on_success => sub {
            my ( $uploaded_file_name, $template, $query, $conf ) = @_;
            # do something useful
        }
    },

    # or

    file_upload => [
        { query   => 'upload1', },
        { query   => 'upload2', },
        {}, # all the defaults
        {
            query   => 'upload4',
            name    => 'foos',
            ext     => '.html',
            content_type => 'text/html',
            on_success => sub {
                my ( $uploaded_file_name, $template, $query, $conf ) = @_;
                # do something useful
            }
        },
    ],

Plugin takes input from C<file_upload> first level ZofCMS template key which
takes an arrayref or a hashref as a value. Passing a hashref as a value
is the same as passing an arrayref with just that hashref as an element.
Each element of the given arrayref is a hashref which
represents one file upload. The possible keys/values of those hashrefs
are as follows:

=head3 C<query>

    { query => 'zofcms_upload' },

B<Optional>. Specifies the query parameter which is the file being uploaded,
in other words, this is the value of the C<name=""> attribute of the
C<< <input type="file"... >>. B<Defaults to:> C<zofcms_upload>

=head3 C<path>

    { path => 'zofcms_upload', }

B<Optional>. Specifies directory (relative to C<index.pl>) into which
the plugin will store uploaded files. B<Defaults to:> C<zofcms_upload>

=head3 C<name>

    { name => 'foos', }

    { name => '[rand]', }

    { name => \1 } # any scalar ref

    {
        name => sub {
            my ( $t, $q, $config ) = @_;
            return 'file_name.png';
        },
    }

B<Optional>. Specifies the name (without the extension)
of the local file into which save the uploaded file. Special value of
C<[rand]> specifies that the name should be random, in which case it
will be created by calling C<rand()> and C<time()> and removing any dots
from the concatenation of those two. If a I<scalarref> is specified
(irrelevant of its value), the plugin will use the filename that the
browser gave it (relying on L<File::Spec::Functions>'s
C<splitpath> here; also, note that extension will be obtained
using C<ext> argument (see below). The C<name> parameter can also take
a subref, if that's the case, then the C<name> parameter will obtain
its value from the return value of that subref. The subref's C<@_> will
contain the following (in that order): ZofCMS Template hashref, hashref
of query parameters and L<App::ZofCMS::Config> object.
B<Defaults to:> C<[rand]>

=head3 C<ext>

    { ext => '.html', }

B<Optional>. Specifies the extension to use for the name of local file
into which the upload will be stored. B<By default> is not specified
and therefore the extension will be obtained from the name of the remote
file.

=head3 C<name_filter>

    { name_filter => qr/Z(?!ofcms)/i, }

B<Optional>. Takes a regex ref (C<qr//>) as a value. Anything
in the C<path> + C<name> + C<ext> final string (regardles of how each
of those is obtained) that matches this regex
will be stripped. B<By default> is not specified.

=head3 C<content_type>

    { content_type => 'text/html', }

    { content_type => [ 'text/html', 'image/jpeg' ], }

B<Optional>. Takes either a scalar string or an arrayref of strings.
Specifying a string is equivalent to specifying an arrayref with just that
string as an element. Each element of the given arrayref indicates the
allowed Content-Type of the uploaded files. If the Content-Type does
not match allowed types the error will be shown (see HTML TEMPLATE VARS
section below). B<By default> all Content-Types are allowed.

=head3 C<on_success>

    on_success => sub {
        my ( $uploaded_file_name, $template, $query, $config ) = @_;
        # do something useful
    }

B<Optional>. Takes a subref as a value. The specified sub will be
executed upon a successful upload. The C<@_> will contain the following
elements: C<$uploaded_file_name, $template, $query, $config> where
C<$uploaded_file_name> is the directory + name + extension of the local
file into which the upload was stored, C<$template> is a hashref of
your ZofCMS template, C<$query> is a hashref of query parameters and
C<$config> is the L<App::ZofCMS::Config> object. B<By default> is not
specified.

=head1 HTML TEMPLATE VARS

Single upload:

    <tmpl_if name="upload_error">
        <p class="error">Upload failed: <tmpl_var name="upload_error">
    </tmpl_if>
    <tmpl_if name="upload_success">
        <p>Upload succeeded: <tmpl_var name="upload_filename"></p>
    </tmpl_if>

    <form action="" method="POST" enctype="multipart/form-data">
    <div>
        <input type="file" name="upload">
        <input type="submit" value="Upload">
    </div>
    </form>

Multi upload:

    <tmpl_if name="upload_error0">
        <p class="error">Upload 1 failed: <tmpl_var name="upload_error0">
    </tmpl_if>
    <tmpl_if name="upload_success0">
        <p>Upload 1 succeeded: <tmpl_var name="upload_filename0"></p>
    </tmpl_if>

    <tmpl_if name="upload_error1">
        <p class="error">Upload 2 failed: <tmpl_var name="upload_error1">
    </tmpl_if>
    <tmpl_if name="upload_success1">
        <p>Upload 2 succeeded: <tmpl_var name="upload_filename1"></p>
    </tmpl_if>

    <form action="" method="POST" enctype="multipart/form-data">
    <div>
        <input type="file" name="upload">
        <input type="file" name="upload2">
        <input type="submit" value="Upload">
    </div>
    </form>

B<NOTE:> upload of multiple files from a single C<< <input type="file"... >>
is currently not supported. Let me know if you need such functionality.
The folowing C<< <tmpl_var name=""> >>s will be set in your
L<HTML::Template> template.

=head2 SINGLE AND MULTI

If you are handling only one upload, i.e. you have only one hashref in
C<file_upload> ZofCMS template key and you have only one
C<< <input type="file"... >> then the HTML::Template variables described
below will B<NOT> have any trailing numbers, otherwise each of them
will have a trailing number indicating the number of the upload. This number
will starts from B<zero> and it will correspond to the index of hashref of
C<file_upload> arrayref.

=head2 C<upload_error>

    # single
    <tmpl_if name="upload_error">
        <p class="error">Upload failed: <tmpl_var name="upload_error">
    </tmpl_if>

    # multi
    <tmpl_if name="upload_error0">
        <p class="error">Upload 1 failed: <tmpl_var name="upload_error0">
    </tmpl_if>

The C<upload_error> will be set if some kind of an error occurred during
the upload of the file. This also includes if the user tried to upload
a file of type which is not listed in C<content_type> arrayref.

=head2 C<upload_success>

    # single
    <tmpl_if name="upload_success">
        <p>Upload succeeded: <tmpl_var name="upload_filename"></p>
    </tmpl_if>

    # multi
    <tmpl_if name="upload_success0">
        <p>Upload 1 succeeded: <tmpl_var name="upload_filename0"></p>
    </tmpl_if>

The C<upload_success> will be set to a true value upon successful upload.

=head2 C<upload_filename>

    # single
    <tmpl_if name="upload_success">
        <p>Upload succeeded: <tmpl_var name="upload_filename"></p>
    </tmpl_if>

    # multi
    <tmpl_if name="upload_success0">
        <p>Upload 1 succeeded: <tmpl_var name="upload_filename0"></p>
    </tmpl_if>

The C<upload_filename> will be set to directory + name + extension of the
local file into which the upload was saved.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut