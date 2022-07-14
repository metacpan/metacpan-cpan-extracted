package App::Greple::frame::RPN;

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw( rpn_calc );

my @operator = sort { length $b <=> length $a } split /[,\s]+/, <<'END';
+,ADD  ++,INCR  -,SUB  --,DECR  *,MUL  /,DIV  %,MOD  POW  SQRT
SIN  COS  TAN
LOG  EXP
ABS  INT
&,AND  |,OR  !,NOT  XOR  ~
<,LT  <=,LE  =,==,EQ  >,GT  >=,GE  !=,NE
IF
DUP  EXCH  POP
MIN  MAX
TIME
RAND  LRAND
END

my $operator_re = join '|', map "\Q$_", @operator;
my $term_re     = qr/(?:\d*\.)?\d+|$operator_re/i;
my $rpn_re      = qr/(?: $term_re ,* ){2,}/xi;

sub rpn_calc {
    use Math::RPN ();
    my @terms = map { /$term_re/g } @_;
    my @ans = do { local $_; Math::RPN::rpn @terms };
    if (@ans == 1 && defined $ans[0] && $ans[0] !~ /[^\.\d]/) {
	$ans[0];
    } else {
	return undef;
    }
}

1;
