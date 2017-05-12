package Business::EDI::CodeList::ScopeOfSecurityApplicationCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0541";}
my $usage       = 'B';

# 0541  Scope of security application, coded
# Desc: Specification of the scope of application of the security
# service defined in the security header.
# Repr: an..3

my %code_hash = (
'1' => [ 'Security header and message body',
    'The current security header segment group and the object body itself, only. In this case no other security header or security trailer segment group shall be encompassed within this scope.' ],
'2' => [ 'From security header to security trailer',
    'From the current security header segment group, to the associated security trailer segment group. In this case the current security header segment group, the object body and all the other embedded security header and trailer segment groups shall be encompassed within this scope.' ],
'3' => [ 'Whole related message, package, group or interchange',
    'From the first character of the message, group, or interchange to the last character of the message, group or interchange.' ],
'4' => [ 'Interactive security information, security header and',
     ],
'message' => [ 'body',
    'Related security information, related interactive security header and interactive message body.' ],
'5' => [ 'Interactive security information plus security header to',
     ],
'security' => [ 'trailer',
    'Related security information, security header, all other embedded interactive security headers, interactive message body and all other embedded interactive security trailers.' ],
'6' => [ 'Entire batch message',
    'From and including, the first character ("U") of the message header segment (UNH) through to and including, the last character (segment  terminator) of the corresponding message trailer segment (UNT).' ],
'ZZZ' => [ 'Mutually agreed',
    'The scope of security application is defined in an agreement between sender and receiver.' ],
);
sub get_codes { return \%code_hash; }

1;
