package Business::EDI::CodeList::ListParameterQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0575";}
my $usage       = 'B';

# 0575  List parameter qualifier
# Desc: Specification of the type of list parameter.
# Repr: an..3

my %code_hash = (
'ZZZ' => [ 'Mutually defined',
    'Mutually defined between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
