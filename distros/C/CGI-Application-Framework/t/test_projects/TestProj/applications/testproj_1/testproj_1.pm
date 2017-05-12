package testproj_1;

use strict;    # always a good idea to include these in your
use warnings;  # modules

use lib 't';

use base qw ( TestProj );


# ------------------------------------------------------------------

sub setup {
    my $self = shift;

    $self->run_modes([ qw(testproj_start) ]);
    $self->SUPER::setup();
}

sub testproj_start {
    my $self = shift;

    my $stash = $self->stash;

    my $output = $self->template->fill({
        var1 => 'my_value_one',
        var2 => 'my_value_two',
        var3 => 'my_value_three',
    });

    $output = $$output if ref $output eq 'SCALAR';

    $stash->{'Template_Output'} = $output;
    $stash->{'Seen_Run_Mode'}{'testproj_start'} = 1;
    $stash->{'Final_Run_Mode'}                = 'testproj_start';
    '';
}

1;


