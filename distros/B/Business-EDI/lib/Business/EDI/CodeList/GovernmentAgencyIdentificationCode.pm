package Business::EDI::CodeList::GovernmentAgencyIdentificationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9415;}
my $usage       = 'B';

# 9415  Government agency identification code                   [B]
# Desc: Code identifying a government agency.
# Repr: an..3

my %code_hash = (
'1' => [ 'Agriculture',
    'Government agency responsible for agriculture and e.g. the inspection of vegetable and animal substances being imported.' ],
'2' => [ 'Ammunition',
    'Government agency responsible for the safe transport of ammunition.' ],
'3' => [ 'Commerce',
    'Government agency responsible for commerce both domestic and international.' ],
'4' => [ 'Coastguard',
    'Government agency responsible for public safety on waterways.' ],
'5' => [ 'Customs',
    'Customs authorities.' ],
'6' => [ 'Food and drug',
    'Government agency responsible for the safety on food and drugs.' ],
'7' => [ 'Health certificate',
    'Health authorities.' ],
'8' => [ 'Harbour police',
    'Police authorities responsible for public safety in the harbour.' ],
'9' => [ 'Immigration',
    'Government agency responsible for immigration matters.' ],
'10' => [ 'Live animals',
    'Government agency responsible for the importation of live animals.' ],
'11' => [ 'Port authority',
    'Government or semi-government body responsible for port operations.' ],
'12' => [ 'Public health',
    'Government body responsible for public health matters.' ],
'13' => [ 'Transportation',
    'Government agency responsible for transportation policy and other transportation matters.' ],
'14' => [ 'Port state control',
    'Government body responsible for the policing of the port.' ],
);
sub get_codes { return \%code_hash; }

1;
