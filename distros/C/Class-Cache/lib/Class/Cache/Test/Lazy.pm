package Class::Cache::Test::Lazy;

use Carp qw(cluck);

sub new {
  cluck "HEYHEYHEY! I was created To-Day!";

  bless {}, __PACKAGE__;
}

1;
