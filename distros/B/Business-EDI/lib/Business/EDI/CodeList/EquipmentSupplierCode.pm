package Business::EDI::CodeList::EquipmentSupplierCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8077;}
my $usage       = 'B';

# 8077  Equipment supplier code                                 [B]
# Desc: Code specifying the party that is the supplier of the
# equipment.
# Repr: an..3

my %code_hash = (
'1' => [ 'Shipper supplied',
    'The transport equipment is supplied by the shipper.' ],
'2' => [ 'Carrier supplied',
    'The transport equipment is supplied by the carrier.' ],
'3' => [ 'Consolidator supplied',
    'The equipment is supplied by the consolidator.' ],
'4' => [ 'Deconsolidator supplied',
    'The equipment is supplied by the deconsolidator.' ],
'5' => [ 'Third party supplied',
    'The equipment is supplied by a third party.' ],
'6' => [ 'Forwarder supplied from a leasing company',
    'The equipment is supplied by the forwarder and is taken from a leasing company.' ],
'7' => [ "Forwarder supplied from the railways' pool",
    'The equipment is supplied by the forwarder and is taken from a pool established by railway companies.' ],
);
sub get_codes { return \%code_hash; }

1;
