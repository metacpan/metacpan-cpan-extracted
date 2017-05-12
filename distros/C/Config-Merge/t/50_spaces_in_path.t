use strict;
use warnings;

use File::Spec;
use Test::More 'tests' => 3;

my $path;
BEGIN {
    my $vol;
    ($vol,$path) = File::Spec->splitpath(
                   File::Spec->rel2abs($0)
            );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        'data','with spaces'
    );
    $path =  File::Spec->catpath($vol,$path,'');
}

BEGIN { use_ok('Config::Merge', 'My' => $path); }
BEGIN { use_ok('My'); }

is(         C('foo.bar'),
            'baz',
            'With spaces' );
