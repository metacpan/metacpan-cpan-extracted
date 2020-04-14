use Test2::V0;
use Term::ANSIColor qw(color RESET);
use App::Tailor;

my $str = '';
open my $in,  '<', \$str or die $!;
open my $out, '>', \$str or die $!;

subtest basics => sub{
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
};

subtest 'captures with string replacement' => sub{
  reset_rules;

  modify qr/^(a) (b)/ => '[$1] [$2]';
  modify qr/^(?<c>c) (?<d>d)/ => '<$+{c}> <$+{d}>';

  my $iter = itail $in;

  print $out "a b\n";
  is $iter->(), "[a] [b]\n", 'back-references';

  print $out "c d\n";
  is $iter->(), "<c> <d>\n", 'named captures';
};

subtest 'captures with sub{} replacement' => sub{
  reset_rules;

  modify qr/^(a) (b)/ => sub{ "[$1] [$2]" };
  modify qr/^(?<c>c) (?<d>d)/ => sub{ "<$+{c}> <$+{d}>" };

  my $iter = itail $in;

  print $out "a b\n";
  is $iter->(), "[a] [b]\n", 'back-references';

  print $out "c d\n";
  is $iter->(), "<c> <d>\n", 'named captures';
};

done_testing;
