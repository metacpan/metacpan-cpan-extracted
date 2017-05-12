use Test::More;

my $c = 'Data::Seek::Search::Result';
my @a = qw(datasets);
my @m = qw(new data nodes values);
eval "require $c";

ok !$@ or diag $@;
can_ok $c => ('new', @a, @m);
isa_ok $c->new, $c;

my $result = Data::Seek::Search::Result->new;

ok 1 and done_testing;
