package Amazon::S3::Constants;

use strict;
use warnings;

use parent qw{Exporter};

use Readonly;

our $VERSION = '0.54';

# defaults
Readonly our $AMAZON_HEADER_PREFIX   => 'x-amz-';
Readonly our $DEFAULT_BUFFER_SIZE    => 4 * 1024;
Readonly our $DEFAULT_HOST           => 's3.amazonaws.com';
Readonly our $DEFAULT_TIMEOUT        => 30;
Readonly our $KEEP_ALIVE_CACHESIZE   => 0;
Readonly our $METADATA_PREFIX        => 'x-amz-meta-';
Readonly our $MAX_BUCKET_NAME_LENGTH => 64;
Readonly our $MIN_BUCKET_NAME_LENGTH => 3;
Readonly our $DEFAULT_LOG_LEVEL      => 'error';
Readonly::Hash our %LOG_LEVELS => (
  trace => 5,
  debug => 4,
  info  => 3,
  warn  => 2,
  error => 1,
  fatal => 0,
);

# booleans
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

# chars
Readonly our $COMMA         => q{,};
Readonly our $COLON         => q{:};
Readonly our $DOUBLE_COLON  => q{::};
Readonly our $EMPTY         => q{};
Readonly our $SLASH         => q{/};
Readonly our $QUESTION_MARK => q{?};
Readonly our $AMPERSAND     => q{&};
Readonly our $EQUAL_SIGN    => q{=};

our %EXPORT_TAGS = (
  chars => [
    qw{
      $AMPERSAND
      $COLON
      $DOUBLE_COLON
      $COMMA
      $EMPTY
      $EQUAL_SIGN
      $QUESTION_MARK
      $SLASH
    }
  ],
  booleans => [
    qw{
      $TRUE
      $FALSE
    }
  ],
  defaults => [
    qw{
      $AMAZON_HEADER_PREFIX
      $METADATA_PREFIX
      $KEEP_ALIVE_CACHESIZE
      $DEFAULT_TIMEOUT
      $DEFAULT_BUFFER_SIZE
      $DEFAULT_LOG_LEVEL
      %LOG_LEVELS
      $DEFAULT_HOST
      $MAX_BUCKET_NAME_LENGTH
      $MIN_BUCKET_NAME_LENGTH
    }
  ],
);

our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;

$EXPORT_TAGS{all} = [@EXPORT_OK];

1;

__END__

=pod

=head1 NAME

Amazon::S3::Constants - constants and defaults for Amazon::S3

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
