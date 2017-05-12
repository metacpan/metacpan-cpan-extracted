package Business::EDI::CodeList::PackagingLevelCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7075;}
my $usage       = 'B';

# 7075  Packaging level code                                    [B]
# Desc: Code specifying a level of packaging.
# Repr: an..3

my %code_hash = (
'1' => [ 'Inner',
    'Level of packing, if it exists, that is immediately subordinate to the intermediate packaging level.' ],
'2' => [ 'Intermediate',
    'Level of packaging, if it exists, that is immediately subordinate to the outer packaging level.' ],
'3' => [ 'Outer',
    'For packed merchandise, outermost level of packaging for a shipment.' ],
'4' => [ 'No packaging hierarchy',
    'There is no specifiable level of packaging: packaging is inner and outer level as well.' ],
'5' => [ 'Shipment level',
    'The packaging level being described is the shipment level.' ],
);
sub get_codes { return \%code_hash; }

1;
