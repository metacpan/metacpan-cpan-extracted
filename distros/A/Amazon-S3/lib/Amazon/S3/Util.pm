package Amazon::S3::Util;

use strict;
use warnings;

use Amazon::S3::Constants qw(:all);
use Data::Dumper;
use Digest::MD5       qw(md5 md5_hex);
use Digest::MD5::File qw(file_md5 file_md5_hex);
use English           qw(-no_match_vars);
use MIME::Base64;
use Scalar::Util qw(reftype);
use URI::Escape  qw(uri_escape_utf8);
use XML::Simple;

use parent qw(Exporter);

our @EXPORT_OK = qw(
  create_query_string
  create_grant_header
  create_xml_request
  create_api_uri
  set_md5_header
  urlencode
  get_parameters
);

our %EXPORT_TAGS;

$EXPORT_TAGS{all} = [@EXPORT_OK];

########################################################################
sub urlencode {
########################################################################
  my (@args) = @_;

  my $unencoded = ref $args[0] ? $args[1] : $args[0];

  ## no critic (RequireInterpolation)
  return uri_escape_utf8( $unencoded, '^A-Za-z0-9\-\._~\x2f' );
}

# hashref or list of key/value pairs
########################################################################
sub create_query_string {
########################################################################
  my (@args) = @_;

  my $parameters = get_parameters(@args);

  return $EMPTY
    if !$parameters || !keys %{$parameters};

  return join $AMPERSAND,
    map { sprintf '%s=%s', $_, urlencode( $parameters->{$_} ) }
    keys %{$parameters};
}

########################################################################
sub create_api_uri {
########################################################################
  my (@args) = @_;

  my $parameters = get_parameters(@args);

  my $path = delete $parameters->{path};
  $path //= $EMPTY;

  if ( $path !~ /\/$/xsm ) {
    $path = "$path/";
  }

  my $api = delete $parameters->{api};
  $api //= $EMPTY;

  my $query_string = create_query_string($parameters);

  return sprintf '%s?%s%s', $path, $api, $query_string;
}

########################################################################
sub create_xml_request {
########################################################################
  my ( $request, $content_key ) = @_;

  if ( !$content_key ) {
    ($content_key) = keys %{$request};
  }

  $request->{$content_key}->{xmlns} = $S3_XMLNS;

  return XMLout(
    $request,
    NSExpand   => $TRUE,
    KeyAttr    => [],
    KeepRoot   => $TRUE,
    ContentKey => $content_key,
    NoAttr     => $TRUE,
    XMLDecl    => $XMLDECL,
  );
}
########################################################################
sub set_md5_header {
########################################################################
  my (@args) = @_;

  my $parameters = get_parameters(@args);

  my ( $content, $headers ) = @{$parameters}{qw(data headers)};

  my $md5 = eval {
    if ( ref($content) && reftype($content) eq 'SCALAR' ) {

      $headers->{'Content-Length'} = -s ${$content};
      my $md5_hex = file_md5_hex( ${$content} );

      return encode_base64( pack 'H*', $md5_hex );
    }
    else {
      $headers->{'Content-Length'} = length $content;

      my $md5 = md5($content);

      my $md5_hex = unpack 'H*', $md5;

      return encode_base64($md5);
    }
  };

  die "$EVAL_ERROR"
    if $EVAL_ERROR;

  chomp $md5;

  $headers->{'Content-MD5'} = $md5;

  return;
}

# grant:
#   full-control
#   read
#   read-acp
#   write
#   write-acp
#
# type:
#   id
#   uri
#   emailAddress

########################################################################
sub create_grant_header {
########################################################################
  my ( $grant, $type, @args ) = @_;

  my $values = ref $args[0] ? $args[0] : \@args;

  return {
    "x-amz-grant-$grant" => join ', ',
    map { sprintf qq{$type="%s"}, $_ } @{$values}
  };
}

#########################################################################
sub get_parameters { return ref $_[0] ? $_[0] : {@_}; }
########################################################################

1;
