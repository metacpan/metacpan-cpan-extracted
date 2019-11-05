package Database::Async::StatementHandle;

use strict;
use warnings;

our $VERSION = '0.010'; # VERSION

sub new { my $class = shift; bless { @_ }, $class }

1;

