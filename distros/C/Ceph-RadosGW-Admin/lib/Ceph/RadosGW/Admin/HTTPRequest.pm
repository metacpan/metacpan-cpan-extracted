package Ceph::RadosGW::Admin::HTTPRequest;
$Ceph::RadosGW::Admin::HTTPRequest::VERSION = '0.4';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use HTTP::Date;
use MIME::Base64 qw( encode_base64 );
use Moose::Util::TypeConstraints;
use URI::Escape qw( uri_escape_utf8 );
use URI::QueryParam;
use URI;
use Digest::HMAC_SHA1;
use Digest::MD5 ();

# this is almost a direct copy of
# https://metacpan.org/pod/Net::Amazon::S3::HTTPRequest

# ABSTRACT: Create a signed HTTP::Request

my $METADATA_PREFIX      = 'x-amz-meta-';
my $AMAZON_HEADER_PREFIX = 'x-amz-';

enum 'HTTPMethod' => [ qw(DELETE GET HEAD PUT POST) ];

has 'url'    => ( is => 'ro',  isa => 'Str', required => 1 );
has 'method' => ( is => 'ro', isa => 'HTTPMethod',      required => 1 );
has 'path'   => ( is => 'ro', isa => 'Str',             required => 1 );
has 'access_key' => ( is => 'ro', isa => 'Str',             required => 1 );
has 'secret_key' => ( is => 'ro', isa => 'Str',             required => 1 );

has 'headers' =>
    ( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );
has 'content' =>
    ( is => 'ro', isa => 'Str|CodeRef', required => 0, default => '' );
has 'metadata' =>
    ( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );

__PACKAGE__->meta->make_immutable;

# make the HTTP::Request object
sub http_request {
    my $self     = shift;
    my $method   = $self->method;
    my $path     = $self->path;
    my $headers  = $self->headers;
    my $content  = $self->content;
    my $metadata = $self->metadata;
    my $uri      = $self->url . $path;
    
    my $http_headers = $self->_merge_meta( $headers, $metadata );

    $self->_add_auth_header( $http_headers, $method, $path )
        unless exists $headers->{Authorization};
    

    
    my $request
        = HTTP::Request->new( $method, $uri, $http_headers, $content );

     #my $req_as = $request->as_string;
     #$req_as =~ s/[^\n\r\x20-\x7f]/?/g;
     #$req_as = substr( $req_as, 0, 1024 ) . "\n\n";
     #warn $req_as;

    return $request;
}

sub query_string_authentication_uri {
    my ( $self, $expires ) = @_;
    my $method  = $self->method;
    my $path    = $self->path;
    my $headers = $self->headers;

    my $aws_access_key_id     = $self->access_key;
    my $aws_secret_access_key = $self->secret_key;
    my $canonical_string
        = $self->_canonical_string( $method, $path, $headers, $expires );
    my $encoded_canonical
        = $self->_encode( $aws_secret_access_key, $canonical_string );

    my $uri = $self->url . $path;
    $uri = URI->new($uri);

    $uri->query_param( AWSAccessKeyId => $aws_access_key_id );
    $uri->query_param( Expires        => $expires );
    $uri->query_param( Signature      => $encoded_canonical );

    return $uri;
}


sub _add_auth_header {
    my ( $self, $headers, $method, $path ) = @_;
    my $aws_access_key_id     = $self->access_key;
    my $aws_secret_access_key = $self->secret_key;

    if ( not $headers->header('Date') ) {
        $headers->header( Date => time2str(time) );
    }
    
    if ( not $headers->header('Content-Type') ) {
        $headers->header( 'Content-Type' => 'text/plain' );
    }
   
    if ( not $headers->header('Content-MD5') ) {
	$headers->header( 'Content-MD5' => Digest::MD5::md5_base64($self->content));
    }

    my $canonical_string
        = $self->_canonical_string( $method, $path, $headers );
    my $encoded_canonical
        = $self->_encode( $aws_secret_access_key, $canonical_string );
    $headers->header(
        Authorization => "AWS $aws_access_key_id:$encoded_canonical" );
}

