package Catmandu::Importer::Pure;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use URI::Escape;
use MIME::Base64;
use Furl;
use Moo;
use Carp;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Data::Validate::URI qw(is_web_uri);
use Scalar::Util qw(blessed);

our $VERSION = '0.05';

with 'Catmandu::Importer';

has base     => ( is => 'ro' );
has endpoint => ( is => 'ro' );
has path     => ( is => 'ro' );
has apiKey   => ( is => 'ro' );
has user     => ( is => 'ro' );
has password => ( is => 'ro' );
has post_xml => ( is => 'ro' );

has handler =>
  ( is => 'ro', default => sub { 'simple' }, coerce => \&_coerce_handler );
has options =>
  ( is => 'ro', default => sub { +{} }, coerce => \&_coerce_options );
has fullResponse => ( is => 'ro', default => sub { 0 } );
has trim_text    => ( is => 'ro', default => sub { 0 } );
has filter       => ( is => 'ro' );
has userAgent    => ( is => 'ro', default => sub { 'Mozilla/5.0' } );
has timeout      => ( is => 'ro', default => sub { 50 } );
has furl         => (
    is  => 'ro',
    isa => sub {
        Catmandu::BadVal->throw("Invalid furl, should be compatible with Furl")
          unless is_maybe_able( $_[0], 'get' );
    },
    lazy    => 1,
    builder => \&_build_furl
);
has max_retries => ( is => 'ro', default => sub { 0 } );
has _currentRecordSet => ( is => 'ro' );
has _n                => ( is => 'ro', default => sub { 0 } );
has _start            => ( is => 'ro', default => sub { 0 } );
has _rs_size          => ( is => 'ro', default => sub { 0 } );
has _total_size       => ( is => 'ro', default => sub { 0 } );
has _next_url         => ( is => 'ro');


