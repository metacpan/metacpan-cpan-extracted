package MyApp::CmdlineTest;

use strict;
use base qw(App::CLI::Command);
use constant options => ( "verbose" => "verbose" );

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->cmdline;
}

1;
