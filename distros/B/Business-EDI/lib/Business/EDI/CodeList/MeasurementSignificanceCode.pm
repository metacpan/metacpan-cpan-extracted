package Business::EDI::CodeList::MeasurementSignificanceCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6321;}
my $usage       = 'C';

# 6321  Measurement significance code                           [C]
# Desc: Code specifying the significance of a measurement.
# Repr: an..3

my %code_hash = (
'3' => [ 'Approximately',
    'The measurement is approximately equal to that specified.' ],
'4' => [ 'Equal to',
    'The measurement is equal to that specified.' ],
'5' => [ 'Greater than or equal to',
    'The measurement is greater than or equal to that specified.' ],
'6' => [ 'Greater than',
    'The measurement is greater than that specified.' ],
'7' => [ 'Less than',
    'The measurement is less than that specified.' ],
'8' => [ 'Less than or equal to',
    'The measurement is less than or equal to that specified.' ],
'9' => [ 'Average value',
    'Average value for a specific series of readings.' ],
'10' => [ 'Not equal to',
    'The measurement is not equal to that specified.' ],
'12' => [ 'True value',
    'The measurement reported is a true value.' ],
'13' => [ 'Observed value',
    'The measurement reported is an observed value.' ],
'14' => [ 'Marked',
    'The measurement marked on the object.' ],
'15' => [ 'Out of range',
    'The measurement reported is out of range.' ],
);
sub get_codes { return \%code_hash; }

1;
