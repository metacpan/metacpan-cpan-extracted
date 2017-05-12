use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 7}

# load your module...
use Data::Reconciliation::Rule;

use Data::Table;
my $t1 = new Data::Table([], ['f1', 'f2', 'f3'], 0);
my $t2 = new Data::Table([], ['F1', 'F2', 'F3'], 0);


## Test 1
my $r = new Data::Reconciliation::Rule($t1, $t2);
ok(eval {$r->isa('Data::Reconciliation::Rule')});

## Test 2 & 3 &4
$r->identification(['f1', 'f3'], sub { join '', @_ },
		   ['F1'], sub { (my $v = shift) =~ tr/a-z/A-Z/; $v });

ok($r->signature(0, ['', undef, 'abcdef']), 'abcdef');
ok($r->signature(0, ['abc', undef, 'def']), 'abcdef');
ok($r->signature(1, ['abcdef']), 'ABCDEF');

## Test 5
$r->add_comparison(['f1'], undef,
		   ['F2'], undef,
		   undef, undef);

my @msgs = $r->compare(['Pouett', 'toto'],
		       [undef, 'Pouett']);
ok(@msgs == 0);


## Test 6
@msgs = $r->compare(['Ponett'],
		    [undef, 'Pouett']);
ok(@msgs != 0);


## Test 7
$t1 = new Data::Table([], ['ccy1', 'ccy2', 'amt'], 0);
$t2 = new Data::Table([], ['ccypair', 'Amount'], 0);
$r = new Data::Reconciliation::Rule($t1, $t2);
$r->add_comparison(['ccy1', 'ccy2'], sub{sort @_},
		   ['ccypair'], sub{sort (shift =~ /^(\w\w\w)(\w\w\w)$/)},
		   undef);

$r->add_comparison(['amt'], undef,
		   ['Amount'], undef,
		   undef);

@msgs = $r->compare(['AEF', 'GBP', 1234.45],
		    ['GBPAEF', 1234.45]);
ok(@msgs == 0);

