package Business::EDI::CodeList::SecuritySegmentPosition;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0138";}
my $usage       = 'B';  # guessed value

# 0138 Security segment position                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
