package Business::EDI::CodeList::AcknowledgementRequest;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0031";}
my $usage       = 'B';

# 0031  Acknowledgement request
# Desc: Code requesting acknowledgement for the interchange.
# Repr: n1

my %code_hash = (
'1' => [ 'Acknowledgement requested',
    'Acknowledgement is requested.' ],
'2' => [ 'Indication of receipt',
    'Confirmation of receipt only.' ],
);
sub get_codes { return \%code_hash; }

1;
