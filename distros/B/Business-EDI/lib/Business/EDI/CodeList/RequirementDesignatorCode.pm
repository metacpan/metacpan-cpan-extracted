package Business::EDI::CodeList::RequirementDesignatorCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7299;}
my $usage       = 'C';

# 7299  Requirement designator code                             [C]
# Desc: Code specifying the requirement designator.
# Repr: an..3

my %code_hash = (
'1' => [ 'Conditional',
    'Object is conditional.' ],
'2' => [ 'Mandatory',
    'Object is mandatory.' ],
'3' => [ 'Optional',
    'Object is optional.' ],
'4' => [ 'Floating',
    'Object is floating, not at a pre-defined position within a message.' ],
'5' => [ 'Not used',
    'Object is not used.' ],
'6' => [ 'Required',
    'Object is required.' ],
'7' => [ 'Advised',
    'Object use is advised.' ],
'8' => [ 'Not advised',
    'Object use is not advised.' ],
'9' => [ 'Dependent',
    'Object use is dependent upon an additional condition or criteria.' ],
'10' => [ 'Default value',
    'Value to be used when no other value is specified.' ],
'11' => [ 'Preferred',
    'The value is preferred.' ],
);
sub get_codes { return \%code_hash; }

1;
