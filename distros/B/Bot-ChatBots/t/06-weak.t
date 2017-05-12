use strict;
use Test::More tests => 27;
use Test::Exception;
use Scalar::Util qw< isweak >;
use Bot::ChatBots::Weak;

my $weak;

lives_ok { $weak = Bot::ChatBots::Weak->new } 'simple constructor lives';
isa_ok $weak, 'Bot::ChatBots::Weak';

my (@foo, %bar);

lives_ok { $weak = Bot::ChatBots::Weak->new(foo => \@foo, bar => \%bar) }
'constructor lives (two params)';

ok exists($weak->{foo}), 'foo exists';
ok isweak($weak->{foo}), 'foo is weak';
ok exists($weak->{bar}), 'bar exists';
ok isweak($weak->{bar}), 'bar is weak';

ok !exists($weak->{what}), 'what does not exist';
lives_ok { $weak->set(what => \@foo) } 'set lives';
ok exists($weak->{what}), 'what exists after set';
ok isweak($weak->{what}), 'what is weak';

push @foo, 'whatever';
my $got;
lives_ok { $got = $weak->get('what') } 'get lives';
is_deeply $got, \@foo, 'got what we expect';
ok isweak($weak->{what}), 'what is (still) weak';

my @got;
lives_ok { @got = $weak->get_multiple(qw< what foo bar >) }
  'get_multiple lives';
ok isweak($weak->{foo}), 'foo is (still) weak';
ok isweak($weak->{bar}), 'bar is (still) weak';
ok isweak($weak->{bar}), 'weak is (still) weak';
is_deeply \@got, [['whatever'], ['whatever'], {}], 'got what expected';

can_ok $weak, 'TO_JSON';
is $weak->TO_JSON, undef, 'TO_JSON always undef';

my $other;
lives_ok { $other = $weak->clone } 'clone lives';
isa_ok $other, 'Bot::ChatBots::Weak';
is_deeply [sort keys %$other], [sort keys %$weak], 'same keys';
ok isweak($weak->{foo}), 'foo is weak in clone';
ok isweak($weak->{bar}), 'bar is weak in clone';
ok isweak($weak->{bar}), 'weak is weak in clone';

done_testing();
