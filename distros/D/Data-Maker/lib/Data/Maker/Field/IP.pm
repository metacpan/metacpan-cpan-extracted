package Data::Maker::Field::IP;
use Moose;
with 'Data::Maker::Field';
use POSIX qw( ceil );

our $VERSION = '0.20';

sub generate_value {
  my ($this, $maker) = @_;
  return join('.', map { ceil(rand(255)) } (1..4));
}
