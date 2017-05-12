package Business::EDI::CodeList::PaymentChannelCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4435;}
my $usage       = 'B';

# 4435  Payment channel code                                    [B]
# Desc: Code specifying the payment channel.
# Repr: an..3

my %code_hash = (
'1' => [ 'Ordinary post',
    'The payment shall be/has been made via ordinary post.' ],
'2' => [ 'Air mail',
    'The payment shall be/has been made via air mail.' ],
'3' => [ 'Telegraph',
    'The payment shall be/has been made via telegraph.' ],
'4' => [ 'Telex',
    'The payment shall be/has been made via telex.' ],
'5' => [ 'S.W.I.F.T.',
    'Society for Worldwide Interbank Financial Telecommunications s.c.' ],
'6' => [ 'Other transmission networks',
    'The payment shall be/has been made via other transmission networks.' ],
'7' => [ 'Networks not defined',
    'The payment shall be/has been made via not defined networks.' ],
'8' => [ 'Fedwire',
    'The payment shall be/has been made via Fedwire.' ],
'9' => [ 'Personal (face-to-face)',
    'Indicates that payment should be made by the bank to the beneficiary or his identified agent, in person.' ],
'10' => [ 'Registered air mail',
    'The payment shall be/has been made via registered air mail.' ],
'11' => [ 'Registered mail',
    'The payment shall be/has been made via registered mail.' ],
'12' => [ 'Courier',
    'Public courier service.' ],
'13' => [ 'Messenger',
    'Private messenger service.' ],
'14' => [ 'National ACH',
    'Nation wide clearing house for automated payment.' ],
'15' => [ 'Other ACH',
    'Other than nation wide clearing house system.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
