package Business::EDI::CodeList::GeographicAreaCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3279;}
my $usage       = 'B';

# 3279  Geographic area code                                    [B]
# Desc: Code specifying a geographical area.
# Repr: an..3

my %code_hash = (
'DO' => [ 'Domestic',
    'Domestic message as defined by relevant central bank.' ],
'DP' => [ 'SEPA (Single Euro Payments Area) ID C',
    'SEPA message following scheme 3 as defined by EBA (EURO Banking Association).' ],
'DQ' => [ 'SEPA (Single Euro Payments Area) ID A',
    'SEPA message following scheme 1 as defined by EBA (EURO Banking Association).' ],
'DR' => [ 'Domestic with regulatory information required',
    'Domestic message with requirement to regulatory information to central bank.' ],
'DS' => [ 'SEPA (Single Euro Payments Area) ID B',
    'SEPA message following scheme 2 as defined by EBA (EURO Banking Association).' ],
'DT' => [ 'SEPA (Single Euro Payments Area) ID D',
    'SEPA message following scheme 4 as defined by EBA (EURO Banking Association).' ],
'EA' => [ 'Economic area',
    'Message crossing at least one national boundary but confined within a specific economic area (e.g. EC, EFTA ...).' ],
'IN' => [ 'International',
    'International message as defined by relevant central bank.' ],
'IR' => [ 'International with regulatory information required',
    'International message with requirement to regulatory information to central bank.' ],
'IS' => [ 'European Union',
    'To identify the message as originating from and destined to a member state of the European Union.' ],
'SPA' => [ 'SEPA (Single Euro Payments Area) ID A',
    'SEPA message following EBA (EURO Banking Association) scheme 1, i.e. used for SEPA Credit Transfers / SEPA Direct Debits.' ],
'SPB' => [ 'SEPA (Single Euro Payments Area) ID B',
    'SEPA message following scheme 2 as defined by EBA (EURO Banking Association).' ],
'SPC' => [ 'SEPA (Single Euro Payments Area) ID C',
    'SEPA message following scheme 3 as defined by EBA (EURO Banking Association).' ],
'SPD' => [ 'SEPA (Single Euro Payments Area) ID D',
    'SEPA message following scheme 4 as defined by EBA (EURO Banking Association).' ],
);
sub get_codes { return \%code_hash; }

1;
