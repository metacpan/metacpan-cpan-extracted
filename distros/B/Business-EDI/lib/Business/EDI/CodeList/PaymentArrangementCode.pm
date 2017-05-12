package Business::EDI::CodeList::PaymentArrangementCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4237;}
my $usage       = 'B';

# 4237  Payment arrangement code                                [B]
# Desc: Code specifying the arrangements for a payment.
# Repr: an..3

my %code_hash = (
'A' => [ 'Payable elsewhere',
    'Responsibility for payment of transport charges unknown at time of departure.' ],
'B' => [ 'Third party to pay',
    'A third party to pay the freight bill is known at the time of shipment.' ],
'C' => [ 'Collect',
    'Charges are (to be) collected from the consignee at the destination.' ],
'P' => [ 'Prepaid',
    'Charges are (to be) prepaid before the transport actually leaves.' ],
);
sub get_codes { return \%code_hash; }

1;
