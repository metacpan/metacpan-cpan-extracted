package Class::Cache::Test::Adder;

use Carp qw(cluck);

sub new {
  my $class = shift;

  bless {data => \@_}, __PACKAGE__;
}

sub add {
  my $self = shift;
  my $sum;
  $sum += $_ for @{$self->{data}};
  $sum;
}

1;
