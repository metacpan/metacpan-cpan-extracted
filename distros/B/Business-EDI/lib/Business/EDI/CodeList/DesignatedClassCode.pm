package Business::EDI::CodeList::DesignatedClassCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1507;}
my $usage       = 'B';

# 1507  Designated class code                                   [B]
# Desc: Code specifying a designated class.
# Repr: an..3

my %code_hash = (
'1' => [ 'EDIFACT service data element code list',
    'The code list is classified as UN/ECE WP.4 service data element.' ],
'2' => [ 'WP.4 international code list',
    'The code list is classified as international and endorsed by WP.4.' ],
'3' => [ 'Non WP.4 code list',
    'The code list is classified as other and is not maintained by and not endorsed by WP.4.' ],
'4' => [ 'EDIFACT user data element code list',
    'The code list is classified as UN/ECE WP.4 user data element.' ],
);
sub get_codes { return \%code_hash; }

1;
