use Test2::V0;
use Term::ANSIColor qw(color RESET);
use App::Tailor;

my $str = '';
open my $in,  '<', \$str or die $!;
open my $out, '>', \$str or die $!;

reset_rules;

ignore qr/foo/;
ignore qr/bar/;

my $iter = itail $in;

print $out "foo should be ignored\n";
print $out "baz should be printed\n";
print $out "bar should be ignored\n";
print $out "bat should be printed\n";

is $iter->(), "baz should be printed\n", 'foo ignored';
is $iter->(), "bat should be printed\n", 'bar ignored';
is $iter->(), U, 'closed: undef';

done_testing;
