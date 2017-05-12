package Data::Maker::Field::Person::MiddleName;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.08';

has letters => ( is => 'ro', default => sub { [ 'A'..'P', 'R'..'W', 'Y' ] }, lazy => 1 );

sub generate_value {
  my $this = shift;
  return $this->letters->[ rand @{$this->letters} ];
}

1;