sub BUILD {
    my $self = shift;

    Catmandu::BadVal->throw("Base URL, endpoint and apiKey are required")
      unless $self->base && $self->endpoint && $self->apiKey;

    Catmandu::BadVal->throw( "Password is needed for user " . $self->user )
      if $self->user && !$self->password;

    Catmandu::BadVal->throw("Invalid filter, filter should be a CODE ref")
      if $self->filter && !is_code_ref( $self->filter );

    Catmandu::BadVal->throw(
        "Invalid value for timeout, should be non negative integer")
      if !is_natural( $self->timeout );

    Catmandu::BadVal->throw(
        "Invalid value for max_retries, should be non negative integer")
      if !is_natural( $self->max_retries );

    my $url = $self->base;

    # remove first any username password:
    $url =~ s|^(\w+://)[^\@/]+[:][^\@/]*\@|$1|;
    if ( !is_web_uri($url) ) {
        Catmandu::BadVal->throw( "Invalid base URL: " . $self->base );
    }

    my $options = $self->options;

    if ( !$self->fullResponse && $self->post_xml ) {
        if ( $options->{offset} ||  $options->{page} ||
            (defined $options->{size} && $options->{size}==0) )  {
            $self->{fullResponse} = 1;
        }
    }
    if ( !$self->fullResponse && $options->{offset} ) {
        $self->{_start} = $options->{offset};
    }
}

sub _build_furl {
    my ( $user, $password, $apiKey ) = ( $_[0]->user, $_[0]->password, $_[0]->apiKey );
    my @headers;

    push @headers,
      ( 'Authorization' => ( 'Basic ' . encode_base64("$user:$password") ) )
      if $user;
    push @headers, ( 'api-key' => $apiKey )
      if $apiKey;    
    Furl->new(
        agent   => $_[0]->userAgent,
        timeout => $_[0]->timeout,
        headers => \@headers
    );
}

sub _coerce_handler {
    my ($handler) = @_;

    return $handler if is_invocant($handler) or is_code_ref($handler);

    if ( is_string($handler) && !is_number($handler) ) {
        my $class =
            $handler =~ /^\+(.+)/
          ? $1
          : "Catmandu::Importer::Pure::Parser::$handler";

        my $handler;
        eval { $handler = Catmandu::Util::require_package($class)->new; };
        if ($@) {
            Catmandu::Error->throw("Unable to load handler $class: $@");
        } else {
            return $handler;
        }
    }

    $handler ||= '';
    Catmandu::BadVal->throw("Invalid handler: '$handler'");
}

sub _coerce_options {
    my ($options) = @_;

    return $options if !%$options;
    
    return { # arrays to comman separated values
        map { $_ => (ref $options->{$_} eq 'ARRAY' ? join (',', @{$options->{$_}}) : $options->{$_})}
            keys %$options
    };
}

sub _request {
    my ( $self, $url, $rcontent ) = @_;

    $self->log->debug("requesting $url\n");

    my $res;
    my $tries = $self->max_retries;
    try {
        do {
            
            $res = $rcontent
                 ? $self->furl->post($url, ['Content-Type' =>  'application/xml'], $$rcontent) 
                 :  $self->furl->get($url);
          } while ( $res->status >= 500 && $tries-- && sleep(10) )
          ;    # Retry on server error;
        die( $res->status_line )
          unless $res->is_success
          || ( $res->content && $res->content =~ m|<\?xml| );
        return $res->content;
    }
    catch {
        Catmandu::Error->throw(
            "Requested '$url'\nStatus code: " . $res->status_line );
    };
}

sub _url {
    my ( $self, $options ) = @_;

    my $url = $self->base . '/' . $self->endpoint
        . ($self->path ? '/' . $self->path : '');

    if ($options && %$options) {
        $url .= '?' . join '&',
          map { "$_=" . uri_escape( $options->{$_}, "^A-Za-z0-9\-\._~," ) }
          sort keys %{$options};
    }
    return $url;
}

sub _nextRecordSet {
    my ($self) = @_;

    my %options = %{ $self->options };
    
    if (!$self->fullResponse && $self->post_xml) {
         $options{offset} = $self->_start;
    } 
 
    my $url = $self->_next_url || $self->_url( \%options );

    my $xml = $self->_request(  $url, ($self->post_xml ? \$self->post_xml : undef) );

    if ( $self->filter ) {
        &{ $self->filter }( \$xml );
    }

    my $hash = $self->_hashify($xml);

    if ( exists $hash->{'error'} ) {
        Catmandu::Error->throw(
                "Requested '$url'\nPure REST Error ($hash->{error}{code}): "
              . $hash->{error}{title}
              . (
                $hash->{'error'}{'description'}
                ? "\nDescription:\n" . $hash->{error}{description}
                : ''
              )
        );
    }

    if ( $self->fullResponse ) {
        $self->{_rs_size}   = 1;
        $self->{_total_size} = 1;
        return $hash->{results}; #check
    }
    
    $self->{_next_url} = $hash->{next_url}; #only GET requests

    # get total number of results
    $self->{_total_size} = $hash->{count};

    my $set = $hash->{results};

    $self->{_rs_size} = scalar(@$set);

    return $set;
}

# Internal: gets the next record from our current resultset.
# Returns a hash representation of the next record.
sub _nextRecord {
    my ($self) = @_;

    # fetch recordset if we don't have one yet.
    $self->{_currentRecordSet} ||= $self->_nextRecordSet || return;

    return
      if (!$self->_next_url ) && $self->_total_size
      && ( $self->_start + $self->_n ) >=
      $self->_total_size;    # no more results

    # check for a exhausted recordset.
    if ( $self->_n >= $self->_rs_size ) {
        $self->{_start} += $self->_rs_size;
        $self->{_n}  = 0;
        $self->{_currentRecordSet} = $self->_nextRecordSet;
    }
    
    my $record_dom = $self->_currentRecordSet->[ $self->{_n}++ ];
    
    return $self->_handle_record($record_dom);

}

# Internal: Converts XML to a perl hash.
# $in - the raw XML input.
# Returns a hash representation of the given XML.
sub _hashify {
    my ( $self, $in ) = @_;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->load_xml( string => $in );
    my $root   = $doc->documentElement;
    my $xc     = XML::LibXML::XPathContext->new($root);

    if ( $self->trim_text ) {
        my $all_text_nodes = $doc->findnodes('//text()');
        $all_text_nodes->foreach(
            sub {
                my $node = shift;
                my $t    = $node->data;
                my $subs_done =
                  ( $t =~ s/\A\s+// || 0 ) + ( $t =~ s/\s+\Z// || 0 );
                $node->setData($t) if $subs_done;
            }
        );
    }

    my $out;

    if ( $xc->exists('/error') ) {
         my $code = $xc->findvalue('/error/code');
         my $title = $xc->findvalue('/error/title');
         my $description = $xc->findvalue('/error/description');

        $out->{error} = { code => $code, title => $title, description => $description };
        return $out;
    }

    my $next_url = $xc->findvalue('/result/navigationLink[@ref="next"]/@href|/result/navigationLinks/navigationLink[@ref="next"]/@href');
    $next_url =~ s/&amp;/&/g if $next_url;
    $out->{next_url} = $next_url if $next_url;

    $out->{count} = $xc->findvalue("/result/count");

    if ( $self->fullResponse ) {
        $out->{results} = [$root];
        return $out;
    }

    my @result_nodes;

    if ( $xc->exists('/result/items') ) {
        @result_nodes = $xc->findnodes('/result/items/*');
    } elsif ($self->endpoint eq 'changes') {
        @result_nodes = $xc->findnodes('/result/contentChange');
    } else {
        @result_nodes = $xc->findnodes('/result/*[@uuid]');
    };

    $out->{results} = \@result_nodes;

    return $out;
}

sub _handle_record {
    my ( $self, $dom ) = @_;
    return unless $dom;

    return blessed( $self->handler )
      ? $self->handler->parse($dom)
      : $self->handler->($dom);
}


# Public Methods. --------------------------------------------------------------

sub url {
    my ($self) = @_;
    return $self->_url( $self->options )
      ;
}

sub generator {
    my ($self) = @_;

    return sub {
        $self->_nextRecord;
    };
}

1;

=head1 NAME

  Catmandu::Importer::Pure - Package that imports Pure data.

=head1 SYNOPSIS

  # From the command line
  $ catmandu convert Pure \
        --base https://host/ws/api/... \
        --endpoint research-outputs \
        --apiKey "..."

  # In Perl
  use Catmandu;

  my %attrs = (
    base     => 'https://host/path',
    endpoint => 'research-outputs',
    apiKey   => '...',
    options  => { 'fields' => 'title,type,authors.*' } 
  );

  my $importer = Catmandu->importer('Pure', %attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

  # get number of validated and approved publications
  my $count = Catmandu->importer(
    'Pure',
    base         => 'https://host/path',
    endpoint     => 'research-outputs',
    apiKey       => '...',
    fullResponse => 1,
    post_xml => '<?xml version="1.0" encoding="utf-8"?>'
      . '<researchOutputsQuery>'
      . '<size>0</size>'
      . '<workflowSteps>'
      . '  <workflowStep>approved</workflowStep>'
      . '  <workflowStep>validated</workflowStep>'
      . '</workflowSteps>'
      . '</researchOutputsQuery>'
  )->first->{count};

=head1 DESCRIPTION

Catmandu::Importer::Pure is a Catmandu package that seamlessly imports data from Elsevier's Pure system using its REST service.
In order to use the Pure Web Service you need an API key. List of all available endpoints and further documentation can currently
be found under /ws on a webserver that is running Pure. Note that this version of the importer is tested with Pure API version
5.18 and might not work with later versions.

=head1 CONFIGURATION

=over

=item base

Base URL for the REST service is required, for example 'http://purehost.com/ws/api/518'

=item endpoint

Valid endpoint is required, like 'research-outputs'

=item apiKey

Valid API key is required for access

=item path

Path after the endpoint 

=item user

User name if basic authentication is used

=item password

Password if basic authentication is used

=item options

Options passed as parameters to the REST service, for example:
{
    'size' => 20,
    'fields' => 'title,type,authors.*'
}


=item post_xml

xml containing a query that will be submitted with a POST request

=item fullResponse

Optional flag. If true delivers the complete results as a single item (record), corresponding to the
XML response received. Only one request to the REST service is made in this case. Default is false.

If the flag is false then the items are set to child
elements of the element 'result' or in case the 'result' element does not exist they are set to child elements
of the root element for each response.

=item handler( sub {} | $object | 'NAME' | '+NAME' )

Handler to transform each record from XML DOM (L<XML::LibXML::Element>) into
Perl hash.

Handlers can be provided as function reference, an instance of a Perl
package that implements 'parse', or by a package NAME. Package names should
be prepended by C<+> or prefixed with C<Catmandu::Importer::Pure::Parser>. E.g
C<foobar> will create a C<Catmandu::Importer::Pure::Parser::foobar> instance.

By default the handler L<Catmandu::Importer::Pure::Parser::simple> is used.
It provides a simple XML parsing, using XML::LibXML::Simple,

Other possible values are  L<Catmandu::Importer::Pure::Parser::struct> for XML::Struct
based structure that preserves order and L<Catmandu::Importer::Pure::Parser::raw> that
returns the XML as it is.

=item userAgent

HTTP user agent string, set to C<Mozilla/5.0> by default.

=item furl

Instance of L<Furl> or compatible class to fetch URLs with.

=item timeout

Timeout for HTTP requests in seonds. Defaults to 50.

=item trim_text

Optional flag. If true then all text nodes in the REST response are trimmed so that any leading and trailing whitespace is removed before parsing.
This is useful if you don't want to risk getting leading and trailing whitespace in your data, since Pure doesn't currently clean leading/trailing white space from
user input. Note that there is a small performance penalty when using this option. Default is false.

=item filter( sub {} )

Optional reference to function that processes the XML response before it is parsed. The argument to the function is a reference to the XML text,
which is then used to modify it. This option is normally not needed but can helpful if there is a problem parsing the response due to a bug
in the REST service.

=back

=head1 METHODS

In addition to methods inherited from Catmandu::Iterable, this module provides the following public methods:

=over

=item B<url >

Return the current Pure REST request URL (useful for debugging).

=back

=head1 SEE ALSO

L<Catmandu>

L<Catmandu::Importer>

L<Catmandu::Iterable>

L<Furl>

=head1 AUTHOR

Snorri Briem E<lt>briem@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Lund University Library

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
