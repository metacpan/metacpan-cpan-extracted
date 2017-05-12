package Business::EDI::CodeList::NameOriginalAlphabetCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3295;}
my $usage       = 'B';

# 3295  Name original alphabet code                             [B]
# Desc: Code specifying the alphabet originally used to
# represent a name.
# Repr: an..3

my %code_hash = (
'1' => [ 'Greek characters',
    'Greek characters.' ],
);
sub get_codes { return \%code_hash; }

1;
