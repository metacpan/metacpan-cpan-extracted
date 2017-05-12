package Business::EDI::CodeList::IntracompanyPaymentIndicatorCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4463;}
my $usage       = 'B';

# 4463  Intra-company payment indicator code                    [B]
# Desc: Code indicating an intra-company payment.
# Repr: an..3

my %code_hash = (
'1' => [ 'Intra-company payment',
    'Moving funds between accounts, where the account owner is one company or belonging to a group of companies.' ],
);
sub get_codes { return \%code_hash; }

1;
