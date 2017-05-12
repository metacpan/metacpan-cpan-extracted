package Business::EDI::CodeList::DeliveryInstructionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4493;}
my $usage       = 'B';

# 4493  Delivery instruction code                               [B]
# Desc: Code specifying a delivery instruction.
# Repr: an..3

my %code_hash = (
'AA' => [ 'Ship on authorization',
    'A delivery requirement indicating the items should not be shipped without specific authorization.' ],
'BK' => [ 'Ship partial - balance back order',
    'Partial shipping is allowed. The rest of the order should be delivered as soon as possible.' ],
'CD' => [ 'Cancel if not delivered by date',
    'An order or the rest of an order should be cancelled if not delivered at specified date.' ],
'DA' => [ 'Do not deliver after',
    'A requirement that an order should not be delivered after a specified date/time.' ],
'DB' => [ 'Do not deliver before',
    'A requirement that an order should not be delivered before a specified date/time.' ],
'DD' => [ 'Deliver on date',
    'An order should be delivered exactly on specified date.' ],
'IS' => [ 'Substitute item',
    'A substitute item may be delivered, if the ordered item is not available.' ],
'P1' => [ 'No schedule established',
    'No specified date/time for delivery.' ],
'P2' => [ 'Ship as soon as possible',
    'The order should be delivered as soon as possible.' ],
'SC' => [ 'Ship complete order',
    'The order should be delivered only complete, not partial.' ],
'SF' => [ 'Ship partial, if no freight rate increase',
    'Partial shipping of an order is allowed, if the total freight rate do not increase.' ],
'SP' => [ 'Ship partial - balance cancel',
    'Partial shipping is allowed. The rest of the order should be cancelled.' ],
);
sub get_codes { return \%code_hash; }

1;
