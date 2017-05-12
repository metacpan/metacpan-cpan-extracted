package Business::EDI::CodeList::TestAdministrationMethodCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4419;}
my $usage       = 'B';

# 4419  Test administration method code                         [B]
# Desc: Code specifying the method of the administration of a
# test.
# Repr: an..3

my %code_hash = (
'1' => [ 'Oral',
    'The test was conducted verbally.' ],
'2' => [ 'Dermal',
    'The test is administrated via the skin.' ],
'3' => [ 'Inhalation',
    'The test is administrated via inhalation.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
