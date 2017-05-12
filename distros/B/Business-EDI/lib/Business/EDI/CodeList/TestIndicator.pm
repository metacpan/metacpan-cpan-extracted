package Business::EDI::CodeList::TestIndicator;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0035";}
my $usage       = 'B';

# 0035  Test indicator
# Desc: Indication that the structural level containing the test
# indicator is a test.
# Repr: n1

my %code_hash = (
'1' => [ 'Interchange is a test',
    'Indicates that the interchange is a test.' ],
'2' => [ 'Syntax only test',
    'Test only syntax of structure.' ],
'3' => [ 'Echo request',
    'To be returned without change, except for this data element to have the value 4.' ],
'4' => [ 'Echo response',
    'Returned without change except for this data element changing from 3 to 4.' ],
);
sub get_codes { return \%code_hash; }

1;
