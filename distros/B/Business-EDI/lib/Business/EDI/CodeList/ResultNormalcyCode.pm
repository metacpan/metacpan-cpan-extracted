package Business::EDI::CodeList::ResultNormalcyCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6079;}
my $usage       = 'B';

# 6079  Result normalcy code                                    [B]
# Desc: Code specifying the degree of conformance to a
# standard.
# Repr: an..3

my %code_hash = (
'1' => [ 'Above high reference limit',
    'Above high reference limit.' ],
'2' => [ 'Below low reference limit',
    'Below low reference limit.' ],
'3' => [ 'Outside reference limits',
    'The result value is outside lower and upper reference limit.' ],
);
sub get_codes { return \%code_hash; }

1;
