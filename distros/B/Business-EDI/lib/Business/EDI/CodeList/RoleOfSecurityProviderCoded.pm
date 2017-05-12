package Business::EDI::CodeList::RoleOfSecurityProviderCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0509";}
my $usage       = 'B';

# 0509  Role of security provider, coded
# Desc: Identification of the role of the security provider in
# relation to the secured item.
# Repr: an..3

my %code_hash = (
'1' => [ 'Issuer',
    'The security provider is the rightful issuer of the signed document.' ],
'2' => [ 'Notary',
    'The security provider acts as a notary in relation to the signed document.' ],
'3' => [ 'Contracting party',
    'The security provider endorses the content of the signed document.' ],
'4' => [ 'Witness',
    'The security provider is a witness, but is not responsible for  the content of the signed document.' ],
'ZZZ' => [ 'Mutually agreed',
    'Mutually agreed between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
