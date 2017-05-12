package FooExport;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/this that/;

sub this { 'this' }
sub that { 'that' }

1;
