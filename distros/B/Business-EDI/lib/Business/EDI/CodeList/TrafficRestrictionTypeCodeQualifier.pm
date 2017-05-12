package Business::EDI::CodeList::TrafficRestrictionTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8035;}
my $usage       = 'I';

# 8035  Traffic restriction type code qualifier                 [I]
# Desc: Code qualifying a type of traffic restriction.
# Repr: an..3

my %code_hash = (
'1' => [ 'Required stopover or connection must occur at the board',
    'point Required stopover or connection from another station to a means of transport can only be made at the board point.' ],
'2' => [ 'Required stopover or connection must occur at the off point',
    'Required stopover or connection from another station to a means of transport can only be made at the off point.' ],
);
sub get_codes { return \%code_hash; }

1;
