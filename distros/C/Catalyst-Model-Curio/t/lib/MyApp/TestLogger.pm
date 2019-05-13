package MyApp::TestLogger;

use Test2::V0;

use strictures 2;
use namespace::clean;

use base 'Catalyst::Log';

sub debug { shift; note @_ }
sub info { shift; note @_ }
sub warn { shift; note @_ }
sub error { shift; note @_ }
sub fatal { shift; note @_ }

1;
