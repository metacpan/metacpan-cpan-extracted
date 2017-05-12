package Business::EDI::CodeList::SectorAreaIdentificationCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7293;}
my $usage       = 'B';

# 7293  Sector area identification code qualifier               [B]
# Desc: Code qualifying identification of a subject area.
# Repr: an..3

my %code_hash = (
'1' => [ 'Construction industry',
    'The specified conditions apply within the construction industry.' ],
'2' => [ 'Governmental export conditions',
    'The specified conditions apply within the government export sector.' ],
'3' => [ 'Chemical industry',
    'The specified conditions apply within the chemical industry.' ],
'4' => [ 'Electronic industry',
    'The specified conditions apply within the electronics industry.' ],
'5' => [ 'Automotive industry',
    'The specified conditions apply within the automotive industry.' ],
'6' => [ 'Steel industry',
    'The specified conditions apply within the steel industry.' ],
'7' => [ 'Factoring',
    'Factoring industry.' ],
'8' => [ 'Defence industry',
    'A code to identify the defence industry.' ],
'9' => [ 'Alcohol beverage industry',
    'Alcohol beverage industry.' ],
'10' => [ 'Police',
    'Applies to police formalities.' ],
'11' => [ 'Customs',
    'Applies to customs regulations.' ],
'12' => [ 'Health regulation',
    'Applies to health regulation.' ],
'13' => [ 'Balance of payments',
    'Balance of payments.' ],
'14' => [ 'National legislation',
    'National regulations specified by the relevant government.' ],
'15' => [ 'Government',
    'To identify requirements and conditions applicable to government activity.' ],
'16' => [ 'Standards implementation',
    'Subject refers to standards implementation.' ],
'17' => [ 'Insurance',
    'The information is related to insurance.' ],
'18' => [ 'Credit inquiry',
    'Applies to credit inquiry.' ],
'19' => [ 'General request',
    'Applies to a general request.' ],
'20' => [ 'Payment terms',
    'Applies to payment terms.' ],
'21' => [ 'Reporting structure',
    'To identify requirements and conditions that apply to reporting structures.' ],
'22' => [ 'Legal filing amounts',
    'Subject applies to legal filing amounts.' ],
'23' => [ 'Electricity supply industry',
    'To identify the electricity supply industry.' ],
'24' => [ 'Aviation industry',
    'A code used to identify the aviation industry.' ],
'25' => [ 'Banking sector',
    'Conditions apply to the banking sector.' ],
'26' => [ 'Purchasing conditions',
    'Code indicating purchasing conditions.' ],
'27' => [ 'Gas supply industry',
    'To identify the gas supply industry.' ],
'28' => [ 'Garbage collection industry',
    'To identify the garbage collection industry.' ],
'29' => [ 'Cable television channel distribution industry',
    'To identify cable television (TV) channel distribution industry.' ],
'30' => [ 'Water distribution industry',
    'To identify the water distribution industry.' ],
);
sub get_codes { return \%code_hash; }

1;
