use strict;
use warnings;
use Test::More;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

my $NAME;
BEGIN {
    $NAME = 'ipchgmon';
    use_ok ('App::' . $NAME); # Modulino should exist
}

# my $invoke = "perl $RealBin/../lib/App/$NAME.pm";
my $invoke = "$^X $RealBin/../bin/$NAME";

subtest 'Help gives sane output' => sub {
    my $rtn = qx($invoke --help 2>&1);
    help_tests($rtn);
};

subtest 'Man gives sane output' => sub {
    my $rtn = qx($invoke --man 2>&1);
    like $rtn, qr/NAME/m,        'NAME found';
    like $rtn, qr/SYNOPSIS/m,    'SYNOPSIS found';
    like $rtn, qr/DESCRIPTION/m, 'DESCRIPTION found';
    like $rtn, qr/ARGUMENTS/m,   'ARGUMENTS found';
    like $rtn, qr/OPTIONS/m,     'OPTIONS found';
    like $rtn, qr/COPYRIGHT/m,   'COPYRIGHT found';
    unlike $rtn, qr/Usage:/m, 'Usage not found (should be in help, not man)';
    unlike $rtn, qr/=pod/m, 'Pod directive missing - if it appears, you may need to install perldoc';
};

subtest 'Versions gives sane output' => sub {
    my $rtn = qx($invoke --versions 2>&1);
    like $rtn, qr/Pod::Usage/m,                     'Pod::Usage found';
    like $rtn, qr/Getopt::Long/m,                   'Getopt::Long found';
    like $rtn, qr/Data::Dumper/m,                   'Data::Dumper found';
    like $rtn, qr/Data::Validate::IP/m,             'Data::Validate::IP found';
    like $rtn, qr/Data::Validate::Email/m,          'Data::Validate::Email found';
    like $rtn, qr/DateTime/m,                       'DateTime found';
    like $rtn, qr/DateTime::Format::Strptime/m,     'DateTime::Format::Strptime found';
    like $rtn, qr/Email::Sender::Transport::SMTP/m, 'Email::Sender::Transport::SMTP found';
    like $rtn, qr/Email::Stuffer/m,                 'Email::Stuffer found';
    like $rtn, qr/LWP::Online/m,                    'LWP::Online found';
    like $rtn, qr/LWP::UserAgent/m,                 'LWP::UserAgent found';
    like $rtn, qr/Socket/m,                         'Socket found';
    like $rtn, qr/Text::CSV/m,                      'Text::CSV found';
    like $rtn, qr/strict/m,                         'strict found';
    like $rtn, qr/Perl/m,                           'Perl found';
    like $rtn, qr/OS/m,                             'OS found';
    like $rtn, qr/$NAME.pm/m,                       'Modulino name found';
    unlike $rtn, qr/=pod/m, 'Pod directive missing - if it appears, you may need to install perldoc';
};

subtest 'Nonsense gives help' => sub {
    my $rtn = qx($invoke --fubar 2>&1);
    help_tests($rtn);
};

done_testing;

sub help_tests {
    my $rtn = shift;
    like $rtn, qr/Usage:/m,     'Usage found';
    like $rtn, qr/Arguments:/m, 'Arguments found';
    like $rtn, qr/Options:/m,   'Options found';
    like $rtn, qr/--help/m,     'Help found';
    like $rtn, qr/--man/m,      'Man found';
    like $rtn, qr/--versions/m, 'Versions found';
    unlike $rtn, qr/NAME/m, 'NAME missing (should be in man, not help)';
    unlike $rtn, qr/=pod/m, 'Pod directive missing - if it appears, you may need to install perldoc';
}