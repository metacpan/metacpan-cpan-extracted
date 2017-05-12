#!perl -T

use strict;

use Carp;
use File::Spec;
use Test::More tests => 15;

%ENV = (); # required for running under -T

my $result;
my $rootdir = findup('Makefile.PL');
my $testapp = "perl -I$rootdir/lib " . File::Spec->catfile($rootdir, 't', 'test-app');
my $fail_str = 'FAILED';

# Test that insufficient mandatory args result in failure
isnt(system( "$testapp     >/dev/null" ), 0, 'Running with no params fails');
isnt(system( "$testapp a   >/dev/null" ), 0, 'Running with 1 param fails');
isnt(system( "$testapp a b >/dev/null" ), 0, 'Running with 2 params fails');

# Testing params
ok(qx( $testapp a b c )   eq 'a|b|c|-|-|-|-|-|', 'Running with 3 params succeeds');
ok(qx( $testapp a b c d ) eq 'a|b,c|d|-|-|-|-|-|', 'Running with 4 params succeeds');

# Testing options
ok(qx( $testapp a b c -v )                      eq 'a|b|c|1|-|-|-|-|', 'Using -v sets verbose to 1');
ok(qx( $testapp a b c -v -v )                   eq 'a|b|c|2|-|-|-|-|', 'Using -v -v sets verbose to 2');
ok(qx( $testapp a b c --verbose )               eq 'a|b|c|1|-|-|-|-|', 'Using --verbose sets verbose to 1');
ok(qx( $testapp a b c --verbose --verbose )     eq 'a|b|c|2|-|-|-|-|', 'Using --verbose --verbose sets verbose to 2');

ok(qx( $testapp a b c -n alf )                  eq 'a|b|c|-|alf|-|-|-|', 'Using -n alf sets name to alf');
ok(qx( $testapp a b c -n alf -n bob )           eq 'a|b|c|-|alf,bob|-|-|-|', 'Using -n alf -n bob sets name to alf,bob');
ok(qx( $testapp a b c --names alf )             eq 'a|b|c|-|alf|-|-|-|', 'Using --names alf sets name to alf');
ok(qx( $testapp a b c --names alf --names bob ) eq 'a|b|c|-|alf,bob|-|-|-|', 'Using --names alf --names bob sets name to (alf, bob)');

ok(qx( $testapp a b c --foo-bar 3 )             eq 'a|b|c|-|-|3|3|-|', 'Option with hyphen works');

ok(qx( $testapp a b c --ages=f=2 )              eq 'a|b|c|-|-|-|-|f|', 'Option with hyphen works');


sub findup {
    my $file_to_find = shift or croak "Usage: findup(\$FILENAME)";
    my $dir = File::Spec->curdir();
    
    my $found = 0;
    while (!$found) {
        return $dir if -e File::Spec->catfile($dir, $file_to_find);

        my $tmpdir = File::Spec->updir($dir);
        if ($dir eq File::Spec->rootdir() || $dir eq $tmpdir) {
            # no further to go
            croak "$file_to_find not found in path";
        }
        $dir = $tmpdir;
    }
}