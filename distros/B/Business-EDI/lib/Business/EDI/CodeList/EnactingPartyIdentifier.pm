package Business::EDI::CodeList::EnactingPartyIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3301;}
my $usage       = 'B';

# 3301  Enacting party identifier                               [B]
# Desc: To identify the party enacting an instruction.
# Repr: an..35

my %code_hash = (
'1' => [ "Applicant's bank",
    'The financial institution which is requested to issue the documentary credit.' ],
'2' => [ 'Issuing bank',
    "The financial institution which issues the documentary credit, if the applicant's bank is not acting as the issuing bank." ],
'3' => [ "Beneficiary's bank",
    'The financial institution with which the beneficiary maintains an account.' ],
'4' => [ 'Buyer',
    'The buyer is responsible for carrying out the instruction.' ],
'5' => [ 'Seller',
    'The seller is responsible for carrying out the instruction.' ],
'6' => [ 'Advise-through bank',
    'Identifies the financial institution through which the advising bank is to advise the documentary credit.' ],
'7' => [ 'Advising bank',
    'Identifies the financial institution used by the issuing bank to advise the documentary credit.' ],
'8' => [ "Debtor's bank",
    'Identifies the bank from whom payment is due.' ],
'9' => [ 'Ordered bank',
    'The financial institution with which the ordering party maintains an account.' ],
);
sub get_codes { return \%code_hash; }

1;
