package TestDBIO::Extension::Plain;
# ABSTRACT: The plain extension class of the mock driver: no rules

use strict;
use warnings;

use base 'DBIO::Extension';

sub extension_interface { 1 }
sub driver { 'TestDBIO::Extension::Deploy' }

1;
