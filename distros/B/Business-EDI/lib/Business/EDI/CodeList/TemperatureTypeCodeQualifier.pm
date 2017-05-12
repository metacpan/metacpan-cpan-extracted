package Business::EDI::CodeList::TemperatureTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6245;}
my $usage       = 'B';

# 6245  Temperature type code qualifier                         [B]
# Desc: Code qualifying the type of a temperature.
# Repr: an..3

my %code_hash = (
'1' => [ 'Storage temperature',
    '[6240] The temperature at which the cargo is to be kept while it is in storage.' ],
'2' => [ 'Transport temperature',
    '[6242] The temperature at which cargo is to be kept while it is under transport.' ],
'3' => [ 'Cargo operating temperature',
    'The temperature at which cargo is to be kept during cargo handling.' ],
'4' => [ 'Transport emergency temperature',
    'The temperature at which emergency procedures apply for the disposal of temperature-controlled goods.' ],
'5' => [ 'Transport control temperature',
    'The maximum temperature at which certain products can be safely transported.' ],
'6' => [ 'Boiling point',
    'The  temperature at which a liquid begins to boil.' ],
'7' => [ 'Temperature, recorded',
    'The recorded temperature.' ],
);
sub get_codes { return \%code_hash; }

1;
