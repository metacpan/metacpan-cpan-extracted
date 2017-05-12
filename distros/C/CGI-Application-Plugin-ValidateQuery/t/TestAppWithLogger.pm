package TestAppWithLogger;

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use base 'CGI::Application';
use CGI::Application::Plugin::ValidateQuery ':all';

{
    package TestLogger; 
    sub new { 
        my $class = shift;
        my $self = {};
        bless($self, $class);
    }
    sub debug     { my $self = shift; warn $_[0]; }
    sub info      { my $self = shift; warn $_[0]; }
    sub notice    { my $self = shift; warn $_[0]; }
    sub warning   { my $self = shift; warn $_[0]; }
    sub error     { my $self = shift; warn $_[0]; }
    sub critical  { my $self = shift; warn $_[0]; }
    sub alert     { my $self = shift; warn $_[0]; }
    sub emergency { my $self = shift; warn $_[0]; }

    1;
}

sub setup {
    my $self = shift; 
    $self->start_mode('test_mode');
    $self->run_modes(
            test_mode => 'test_mode',
            fail_mode => 'fail_mode'
            );
    $self->{logger} = TestLogger->new();
}

sub test_mode {
    my $self = shift;
    return "output";
}

sub fail_mode {
    my $self = shift;
    return "There has been an error!";
}

sub log {
    my $self = shift; 
    return $self->{logger};
}

1; 
