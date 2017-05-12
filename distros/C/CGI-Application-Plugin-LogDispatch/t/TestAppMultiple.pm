package TestAppMultiple;

use strict;

use CGI::Application;
use CGI::Application::Plugin::LogDispatch;
use DummyIOHandle;
@TestAppMultiple::ISA = qw(CGI::Application);

sub cgiapp_init {
    my $self = shift;

    $self->{__LOG_MESSAGES}->{HANDLE} = new DummyIOHandle;
    $self->{__LOG_MESSAGES}->{HANDLE2} = new DummyIOHandle;
    $self->log_config(
              LOG_DISPATCH_MODULES => [
                          {
                            module         => 'Log::Dispatch::Handle',
                            name           => 'handle',
                            min_level      => 'debug',
                            handle         => $self->{__LOG_MESSAGES}->{HANDLE},
                          },
                          {
                            module         => 'Log::Dispatch::Handle',
                            name           => 'handle2',
                            min_level      => 'info',
                            handle         => $self->{__LOG_MESSAGES}->{HANDLE2},
                          },
              ],
    );
}

sub setup {
    my $self = shift;
    $self->start_mode('test_mode');
    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;

    $self->log->debug('log debug');
    $self->log->info('log info');
    return "test_mode return value";
}

1;
