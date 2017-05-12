package Business::EDI::CodeList::MembershipCategoryDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7451;}
my $usage       = 'B';

# 7451  Membership category description code                    [B]
# Desc: Code specifying a membership category.
# Repr: an..4

my %code_hash = (
'1' => [ 'Family',
    'A group of persons belonging to the same family.' ],
'2' => [ 'Unaccompanied person',
    'Person who is not accompanied.' ],
'3' => [ 'Senior person',
    'Senior person.' ],
'4' => [ 'Child',
    'Child.' ],
);
sub get_codes { return \%code_hash; }

1;
