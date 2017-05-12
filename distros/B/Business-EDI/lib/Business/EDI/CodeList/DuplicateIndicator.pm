package Business::EDI::CodeList::DuplicateIndicator;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0325";}
my $usage       = 'B';

# 0325  Duplicate Indicator
# Desc: Indication that the structure is a duplicate of a previously
# sent structure.
# Repr: a1

my %code_hash = (
'D' => [ 'Duplicate',
    'A duplicate transfer.' ],
);
sub get_codes { return \%code_hash; }

1;
