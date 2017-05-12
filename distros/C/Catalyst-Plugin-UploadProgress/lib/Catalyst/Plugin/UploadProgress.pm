package Catalyst::Plugin::UploadProgress;
use Moose::Role;
use Catalyst::Exception;
use MooseX::RelatedClassRoles ();
use namespace::autoclean;

our $VERSION = '0.06';

requires qw/
    prepare_body_chunk
    prepare_body
    dispatch
    setup_finalize
/;


around _build_request_constructor_args => sub {
    my ($orig, $self, @args) = @_;
    my $p = $self->$orig(@args);
    $p->{_cache} = $self->cache;
    return $p;
};

around 'prepare_body' => sub {
    my $orig = shift;
    my $c = shift;

    # Detect if the user stopped the upload, prepare_body will die with an invalid
    # content-length error

    my $croaked;

    {
        no warnings 'redefine';
        local *Carp::croak = sub {
            $croaked = shift;
        };

        $c->$orig(@_);
    }

    if ( $croaked ) {
        if ( my $id = $c->req->query_parameters->{progress_id} ) {
            $c->log->info( "UploadProgress: User aborted upload $id" );

            # Update progress to flag this so javascript will stop polling
            my $progress = $c->cache->get( 'upload_progress_' . $id ) || {};

            $progress->{aborted} = 1;

            $c->cache->set( 'upload_progress_' . $id, $progress );
        }

        # rethrow the error
        Catalyst::Exception->throw( $croaked );
    }
};

around 'dispatch' => sub {
    my $orig = shift;
    my $c = shift;

    # if the URI query string is ?progress_id=<id> intercept the request
    # and display the progress JSON.
    my $query = $c->req->uri->path_query;
    if ( $c->req->method eq 'GET' && $query =~ m{\?progress_id=([a-f0-9]{32})$} ) {
        return $c->upload_progress_output( $1 );
    }

    return $c->$orig(@_);
};

after 'setup_finalize' => sub {
    my $c = shift;

    unless ( $c->can('cache') ) {
        Catalyst::Exception->throw(
            message => 'UploadProgress requires a cache plugin.'
        );
    }
    Class::MOP::class_of('MooseX::RelatedClassRoles')
      ->apply($c->meta, name => 'request', require_class_accessor => 0);
    $c->apply_request_class_roles('Catalyst::Plugin::UploadProgress::Role::Request');
};

sub upload_progress {
    my ( $c, $upload_id ) = @_;

    return $c->cache->get( 'upload_progress_' . $upload_id );
}

