package Business::EDI::CodeList::AgreementTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7431;}
my $usage       = 'B';

# 7431  Agreement type code qualifier                           [B]
# Desc: Code qualifying the type of agreement.
# Repr: an..3

my %code_hash = (
'1' => [ 'Type of participation',
    'The subject of the agreement is the type of participation.' ],
'2' => [ 'Credit cover agreement',
    'Agreement on protection against risk of credit losses on sales to buyers.' ],
'3' => [ "Cedent's treaty identifier",
    'Identifies the treaty as assigned by the cedent.' ],
'4' => [ "Reinsurer's treaty identifier",
    'Identifies the treaty as assigned by the reinsurer.' ],
'5' => [ 'Type of contract letting',
    'The type of agreement needed to specify construction works tendered out as public or restricted.' ],
'6' => [ 'Contract breakdown type',
    'The type of contract breakdown.' ],
'7' => [ 'Contractor responsibility and liability structure',
    'The way the contractor(s) are structured to perform a contract for the purpose of responsibility and liability.' ],
'8' => [ 'Health insurance cover agreement',
    'Agreement on health insurance coverage.' ],
'9' => [ 'Contract',
    'The type of agreement is a contract.' ],
'10' => [ 'Social security cover agreement',
    'Agreement on social security cover.' ],
'11' => [ 'Grid connection contract',
    'Contract for connection to a grid.' ],
'12' => [ 'Power supply contract',
    'Contract for supply of power.' ],
);
sub get_codes { return \%code_hash; }

1;
