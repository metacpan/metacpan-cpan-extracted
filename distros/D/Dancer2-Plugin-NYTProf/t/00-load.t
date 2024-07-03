#!/usr/bin/env perl
use Test2::V0;
use File::Which;
 
BEGIN {
    # If nytprofhtml isn't found, the module can't do anything so fails to load
    # - so check that first of all
    my $nytprofhtml_path = File::Which::which('nytprofhtml');
    if (!$nytprofhtml_path) {
        plan skip_all => 'nytprofhtml not found in path, cannot continue';
    } else {
        plan tests => 2;
        use ok 'Dancer2';
        use ok 'Dancer2::Plugin::NYTProf';
    }
}
 
diag( "Testing Dancer2::Plugin::NYTProf $Dancer2::Plugin::NYTProf::VERSION, Perl $], $^X" );