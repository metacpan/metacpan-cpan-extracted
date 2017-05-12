package Business::EDI::CodeList::OrganisationalClassNameCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3083;}
my $usage       = 'B';

# 3083  Organisational class name code                          [B]
# Desc: Code specifying a class of organisation.
# Repr: an..17

my %code_hash = (
'1' => [ 'Internal medicine',
    'Medical speciality concerned with diagnosis and treatment of diseases and conditions, which normally do not require surgery.' ],
'2' => [ 'Surgery',
    'Medical speciality concerned with diagnosis and treatment of diseases and conditions, which normally do require surgery.' ],
'3' => [ 'Psychiatry',
    'Medical speciality concerned with diagnosis and treatment of diseases and conditions of the mind.' ],
'4' => [ 'General medicine',
    'Medical speciality covering all general areas of medicine.' ],
);
sub get_codes { return \%code_hash; }

1;
