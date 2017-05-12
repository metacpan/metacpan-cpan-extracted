#!perl

use warnings;
use strict;

use Test::More;

use App::podweaver;

plan tests => 1;

my @files = App::podweaver->find_files_to_weave();

#
#  1:  Do we find the weaveable files in this distro?
is_deeply( [ sort( @files ) ],
    [ 
        'lib/App/podweaver.pm',
        'script/podweaver',
    ],
    'weaveable files found' );
