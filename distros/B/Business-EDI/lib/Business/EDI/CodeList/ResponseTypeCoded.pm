package Business::EDI::CodeList::ResponseTypeCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0503";}
my $usage       = 'B';

# 0503  Response type, coded
# Desc: Specification of the type of response expected from the
# recipient.
# Repr: an..3

my %code_hash = (
'1' => [ 'No acknowledgement required',
    'No AUTACK acknowledgement message expected.' ],
'2' => [ 'Acknowledgement required',
    'AUTACK acknowledgement message expected.' ],
);
sub get_codes { return \%code_hash; }

1;
