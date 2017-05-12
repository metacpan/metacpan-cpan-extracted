package Business::EDI::CodeList::SecurityPartyCodeListResponsibleAgencyCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0515";}
my $usage       = 'B';

# 0515  Security party code list responsible agency, coded
# Desc: Identification of the agency in charge of registration of the
# security parties.
# Repr: an..3

my %code_hash = (
'1' => [ 'UN/CEFACT',
    'United Nations Centre for Trade Facilitation and Electronic Business (UN/CEFACT).' ],
'2' => [ 'ISO',
    'International Organization for Standardization.' ],
);
sub get_codes { return \%code_hash; }

1;
