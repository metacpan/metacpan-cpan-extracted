package Business::EDI::CodeList::HaulageArrangementsCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8341;}
my $usage       = 'B';

# 8341  Haulage arrangements code                               [B]
# Desc: Code specifying the arrangement for the haulage of
# goods.
# Repr: an..3

my %code_hash = (
'1' => [ 'Carrier',
    'Haulage arranged by carrier.' ],
'2' => [ 'Merchant',
    'Haulage arranged by merchant (shipper, consignee, or their agent).' ],
);
sub get_codes { return \%code_hash; }

1;
