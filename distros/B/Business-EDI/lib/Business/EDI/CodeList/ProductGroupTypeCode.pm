package Business::EDI::CodeList::ProductGroupTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5379;}
my $usage       = 'B';

# 5379  Product group type code                                 [B]
# Desc: Code specifying the type of product group.
# Repr: an..3

my %code_hash = (
'1' => [ 'Base x coefficient',
    'The product is grouped based on price multiplied with a coefficient.' ],
'2' => [ 'No price group used',
    'Code specifying that the product is not subject to price group.' ],
'3' => [ 'Catalogue',
    'Code specifying that the product is indexed in a catalogue.' ],
'4' => [ 'Group of products with same price',
    'Code specifying that all the products of the group have the same price.' ],
'5' => [ 'Itemized',
    'Code specifying that the product group is itemized.' ],
'7' => [ 'Current discount group',
    'Items in this discount group are available to the buyer at a common discount percentage.' ],
'8' => [ 'Previous discount group',
    'The common discount percentage group to which an item previously belonged.' ],
'9' => [ 'No group used',
    'No grouping is being used.' ],
'10' => [ 'Price group',
    'Products grouped together on the basis of price.' ],
'11' => [ 'Product group',
    'A code indicating a product group.' ],
'12' => [ 'Promotional group',
    'Grouping of products for promotional reasons.' ],
'13' => [ 'Legal',
    'A product group governed by a common set of legal rules.' ],
'14' => [ 'Geographical target market division/subdivision code',
    'The target market is a geographical region based upon geographical boundaries sanctioned by the United Nations.' ],
);
sub get_codes { return \%code_hash; }

1;