# generate a canonical string for the given parameters.  expires is optional and is
# only used by query string authentication.
sub _canonical_string {
    my ( $self, $method, $path, $headers, $expires ) = @_;
    my %interesting_headers = ();
    while ( my ( $key, $value ) = each %$headers ) {
        my $lk = lc $key;
        if (   $lk eq 'content-md5'
            or $lk eq 'content-type'
            or $lk eq 'date'
            or $lk =~ /^$AMAZON_HEADER_PREFIX/ )
        {
            $interesting_headers{$lk} = $self->_trim($value);
        }
    }

    

    # just in case someone used this.  it's not necessary in this lib.
    $interesting_headers{'date'} = ''
        if $interesting_headers{'x-amz-date'};

    # if you're using expires for query string auth, then it trumps date
    # (and x-amz-date)
    $interesting_headers{'date'} = $expires if $expires;

    my $buf = "$method\n";
    foreach my $key ( sort keys %interesting_headers ) {
        if ( $key =~ /^$AMAZON_HEADER_PREFIX/ ) {
            $buf .= "$key:$interesting_headers{$key}\n";
        } else {
            $buf .= "$interesting_headers{$key}\n";
        }
    }

    # don't include anything after the first ? in the resource...
    $path =~ /^([^?]*)/;
    $path = "/$1";
    $path =~ s:/+:/:g;
    $buf .= $path;
    
    
    # ...unless there any parameters we're interested in...
    if ( $path =~ /[&?](acl|torrent|location|uploads|delete)($|=|&)/ ) {
        $buf .= "?$1";
    } elsif ( my %query_params = URI->new($path)->query_form ){
        #see if the remaining parsed query string provides us with any query string or upload id
        if($query_params{partNumber} && $query_params{uploadId}){
            #re-evaluate query string, the order of the params is important for request signing, so we can't depend on URI to do the right thing
            $buf .= sprintf("?partNumber=%s&uploadId=%s", $query_params{partNumber}, $query_params{uploadId});
        }
        elsif($query_params{uploadId}){
            $buf .= sprintf("?uploadId=%s",$query_params{uploadId});
        }
    }

    #warn "Buf:\n$buf\n";
    
    return $buf;
}

# finds the hmac-sha1 hash of the canonical string and the aws secret access key and then
# base64 encodes the result (optionally urlencoding after that).
sub _encode {
    my ( $self, $aws_secret_access_key, $str, $urlencode ) = @_;
    my $hmac = Digest::HMAC_SHA1->new($aws_secret_access_key);
    $hmac->add($str);
    my $b64 = encode_base64( $hmac->digest, '' );
    if ($urlencode) {
        return $self->_urlencode($b64);
    } else {
        return $b64;
    }
}

# EU buckets must be accessed via their DNS name. This routine figures out if
# a given bucket name can be safely used as a DNS name.
sub _is_dns_bucket {
    my $bucketname = $_[0];

    if ( length $bucketname > 63 ) {
        return 0;
    }
    if ( length $bucketname < 3 ) {
        return;
    }
    return 0 unless $bucketname =~ m{^[a-z0-9][a-z0-9.-]+$};
    my @components = split /\./, $bucketname;
    for my $c (@components) {
        return 0 if $c =~ m{^-};
        return 0 if $c =~ m{-$};
        return 0 if $c eq '';
    }
    return 1;
}

# generates an HTTP::Headers objects given one hash that represents http
# headers to set and another hash that represents an object's metadata.
sub _merge_meta {
    my ( $self, $headers, $metadata ) = @_;
    $headers  ||= {};
    $metadata ||= {};

    my $http_header = HTTP::Headers->new;
    while ( my ( $k, $v ) = each %$headers ) {
        $http_header->header( $k => $v );
    }
    while ( my ( $k, $v ) = each %$metadata ) {
        $http_header->header( "$METADATA_PREFIX$k" => $v );
    }

    return $http_header;
}

sub _trim {
    my ( $self, $value ) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

sub _urlencode {
    my ( $self, $unencoded ) = @_;
    return uri_escape_utf8( $unencoded, '^A-Za-z0-9_-' );
}

1;

__END__

=pod

=head1 NAME

Ceph::RadosGW::Admin::HTTPRequest::HTTPRequest - Create a signed HTTP::Request

=head1 VERSION

version 0.60

=head1 SYNOPSIS

  my $http_request = Ceph::RadosGW::Admin::HTTPRequest::HTTPRequest->new(
    method  => 'PUT',
    path    => $self->bucket . '/',
    headers => $headers,
    content => $content,
  )->http_request;

=head1 DESCRIPTION

This module creates an HTTP::Request object that is signed
appropriately for Amazon S3.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method creates, signs and returns a HTTP::Request object.

=head2 query_string_authentication_uri

This method creates, signs and returns a query string authentication
URI.

=head1 AUTHOR

Pedro Figueiredo <me@pedrofigueiredo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut