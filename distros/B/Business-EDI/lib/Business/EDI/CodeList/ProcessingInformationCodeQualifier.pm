package Business::EDI::CodeList::ProcessingInformationCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9649;}
my $usage       = 'B';

# 9649  Processing information code qualifier                   [B]
# Desc: Code qualifying the processing information.
# Repr: an..3

my %code_hash = (
'1' => [ 'Entity asset reporting',
    'To convey information related to the reporting of assets held by an entity.' ],
'2' => [ 'Accounting data',
    'Identifies information about accounting data.' ],
'3' => [ 'Scheduling type information',
    'Identifies information about the scheduling type.' ],
'4' => [ 'Party type information',
    'Identifies information about the party type.' ],
'5' => [ 'Consignment type information',
    'Identifies information about the consignment type.' ],
'6' => [ 'Statistical array processing',
    'Defines information required to process the contents of a statistical array.' ],
);
sub get_codes { return \%code_hash; }

1;
