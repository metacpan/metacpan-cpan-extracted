package Dallycot::TextResolver::Request;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Manages request cycle for text resources

use strict;
use warnings;

use utf8;
use Moose;

use experimental qw(switch);

use Promises qw(deferred);
use URI::WithBase;
use Dallycot::Value::String;

has ua => (
  is       => 'ro',
  required => 1
);

has url => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

has redirects => (
  is      => 'ro',
  isa     => 'Int',
  default => 10
);

has canonical_url => (
  is  => 'ro',
  isa => 'Str'
);

my %acceptable_types = (
  'application/xml'       => 1.0,
  'application/xhtml+xml' => 1.0,
  'text/html'             => 0.9,
  'text/plain'            => 0.8
);

my $accept_headers = join( ",", map { _stringify_acceptable_type($_) } keys %acceptable_types );

sub _stringify_acceptable_type {
  my ($type) = @_;

  if ( exists $acceptable_types{$type} && $acceptable_types{$type} < 1 ) {
    return $type . ";q=" . $acceptable_types{$type};
  }
  else {
    return $type;
  }
}

sub run {
  my ($self) = @_;

  my $deferred = deferred;
  my $url      = $self->url;
  my $request  = $self->ua->build_tx( GET => $url );
  $request->req->headers->accept($accept_headers);
  my $base_uri = URI::WithBase->new( $self->url )->base;

  $self->ua->start(
    $request,
    sub {
      my ( $ua, $response ) = @_;
      if ( $response->success ) {
        my $res = $response->res;
        if ( $res->code == 200 ) {

          # regular response - we can parse this and work with it
          # we'll load a handler based on the content type
          my $content_type_header = $res->headers->content_type;
          my @bits                = split( /;/, $content_type_header );
          my $content_type        = shift @bits;
          my $object_type;
          given ($content_type) {
            when ('application/xml') {
              $object_type = 'Dallycot::Value::XML';
            }
            when ('application/xhtml+xml') {
              $object_type = 'Dallycot::Value::HTML';
            }
            when ('text/html') {
              $object_type = 'Dallycot::Value::HTML';
            }
            when ('text/plain') {
              $object_type = 'Dallycot::Value::String';
            }
            default {
              $deferred->reject("Unrecognized content type ($content_type)");
              return;
            }
          }
          $deferred->resolve( Dallycot::Value::String->new( $res->content->build_body ) );
        }
        elsif ( $res->code == 303 ) {    # See Other
                                         # look for an 'Alternatives' header
          my $new_uri;
          if ( 0 >= $self->redirects ) {
            $deferred->reject("Unable to fetch $url: too many redirects");
            return;
          }

          if ( $res->headers->header('alternatives') ) {
            my $alts    = $res->headers->header('alternatives');
            my @options = $alts =~ m{
            (:?{"(.+?)"\s+([0-9.]+)\s+{type (.+?)}},?\s*)*
          }xm;
            my %types;
            while ( my ( $path, $val, $type ) = splice( @options, 0, 3 ) ) {
              $types{$type} = [ $val, $path ];
            }
            my @sorted_types = grep { $acceptable_types{$_} }
              sort { $types{$a}->[0] <=> $types{$b}->[0] } keys %types;

            # we'll take the first one we get
            if (@sorted_types) {
              $new_uri = $types{ $sorted_types[0] }->[1];
            }
          }
          elsif ( $res->headers->location ) {
            $new_uri = $res->headers->location;
          }
          if ($new_uri) {
            $self->new(
              ua            => $ua,
              url           => $new_uri,
              redirects     => $self->redirects - 1,
              canonical_url => $self->canonical_url
            )->run->done( sub { $deferred->resolve(@_); }, sub { $deferred->reject(@_); } );
          }
          else {
            # we give up... nothing to see here
            $deferred->reject("Unable to fetch $url: redirect with no suitable location");
          }
        }
        else {
          $deferred->reject( "Unable to fetch $url: " . $res->status_line );
        }
      }
      else {
        my $err = $response->error;
        $deferred->reject("Unable to fetch $url: $err->{message}");
      }
    },
    sub {
      $deferred->reject(@_);
    }
  );

  return $deferred->promise;
}

__PACKAGE__ -> meta -> make_immutable;

1;
