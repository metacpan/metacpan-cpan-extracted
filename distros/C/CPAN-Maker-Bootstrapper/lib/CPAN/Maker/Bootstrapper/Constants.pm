package CPAN::Maker::Bootstrapper::Constants;

use strict;
use warnings;

use parent qw(Exporter);

our @EXPORT_OK = qw(
  $COLORS
  $DEFAULT_CODE_REVIEW_MODEL
  $DEFAULT_POD_REVIEW_MODEL
  $DISPOSITIONS
  $MAX_DIFF_FILES
);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

use Readonly;

Readonly::Scalar our $MAX_DIFF_FILES => 50;
Readonly::Scalar our $DISPOSITIONS => {
  ACCEPT             => 1,
  CONFIRMED          => 1,
  DEFER              => 1,
  REJECT             => 1,
  WRONG              => 1,
  'WRONG-RECONSIDER' => 1,
};

Readonly::Scalar our $COLORS => {
  high               => 'red',
  medium             => 'yellow',
  low                => 'white',
  ACCEPT             => 'green',
  REJECT             => 'magenta',
  CONFIRM            => 'green',
  DEFER              => 'yellow',
  WRONG              => 'cyan',
  'WRONG-RECONSIDER' => 'cyan',
};

Readonly::Scalar our $DEFAULT_POD_REVIEW_MODEL  => 'claude-haiku-4-5-20251001';
Readonly::Scalar our $DEFAULT_CODE_REVIEW_MODEL => 'claude-sonnet-4-6';

1;
