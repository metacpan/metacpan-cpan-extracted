use Test2::V0;
use Term::ANSIColor qw(color RESET);
use App::Tailor;

my $str = '';
open my $in,  '<', \$str or die $!;
open my $out, '>', \$str or die $!;

reset_rules;

colorize 'foo'      => qw(red);
colorize 'bar'      => qw(black on_white);
colorize 'baz'      => qw(red);
colorize 'az'       => qw(blue);
colorize qr/a(?=b)/ => qw(red);

my $iter = itail $in;

print $out "foo\n";
print $out "bar\n";
print $out "baz\n";
print $out "bat\n";
print $out "ab ba\n";

is $iter->(), color('red').'foo'.RESET."\n", 'single color';
is $iter->(), color('black', 'on_white').'bar'.RESET."\n", 'multiple colors';
is $iter->(), color('red').'b'.color('blue').'az'.RESET.RESET."\n", 'multiple matching rules';
is $iter->(), "bat\n", 'unmatched';
is $iter->(), color('red').'a'.RESET."b ba\n", 'match with zero-length component';
is $iter->(), U, 'closed: undef';

done_testing;
