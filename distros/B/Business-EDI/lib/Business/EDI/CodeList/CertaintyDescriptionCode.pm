package Business::EDI::CodeList::CertaintyDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4049;}
my $usage       = 'C';

# 4049  Certainty description code                              [C]
# Desc: Code specifying a certainty.
# Repr: an..3

my %code_hash = (
'1' => [ 'Connection guaranteed',
    'The connection is guaranteed under any circumstances.' ],
'2' => [ 'Connection normally guaranteed',
    'The connection is normally guaranteed, although the connection time available is shorter than the location connection time.' ],
'3' => [ 'Connection not guaranteed',
    'The connetion is not guaranteed, although the connection time available is longer than the location connection time.' ],
);
sub get_codes { return \%code_hash; }

1;
