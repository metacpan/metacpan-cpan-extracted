package Data::Maker::Field::Person::SSN;
use base 'Data::Maker::Field::Format';

our $VERSION = '0.14';

sub format { '\d\d\d-\d\d-\d\d\d\d' };

1;

