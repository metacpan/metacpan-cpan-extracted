package Acme::Monkey::ClearScreen;

use Moose;
use Readonly;

Readonly my %OS_COMMANDS => (
    linux   => 'clear',
    MSWin32 => 'cls',
);

Readonly my $COMMAND => $OS_COMMANDS{$^O};

sub clear_screen {
    system( $COMMAND );
}

1;
