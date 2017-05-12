package Business::EDI::CodeList::OrganisationClassificationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3079;}
my $usage       = 'B';

# 3079  Organisation classification code                        [B]
# Desc: Code specifying the classification of an organisation.
# Repr: an..3

my %code_hash = (
'1' => [ 'Type of department',
    'The organisation classification is according to department.' ],
'2' => [ 'Type of medical speciality',
    'The organisation classification is according to medical speciality.' ],
);
sub get_codes { return \%code_hash; }

1;
