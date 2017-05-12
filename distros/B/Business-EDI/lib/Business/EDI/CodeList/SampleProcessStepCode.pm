package Business::EDI::CodeList::SampleProcessStepCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4407;}
my $usage       = 'B';

# 4407  Sample process step code                                [B]
# Desc: Code specifying the step in the sample process.
# Repr: an..3

my %code_hash = (
'1' => [ 'In process specimen',
    'The product was in development.' ],
'2' => [ 'Finished product specimen',
    'The product had completed development.' ],
);
sub get_codes { return \%code_hash; }

1;
