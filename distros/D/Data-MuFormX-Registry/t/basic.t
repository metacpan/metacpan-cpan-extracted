use Test::Most;
use FindBin;
use lib "$FindBin::Bin/lib";

use Data::MuFormX::Registry;
use FormRegistry;

ok my $registry = MyRegistry->new();
ok $registry->forms_by_ns->{Transaction};
ok $registry->forms_by_ns->{NewNodes};

ok my $transaction = $registry->create('Transaction');
ok ! $transaction->check(data=>+{aaa=>1});
ok ! $transaction->process(params=>+{signature=>1});
ok $transaction->has_errors;

ok my $nn = $registry->create('NewNodes', example2=>2);
ok $nn->check(data=>+{nodes=>1});
ok $nn->process(params=>+{nodes=>1});
ok !$nn->has_errors;
is $nn->example1, 1;
is $nn->example2, 2;

{
  # When you don't want or need a subclass
  ok my $registry = Data::MuFormX::Registry->new(
    form_namespace=>'Form',
    config => +{
      NewNodes=> +{
        example1=>1,
        example2=>1,
      },
    },
  );

  ok $registry->forms_by_ns->{Transaction};
  ok $registry->forms_by_ns->{NewNodes};

  ok my $transaction = $registry->create('Transaction');
  ok ! $transaction->check(data=>+{aaa=>1});
  ok ! $transaction->process(params=>+{signature=>1});
  ok $transaction->has_errors;

  ok my $nn = $registry->create('NewNodes', example2=>2);
  ok $nn->check(data=>+{nodes=>1});
  ok $nn->process(params=>+{nodes=>1});
  ok !$nn->has_errors;
  is $nn->example1, 1;
  is $nn->example2, 2;
}


done_testing;

