package Business::EDI::CodeList::RequirementOrConditionDescriptionIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7295;}
my $usage       = 'B';

# 7295  Requirement or condition description identifier         [B]
# Desc: Code specifying a requirement or condition.
# Repr: an..17

my %code_hash = (
'1' => [ 'Service provider determined service',
    'The service was determined by the service provider.' ],
'2' => [ 'All X-rays specifically requested',
    'All X-rays specifically requested.' ],
'3' => [ 'Not for comparison',
    'Not for comparison.' ],
'4' => [ 'Contiguous body area service with different set-up',
    'The service on contiguous body area that required different set-up.' ],
'5' => [ 'Non-contiguous body areas service',
    'The service was conducted on non-contiguous body areas.' ],
'6' => [ 'Three hours or more between services',
    'Three hours or more between the services.' ],
'7' => [ 'Left body part service',
    'Service was conducted on the left part of the body.' ],
'8' => [ 'Lost referral',
    'The referral has been lost.' ],
'9' => [ 'Necessary emergency and/or immediate treatment',
    'Treatment was necessary as it was an emergency and/or immediately required.' ],
'10' => [ 'Second visit in one day',
    'Second visit in one day.' ],
'11' => [ 'Separate procedure',
    'The procedure is separate.' ],
'12' => [ 'Not usual medical after-care',
    'Post treatment medical care which differs from the usual post treatment medical care.' ],
'13' => [ 'Right body part service',
    'Service was conducted on the right part of the body.' ],
);
sub get_codes { return \%code_hash; }

1;
