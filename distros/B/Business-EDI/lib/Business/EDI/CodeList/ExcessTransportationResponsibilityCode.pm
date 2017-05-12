package Business::EDI::CodeList::ExcessTransportationResponsibilityCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8459;}
my $usage       = 'B';

# 8459  Excess transportation responsibility code               [B]
# Desc: Code specifying the responsibility for excess
# transportation.
# Repr: an..3

my %code_hash = (
'B' => [ 'Material release issuer',
    'The responsibility for excess transportation is with the material release issuer.' ],
'S' => [ 'Supplier authority',
    'The responsibility for excess transportation is with the supplier authority.' ],
'X' => [ 'Responsibility to be determined',
    'The responsibility for the excess transportation is to be determined.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
