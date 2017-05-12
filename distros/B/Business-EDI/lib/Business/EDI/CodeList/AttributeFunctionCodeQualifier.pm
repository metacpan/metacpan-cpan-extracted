package Business::EDI::CodeList::AttributeFunctionCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9017;}
my $usage       = 'C';

# 9017  Attribute function code qualifier                       [C]
# Desc: Code qualifying an attribute function.
# Repr: an..3

my %code_hash = (
'1' => [ 'Member',
    'Attribute refers to a member of a group of persons or a service scheme.' ],
'2' => [ 'Person',
    'Attribute refers to a person.' ],
'3' => [ 'Array structure component',
    'A structure component of an array.' ],
'4' => [ 'University degree',
    'Attribute to specify an academic title.' ],
'5' => [ 'Professional title',
    'Attribute to specify professional title.' ],
'6' => [ 'Courtesy title',
    'Attribute to specify a personal title.' ],
'7' => [ 'Directory set definition',
    'Attribute refers to a directory set definition.' ],
'8' => [ 'Structure object attribute',
    'The attribute refers to an object in a structure.' ],
'9' => [ 'Account',
    'Identifying attributes related to an account.' ],
'10' => [ 'Financial statement',
    'Identifies the attributes related to a financial statement.' ],
'11' => [ 'Payment manner',
    'To provide information regarding the manner of payment.' ],
'12' => [ 'Loan information',
    'To specify information applicable to a loan.' ],
'13' => [ 'Contract',
    'To identify the contract attributes.' ],
'14' => [ 'Funding',
    'To identify funding attributes.' ],
'15' => [ 'Acquisition phase',
    'To identify the attributes for the acquisition phases of a product or service.' ],
'16' => [ 'Monetary appropriation',
    'To identify the attributes of money set aside to accomplish a task.' ],
'17' => [ 'Laboratory investigation',
    'Attribute relates to a laboratory investigation.' ],
'18' => [ 'Clinical investigation',
    'Attribute relates to a clinical investigation.' ],
'19' => [ 'Reason for request',
    'Attribute relates to a reason for a request.' ],
'20' => [ 'Reason for prescription',
    'Attribute relates to the reason for a prescription.' ],
'21' => [ 'Comment to prescription',
    'Attribute relates to a comment to a prescription.' ],
'22' => [ 'Observation',
    'Attribute relates to an observation.' ],
'23' => [ 'Comment to a request',
    'Attribute relates to a comment to a request.' ],
'24' => [ 'Event',
    'Attribute relates to an event.' ],
'25' => [ 'Additional function',
    'The attribute specified is an additional function.' ],
'ZZZ' => [ 'Mutually defined',
    'Mutually defined attribute function qualifier.' ],
);
sub get_codes { return \%code_hash; }

1;
