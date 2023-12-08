package Amazon::S3::Constants;

use strict;
use warnings;

use parent qw(Exporter);

use Readonly;

our $VERSION = '0.65'; ## no critic (RequireInterpolation)

# defaults
Readonly our $AMAZON_HEADER_PREFIX            => 'x-amz-';
Readonly our $DEFAULT_BUFFER_SIZE             => 4 * 1024;
Readonly our $DEFAULT_HOST                    => 's3.amazonaws.com';
Readonly our $DEFAULT_TIMEOUT                 => 30;
Readonly our $KEEP_ALIVE_CACHESIZE            => 0;
Readonly our $METADATA_PREFIX                 => 'x-amz-meta-';
Readonly our $MAX_BUCKET_NAME_LENGTH          => 64;
Readonly our $MIN_BUCKET_NAME_LENGTH          => 3;
Readonly our $MIN_MULTIPART_UPLOAD_CHUNK_SIZE => 5 * 1024 * 1024;
Readonly our $DEFAULT_LOG_LEVEL               => 'error';
Readonly our $MAX_DELETE_KEYS                 => 1000;
Readonly our $MAX_RETRIES                     => 5;
Readonly our $DEFAULT_REGION                  => 'us-east-1';

Readonly our $XMLDECL  => '<?xml version="1.0" encoding="UTF-8"?>';
Readonly our $S3_XMLNS => 'http://s3.amazonaws.com/doc/2006-03-01/';

Readonly::Hash our %LOG_LEVELS => (
  trace => 5,
  debug => 4,
  info  => 3,
  warn  => 2,
  error => 1,
  fatal => 0,
);

Readonly::Hash our %LIST_OBJECT_MARKERS => (
  '2' => [qw(ContinuationToken NextContinuationToken continuation-token)],
  '1' => [qw(Marker NextMarker marker)],
);

# booleans
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

# chars
Readonly our $COMMA         => q{,};
Readonly our $COLON         => q{:};
Readonly our $DOT           => q{.};
Readonly our $DOUBLE_COLON  => q{::};
Readonly our $EMPTY         => q{};
Readonly our $SLASH         => q{/};
Readonly our $QUESTION_MARK => q{?};
Readonly our $AMPERSAND     => q{&};
Readonly our $EQUAL_SIGN    => q{=};

# HTTP codes

Readonly our $HTTP_BAD_REQUEST       => 400;
Readonly our $HTTP_UNAUTHORIZED      => 401;
Readonly our $HTTP_PAYMENT_RQUIRED   => 402;
Readonly our $HTTP_FORBIDDEN         => 403;
Readonly our $HTTP_NOT_FOUND         => 404;
Readonly our $HTTP_CONFLICT          => 409;
Readonly our $HTTP_MOVED_PERMANENTLY => 301;
Readonly our $HTTP_FOUND             => 302;
Readonly our $HTTP_SEE_OTHER         => 303;
Readonly our $HTTP_NOT_MODIFIED      => 304;

our %EXPORT_TAGS = (
  chars => [
    qw(
      $AMPERSAND
      $COLON
      $DOUBLE_COLON
      $DOT
      $COMMA
      $EMPTY
      $EQUAL_SIGN
      $QUESTION_MARK
      $SLASH
    )
  ],
  booleans => [
    qw(
      $TRUE
      $FALSE
    )
  ],
  defaults => [
    qw(
      $AMAZON_HEADER_PREFIX
      $METADATA_PREFIX
      $KEEP_ALIVE_CACHESIZE
      $DEFAULT_TIMEOUT
      $DEFAULT_BUFFER_SIZE
      $DEFAULT_LOG_LEVEL
      $DEFAULT_HOST
      $DEFAULT_REGION
      $MAX_BUCKET_NAME_LENGTH
      $MAX_DELETE_KEYS
      $MIN_BUCKET_NAME_LENGTH
      $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
      $MAX_RETRIES
    )
  ],
  misc => [
    qw(
      $S3_XMLNS
      $XMLDECL
      %LIST_OBJECT_MARKERS
      %LOG_LEVELS
      $NOT_FOUND
    )
  ],
  http => [
    qw(
      $HTTP_BAD_REQUEST
      $HTTP_CONFLICT
      $HTTP_UNAUTHORIZED
      $HTTP_PAYMENT_RQUIRED
      $HTTP_FORBIDDEN
      $HTTP_NOT_FOUND
      $HTTP_MOVED_PERMANENTLY
      $HTTP_FOUND
      $HTTP_SEE_OTHER
      $HTTP_NOT_MODIFIED
    )

  ],
);

our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;

$EXPORT_TAGS{all} = [@EXPORT_OK];

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

Amazon::S3::Constants - constants and defaults for Amazon::S3

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
