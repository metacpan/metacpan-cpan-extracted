use strict;
use warnings;

use Test::More tests => 5;

use_ok('LWP::UserAgent');
use_ok('Getopt::Long::Descriptive');
use_ok('JSON');
use_ok( 'List::MoreUtils', qw(uniq) );
use_ok('App::Github::Email');

done_testing;
