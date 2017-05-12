package Business::EDI::CodeList::SectionIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0081";}
my $usage       = 'B';

# 0081  Section identification
# Desc: Identification of the separation of sections of a message.
# Repr: a1

my %code_hash = (
'D' => [ 'Header/detail section separation',
    'To qualify the segment UNS, when separating the header from the detail section of a message.' ],
'S' => [ 'Detail/summary section separation',
    'To qualify the segment UNS, when separating the detail from the summary section of a message.' ],
);
sub get_codes { return \%code_hash; }

1;
