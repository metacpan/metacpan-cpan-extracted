package Business::EDI::CodeList::ReturnablePackageFreightPaymentResponsibilityCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8395;}
my $usage       = 'B';

# 8395  Returnable package freight payment responsibility code  [B]
# Desc: Code specifying the responsibility for the freight
# payment for a returnable package.
# Repr: an..3

my %code_hash = (
'1' => [ 'Paid by customer',
    'The freight charges involved with returning of the packaging are to be paid by the customer.' ],
'2' => [ 'Free',
    'There is no charge for the freight of returning the packaging.' ],
'3' => [ 'Paid by supplier',
    'The responsibility for the freight for returning the packaging is to be paid by the supplier.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
