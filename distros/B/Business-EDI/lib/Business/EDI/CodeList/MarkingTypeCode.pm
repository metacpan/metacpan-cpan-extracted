package Business::EDI::CodeList::MarkingTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7511;}
my $usage       = 'B';

# 7511  Marking type code                                       [B]
# Desc: Code specifying the type of marking.
# Repr: an..3

my %code_hash = (
'1' => [ 'Not marked with an EAN.UCC system code',
    'Indication that the package is not marked with an EAN.UCC (International Article Numbering.Uniform Code Council) system code.' ],
);
sub get_codes { return \%code_hash; }

1;
