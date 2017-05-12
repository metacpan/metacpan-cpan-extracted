package Business::EDI::CodeList::DosageAdministrationCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6085;}
my $usage       = 'B';

# 6085  Dosage administration code qualifier                    [B]
# Desc: Code qualifying the administration of a dosage.
# Repr: an..3

my %code_hash = (
'1' => [ 'Route of administration',
    'Route of administration of item.' ],
'2' => [ 'Physical form',
    'Physical form of medicinal products.' ],
);
sub get_codes { return \%code_hash; }

1;
