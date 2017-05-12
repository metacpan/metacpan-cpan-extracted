package Business::EDI::CodeList::SegmentPositionInMessageBody;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0096";}
my $usage       = 'B';  # guessed value

# 0096 Segment position in message body                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
