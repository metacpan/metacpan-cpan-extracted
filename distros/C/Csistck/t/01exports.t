use Test::More;
use Csistck;

# Test exported methods

my @tests = qw/
    file
    template
    script
    pkg
    noop
/;

plan tests => scalar(@tests);

for my $test (@tests) {
   ok(exists(&{"main::${test}"}), "method ${test} is exported"); 
}

