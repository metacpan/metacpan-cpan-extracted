package Win32::PEPM::Test;

use 5.006;
use strict;
use warnings FATAL => 'all';

#supress blib/lib/Win32/PEPM/Test.pm (32): Non-ASCII character
#seen before =encoding in '=&JŒP1‹=±   C:\Documents'. Assuming ISO8859-1
=encoding latin1

=head1 NAME

Win32::PEPM::Test - A test module for Acme-Win32-PEPM.

=cut

our $VERSION = '0.01';

use Win32::PEPM;
Win32::PEPM::load(__FILE__, $VERSION);

1;
