package Business::EDI::CodeList::RelatedCauseCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9625;}
my $usage       = 'I';

# 9625  Related cause code                                      [I]
# Desc: Code specifying a related cause.
# Repr: an..3

my %code_hash = (
'1' => [ 'Accident',
    'The related cause was an accident.' ],
);
sub get_codes { return \%code_hash; }

1;
