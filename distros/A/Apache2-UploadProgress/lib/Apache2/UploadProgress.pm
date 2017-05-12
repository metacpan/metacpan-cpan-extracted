package Apache2::UploadProgress;

use strict;
use warnings;
use bytes;

use Apache2::Const       -compile => qw( OK DECLINED NOT_FOUND M_POST RSRC_CONF TAKE1 );
use Apache2::Filter      qw[];
use Apache2::Module      qw[];
use Apache2::RequestRec  qw[];
use Apache2::RequestIO   qw[];
use Apache2::Response    qw[];
use Apache2::ServerUtil  qw[];
use APR::Const           -compile => qw( SUCCESS );
use APR::Brigade         qw[];
use APR::Bucket          qw[];
use APR::Table           qw[];
use Cache::FastMmap      qw[];
use File::Spec           qw[];
use HTTP::Headers::Util  qw[split_header_words];
use Time::HiRes          qw[sleep];

our $VERSION = 0.2;

our $CACHE = Cache::FastMmap->new(
    share_file => $ENV{UPLOADPROGRESS_SHARE_FILE} || File::Spec->catfile( File::Spec->tmpdir, 'Apache2-UploadProgress' ),
    init_file  => 1,
    raw_values => 1,
    page_size  => $ENV{UPLOADPROGRESS_PAGE_SIZE} || '64k',
    num_pages  => $ENV{UPLOADPROGRESS_NUM_PAGES} || '89',
) or die qq/Failed to create a new instance of Cache::FastMmap. Reason: '$!'/;

our $DIRECTIVES = [
    {
        name         => 'UploadProgressBaseURI',
        req_override => Apache2::Const::RSRC_CONF,
        args_how     => Apache2::Const::TAKE1,
        errmsg       => 'Absolute or relative URI to extras without trailing forward slash',
    }
];

our ( $TEMPLATES, $MIMES, $HAS_BASEURI );

if ( $ENV{MOD_PERL} ) {

    Apache2::Module::add( __PACKAGE__, $DIRECTIVES );

    if (    Apache2::ServerUtil::restart_count() > 1
         && Apache2::Module::loaded('mod_alias.c')
         && Apache2::Module::loaded('mod_mime.c') ) {

        my $config = [
            sprintf( 'Alias /UploadProgress %s/extra', substr( __FILE__, 0, -3 ) ),
            '<Location /UploadProgress>',
            'SetHandler default-handler',
            Apache2::Module::loaded('mod_expires.c')
              ? ( 'ExpiresActive On', 'ExpiresDefault "access plus 1 day"')
              : (),
            '</Location>',
            '<Location /UpdateProgress>',
            'SetHandler modperl',
            'PerlResponseHandler Apache2::UploadProgress->progress',
            '</Location>'
        ];

        Apache2::ServerUtil->server->add_config($config);

        $HAS_BASEURI = 1;
    }
}

$TEMPLATES->{html} = <<'EOF';
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
  <title>UploadProgress</title>
  <link rel="stylesheet" type="text/css" href="/UploadProgress/progress.css" />
  <script src="/UploadProgress/progress.js" type="text/javascript"></script>
  <script src="/UploadProgress/progress.jmpl.js" type="text/javascript"></script>
</head>
<body onLoad="updateHTMLProgressBar({ size : '%d', received : '%d' })">
  <h3>Upload Progress</h3>
  <div id="progress"></div>
</body>
</html>
EOF

$TEMPLATES->{json} = <<'EOF';
{"size":%d,"received":%d}
EOF

$TEMPLATES->{text} = <<'EOF';
size: %d
received: %d
EOF

$TEMPLATES->{yaml} = <<'EOF';
---
size: %d
received: %d
EOF

$TEMPLATES->{xml} = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
%s<upload%s>
    <size>%d</size>
    <received>%d</received>
</upload>
EOF

$MIMES = {
    'application/x-json'    => sub { sprintf( $TEMPLATES->{json}, @_ ) },
    'application/x-yaml'    => sub { sprintf( $TEMPLATES->{yaml}, @_ ) },
    'application/xhtml+xml' => sub { sprintf( $TEMPLATES->{html}, @_ ) },
    'application/xml'       => \&xml_template,
    'text/html'             => sub { sprintf( $TEMPLATES->{html}, @_ ) },
    'text/plain'            => sub { sprintf( $TEMPLATES->{text}, @_ ) },
    'text/x-json'           => sub { sprintf( $TEMPLATES->{json}, @_ ) },
    'text/x-yaml'           => sub { sprintf( $TEMPLATES->{yaml}, @_ ) },
    'text/xml'              => \&xml_template,
};

