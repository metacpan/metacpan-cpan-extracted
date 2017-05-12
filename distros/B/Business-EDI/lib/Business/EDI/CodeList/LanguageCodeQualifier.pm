package Business::EDI::CodeList::LanguageCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3455;}
my $usage       = 'C';

# 3455  Language code qualifier                                 [C]
# Desc: Code qualifying a language.
# Repr: an..3

my %code_hash = (
'1' => [ 'Language normally used',
    'The language normally used.' ],
'2' => [ 'Language understood',
    'Language understood by the person.' ],
'3' => [ 'Spoken language',
    'Language that can be spoken by a person.' ],
'4' => [ 'Written language',
    'Language that can be written by the person.' ],
'5' => [ 'Read language',
    'Language that can be read by the person.' ],
'6' => [ 'For all types of communication',
    'Language used for all types of communications.' ],
'7' => [ 'Native language',
    'Language first spoken by the person.' ],
);
sub get_codes { return \%code_hash; }

1;
