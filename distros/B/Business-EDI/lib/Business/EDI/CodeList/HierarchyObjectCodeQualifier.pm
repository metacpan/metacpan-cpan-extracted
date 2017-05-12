package Business::EDI::CodeList::HierarchyObjectCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7173;}
my $usage       = 'B';

# 7173  Hierarchy object code qualifier                         [B]
# Desc: Code qualifying an object in a hierarchy.
# Repr: an..3

my %code_hash = (
'1' => [ 'Figure',
    'Hierarchy applying to figures (an illustration showing the components of an item).' ],
'2' => [ 'Product',
    'Hierarchy applying to products.' ],
'3' => [ 'No hierarchy',
    'No hierarchy to be described.' ],
'4' => [ 'Data structures',
    'Objects are related in the hierarchy as data structures.' ],
'5' => [ 'Sub-assembly',
    'An item assembled from a number of component parts.' ],
'6' => [ 'Component part',
    'Part assembled with other items to produce an assembly.' ],
'7' => [ 'Technical drawing',
    'A structured view on how an item is composed.' ],
'8' => [ 'Financial institution details',
    'Hierarchy applies to financial institution details information.' ],
'9' => [ 'Financial data',
    'Hierarchy applies to financial data information.' ],
'10' => [ 'Party history',
    'Hierarchy applies to party history information.' ],
'11' => [ 'Entity identification',
    'Hierarchy applies to entity identification information.' ],
'12' => [ 'Business insurance',
    'Hierarchy applies to business insurance information.' ],
'13' => [ 'Credit appraisal',
    'Hierarchy applies to credit appraisal information.' ],
'14' => [ 'Location',
    'Hierarchy applies to location information.' ],
'15' => [ 'Management details',
    'Hierarchy applies to management details information.' ],
'16' => [ 'Operations',
    'Hierarchy applies to operations information.' ],
'17' => [ 'Payment handling',
    'Hierarchy applies to payment handling information.' ],
'18' => [ 'Public records',
    'Hierarchy applies to public records information.' ],
'19' => [ 'Real estate property',
    'Hierarchy applies to real estate property information.' ],
'20' => [ 'Related entities',
    'Hierarchy applies to related entities information.' ],
'21' => [ 'Data source',
    'Hierarchy applies to data source information.' ],
'22' => [ 'Equity holder',
    'Hierarchy applies to equity holder information.' ],
'23' => [ 'Summary evaluation',
    'Hierarchy applies to summary evaluation information.' ],
'24' => [ 'Report update',
    'The hierarchy applies to report update information.' ],
'25' => [ 'Party',
    'Hierarchy applying to parties.' ],
'26' => [ 'Central procurement party',
    'Hierarchy applying to a central procurement party.' ],
'27' => [ 'Quotation party',
    'Hierarchy applying to a quotation party.' ],
'28' => [ 'Operational group',
    'Hierarchy applying to an operational group.' ],
'29' => [ 'Juridical group',
    'Hierarchy applying to a juridical group.' ],
'30' => [ 'Loan information',
    'Hierarchy applies to loan information.' ],
'31' => [ 'Performance',
    'Hierarchy applies to performance.' ],
'32' => [ 'Historical performance',
    'Hierarchy applies to historical performance.' ],
'33' => [ 'Associated accessory',
    'The hierarchy applies to associated accessories.' ],
);
sub get_codes { return \%code_hash; }

1;
