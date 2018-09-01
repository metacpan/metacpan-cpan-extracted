package Wallflower;
$Wallflower::VERSION = '1.011';
use strict;
use warnings;

use Plack::Util ();
use Path::Tiny ();
use URI;
use HTTP::Date qw( time2str str2time);
use HTTP::Headers::Fast;    # same as Plack::Response
use Carp;

# quick getters
for my $attr (qw( application destination env index url )) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

# create a new instance
sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        destination => Path::Tiny->new('.'),
        env         => {},
        index       => 'index.html',
        url         => 'http://localhost/',
        %args,
    }, $class;

    # some basic parameter checking
    croak "application is required" if !defined $self->application;
    croak "destination is invalid"
        if !-e $self->destination || !-d $self->destination;

    # turn the url attribute into a URI object
    $self->{url} = URI->new( $self->url );

    # if the application is mounted somewhere
    my $path;
    if ( $path = $self->url->path and $path ne '/' ) {
        require Plack::App::URLMap;
        my $urlmap = Plack::App::URLMap->new;
        $urlmap->mount( $path => $self->application );
        $self->{application} = $urlmap->to_app;
    }

    return $self;
}

# url -> file converter
sub target {
    my ( $self, $uri ) = @_;

    # the URI must have a path
    croak "$uri has an empty path" if !length $uri->path;

    # URI ending with / have the empty string as their last path_segment
    my @segments = $uri->path_segments;
    $segments[-1] = $self->index if $segments[-1] eq '';

    # generate target file name
    return Path::Tiny->new( $self->destination, grep length, @segments );
}

# save the URL to a file
sub get {
    my ( $self, $uri ) = @_;
    $uri = URI->new($uri) if !ref $uri;

    # absolute paths have the empty string as their first path_segment
    croak "$uri is not an absolute URI"
        if $uri->path && length +( $uri->path_segments )[0];

    # setup the environment
    my $env = {

        # current environment
        %ENV,

        # overridable defaults
        'psgi.errors' => \*STDERR,

        # current instance defaults
        %{ $self->env },
        ('psgi.url_scheme' => $self->url->scheme )x!! $self->url->scheme,

        # request-related environment variables
        REQUEST_METHOD => 'GET',

        # request attributes
        SCRIPT_NAME     => '',
        PATH_INFO       => $uri->path,
        REQUEST_URI     => $uri->path,
        QUERY_STRING    => '',
        SERVER_NAME     => $self->url->host,
        SERVER_PORT     => $self->url->port,
        SERVER_PROTOCOL => "HTTP/1.0",

        # wallflower defaults
        'psgi.streaming' => '',
    };

    # add If-Modified-Since headers if the target file exists
    my $target = $self->target($uri);
    $env->{HTTP_IF_MODIFIED_SINCE} = time2str( ( stat _ )[9] ) if -e $target;

    # fixup URI (needed to resolve relative URLs in retrieved documents)
    $uri->scheme( $env->{'psgi.url_scheme'} ) if !$uri->scheme;
    $uri->host( $env->{SERVER_NAME} ) if !$uri->host;

    # get the content
    my ( $status, $headers, $file, $content ) = ( 500, [], '', '' );
    my $res = Plack::Util::run_app( $self->application, $env );

    if ( ref $res eq 'ARRAY' ) {
        ( $status, $headers, $content ) = @$res;
    }
    elsif ( ref $res eq 'CODE' ) {
        croak "Delayed response and streaming not supported yet";
    }
    else { croak "Unknown response from application: $res"; }

    # save the content to a file
    if ( $status eq '200' ) {

        # get a file to save the content in
        my $dir = ( $file = $target )->parent;
        if ( !-e $dir ) {
            eval { $dir->mkpath } or do {
                warn "$@\n" if $@;
                return [ 999, [], '' ];
            };
        }
        open my $fh, '> :raw', $file    # no stinky crlf on Win32
          or do {
            warn "Can't open $file for writing: $!\n";
            return [ 999, [], '' ];
          };

        # copy content to the file
        if ( ref $content eq 'ARRAY' ) {
            print $fh @$content;
        }
        elsif ( ref $content eq 'GLOB' ) {
            local $/ = \8192;
            print {$fh} $_ while <$content>;
            close $content;
        }
        elsif ( eval { $content->can('getline') } ) {
            local $/ = \8192;
            while ( defined( my $line = $content->getline ) ) {
                print {$fh} $line;
            }
            $content->close;
        }
        else {
            croak "Don't know how to handle body: $content";
        }

        # finish
        close $fh;

        # if the app sent Last-Modified, set the local file date to that
        if ( my $last_modified = HTTP::Headers::Fast->new(@$headers)
             ->header('Last-Modified') ) {
            my $epoch = str2time( $last_modified );
            utime $epoch, $epoch, $file;
        }
    }

    return [ $status, $headers, $file ];
}

1;

__END__

=pod

=head1 NAME

Wallflower - Stick Plack applications to the wallpaper

=head1 VERSION

version 1.011

=head1 SYNOPSIS

    use Wallflower;

    my $w = Wallflower->new(
        application => $app, # a PSGI app
        destination => $dir, # target directory
    );

    # dump all URL from $app to files in $dir
    $w->get( $_ ) for @urls;

=head1 DESCRIPTION

Given a URL and a L<Plack> application, a L<Wallflower> object will
save the corresponding response to a file.

=head1 METHODS

=head2 new

    my $w = Wallflower->new( %args );

Create a new L<Wallflower> object.

The parameters are:

=over 4

=item C<application>

The PSGI/Plack application, as a CODE reference.

This parameter is I<required>.

=item C<destination>

The destination directory. Default is the current directory.

The destination directory must exist.

=item C<env>

Additional environment key/value pairs.

=item C<index>

The default filename for URLs ending in C</>.
The default value is F<index.html>.

=item C<url>

URL where the root of the application will be reachable in production.

If the URL has a path component, the application will be "mounted" at
that position.

=back

=head2 get

    my $response = $w->get( $url );

Perform a C<GET> request for C<$url> through the application, and
if successful, save the result to a filename derived from C<$url> by
the C<target()> method.

C<$url> can be either a string or a L<URI> object, representing an
absolute URL (the path must start with a C</>). The scheme, host, port,
and query string are ignored if present.

The return value is very similar to a L<Plack> application response:

   [ $status, $headers, $file ]

where C<$status> and C<$headers> are those returned by the application
itself for the given C<$url>, and C<$file> is the name of the file where
the content has been saved.

If an error is encountered when trying to open the file, C<$status>
will be set to C<999> (an invalid HTTP status code), and a warning will
be emitted.

If the application sends the C<Last-Modified> header in its response,
the modification date of the target file will be modified accordingly.

If a file exists at the location pointed to by the target, a
C<If-Modified-Since> header is added to the Plack environment,
with the modification timestamp for this file as the value.
If the application sends a C<304 Not modified> in response,
the target file will not be modified.

=head2 target

    my $target = $w->target($uri);

Return the filename where the content of C<$uri> will be saved.

The C<path> component of C<$uri> is concatenated to the C<destination>
attribute. If the URL ends with a C</>, the C<index> attribute is appended
to create a file path.

Note that C<target()> assumes C<$uri> is a L<URI> object, and that it
must be absolute.

=head1 ACCESSORS

Accessors (getters only) exist for all parameters
to C<new()> and bear the same name.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2018 by Philippe Bruhat (BooK).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
