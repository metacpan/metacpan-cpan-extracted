package Business::EDI::CodeList::PaymentTermsDescriptionIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4277;}
my $usage       = 'B';

# 4277  Payment terms description identifier                    [B]
# Desc: Identification of the terms of payment between the
# parties to a transaction (generic term).
# Repr: an..17

my %code_hash = (
'1' => [ 'Draft(s) drawn on issuing bank',
    'Draft(s) must be drawn on the issuing bank.' ],
'2' => [ 'Draft(s) drawn on advising bank',
    'Draft(s) must be drawn on the advising bank.' ],
'3' => [ 'Draft(s) drawn on reimbursing bank',
    'Draft(s) must be drawn on the reimbursing bank.' ],
'4' => [ 'Draft(s) drawn on applicant',
    'Draft(s) must be drawn on the applicant.' ],
'5' => [ 'Draft(s) drawn on any other drawee',
    'Draft(s) must be drawn on any other drawee.' ],
'6' => [ 'No drafts',
    'No drafts required.' ],
'7' => [ 'Payment means specified in commercial account summary',
    'An indication that the payment means are specified in a commercial account summary.' ],
);
sub get_codes { return \%code_hash; }

1;
