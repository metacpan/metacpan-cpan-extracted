
use Test::More;

my @valid_pis;
my @invalid_pis;

BEGIN {

    @valid_pis = (
      '121.51144.13-7',
      '12151144137',
    );
    @invalid_pis = (
      '',
      '1',
      '121.51144.13-0',
    );

}

BEGIN { plan tests => 1 + @valid_pis + @invalid_pis; }

BEGIN { use_ok('Business::BR::PIS') };

for (@valid_pis) {
  ok(test_pis($_), "'$_' is correct");
}

for (@invalid_pis) {
  ok(!test_pis($_), "'$_' is incorrect");
}

