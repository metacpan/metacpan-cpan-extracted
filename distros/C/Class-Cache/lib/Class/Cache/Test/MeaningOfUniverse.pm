package Class::Cache::Test::MeaningOfUniverse;

use Carp qw(cluck);

sub new {
  my $class = shift;

  bless {data => \@_}, __PACKAGE__;
}

sub divulge { 42 }

1;
