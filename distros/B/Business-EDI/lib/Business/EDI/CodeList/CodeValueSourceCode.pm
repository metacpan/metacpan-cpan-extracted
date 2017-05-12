package Business::EDI::CodeList::CodeValueSourceCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9453;}
my $usage       = 'B';

# 9453  Code value source code                                  [B]
# Desc: Code specifying the source of a code value.
# Repr: an..3

my %code_hash = (
'1' => [ 'External',
    'The code value is from an external code list.' ],
'2' => [ 'Standard',
    'The code value is from the code list specified within the standard.' ],
'3' => [ 'Non-published',
    'The code value is taken from a non-published code list.' ],
);
sub get_codes { return \%code_hash; }

1;
