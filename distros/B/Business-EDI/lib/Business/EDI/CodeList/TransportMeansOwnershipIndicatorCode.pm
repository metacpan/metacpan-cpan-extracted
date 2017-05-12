package Business::EDI::CodeList::TransportMeansOwnershipIndicatorCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8281;}
my $usage       = 'B';

# 8281  Transport means ownership indicator code                [B]
# Desc: Code indicating the ownership of a means of transport.
# Repr: an..3

my %code_hash = (
'1' => [ "Transport for the owner's account",
    'The owner of the transported goods is also the owner of the means of transport or rented it for this transport.' ],
'2' => [ 'Transport for another account',
    'The owner of the transported goods does not own the means of transport or has not rented it for this transport.' ],
'3' => [ 'Private transport',
    'A code indicating privately owned transport.' ],
);
sub get_codes { return \%code_hash; }

1;
