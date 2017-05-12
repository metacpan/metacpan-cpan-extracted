#! perl

use strict;
use warnings;

use Test::More tests => 5;

use Data::Transpose;
use Data::Dumper;

my ($tp, $output);

# unknown: default
$tp = Data::Transpose->new;
$output = $tp->transpose({foo => 'bar'});
ok(exists $output->{foo} && $output->{foo} eq 'bar',
   'test for unknown behaviour (default)')
    || diag "Transpose output: " . Dumper($output);

# unknown: pass
$tp = Data::Transpose->new(unknown => 'pass');
$output = $tp->transpose({foo => 'bar'});
ok(exists $output->{foo} && $output->{foo} eq 'bar',
   'test for unknown behaviour (pass)')
    || diag "Transpose output: " . Dumper($output);

# unknown: skip
$tp = Data::Transpose->new(unknown => 'skip');
$output = $tp->transpose({foo => 'bar'});
ok(! exists $output->{foo},
   'test for unknown behaviour (skip)')
    || diag "Transpose output: " . Dumper($output);

# unknown: fail
$tp = Data::Transpose->new(unknown => 'fail');
eval {
    $output = $tp->transpose({foo => 'bar'});
};
ok($@, 
   'test for unknown behaviour (fail)')
    || diag "Transpose output: " . Dumper($output);

eval { $tp = Data::Transpose->new(unknown => 'dummy'); };
ok ($@, "Crash on for wrong constructor: $@");
