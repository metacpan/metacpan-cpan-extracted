package Business::EDI::CodeList::CreditCoverRequestTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4505;}
my $usage       = 'B';

# 4505  Credit cover request type code                          [B]
# Desc: Code specifying the type of request for credit cover.
# Repr: an..3

my %code_hash = (
'1' => [ 'Multi-currency credit cover',
    'Invoices in currencies other than the currency of the credit cover are expected.' ],
'2' => [ 'Request new limit',
    'Seller requests new limit.' ],
'3' => [ 'Request increased limit',
    'Seller requests increase of existing limit.' ],
'4' => [ 'Request for preliminary assessment',
    'Request for information to be used during negotiation with prospective clients (sellers).' ],
'5' => [ 'Request for new account only',
    'Request for opening new account only.' ],
'6' => [ 'Cancellation',
    'Request to cancel an existing credit cover.' ],
'7' => [ 'Reduction',
    'Request to reduce an existing credit cover.' ],
'8' => [ 'Prolongation of credit cover',
    'Request to prolong an existing credit cover.' ],
);
sub get_codes { return \%code_hash; }

1;
