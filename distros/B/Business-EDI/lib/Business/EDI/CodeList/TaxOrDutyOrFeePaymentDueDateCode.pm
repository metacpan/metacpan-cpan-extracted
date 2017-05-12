package Business::EDI::CodeList::TaxOrDutyOrFeePaymentDueDateCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5307;}
my $usage       = 'B';

# 5307  Tax or duty or fee payment due date code                [B]
# Desc: A code indicating when the duty, tax, or fee payment
# will be due.
# Repr: an..3

my %code_hash = (
'1' => [ 'Duty, tax or fee payment due on invoice payment date',
    'Duty, tax or fee payment is due on the date when the invoice is paid.' ],
'2' => [ 'Duty, tax or fee payment due on invoice issue date',
    'Duty, tax or fee payment is due on the date when the invoice is issued.' ],
);
sub get_codes { return \%code_hash; }

1;
