use Test2::V0;
use Term::ANSIColor qw(color RESET);
use App::Tailor;

my $str = '';
open my $in,  '<', \$str or die $!;
open my $out, '>', \$str or die $!;

reset_rules;

my $iter = itail $in;

print $out "$_\n" for qw(foo bar baz bat);
is $iter->(), "$_\n", "out: $_" for qw(foo bar baz bat);
is $iter->(), U, 'out: undef';

done_testing;
