package Business::EDI::CodeList::DeliveryPlanCommitmentLevelCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4017;}
my $usage       = 'B';

# 4017  Delivery plan commitment level code                     [B]
# Desc: Code specifying the level of commitment to a delivery
# plan.
# Repr: an..3

my %code_hash = (
'1' => [ 'Firm',
    'Indicates that the scheduling information is a firm commitment.' ],
'2' => [ 'Commitment for manufacturing and material',
    'Authorizes the supplier to start the manufacturing of goods.' ],
'3' => [ 'Commitment for material',
    'Authorizes the manufacturer to order material required for manufacturing specified goods.' ],
'4' => [ 'Planning/forecast',
    'An estimate of future requirements based on trends and actual information.' ],
'5' => [ 'Short delivered on previous delivery',
    'Part of a consignment which was not delivered when the original delivery was made.' ],
'6' => [ 'Capacity available',
    'Capacity is available to meet the requested scheduling demands.' ],
'7' => [ 'Promotion',
    'All related schedule information refer to a promotion.' ],
'8' => [ 'Special demand',
    'All related schedule information refers to a special demand.' ],
'9' => [ 'User defined',
    'The user can interpret the meaning of the values from information exchanged previously.' ],
'10' => [ 'Immediate',
    'Indicates that the scheduling information is for immediate execution.' ],
'11' => [ 'Pilot/Pre-volume',
    'Initial products required in advance of the normal production process.' ],
'12' => [ 'Planning',
    'An estimate of future requirements.' ],
'13' => [ 'Potential order increase',
    'The possibility and magnitude of a schedule fluctuation.' ],
'14' => [ 'Average plant usage',
    'The usual amount that a manufacturing facility will use over a specified duration.' ],
'15' => [ 'First time reported firm',
    'Initial confirmation of a material requirement.' ],
'16' => [ 'Maximum',
    'The highest attainable amount.' ],
'17' => [ 'Tooling capacity',
    'The maximum amount that the process was designed to accommodate.' ],
'18' => [ 'Normal tooling capacity',
    'The anticipated amount that the process was designed to accommodate over a specific period of time.' ],
'19' => [ 'Prototype',
    'The preliminary version of a product or service.' ],
'20' => [ 'Strike protection',
    'Product level that is set aside as protection in the event of a work stoppage.' ],
'21' => [ 'Required tooling capacity',
    'The contracted amount that the process was designed to accommodate over a specific period of time.' ],
'22' => [ 'Deliver to schedule',
    'Deliver to schedule separately supplied.' ],
'23' => [ 'Await manual pull',
    'Await non-EDI instruction before shipping.' ],
'24' => [ 'Reference to commercial agreement between partners',
    "The buyer's commitment is the one defined in the commercial agreement." ],
'26' => [ 'Proposed',
    'Indicates that the scheduling information is a proposal.' ],
);
sub get_codes { return \%code_hash; }

1;
