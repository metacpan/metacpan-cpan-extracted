package Business::EDI::CodeList::ReferenceQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0813";}
my $usage       = 'B';

# 0813  Reference qualifier
# Desc: Code giving specific meaning to a reference identification
# number.
# Repr: an..3

my %code_hash = (
'1' => [ 'Object identification number',
    'Identification number assigned to an object.' ],
'2' => [ 'Application message reference number',
    'Reference number assigned to a message by a computer application.' ],
);
sub get_codes { return \%code_hash; }

1;
