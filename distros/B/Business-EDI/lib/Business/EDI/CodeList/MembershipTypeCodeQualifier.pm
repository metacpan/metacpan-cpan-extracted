package Business::EDI::CodeList::MembershipTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7449;}
my $usage       = 'B';

# 7449  Membership type code qualifier                          [B]
# Desc: Code qualifying the type of membership.
# Repr: an..3

my %code_hash = (
'1' => [ 'Life insurance',
    'Member of a life insurance scheme.' ],
'2' => [ 'Superannuation',
    'For retirement benefits, including pension, purposes.' ],
'ZZZ' => [ 'Mutually defined',
    'Mutually defined member qualifier.' ],
);
sub get_codes { return \%code_hash; }

1;
