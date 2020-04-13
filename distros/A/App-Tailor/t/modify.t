use Test2::V0;
use Term::ANSIColor qw(color RESET);
use App::Tailor;

my $str = '';
open my $in,  '<', \$str or die $!;
open my $out, '>', \$str or die $!;

reset_rules;

modify qr/foo/    => sub{ uc $_ };
modify qr/bar/    => 'barbar';
modify qr/barbar/ => 'barbarbar';

my $iter = itail $in;

print $out "foo\n";
print $out "bar\n";
print $out "baz\n";

is $iter->(), "FOO\n", 'modify foo';
is $iter->(), "barbarbar\n", 'multiple rules match bar';
is $iter->(), "baz\n", 'do not modify baz';
is $iter->(), U, 'closed: undef';

done_testing;
