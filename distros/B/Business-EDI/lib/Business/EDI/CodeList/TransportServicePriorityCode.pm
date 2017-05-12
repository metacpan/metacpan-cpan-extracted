package Business::EDI::CodeList::TransportServicePriorityCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4219;}
my $usage       = 'B';

# 4219  Transport service priority code                         [B]
# Desc: Code specifying the priority of a transport service.
# Repr: an..3

my %code_hash = (
'1' => [ 'Express',
    'Express treatment (if by rail, legal express regime for parcels transport).' ],
'2' => [ 'High speed',
    'Transport under legal international rail convention (CIM) concluded between rail organizations and based on fast routing and specified timetables.' ],
'3' => [ 'Normal speed',
    'Transport under legal international rail convention (CIM) concluded between rail organizations.' ],
'4' => [ 'Post service',
    'Transport under conditions specified by UPU (Universal Postal Union) and Rail organizations (parcels transport only).' ],
);
sub get_codes { return \%code_hash; }

1;
