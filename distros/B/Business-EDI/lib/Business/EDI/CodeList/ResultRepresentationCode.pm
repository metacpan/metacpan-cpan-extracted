package Business::EDI::CodeList::ResultRepresentationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6077;}
my $usage       = 'B';

# 6077  Result representation code                              [B]
# Desc: Code specifying the representation of a result.
# Repr: an..3

my %code_hash = (
'1' => [ 'Numerical value range',
    'Numerical value range.' ],
'2' => [ 'Numerical value',
    'Numerical value.' ],
'3' => [ 'Coded value',
    'The result is a coded value.' ],
'4' => [ 'Alphanumeric value',
    'The result is expressed as an alphanumeric value.' ],
'5' => [ 'Narrative description',
    'The result is expressed as free text narrative.' ],
'6' => [ 'Time related value',
    'The result is expressed as a value related to time.' ],
);
sub get_codes { return \%code_hash; }

1;
