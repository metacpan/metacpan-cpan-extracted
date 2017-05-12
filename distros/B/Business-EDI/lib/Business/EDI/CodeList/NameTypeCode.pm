package Business::EDI::CodeList::NameTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3403;}
my $usage       = 'B';

# 3403  Name type code                                          [B]
# Desc: Code specifying the type of name.
# Repr: an..3

my %code_hash = (
'1' => [ 'Maiden name',
    'Family name of person before marriage.' ],
'2' => [ 'Marital name',
    'Marital name.' ],
'3' => [ 'Used name',
    'Name used to identify an entity.' ],
'4' => [ 'Call name',
    'Name used to identify a person in a particular context.' ],
'5' => [ 'Official name',
    'The name as registered by official authorities.' ],
'6' => [ 'Franchise name',
    'Name of an entity authorized by a company to sell its goods or services in a particular way.' ],
'7' => [ 'Pseudonym',
    'A fictitious name adopted.' ],
'8' => [ 'Alias',
    'An assumed name.' ],
'9' => [ 'Company name',
    'The name of a company.' ],
'10' => [ 'Organisation name',
    'Name of an organisation.' ],
'11' => [ 'Party acronym',
    'A name formed from the initial letters of other words.' ],
'12' => [ 'Doing business as',
    'To specify the name under which the party is conducting business.' ],
'13' => [ 'Brand name',
    'A name legally registered as a trademark.' ],
'14' => [ 'Primary name',
    'Identifies the name of first importance.' ],
);
sub get_codes { return \%code_hash; }

1;
