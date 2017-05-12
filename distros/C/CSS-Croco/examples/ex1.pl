# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CSS-Croco.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 18;
BEGIN { use_ok('CSS::Croco') };
my $parser = CSS::Croco->new;
my $stylesheet = $parser->parse( '
    @charset "windows-1251"; 
    * { color: red; background-color: black; fint-size: 12px !important}
    p { padding: 0 }
' );
my @rules = $stylesheet->rules;
my $decls = $rules[2]->declarations;
