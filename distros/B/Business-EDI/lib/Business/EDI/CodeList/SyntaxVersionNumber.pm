package Business::EDI::CodeList::SyntaxVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0002";}
my $usage       = 'B';

# 0002  Syntax version number
# Desc: Version number of the syntax.
# Repr: an1

my %code_hash = (
'1' => [ 'Version 1',
    'ISO 9735:1988.' ],
'2' => [ 'Version 2',
    'ISO 9735:1990.' ],
'3' => [ 'Version 3',
    'ISO 9735 Amendment 1:1992.' ],
'4' => [ 'Version 4',
    'ISO 9735:1998.' ],
);
sub get_codes { return \%code_hash; }

1;
