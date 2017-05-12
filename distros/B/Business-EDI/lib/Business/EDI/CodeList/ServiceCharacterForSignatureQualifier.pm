package Business::EDI::CodeList::ServiceCharacterForSignatureQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0551";}
my $usage       = 'B';

# 0551  Service character for signature qualifier
# Desc: Identification of the type of service character used when the
# signature was computed.
# Repr: an..3

my %code_hash = (
'1' => [ 'Segment terminator',
    'Specifies that this is the separator at the end of segments.' ],
'2' => [ 'Component data element separator',
    'Specifies that this is the separator between component data elements.' ],
'3' => [ 'Data element separator',
    'Specifies that this is the separator between data elements.' ],
'4' => [ 'Release character',
    'Specifies that this is the release character.' ],
'5' => [ 'Repetition separator',
    'Specifies that this is the separator between repeating data elements.' ],
);
sub get_codes { return \%code_hash; }

1;
