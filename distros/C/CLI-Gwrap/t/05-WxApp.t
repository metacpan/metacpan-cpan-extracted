#===============================================================================
#
#  DESCRIPTION:  test for CLI::Gwrapper::Wx::App
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/09/2013 12:26:16 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More tests => 4;                      # last test to print
use IO::File;
use File::Spec;
use Readonly;

use_ok 'CLI::Gwrapper::Wx::App';

# VERSION

my $app = new_ok('CLI::Gwrapper::Wx::App');

is($app->title, 'Gwrap Frame', 'title matches');
$app->title('App');
is($app->title, 'App', 'title changed');

