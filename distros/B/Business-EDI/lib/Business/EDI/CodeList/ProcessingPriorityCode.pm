package Business::EDI::CodeList::ProcessingPriorityCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0029";}
my $usage       = 'B';

# 0029  Processing priority code
# Desc: Code determined by the sender requesting processing priority
# for the interchange.
# Repr: a1

my %code_hash = (
'A' => [ 'Highest priority',
    'Requested processing priority is the highest.' ],
);
sub get_codes { return \%code_hash; }

1;
