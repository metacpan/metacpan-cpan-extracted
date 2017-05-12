package Business::EDI::CodeList::RequestedInformationDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4511;}
my $usage       = 'B';

# 4511  Requested information description code                  [B]
# Desc: Code specifying the response information requested.
# Repr: an..3

my %code_hash = (
'1' => [ 'Article price composition',
    'A breakdown of the item price is requested.' ],
'2' => [ 'Article price',
    'The item price is requested.' ],
'3' => [ 'Constituent material',
    'Information about constituent material, such as copper and plastics, is requested.' ],
'4' => [ 'Carrier',
    'Suggested carrier is requested.' ],
'5' => [ 'Conditions of sale',
    'General conditions of sale are requested.' ],
'6' => [ 'Delivery party',
    'Suggested grouping centre is requested.' ],
'7' => [ 'Economics dates',
    'Material, labour and overheads economic dates are requested.' ],
'8' => [ 'Lead time',
    'Item lead time is requested.' ],
'9' => [ 'Packaging price composition',
    'A breakdown of the package price is requested.' ],
'10' => [ 'Packaging details',
    'Details about packaging is requested.' ],
'11' => [ 'Production location',
    'Information about which production site is going to be used is requested.' ],
'12' => [ 'Packaging price',
    'The packaging price is requested.' ],
'13' => [ 'Payment terms',
    'Payment terms are requested.' ],
'14' => [ 'Shipment from location',
    'Information from where the items are shipped is requested.' ],
'15' => [ 'Tooling price composition',
    'A breakdown of the tooling price is requested.' ],
'16' => [ 'Tooling items details',
    'Details about the tooling items are requested.' ],
'17' => [ 'Tooling total details',
    'Details about the total tooling is requested.' ],
'18' => [ 'Validity dates',
    'The quotations validity dates are requested.' ],
'19' => [ 'Working pattern',
    'Information about working week, day and shift is requested.' ],
'20' => [ 'Assigned log numbers',
    'Assigned log numbers are requested.' ],
'21' => [ 'Cycle start date',
    'The start date for the cycle is requested.' ],
'22' => [ 'Technical assessment status',
    'Technical assessment status information is requested.' ],
'23' => [ 'Structure tag assignment',
    'The assigned structure tag is requested.' ],
'24' => [ 'All available status information',
    'All available status information is requested.' ],
'25' => [ 'Delivery status of all back order articles',
    'Information on the delivery status of all articles on back order.' ],
'26' => [ 'General status of all back order articles',
    'Information on the general status of all articles on back order.' ],
'27' => [ 'Delivery status of all outstanding orders',
    'Information on the delivery status of all outstanding orders.' ],
'28' => [ 'General status of all outstanding orders',
    'Information on the general status of all outstanding orders.' ],
'29' => [ 'Delivery status of the specified order(s) or order line(s)',
    'Delivery status of each order(s) or order line(s) specified.' ],
'30' => [ 'General status of the specified order(s) or order line(s)',
    'General status of each order(s) or order line(s) specified.' ],
);
sub get_codes { return \%code_hash; }

1;