sub xml_template {
    my ($size, $received, $r) = @_;
    my $xsl = '';
    my $xsd = '';
    if ( my $uri = Apache2::UploadProgress->base_uri($r) ) {
        $xsl = "<?xml-stylesheet type=\"text/xsl\" href=\"${uri}/progress.xsl\"?>\n";
        $xsd = ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="${uri}/progress.xsd"';
    }
    return sprintf( $TEMPLATES->{xml}, $xsl, $xsd, $size, $received);
}


sub register_mime : method {
    my ( $class, $mime, $callback ) = @_;
    $MIMES->{ lc $mime } = $callback;
}

sub UploadProgressBaseURI {
    my ( $self, $parms, $uri ) = @_;
    $self->{UploadProgressBaseURI} = $uri;    
}

sub config {
    my ( $class, $r ) = @_;
    return Apache2::Module::get_config( __PACKAGE__, $r->server, $r->per_dir_config );
}

sub base_uri {
    my ( $class, $r ) = @_;

    if ( $r ) {
        my $config = $class->config($r);
        return $config->{UploadProgressBaseURI} if $config->{UploadProgressBaseURI};
    }

    if ( $HAS_BASEURI ) {
        return '/UploadProgress';
    }

    return undef;
}

sub progress_id {
    my ( $class, $r ) = @_;

    return $r->headers_in->get('X-Upload-ID')
        || $r->headers_in->get('X-Progress-ID')                        # lighttpd compat
        || ( $r->unparsed_uri =~ m/\?([a-fA-F0-9]{32})$/ )[0]          # lighttpd compat
        || ( $r->unparsed_uri =~ m/(?:progress|upload)_id=([a-fA-F0-9]{32})/ )[0];
}

sub fetch_progress {
    my ( $class, $progress_id ) = @_;

    my $progress = $CACHE->get($progress_id)
      or return undef;

    return [ unpack( 'LL', $progress ) ];
}

sub store_progress {
    my ( $class, $progress_id, $progress ) = @_;

    return $CACHE->set( $progress_id => pack( 'LL', @$progress ) );
}

sub track_progress {
    my ( $class, $f, $bb, $mode, $block, $readbytes ) = @_;

    unless ( $f->ctx ) {

        my $ctx = [];

        $ctx->[0] = $class->progress_id( $f->r )
          or return Apache2::Const::DECLINED;

        $ctx->[1]->[0] = $f->r->headers_in->get('Content-Length') || 0;
        $ctx->[1]->[1] = 0;

        $f->ctx($ctx);

        $class->store_progress( @{ $f->ctx } );
    }

    my $rv = $f->next->get_brigade( $bb, $mode, $block, $readbytes );

    unless ( $rv == APR::Const::SUCCESS ) {
        return $rv;
    }

    $f->ctx->[1]->[1] += $bb->length;

    $class->store_progress( @{ $f->ctx } );

    return Apache2::Const::OK;
}

sub handler : method {
    my ( $class, $r ) = @_;

    $r->method_number == Apache2::Const::M_POST
      or return Apache2::Const::DECLINED;

    $class->progress_id($r)
      or return Apache2::Const::DECLINED;

    $r->add_input_filter( $class . '->track_progress' );

    return Apache2::Const::OK;
}

