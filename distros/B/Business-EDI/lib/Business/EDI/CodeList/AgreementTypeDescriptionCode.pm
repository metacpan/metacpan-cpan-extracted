package Business::EDI::CodeList::AgreementTypeDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7433;}
my $usage       = 'B';

# 7433  Agreement type description code                         [B]
# Desc: Code specifying the type of agreement.
# Repr: an..3

my %code_hash = (
'1' => [ 'User group agreed',
    'The description for the type of agreement is agreed within the user group.' ],
'2' => [ 'Bilateral agreement between countries',
    'The agreement is bilaterally defined by countries.' ],
'3' => [ 'Unknown agreement',
    'The type of agreement is not known.' ],
'4' => [ 'European Union agreement',
    'The agreement is multilaterally defined by the countries of the European Union.' ],
'5' => [ 'National agreement',
    'The agreement is defined at the national level.' ],
);
sub get_codes { return \%code_hash; }

1;
