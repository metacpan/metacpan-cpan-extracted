package Business::EDI::CodeList::InstructionReceivingPartyIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3285;}
my $usage       = 'B';

# 3285  Instruction receiving party identifier                  [B]
# Desc: Code specifying the party to receive an instruction.
# Repr: an..35

my %code_hash = (
'1' => [ "Applicant's bank",
    'The financial institution which is requested to issue the documentary credit.' ],
'2' => [ 'Issuing bank',
    "The financial institution which issues the documentary credit, if the applicant's bank is not acting as the issuing bank." ],
'3' => [ "Beneficiary's bank",
    'The financial institution with which the beneficiary maintain an account.' ],
'4' => [ 'Beneficiary',
    "The party in whose favour the documentary credit is to be issued and the party who must comply with the credit's terms and conditions." ],
'5' => [ 'Contact party 1',
    'First party to contact.' ],
'6' => [ 'Contact party 2',
    'Second party to contact.' ],
'7' => [ 'Contact party 3',
    'Third party to contact.' ],
'8' => [ 'Contact party 4',
    'Fourth party to contact.' ],
'9' => [ 'Contact bank 1',
    'First financial institution to contact.' ],
'10' => [ 'Contact bank 2',
    'Second financial institution to contact.' ],
'11' => [ 'Creditor',
    'Party to whom payment is due.' ],
'12' => [ 'Receiving bank',
    'Identifies the bank which is to receive funds.' ],
'13' => [ "Creditor's bank",
    'Identifies the bank to whom payment is due.' ],
'14' => [ 'Instruction receiving party identifier',
    'Code specifying the party to receive an instruction.' ],
'15' => [ 'Debtor',
    'Party from whom payment is due.' ],
'16' => [ "Payer or payer's agent",
    "Party or party's agent from whom funds will be made available." ],
);
sub get_codes { return \%code_hash; }

1;
