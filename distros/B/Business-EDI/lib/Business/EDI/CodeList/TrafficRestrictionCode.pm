package Business::EDI::CodeList::TrafficRestrictionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8015;}
my $usage       = 'I';

# 8015  Traffic restriction code                                [I]
# Desc: Code specifying a traffic restriction.
# Repr: an..3

my %code_hash = (
'1' => [ 'Stop only for boarding',
    'Travel service stops at a given location, only to pick up travellers.' ],
'2' => [ 'Stop only for alighting',
    'Travel service stops at a given location, only to allow disembarkation.' ],
'3' => [ 'Technical stop, without boarding or alighting',
    'Location where a travel service makes a technical stop without allowing passengers to board or to disembark.' ],
'4' => [ 'Passing location',
    'Location where a travel service passes without stopping.' ],
);
sub get_codes { return \%code_hash; }

1;
