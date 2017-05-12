package Business::EDI::CodeList::MembershipLevelCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7455;}
my $usage       = 'B';

# 7455  Membership level code qualifier                         [B]
# Desc: Code qualifying the level of membership.
# Repr: an..3

my %code_hash = (
'1' => [ 'Insurance',
    'Membership level is related to insurance.' ],
'2' => [ 'Superannuation',
    'Membership level is related to retirement benefits.' ],
);
sub get_codes { return \%code_hash; }

1;
