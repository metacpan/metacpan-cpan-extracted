package Business::EDI::CodeList::DespatchPatternTimingCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {2017;}
my $usage       = 'C';

# 2017  Despatch pattern timing code                            [C]
# Desc: Code specifying a set of dates/times within a despatch
# pattern.
# Repr: an..3

my %code_hash = (
'A' => [ '1st shift (normal working hours)',
    'The first working period as defined by an entity.' ],
'B' => [ '2nd shift',
    'A subsequent working period as defined by an entity, that follows 1st shift.' ],
'C' => [ '3rd shift',
    'A subsequent working period as defined by an entity, that follows 2nd shift.' ],
'D' => [ 'A.M.',
    'Ante Meridiem (forenoon).' ],
'E' => [ 'P.M.',
    'Post Meridiem (afternoon).' ],
'F' => [ 'As directed',
    'Shipment/delivery instruction will be provided in an independent communication session.' ],
'G' => [ 'Any shift',
    'The production period that a product will be built such as 1st shift or 3rd shift.' ],
'H' => [ '24 hour clock',
    'Shipment/deliveries will be specified by a continuous time clock .' ],
'Y' => [ 'None',
    'Used to cancel or override a previous pattern.' ],
'ZZZ' => [ 'Mutually defined',
    'Despatch pattern timing according to agreement.' ],
);
sub get_codes { return \%code_hash; }

1;
