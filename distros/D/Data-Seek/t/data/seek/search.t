use Test::More;

my $c = 'Data::Seek::Search';
my @a = qw(criteria data);
my @m = qw(new perform result);
eval "require $c";

ok !$@ or diag $@;
can_ok $c => ('new', @a, @m);
isa_ok $c->new, $c;

my $search = Data::Seek::Search->new(
    criteria => { '*' => 0, '@.*' => 1, '@.*.id' => 2, },
    data     => { foo => 'bar' },
);

ok ! eval { $search->perform };
ok $@;

ok 1 and done_testing;
