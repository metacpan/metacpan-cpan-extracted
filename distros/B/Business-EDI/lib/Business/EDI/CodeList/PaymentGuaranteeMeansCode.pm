package Business::EDI::CodeList::PaymentGuaranteeMeansCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4431;}
my $usage       = 'B';

# 4431  Payment guarantee means code                            [B]
# Desc: Code specifying the means of payment guarantee.
# Repr: an..3

my %code_hash = (
'1' => [ 'Factor guarantee',
    'Payment of an invoice is made by a factor under the guarantee he issued to seller or to another factor.' ],
'10' => [ 'Bank guarantee',
    'A bank has agreed to stand as guarantor to ensure that payment is made.' ],
'11' => [ 'Public authority guarantee',
    'A public authority has agreed to stand as guarantor to ensure that payment is made.' ],
'12' => [ 'Third party guarantee',
    'The party who has agreed to stand as guarantor to ensure that payment is made is neither the payee nor the payer.' ],
'13' => [ 'Standby letter of credit',
    'The guarantee of payment is in the form of a standby letter of credit.' ],
'14' => [ 'No guarantee',
    'No guarantee of payment has been made or is available.' ],
'20' => [ 'Goods as security',
    'The payer has provided possession of, or title in goods, as security against payment.' ],
'21' => [ 'Business as security',
    'The payer has provided title in, or a lien over a business whose assets may be sold or sequestered, as security against payment.' ],
'23' => [ 'Warrant or similar (warehouse receipts)',
    'The payer has provided a warrant or warehouse receipts for goods or property to be held or used as security against payment.' ],
'24' => [ 'Mortgage',
    'The payer has provided a mortgage as security against payment.' ],
'45' => [ 'Insurance certificate',
    'A certificate of insurance has been provided as a guarantee of eventual payment.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
