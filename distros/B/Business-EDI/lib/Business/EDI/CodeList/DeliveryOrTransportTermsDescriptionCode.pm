package Business::EDI::CodeList::DeliveryOrTransportTermsDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4053;}
my $usage       = 'B';

# 4053  Delivery or transport terms description code            [B]
# Desc: Code specifying the delivery or transport terms.
# Repr: an..3

my %code_hash = (
'1' => [ 'Delivery arranged by the supplier',
    'Indicates that the supplier will arrange delivery of the goods.' ],
'2' => [ 'Delivery arranged by logistic service provider',
    'Code indicating that the logistic service provider has arranged the delivery of goods.' ],
);
sub get_codes { return \%code_hash; }

1;
