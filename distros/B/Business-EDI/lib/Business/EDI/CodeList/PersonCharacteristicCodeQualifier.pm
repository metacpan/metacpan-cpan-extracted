package Business::EDI::CodeList::PersonCharacteristicCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3289;}
my $usage       = 'B';

# 3289  Person characteristic code qualifier                    [B]
# Desc: Code qualifying a type of characteristic of a person.
# Repr: an..3

my %code_hash = (
'1' => [ 'Skin colour',
    'The skin colour of an individual.' ],
);
sub get_codes { return \%code_hash; }

1;