sub progress : method {
    my ( $class, $r ) = @_;

    my $progress_id = $class->progress_id($r)
      or return Apache2::Const::NOT_FOUND;
      
    my $progress = undef;
    my $tries    = 16; # wait a max of 4 seconds for the upload to start
    
    while ( $tries && !$progress ) {

        $progress = $class->fetch_progress($progress_id)
          or sleep(0.250);
        
        $tries--;
    }
    
    unless ( $progress ) {
        return Apache2::Const::NOT_FOUND;
    }

    my $content_type = 'text/xml';

    if ( my $accept_header = $r->headers_in->get('Accept') ) {

        my %accept  = ();
        my $counter = 0;

        foreach my $pair ( split_header_words($accept_header) ) {

            my ( $type, $qvalue ) = @{ $pair }[0,3];

            unless ( defined $qvalue ) {
                $qvalue = 1 - ( ++$counter / 1000 );
            }

            $accept{ $type } = sprintf( '%.3f', $qvalue );
        }

        foreach my $type ( sort { $accept{$b} <=> $accept{$a} } keys %accept ) {

            if ( exists $MIMES->{$type} ) {
                $content_type = $type;
                last;
            }
        }
    }

    $r->headers_out->set( 'Vary'          => 'Accept' );
    $r->headers_out->set( 'Pragma'        => 'no-cache' );
    $r->headers_out->set( 'Expires'       => 'Thu, 01 Jan 1970 00:00:00 GMT' );
    $r->headers_out->set( 'Cache-Control' => 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0' );

    my $callback = $MIMES->{$content_type};
    my $content  = $callback->( @$progress, $r );

    $r->content_type($content_type);
    $r->set_content_length( length $content );
    $r->write($content);

    return Apache2::Const::OK;
}

1;

__END__

=head1 NAME

Apache2::UploadProgress - Track the progress and give realtime feedback of file uploads

=head1 SYNOPSIS

In Apache:

    PerlLoadModule             Apache2::UploadProgress
    PerlPostReadRequestHandler Apache2::UploadProgress

In your HTML form:

 <script src="/UploadProgress/progress.js"></script>
 <link type="text/css" href="/UploadProgress/progress.css"/>
 <form action="/cgi-bin/script.cgi"
       method="post"
       enctype="multipart/form-data"
       onsubmit="return startEmbeddedProgressBar(this)">
 <input type="file" name="file"/>
 <input type="submit" name=".submit"/>
 </form>
 <div id="progress"></div>


=head1 DESCRIPTION

This module allows you to track the progress of a file upload in order
to provide a user with realtime updates on the progress of their file
upload.

The information that is provided by this module is very basic.  It just
includes the total size of the upload, and the current number of bytes that
have been received.  However, this information is sufficient to display lots of
information about the upload to the user.  At it's simplest, you can trigger a
popup window that will automatically refresh until the upload completes.
However, popups can be a problem sometimes, so it is also possible to embed a
progress monitor directly into the page using some JavaScript and AJAX calls.
Examples using both techniques are discussed below in the EXAMPLES section.


=head1 EXAMPLES

=head2 Simple Popup Upload Monitor

The simplest way to add a progress monitor to your forms is to use the popup
technique.  This will launch a popup window with a progress monitor that will
automatically refresh until the upload is complete.  The popup will use the XML
method by default, and format the page using an included XSL stylesheet (which
can be customized to suit your needs).  If the browser does not support XML
transformations, then content negotiation will automatically fall back on a
basic HTML page.

Here is what you need to do to get the popup technique working:

 <script src="/UploadProgress/progress.js"></script>
 <form action="/cgi-bin/script.cgi"
       method="post"
       enctype="multipart/form-data"
       onsubmit="return startPopupProgressBar(this, {width : 500, height : 400})">
 <input type="file" name="file"/>
 <input type="submit" name=".submit"/>
 </form>

So all we have done is add an onsubmit handler on the form that will pop up a
new window and load the progress monitor.  No changes need to be made to your
CGI script, and nothing else needs to be done (apart from the standard Apache
configuration directives listed in the SYNOPSIS above)

=head2 Embedded Upload Monitor

It is also possible to embed the progress monitor directly into the page and it
is just as easy:

 <script src="/UploadProgress/progress.js"></script>
 <link type="text/css" href="/UploadProgress/progress.css"/>
 <form action="/cgi-bin/script.cgi"
       method="post"
       enctype="multipart/form-data"
       onsubmit="return startEmbeddedProgressBar(this)">
 <input type="file" name="file"/>
 <input type="submit" name=".submit"/>
 </form>
 <div id="progress"></div>

The only difference is that we changed the onsubmit handler to call
startEmbeddedProgressBar, and then we added and extra 'div' tag to indicate
where we want the progress monitor to appear.


For complete runable examples please see the scripts in the examples directory.

=head1 APACHE CONFIGURATION

=over 4

=item UploadProgressBaseURI

Change the location of the extra support files, so that you can customize them
to suit your needs.

 UploadProgressBaseURI /CustomUploadProgess
 Alias /CustomUploadProgess /var/www/customprogressfiles

Make sure that you copy all the support files found in the 'extra' directory to
this new location and then you can customize them to your liking.

This currently only affects the urls used in the XML/XSL and HTML mime handlers
used in the popup progress monitor.

=back

=head1 HANDLERS

=over 4

=item handler

This handler should be run at the PerlPostReadRequestHandler stage,
and will detect whether we need to track the upload progress of the current
request.  There are 5 ways for the handler to determine if the upload progress
should be tracked:

=over 4

=item X-Upload-ID

There is an incoming header called X-Upload-ID which contains the progess ID

=item X-Progress-ID

There is an incoming header called X-Progress-ID which contains the progess ID

=item Query contains ID

The query portion of the URL consists of just a 32 character hexadecimal
string (for example http://localhost/upload.cgi?1234567890abcdef1234567890abcdef)

=item Query contains progress_id

There is a query parameter in the query string called progress_id, and it
contains a 32 character hexadecimal number (for example
http://localhost/upload.cgi?progress_id=1234567890abcdef1234567890abcdef)

=item Query contains upload_id

There is a query parameter in the query string called upload_id, and it
contains a 32 character hexadecimal number (for example
http://localhost/upload.cgi?upload_id=1234567890abcdef1234567890abcdef)

=back

Note that you can not pass the progress_id as a hidden POST parameter,
since the Apache2::UploadProgress module never actually decodes the POST
request so it will not be able to determine what the ID is.  The reason
for this is that we are trying to track the rate at which the POST request
takes to upload, so we need that ID before we even start counting the incoming
POST request.  So the ID must be passed as a header, or as a simple query parameter,
as part of the action attribute of the form.

=item progress

When called, this handler will return the upload progress of the request
identified by the given ID.  The ID can be provided in exactly the same way
as in the handler method given above (Although is usually easiest to just provide
is as a query parameter called progress_id).

This handler can return the results in several different formats.  By default,
it will return XML data, but that can be changed by altering the Accept header
of the request (if multiple mimes are present in the Accept header, they are
tried in order of qvalue according to RFC 2616).

For example, if you set the Accept header to the following:

    Accept:  text/plain; q=0.5, text/x-json

Then the preferred mime type would be text/x-json, but if it was
not available, the data would be sent in text/plain.

The following formats are currently supported:

=over 4

=item HTML ( text/html   application/xhtml+xml )

=item JSON ( text/x-json application/x-json    )

=item TEXT ( text/plain                        )

=item YAML ( text/x-yaml application/x-yaml    )

=item XML  ( text/xml    application/xml       )

=back

For an example of how to alter the incoming Accept header see the example
script that is included in the examples directory.

=back

=head1 PUBLIC METHODS

=over 4

=item register_mime( $mime, \&callback )

    my $callback = sub { 
        my ( $size, $received, $r ) = @_;
        return sprintf "Total size: %d\n Received: %d\n", $size, $received;
    };

    Apache2::UploadProgress->register_mime( 'text/plain' => $callback );

Register a content handler for a mime. Callback will be called with three 
positional arguments, size, received and C<$r>. Callback is expected to return a 
scalar of octets representing the response body.  This can be used to override
any of the existing content handlers (for example if you wanted a custom HTML
response, override 'text/html').

=back

=head1 INTERNAL METHODS

The following internal methods should never need to be called directly but
are documented for completeness.

=over 4

=item progress_id( $r )

    $progress_id = Apache2::UploadProgress->progress_id($r);

Determine the progress ID for the current request (if it exists)

=item fetch_progress( $progress_id )

    $progress = Apache2::UploadProgress->fetch_progress($progress_id);
    printf "size:     %d", $progress->[0];
    printf "received: %d", $progress->[1];

Pulls the progress values from the cache based on the provided ID

=item store_progress( $progress_id, [ $size, $received ] )

    Apache2::UploadProgress->store_progress( $progress_id, [ $size, $received ] );

Update the progress values in the cache for the given ID

=item track_progress

An Input filter handler that totals up the number of bytes that have been sent
as part of the current request, and updates the current progress through calls
to C<store_progress>.

=back

=head1 BUGS

=over 4

=item Safari

The JavaScript for the embedded progress meter is currently failing in
Safari

=item Cancelled uploads

When a user cancels an upload, but leaves the page with the progress
meter active, the progress meter may continue to reload indefinately

=back

=head1 SEE ALSO

L<http://perl.apache.org/docs/2.0/>.

L<http://www.modperlbook.org/>.

L<Apache2::Filter>.

L<Apache2::RequestRec>.

=head1 AUTHOR(S)

Christian Hansen C<chansen@cpan.org>

Cees Hek C<ceeshek@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
