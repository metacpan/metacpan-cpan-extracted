use strict;
use warnings;

use Test::More   tests => 4;

use Csound::ScoreStatement::f;

my $f1 = Csound::ScoreStatement::f->new();
my $f2 = Csound::ScoreStatement::f->new();

isa_ok($f1, 'Csound::ScoreStatement::f');
isa_ok($f2, 'Csound::ScoreStatement::f');

is($f1->{table_nr}, 1, 'Table number is 1');
is($f2->{table_nr}, 2, 'Table number is 2');
