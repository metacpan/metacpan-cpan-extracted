package Business::EDI::CodeList::RecipientReferencepasswordQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0025";}
my $usage       = 'B';

# 0025  Recipient reference/password qualifier
# Desc: Qualifier for the recipient's reference or password.
# Repr: an2

my %code_hash = (
'AA' => [ 'Reference',
    "Recipient's reference/password is a reference." ],
'BB' => [ 'Password',
    "Recipient's reference/password is a password." ],
);
sub get_codes { return \%code_hash; }

1;
