package Business::EDI::CodeList::SealingPartyNameCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9303;}
my $usage       = 'B';

# 9303  Sealing party name code                                 [B]
# Desc: Code specifying the name of the sealing party.
# Repr: an..3

my %code_hash = (
'AA' => [ 'Consolidator',
    'Party which consolidates cargo.' ],
'AB' => [ 'Unknown',
    'The sealing party is unknown.' ],
'AC' => [ 'Quarantine agency',
    'Agency responsible for the administration of statutory disease controls on the movement of people, animals and plants.' ],
'CA' => [ 'Carrier',
    'Party undertaking or arranging transport of goods between named points.' ],
'CU' => [ 'Customs',
    "'Customs' means the Government Service which is responsible for the administration of Customs law and the collection of duties and taxes and which also has the responsibility for the application of other laws and regulations relating to the importation, exportation, movement or storage of goods." ],
'SH' => [ 'Shipper',
    'Party which, by contract with a carrier, consigns or sends goods with the carrier, or has them conveyed by him.' ],
'TO' => [ 'Terminal operator',
    'Party which handles the loading and unloading of marine vessels.' ],
);
sub get_codes { return \%code_hash; }

1;
