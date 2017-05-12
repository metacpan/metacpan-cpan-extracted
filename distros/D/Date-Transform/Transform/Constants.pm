package Date::Transform::Constants;
our $VERSION = '0.09';

use 5.006;
use strict;

require Exporter;
our @ISA = qw(Exporter);

# 2. General Method
my @CONSTANTS = qw(
  MYSQL_DATETIME
  MYSQL_DATE
  MYSQL_TIME
  MYSQL_TIMESTAMP
);

### DECLARE DATATYPE CONSTANTS ###
use constant MYSQL_DATETIME  => '%Y-%m-%d %T';
use constant MYSQL_DATE      => '%Y-%m-%d';
use constant MYSQL_TIME      => '%T';
use constant MYSQL_TIMESTAMP => '%Y-%m-%d %T';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = (@CONSTANTS);

1;

__END__




