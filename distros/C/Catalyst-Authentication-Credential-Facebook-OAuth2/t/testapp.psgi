use strict;
use warnings;

use TestApp;

TestApp->setup_engine('PSGI');

my $app = sub { TestApp->run(@_) };