sub upload_progress_output {
    my ( $c, $upload_id ) = @_;

    $upload_id ||= $c->req->params->{progress_id};

    my $progress = $c->upload_progress( $upload_id );

    # there could be a race condition where /progress is called before
    # the upload has passed through prepare_body_chunk.  Set a default
    # progress hash in this case.  Once through prepare_body_chunk,
    # the values will be correct.
    if ( !ref $progress ) {
        $progress = {
            received => 0,
            size     => -1,
        };
    }

    # format the progress data as JSON
    my $json   = '{"size":%d,"received":%d,"aborted":%d}';
    my $output = sprintf $json, 
        $progress->{size},
        $progress->{received},
        $progress->{aborted} || 0;

    $c->response->headers->header( Pragma  => 'no-cache' );
    $c->response->headers->header( Expires 
        => 'Thu, 01 Jan 1970 00:00:00 GMT' );
    $c->response->headers->header( 'Cache-Control' 
        => 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0' );

    $c->response->content_type( 'text/x-json' );
    $c->response->body( $output );
}

sub upload_progress_javascript {
    my $c = shift;

    require Catalyst::Plugin::UploadProgress::Static;

    my @output;
    push @output,
          '<style type="text/css">' . "\n"
        . Catalyst::Plugin::UploadProgress::Static->upload_progress_css
        . '</style>';

    push @output,
          '<script type="text/javascript">' . "\n" 
        . Catalyst::Plugin::UploadProgress::Static->upload_progress_js
        . '</script>';

    push @output,
          '<script type="text/javascript">' . "\n"
        . Catalyst::Plugin::UploadProgress::Static->upload_progress_jmpl_js
        . '</script>';

    return join "\n", @output;
}

1;

=head1 NAME

Catalyst::Plugin::UploadProgress - Realtime file upload information

=head1 SYNOPSIS

    use Catalyst;
    MyApp->setup( qw/Static::Simple Cache::FastMmap UploadProgress/ );

    # On the HTML page with the upload form, include the progress
    # JavaScript and CSS.  These are available via a single method
    # if you are lazy.
    <html>
      <head>
        [% c.upload_progress_javascript %]
      </head>
      ...

    # For better performance, copy these 3 files from the UploadProgress
    # distribution to your static directory and include them normally.
    <html>
      <head>
        <link href="/static/css/progress.css" rel="stylesheet" type="text/css" />
        <script src="/static/js/progress.js" type="text/javascript"></script>
        <script src="/static/js/progress.jmpl.js" type="text/javascript"></script>
      </head>
      ...

    # Create the upload form with an onsubmit action that creates
    # the Ajax progress bar.  Note the empty div following the form
    # where the progress bar will be inserted.
    <form action='/upload'
          method="post"
          enctype="multipart/form-data"
          onsubmit="return startEmbeddedProgressBar(this)">
  
      <input type="file" name="file" />
      <input type="submit" />
    </form>
    <div id='progress'></div>

    # No special code is required within your application, just handle
    # the upload as usual.
    sub upload : Local {
        my ( $self, $c ) = @_;

        my $upload = $c->request->uploads->{file};
        $upload->copy_to( '/some/path/' . $upload->filename );
    }

=head1 DESCRIPTION

This plugin is a simple, transparent method for displaying a
progress bar during file uploads.

=head1 DEMO

Please see the example/Upload directory in the distribution for a working
example Catalyst application with upload progress.  Since Upload Progress
requires 2 concurrent connections (one for the upload and one for the
Ajax, you will need to use either script/upload_poe.pl (which requires
L<Catalyst::Engine::HTTP::POE> >= 0.02) or script/upload_server.pl -f.  
The -f enables forking for each new request.

=head1 ENGINE SUPPORT

The included demo application has been tested and is known to work on
the following setups with Catalyst 5.7003:

C::E::HTTP (server.pl) with -f flag (OSX)
C::E::HTTP::POE 0.06 (OSX)
C::E::Apache2::MP20 1.07 with Apache 2.0.58, mod_perl 2.0.2 (OSX)
C::E::FastCGI with Apache 2.0.55, mod_fastcgi 2.4.2 (Ubuntu)

=head1 INTERNAL METHODS

You don't need to know about these methods, but they are documented
here for developers.

=head2 upload_progress( $progress_id )

Returns the data structure associated with the given progress ID.
Currently the data is a hashref with the total size of the upload
and the amount of bytes received so far.

    {
        size     => 110636659,
        received => 134983
    }

=head2 upload_progress_output

Returns a JSON response containing the upload progress data.

=head2 upload_progress_javascript

Inlines the necessary JavaScript and CSS code into your page.  For better
performance, you should copy the files into your application as displayed
above in the Synopsis.

=head1 EXTENDED METHODS

=head2 prepare_body ( $c )

Detects if the user aborted the upload.

=head2 prepare_body_chunk ( $chunk )

Takes each chunk of incoming upload data and updates the upload progress
record with new information.

=head2 dispatch

Watches for a URI ending with '?progress_id=<id>' and returns the
JSON output from C</upload_progress_output>.

=head2 setup

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

NEXT to Moose::Role conversion by Toby Corkindale, <tjc@cpan.org>, blame him
for any faults there..

=head1 THANKS

The authors of L<Apache2::UploadProgress>, for the progress.js and
progress.css code:

    Christian Hansen <chansen@cpan.org>
    Cees Hek <ceeshek@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

