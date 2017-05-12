package Business::EDI::CodeList::RelationshipTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9141;}
my $usage       = 'C';

# 9141  Relationship type code qualifier                        [C]
# Desc: Code qualifying a type of relationship.
# Repr: an..3

my %code_hash = (
'1' => [ 'Beneficiary',
    'The relationship applies to a beneficiary.' ],
'2' => [ 'Dependency',
    'This value denotes that the associated relationship is that of a dependency.' ],
'3' => [ 'Project',
    'The relationship applies to a project.' ],
'4' => [ 'Activity',
    'The relationship applies to an activity.' ],
'5' => [ 'Account',
    'The relationship applies to an account.' ],
'6' => [ 'Entity',
    'The relationship applies to an entity.' ],
'7' => [ 'Patient',
    'The relationship applies to the patient.' ],
'8' => [ 'Reporting structure',
    'Relationship information applicable to a reporting structure.' ],
'9' => [ 'Statistical array',
    'The relationship applies to a statistical array.' ],
'10' => [ 'Service provider',
    'The relationship applies to the party who provides a service.' ],
'11' => [ 'Person',
    'The relationship applies to a person.' ],
'12' => [ 'Next of kin',
    'The relationship applies to a person who is next of kin.' ],
'13' => [ 'Association',
    'The relation applies to an association.' ],
);
sub get_codes { return \%code_hash; }

1;
