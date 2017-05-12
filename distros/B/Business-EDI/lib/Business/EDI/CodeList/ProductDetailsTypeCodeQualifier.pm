package Business::EDI::CodeList::ProductDetailsTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7133;}
my $usage       = 'I';

# 7133  Product details type code qualifier                     [I]
# Desc: Code qualifying a type of product details.
# Repr: an..3

my %code_hash = (
'1' => [ 'Physical configuration',
    'The associated data relates to the physical configuration.' ],
'2' => [ 'Class availability status',
    'The associated data relates to availability status for one or more classes of service.' ],
'3' => [ 'Actual availability',
    'The product detail is the actual availability.' ],
'4' => [ 'Availability range',
    'The product detail is the availability range.' ],
);
sub get_codes { return \%code_hash; }

1;
