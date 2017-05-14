use strict;
use warnings;

use Test::More tests => 14;

# 1
use_ok('Bio::Polloc::RuleI');
use_ok('Bio::Polloc::RuleIO');

# 3
my $r = Bio::Polloc::RuleIO->new(-file=>'t/vntrs.bme')->next_rule;
is($r->type, 'tandemrepeat');

# 4
isa_ok($r->context, 'ARRAY');
is($r->context->[0], 0);
is($r->context->[1], 0);
is($r->context->[2], 0);

# 8
is($r->executable, 1);
is($r->name, 'VNTR repeat');

is($r->id, 'VNTR:1');

my $str = "-pm=>80 -minperiod=>5 -minscore=>50 -pi=>20 ".
	"-minsim=>80 -maxscore=>0 -exp=>6 -maxperiod=>9 ".
	"-maxsim=>100 -match=>2 -maxsize=>1000 -minsize=>30 ".
	"-indels=>5 -mismatch=>3 ";
is($r->stringify, "Tandemrepeat 'VNTR repeat': ".$str);
is($r->stringify_value, $str);

# 13
isa_ok($r->ruleset, 'Bio::Polloc::RuleIO');

# 14
is($r->source, 'tandemrepeat');



