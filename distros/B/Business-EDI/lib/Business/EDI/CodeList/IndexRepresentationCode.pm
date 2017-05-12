package Business::EDI::CodeList::IndexRepresentationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5039;}
my $usage       = 'B';

# 5039  Index representation code                               [B]
# Desc: Code specifying the representation of an index value.
# Repr: an..3

my %code_hash = (
'1' => [ 'Percentage',
    'The index value is represented in a proportion.' ],
);
sub get_codes { return \%code_hash; }

1;
