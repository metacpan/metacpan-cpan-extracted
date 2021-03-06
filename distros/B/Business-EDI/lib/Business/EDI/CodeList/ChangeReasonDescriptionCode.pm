package Business::EDI::CodeList::ChangeReasonDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4295;}
my $usage       = 'B';

# 4295  Change reason description code                          [B]
# Desc: Code specifying the reason for a change.
# Repr: an..3

my %code_hash = (
'AA' => [ 'Member attribute change',
    'An attribute of a member of a group has changed.' ],
'AB' => [ 'Abroad',
    'In an other country.' ],
'AC' => [ 'Member category change',
    'The member or benefits category has changed.' ],
'AD' => [ 'Death',
    'Subject has died.' ],
'AE' => [ 'Disability',
    'Subject is disabled.' ],
'AF' => [ 'Early retirement',
    'Retirement before the normal retirement age.' ],
'AG' => [ 'Hardship',
    'Subject is incurring hardship.' ],
'AH' => [ 'Ill health',
    'Subject has ill health.' ],
'AI' => [ 'Leaving employer',
    'Subject is leaving employer.' ],
'AJ' => [ 'Leaving industry',
    'Person is leaving, or has left, an identified industry.' ],
'AK' => [ 'Level/rate table change',
    'The insurance level/rate table has changed.' ],
'AL' => [ 'Normal retirement',
    'Subject has retired at the normal retirement age.' ],
'AM' => [ 'Other',
    'Reason differs from any of the other coded values.' ],
'AN' => [ 'Retrenchment',
    'Subject has been retrenched from work.' ],
'AO' => [ 'Resignation',
    'Subject has resigned from work.' ],
'AP' => [ 'Member status change',
    'The member status has changed.' ],
'AQ' => [ 'Alternate quantity and unit of measurement',
    'Change is due to an alternate quantity and unit of measurement.' ],
'AR' => [ 'Article out of assortment for particular company',
    'Item normally part of a suppliers standard assortment but is unavailable for a specific buyer due to legal or commercial reasons.' ],
'AS' => [ 'Article out of assortment',
    'Article normally part of a standard assortment is unavailable.' ],
'AT' => [ 'Item not ordered',
    'Code indicating the item or product was not ordered.' ],
'AU' => [ 'No delivery due to outstanding payments',
    'Delivery of an item was stopped due to outstanding deliveries which have not yet been paid.' ],
'AV' => [ 'Out of inventory',
    'Item is out of inventory.' ],
'AW' => [ 'Quantity adjustment',
    'Code indicating that the reason for the quantity variance is because of adjustments.' ],
'AX' => [ 'National pricing authority agreement is final',
    'Code to indicate that the national pricing authority agreement for a price is final.' ],
'AY' => [ 'Sale location different',
    'Sold in a different sales location.' ],
'AZ' => [ 'Best before date out of sequence',
    'Goods have a best before date that is earlier than that of goods previously received.' ],
'BA' => [ 'Damaged goods',
    'A change resulting from damaged goods.' ],
'BB' => [ 'Transport means technical failure',
    'Transport means had a technical failure, e.g. transport means could not be unloaded or did not comply with hygienic requirements.' ],
'BC' => [ 'Equipment technical failure',
    'Equipment had a technical failure, e.g. equipment was damaged or wrong.' ],
'BD' => [ 'Blueprint deviation',
    'Change is due to a deviation in the blueprint.' ],
'BE' => [ 'Goods technical failure',
    'Goods had a technical failure, e.g. instability, overhang, transportation lock or damage.' ],
'BF' => [ 'Spoilage of goods',
    'A change resulting from the spoilage of goods.' ],
'BG' => [ 'Grade difference out of tolerance level',
    'The change is due to a variation in the grade of the product outside the tolerance level allowed in an agreement.' ],
'BQ' => [ 'Balancing quantity',
    'Amount needed to resolve difference between ordered and delivered quantity.' ],
'DC' => [ 'Date change',
    'Date has changed.' ],
'EV' => [ 'Estimated quantity',
    'The estimated quantity has changed.' ],
'GU' => [ 'Gross volume per pack and unit of measure',
    'The gross volume per pack and unit of measure has changed.' ],
'GW' => [ 'Gross weight per pack',
    'The gross weight per pack has changed.' ],
'LD' => [ 'Length difference',
    'The change is due to a difference in length.' ],
'MC' => [ 'Pack/size measure difference',
    'The change is due to a difference in pack/size measure.' ],
'PC' => [ 'Pack type difference',
    'The reason for the variation is due to a difference in the type of pack.' ],
'PD' => [ 'Pack dimension difference',
    'The change is due to a difference in the dimension.' ],
'PQ' => [ 'Pack quantity',
    'The pack quantity has changed.' ],
'PS' => [ 'Product/services ID change',
    'The product/services identification has changed.' ],
'PW' => [ 'Pack weight difference',
    'The change is due to a difference in the pack weight.' ],
'PZ' => [ 'Pack size difference',
    'The reason for the variation is due to a difference in the size of pack.' ],
'QO' => [ 'Quantity ordered',
    'The quantity ordered has changed.' ],
'QP' => [ 'Quantity based on price qualifier',
    'The quantity based on price qualifier has changed.' ],
'QT' => [ 'Quantity price break',
    'The quantity price break has changed.' ],
'SC' => [ 'Size difference',
    'The change is due to a difference in the size.' ],
'UM' => [ 'Unit of measure difference',
    'The change is due to a difference in the unit of measure.' ],
'UP' => [ 'Unit price',
    'The unit price has changed.' ],
'WD' => [ 'Width difference',
    'The change is due to a difference in width.' ],
'WO' => [ 'Weight qualifier/gross weight per package',
    'The weight qualifier/gross weight per package has changed.' ],
'WP' => [ 'Inadvertent error',
    'An inadvertent error in recording a quantity.' ],
'WQ' => [ 'Over shipped',
    'A shipped quantity greater than the ordered or invoiced quantity.' ],
'WR' => [ 'Temporarily unavailable',
    'Product is temporarily unavailable.' ],
'WS' => [ 'Government action',
    'Due to government action.' ],
'WT' => [ 'Excluded from the promotion activity',
    'Product is not included in the promotion activity.' ],
'WU' => [ 'Committed purchase quantity exceeded',
    'The committed purchase quantity has been exceeded.' ],
'WV' => [ 'Committed purchase quantity not ordered',
    'The committed purchase quantity has not been ordered.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
