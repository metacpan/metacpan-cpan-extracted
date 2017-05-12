package Business::EDI::CodeList::MessageRelationCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0565";}
my $usage       = 'B';

# 0565  Message relation, coded
# Desc: Relationship with another message, past or future.
# Repr: an..3

my %code_hash = (
'1' => [ 'No relation',
    'The message is initial.' ],
'2' => [ 'Response',
    'The message is a response message.' ],
'3' => [ 'Response requested',
    'The message requests an answer.' ],
);
sub get_codes { return \%code_hash; }

1;
