package Catmandu::Importer::getJSON;

our $VERSION = '0.50';
our $CACHE;

use Catmandu::Sane;
use Moo;
use JSON;
use Furl;
use Scalar::Util qw(blessed);
use URI::Template;

with 'Catmandu::Importer';

has url     => ( 
    is  => 'rw', 
    trigger => sub {
        $_[0]->{url} = _url_template_or_url($_[1])
    }
);

has from    => ( is => 'ro');
has timeout => ( is => 'ro', default => sub { 10 } );
has agent   => ( is => 'ro' );
has proxy   => ( is => 'ro' );
has dry     => ( is => 'ro' );
has headers => ( 
    is => 'ro', 
    default => sub { [ 'Accept' => 'application/json' ] } 
);
has wait    => ( is => 'ro' );
has cache   => ( is => 'ro', trigger => 1 );
has client  => (
    is => 'ro',
    lazy => 1,
    builder => sub { 
        Furl->new( 
            map { $_ => $_[0]->{$_} } grep { defined $_[0]->{$_} }
            qw(timeout agent proxy),
        ) 
    }
);
has json => ( is => 'ro', default => sub { JSON->new->utf8(1) } );
has time => ( is => 'rw' );
has warn => ( is => 'ro', default => sub { 1 } );

sub _url_template_or_url {
    my ($url) = @_;

    if (!blessed $url) {
        $url = URI::Template->new($url);
    }

    if ($url->isa('URI::Template')) {
        unless ( my @variables = $url->variables ) {
            $url = URI->new("$url");
        }
    }
    return $url;
}


{
    package Importer::getJSON::MemoryCache;
    use JSON;
    our $JSON = JSON->new->utf8;
    sub new { bless {}, $_[0] }
    sub get { eval { $JSON->decode($_[0]->{$_[1]}) } }
    sub set { $_[0]->{$_[1]} = ref $_[2] ? $JSON->encode($_[2]) : '' }
}
$CACHE = Importer::getJSON::MemoryCache->new;

{
    package Importer::getJSON::FileCache;
    use JSON;
    use Catmandu::Util qw(read_json);
    use Digest::MD5 qw(md5_hex);
    our $JSON = JSON->new->utf8;
    sub new {
        my ($class, $dir) = @_;
        $dir =~ s{/$}{};
        bless { dir => $dir }, $class 
    }
    sub file {
        my ($self, $url) = @_;
        $self->{dir}.'/'.md5_hex($url).'.json';
    }
    sub get { eval { read_json($_[0]->file($_[1])) } }
    sub set { 
        my ($self, $url, $data) = @_;
        open my $fh, ">", $self->file($url);
        print $fh (ref $data ? $JSON->encode($data) : '');
    }
}

sub _trigger_cache {
    my ($self, $cache) = @_;
 
    if (blessed $cache and $cache->can('get') and $cache->can('set')) {
        # use cache object 
    } elsif ($cache and -d $cache) {
        $cache = Importer::getJSON::FileCache->new($cache);
    } elsif ($cache) {
        $cache = $CACHE;
    }

    $self->{cache} = $cache;
}

