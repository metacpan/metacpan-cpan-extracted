use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;

use lib dirname( abs_path( $0 ) ) . '/lib';

use TestApp;
my $app = TestApp->apply_default_middlewares(TestApp->psgi_app);

$app;
