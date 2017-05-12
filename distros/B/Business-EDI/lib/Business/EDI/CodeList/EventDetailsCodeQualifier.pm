package Business::EDI::CodeList::EventDetailsCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9635;}
my $usage       = 'B';

# 9635  Event details code qualifier                            [B]
# Desc: Code qualifying the event details.
# Repr: an..3

my %code_hash = (
'1' => [ 'Claim',
    'The event is a claim.' ],
'2' => [ 'Bankruptcy case',
    'The event is a bankruptcy case.' ],
);
sub get_codes { return \%code_hash; }

1;
