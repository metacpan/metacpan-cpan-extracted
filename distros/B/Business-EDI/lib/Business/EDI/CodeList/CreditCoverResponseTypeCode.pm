package Business::EDI::CodeList::CreditCoverResponseTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4507;}
my $usage       = 'B';

# 4507  Credit cover response type code                         [B]
# Desc: Code specifying the type of response to a request for
# credit cover.
# Repr: an..3

my %code_hash = (
'1' => [ 'Preliminary assessment',
    'A preliminary assessment without formal approval or commitment.' ],
'2' => [ 'Approved',
    'The limit request has been approved.' ],
'3' => [ 'Not approved',
    'The limit request has not been approved.' ],
'4' => [ 'Conditional approval',
    'Approval subject to conditions as specified.' ],
'5' => [ 'Partly approved',
    'Partly approved as specified.' ],
'6' => [ 'Still investigating',
    'The limit request is still under investigation.' ],
'7' => [ 'Open new account only',
    'Buyer account has been opened without an approved limit.' ],
'8' => [ 'Cancellation',
    'The existing limit has been cancelled.' ],
'9' => [ 'Reduction',
    'Credit limit is reduced.' ],
'10' => [ 'Change of name and/or address',
    'The name and/or address of the buyer has changed.' ],
'11' => [ "Close buyer's account",
    "The buyer's account is to be closed." ],
);
sub get_codes { return \%code_hash; }

1;
