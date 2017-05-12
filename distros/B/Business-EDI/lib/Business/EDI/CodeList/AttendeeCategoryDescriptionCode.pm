package Business::EDI::CodeList::AttendeeCategoryDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7459;}
my $usage       = 'B';

# 7459  Attendee category description code                      [B]
# Desc: Code specifying a category of attendee.
# Repr: an..3

my %code_hash = (
'1' => [ 'Same-day patient with overnight stay',
    'Actual or intended arrangement for same-day procedure with overnight stay.' ],
'2' => [ 'Same-day patient without overnight stay',
    'Actual or intended arrangement for same-day procedure without overnight stay.' ],
'3' => [ 'Non same-day patient with overnight stay',
    'Actual or intended arrangement for procedure, other than a same-day procedure, involving overnight stay.' ],
'4' => [ 'Outreach clinic visit',
    'Visit to an outreach clinical facility.' ],
'5' => [ 'Home care visit',
    "Provision of care to the patient in the patient's home." ],
);
sub get_codes { return \%code_hash; }

1;
