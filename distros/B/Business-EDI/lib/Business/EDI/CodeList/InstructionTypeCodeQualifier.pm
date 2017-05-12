package Business::EDI::CodeList::InstructionTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4403;}
my $usage       = 'C';

# 4403  Instruction type code qualifier                         [C]
# Desc: Code qualifying the type of instruction.
# Repr: an..3

my %code_hash = (
'1' => [ 'Action required',
    'Instruction requires action.' ],
'2' => [ 'Party instructions',
    'The instructions are to be executed by means of a party.' ],
'3' => [ 'Maximum value exceeded instructions',
    'Instruction how to act if maximum value will be or has been exceeded.' ],
'4' => [ 'Confirmation instructions',
    'Documentary credit confirmation instructions.' ],
'5' => [ 'Method of issuance',
    'Documentary credit confirmation of issuance.' ],
'6' => [ 'Pre-advice instructions',
    'Documentary credit pre-advice instructions.' ],
'7' => [ 'Documents delivery instruction',
    'Delivery instructions for documents required under a documentary credit.' ],
'8' => [ 'Additional terms and/or conditions documentary credit',
    'Additional terms and/or conditions to the documentary credit.' ],
'9' => [ 'Investment instruction',
    'Instruction refers to an investment.' ],
'10' => [ 'Reimbursement instructions',
    'Instructions as to how the reimbursement is to be effected.' ],
'11' => [ 'Instructions to the paying and/or accepting and/or',
    'negotiating bank Instructions to the paying and/or accepting and/or negotiating bank.' ],
'12' => [ 'Instructions and/or information to the applicant',
    'Instructions and/or information to the applicant.' ],
'13' => [ 'Case of need party power instructions',
    'Case of need party power instructions.' ],
'14' => [ 'Instructions for payment in local currency',
    'Payment of the documentary credit in local currency instructions.' ],
'15' => [ 'Instructions for return of acceptance draft',
    'Return of acceptance draft instructions.' ],
'16' => [ 'Method for advice of non-payment',
    'Advice of non-payment method.' ],
'17' => [ 'Documentary credit advice of non-acceptance method',
    'Advice of non-acceptance method of the documentary credit.' ],
'18' => [ 'Documentary credit advice of payment method',
    'Advice of payment method of the documentary credit.' ],
'19' => [ 'Documentary credit advice of acceptance method',
    'Advice of acceptance method of the documentary credit.' ],
'20' => [ 'Instructions for the first transmission of documents',
    'Instructions for the first transmission of documents.' ],
'21' => [ 'Instructions for the second transmission of documents',
    'Instructions for the second transmission of documents.' ],
'22' => [ 'Instructions for terms of delivery of documents',
    'Instructions for terms of delivery of documents.' ],
'23' => [ 'Instructions and/or information to the beneficiary',
    'Instructions and/or information to the beneficiary.' ],
'24' => [ 'Protest instructions',
    'Instructions as to whether a protest is to be made.' ],
'25' => [ 'Warehouse and/or insurance instructions',
    'Instructions about warehousing and/or insurance.' ],
'26' => [ 'Charges waiver instructions',
    'Instructions as to whether charges may be waived.' ],
'27' => [ 'Interest waiver instructions',
    'Instructions as to whether interest may be waived.' ],
'28' => [ 'Deferral of payment and/or acceptance instructions',
    'Instructions as to whether payment and/or acceptance may be deferred.' ],
'29' => [ 'Patient preparation',
    'Instruction concerning the preparation of a patient.' ],
'30' => [ 'Dosage of medicine',
    'Instruction concerning the dosage of medicine.' ],
'31' => [ 'Instruction about patient',
    'Instruction concerning a patient.' ],
'32' => [ 'Meter reading instruction',
    'Instruction concerning the reading of a meter.' ],
'33' => [ 'Meter change instruction',
    'Instruction concerning the change of a meter.' ],
);
sub get_codes { return \%code_hash; }

1;
