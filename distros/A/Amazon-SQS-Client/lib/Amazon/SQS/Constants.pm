package Amazon::SQS::Constants;

# constants for Amazon::SQS classes

use strict;
use warnings;

use parent qw(Exporter);

use Readonly;

# booleans
Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

# chars
Readonly::Scalar our $EMPTY     => q{};
Readonly::Scalar our $EQUALS    => q{=};
Readonly::Scalar our $AMPERSAND => q{&};
Readonly::Scalar our $SLASH     => q{/};

# http
Readonly::Scalar our $HTTP_OK                    => '200';
Readonly::Scalar our $HTTP_INTERNAL_SERVER_ERROR => '500';
Readonly::Scalar our $HTTP_GATEWAY_TIMEOUT       => '503';

our %EXPORT_TAGS = (
  chars => [
    qw(
      $EMPTY
      $EQUALS
      $AMPERSAND
      $SLASH
    )
  ],
  booleans => [
    qw(
      $TRUE
      $FALSE
    )
  ],
  http => [
    qw(
      $HTTP_OK
      $HTTP_INTERNAL_SERVER_ERROR
      $HTTP_GATEWAY_TIMEOUT
    )
  ]
);

our @EXPORT_OK;

foreach my $k ( keys %EXPORT_TAGS ) {
  push @EXPORT_OK, @{ $EXPORT_TAGS{$k} };
}

$EXPORT_TAGS{'all'} = [@EXPORT_OK];

1;

__END__