sub generator {
    my ($self) = @_;
    
    if ($self->from) {
        return sub {
            state $data = do {
                my $r = $self->request($self->from);
                (ref $r // '') eq 'ARRAY' ? $r : [$r];
            };
            return shift @$data;
        }
    }

    sub {
        state $fh = $self->fh;
        state $data;

        if ( $data and ref $data eq 'ARRAY' and @$data ) {
            return shift @$data;
        }

        my $url;
        until ( $url ) {
            my $line = <$fh> // return;
            chomp $line;
            $line =~ s/^\s+|\s+$//g;
            next if $line eq ''; # ignore empty lines

            my $request = eval { $self->request_hook($line) };
            $url = $self->construct_url($request);
            warn "failed to construct URL: $line\n" if !$url and $self->warn;
        }

        $data = $self->request($url);

        return (ref $data // '') eq 'ARRAY' ? shift @$data : $data;
    }
}

sub request_hook {
    my ($self, $line) = @_;
    return $line =~ /^\s*{/ ? $self->json->decode($line) : $line;
}

sub construct_url {
    my $self    = shift;
    my $url     = @_ > 1 ? _url_template_or_url(shift) : $self->url;
    my $request = shift;
        
    # Template or query variables
    if (ref $request and not blessed $request) {
        return unless blessed $url;
        if ($url->isa('URI::Template')) {
            $url = $url->process($request);
        } else {
            $url = $url->clone;
            $url->query_form($request);
        }  
        return $url;       
    } elsif (blessed $request and $request->isa('URI::URL')) {
        return $request;
    } elsif ( $request =~ /^https?:\/\// ) { # plain URL
        return URI->new($request);
    } elsif ( $request  =~ /^\// ) { # URL path (and optional query)
        $url = "$url";
        $url =~ s{/$}{}; 
        $request =~ s{\s+$}{};
        return URI->new($url . $request);
    }

    return;
} 

sub request {
    my ($self, $url) = @_;

    $self->log->debug($url);

    my $json = '';

    if ( $self->dry ) {
        return { url => "$url" };
    }

    if ( $self->cache ) {
        $json = $self->cache->get($url);
        if (defined $json) {
            return ref $json ? $json : undef;
        }   
    }

    if ( $self->wait and $self->time ) {
        my $elapsed = ($self->time // time) - time;
        sleep( $self->wait - $elapsed );
    }
    $self->time(time);

    my $response = $self->client->get($url, $self->headers);
    if ($response->is_success) {
        my $content = $response->decoded_content;
        my $data    = $self->json->decode($content);
        $json       = $self->response_hook($data);
     } else {
        warn "request failed: $url\n" unless !$self->warn;
        if ($response->status =~ /^4/) {
            $json = '';
        } else {
            return;
        }
    }

    if ( $self->cache ) {
        $self->cache->set($url, $json);
    }

    return ref $json ? $json : undef;
}

sub response_hook { $_[1] }

1;
__END__

=head1 NAME

Catmandu::Importer::getJSON - load JSON-encoded data from a server using a GET HTTP request

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Catmandu-Importer-getJSON.png)](https://travis-ci.org/nichtich/Catmandu-Importer-getJSON)
[![Coverage Status](https://coveralls.io/repos/nichtich/Catmandu-Importer-getJSON/badge.png)](https://coveralls.io/r/nichtich/Catmandu-Importer-getJSON)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-Importer-getJSON.png)](http://cpants.cpanauthors.org/dist/Catmandu-Importer-getJSON)

=end markdown

=head1 SYNOPSIS

The following three examples are equivalent:

    Catmandu::Importer::getJSON->new(
        file => \"http://example.org/alice.json\nhttp://example.org/bob.json"
    )->each(sub { my ($record) = @_; ... );

    Catmandu::Importer::getJSON->new(
        url  => "http://example.org",
        file => \"/alice.json\n/bob.json"
    )->each(sub { my ($record) = @_; ... );
    
    Catmandu::Importer::getJSON->new(
        url  => "http://example.org/{name}.json",
        file => \"{\"name\":\"alice\"}\n{\"name\":\"bob\"}"
    )->each(sub { my ($record) = @_; ... );

For more convenience the L<catmandu> command line client can be used:

    echo http://example.org/alice.json | catmandu convert getJSON to YAML
    catmandu convert getJSON --from http://example.org/alice.json to YAML
    catmandu convert getJSON --dry 1 --url http://{domain}/robots.txt < domains

=head1 DESCRIPTION

This L<Catmandu::Importer> performs a HTTP GET request to load JSON-encoded
data from a server. The importer expects a line-separated input. Each line
corresponds to a HTTP request that is mapped to a JSON-record on success. The
following input formats are accepted:

=over

=item plain URL

A line that starts with "C<http://>" or "C<https://>" is used as plain URL.

=item URL path

A line that starts with "C</>" is appended to the configured B<url> parameter.

=item variables

A JSON object with variables to be used with an URL template or as HTTP query
parameters. For instance the input line C<< {"name":"Karl Marx"} >> with URL
C<http://api.lobid.org/person> or the input line 
C<< {"entity":"person","name":"Karl Marx"} >> with URL template
C<http://api.lobid.org/{entity}{?id}{?name}{?q}> are both expanded to
L<http://api.lobid.org/person?name=Karl+Marx>.

=back

If the JSON data returned in a HTTP response is a JSON array, its elements are
imported as multiple items. If a JSON object is returned, it is imported as one
item.

=head1 CONFIGURATION

=over

=item url

An L<URI> or an URI templates (L<URI::Template>) as defined by 
L<RFC 6570|http://tools.ietf.org/html/rfc6570> to load JSON from. If no B<url>
is configured, plain URLs must be provided as input or option C<from> must be
used instead.

=item from

A plain URL to load JSON without reading any input lines.

=item timeout / agent / proxy / headers

Optional HTTP client settings.

=item client

Instance of a L<Furl> HTTP client to perform requests with.

=item dry

Don't do any HTTP requests but return URLs that data would be queried from. 

=item file / fh

Input to read lines from (see L<Catmandu::Importer>). Defaults to STDIN.

=item fix

An optional fix to be applied on every item (see L<Catmandu::Fix>).

=item wait

Number of seconds to wait between requests.

=item cache

Cache JSON response of URLs to not request the same URL twice. HTTP error
codes in the 4xx range (e.g. 404) are also cached but 5xx errors are not.

The value of this option can be any objects that implements method C<get> and
C<set> (e.g. C<CHI>), an existing directory for file caching, a true value to
enable global in-memory-caching, or a false value to disable caching (default).

File caching uses file names based on MD5 of an URL so for instance
C<http://example.org/> is cached as C<4389382917e51695b759543fdfd5f690.json>.

=back

=head1 METHODS

=head2 time

Returns the UNIX timestamp right before the last request. This can be used for
instance to add timestamps or the measure how fast requests were responded.

=head2 construct_url( [ $base_url, ] $vars_url_or_path )

Returns an URL given a hash reference with variables, a plain URL or an URL
path. The optional first argument can be used to override option C<url>.

    $importer->construct_url( %query_vars ) 
    $importer->construct_url( $importer->url, %query_vars ) # equivalent 

=head2 request($url)

Perform a HTTP GET request of a given URL including logging, caching, request
hook etc. Returns a hash/array reference or C<undef>.

=head1 EXTENDING

This importer provides two methods to filter requests and responses,
respectively. See L<Catmandu::Importer::Wikidata> for an example.

=head2 request_hook

Gets a whitespace-trimmed input line and is expected to return an unblessed
hash reference, an URL, or undef. Errors are catched and treated equal to
undef. 

=head2 response_hook

Gets the queried response object and is expected to return an object.

=head1 LOGGING

URLs are emitted before each request on DEBUG log level.

=head1 LIMITATIONS

Future versions of this module may also support asynchronous HTTP fetching
modules such as L<HTTP::Async>, for retrieving multiple URLs at the same time.

=head1 SEE ALSO

L<Catmandu::Fix::get_json> provides this importer as fix function.

=encoding utf8

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voß, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
