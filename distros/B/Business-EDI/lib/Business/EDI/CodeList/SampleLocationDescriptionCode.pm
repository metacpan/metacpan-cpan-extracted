package Business::EDI::CodeList::SampleLocationDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3237;}
my $usage       = 'B';

# 3237  Sample location description code                        [B]
# Desc: Code specifying the sample location.
# Repr: an..3

my %code_hash = (
'1' => [ 'Bore',
    'A hollowed out section of the item.' ],
'2' => [ 'Rim',
    'A raised edge or border.' ],
'3' => [ 'Web',
    'A complete structure or connected series.' ],
'4' => [ 'Centre',
    'The middle point from any point on the circumference or surface.' ],
'5' => [ 'Core',
    'The central or most important part of the item.' ],
'6' => [ 'Surface',
    'The outer most surface of an item.' ],
'7' => [ 'Beginning',
    'The sample is taken at the beginning of the specimen.' ],
'8' => [ 'End',
    'The sample is taken at the end of the specimen.' ],
'9' => [ 'Middle',
    'The sample is taken at the middle of the specimen.' ],
'10' => [ 'Centre Back',
    'The sample location is centre across width, back end across length.' ],
'11' => [ 'Centre front',
    'The sample location is centre across width, front end across length.' ],
'12' => [ 'Centre middle',
    'The sample location is centre across width, middle end across length.' ],
'13' => [ 'Edge back',
    'The sample location is on the edge across width, back end across length.' ],
'14' => [ 'Edge front',
    'The sample location is on the edge across width, front end across length.' ],
'15' => [ 'Edge middle',
    'The sample location is on the edge across the width, middle end across length.' ],
'16' => [ 'Quarter back',
    'The sample location is a quarter way across the width, back end across length.' ],
'17' => [ 'Quarter front',
    'The sample location is a quarter way across the width, front end across length.' ],
'18' => [ 'Quarter middle',
    'The sample location is a quarter way across the width, middle end across length.' ],
'19' => [ 'Weld',
    'The sample is taken from the weld of the specimen.' ],
'20' => [ 'Body',
    'Sample is taken from the body of the specimen.' ],
);
sub get_codes { return \%code_hash; }

1;
