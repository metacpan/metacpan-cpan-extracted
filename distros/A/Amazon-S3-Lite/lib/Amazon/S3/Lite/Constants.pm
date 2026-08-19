package Amazon::S3::Lite::Constants;

use strict;
use warnings;

use parent qw(Exporter);

use Readonly;
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

our %EXPORT_TAGS = ( booleans => [qw($TRUE $FALSE)], );

our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;

1;
