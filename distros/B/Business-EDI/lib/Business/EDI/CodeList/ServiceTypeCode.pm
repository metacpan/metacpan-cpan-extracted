package Business::EDI::CodeList::ServiceTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5267;}
my $usage       = 'I';

# 5267  Service type code                                       [I]
# Desc: Code specifying the type of service.
# Repr: an..3

my %code_hash = (
'1' => [ 'Flight segments booked',
    'Payment is for all flight segments booked.' ],
'2' => [ 'Car segments booked',
    'Payment is for all car segments booked.' ],
'3' => [ 'Hotel segments booked',
    'Payment is for all hotel segments booked.' ],
);
sub get_codes { return \%code_hash; }

1;
