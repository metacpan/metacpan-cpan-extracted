use Test::More tests => 7;
use Data::Dumper;

BEGIN { use_ok('Class::Multimethods::Pure') }

#ok(my $method = Class::Multimethods::Pure::Method->new(name => 'foo'), 'New method');

my $sref = \my $sderef;
my @vars = (
    #[ 'A', '$', "Hello" ],
    #[ 'B', '#', "345" ],
    [ 'C', 'ARRAY', [1,2,3] ],
    [ 'D', 'HASH', { a => 'b' } ],
    [ 'E', 'SCALAR', $sref ],
    [ 'F', 'GLOB', \*STDOUT ],
    [ 'G', 'REF', \$sref ],
    [ 'H', 'CODE', sub { 42 } ],
);

for (@vars) {
    my $cur = $_;
    multi foo => $cur->[1] 
              => sub { $cur->[0] };
}

for (@vars) {
    is(foo($_->[2]), $_->[0], "multi ($_->[1])");
}

# vim: ft=perl :
