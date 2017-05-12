package Business::EDI::CodeList::ComputerEnvironmentDetailsCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1501;}
my $usage       = 'B';

# 1501  Computer environment details code qualifier             [B]
# Desc: Code qualifying computer environment details.
# Repr: an..3

my %code_hash = (
'1' => [ 'Hardware platform',
    'Code to identify the type of hardware installed in a computer environment e.g. PC, Mac, UNIX-Workstation, Mini, Mainframe.' ],
'2' => [ 'Operating system',
    'Code to identify the operating system, like DOS, VMS, etc. used in a computer environment.' ],
'3' => [ 'Application software',
    'Code to identify an application software, like AutoCad, WinWord, etc. used in a computer environment.' ],
'4' => [ 'Network',
    'Code to identify a network like Ethernet, Token Ring, etc. implemented in a computer environment.' ],
'5' => [ 'Sending system',
    'Code to identify the system, which acts as a sending system in an interchange.' ],
'6' => [ 'File generating software',
    'Software used to generate a file.' ],
'7' => [ 'File compression software',
    'Software used for the compression of a file.' ],
'8' => [ 'File compression method',
    'Method used for the compression of a file.' ],
);
sub get_codes { return \%code_hash; }

1;
