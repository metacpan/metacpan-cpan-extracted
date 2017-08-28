use strict;
use warnings;
# 
use Test::More   tests => 1;
ok(1);
# 
# use Csound::ScoreStatement::i;
# 
# my $i1 = Csound::ScoreStatement::i->new(1, 5.5, 0.5, 2.22, 3.33);
# my $i2 = Csound::ScoreStatement::i->new(2, 0  , 1              );
# 
# isa_ok($i1, 'Csound::ScoreStatement::i');
# isa_ok($i2, 'Csound::ScoreStatement::i');
# 
# is($i1->{instr_nr}, 1,   'Instrument number == 1');
# is($i2->{instr_nr}, 2,   'Instrument number == 2');
# 
# is($i1->{t_start }, 5.5, 'Start == 5.5');
# is($i2->{t_start }, 0  , 'Start == 0');
# 
# is($i1->{t_len   }, 0.5, 'Len == 0.5');
# is($i2->{t_len   }, 1  , 'Len == 1');
# 
# isa_ok($i1->{params}, 'ARRAY');
# isa_ok($i2->{params}, 'ARRAY');
# 
# is(@{$i1->{params}}  , 2   , 'Size of params == 2');
# is(  $i1->{params}[0], 2.22);
# is(  $i1->{params}[1], 3.33);
# 
# is(@{$i2->{params}}  , 0   , 'Size of params == 0');
