package TestAppNewline;

use strict;

use CGI::Application;
use CGI::Application::Plugin::LogDispatch;
use DummyIOHandle;
@TestAppNewline::ISA = qw(CGI::Application);

sub cgiapp_init {
    my $self = shift;

    $self->{__LOG_MESSAGES}->{HANDLE} = new DummyIOHandle;
    $self->{__LOG_MESSAGES}->{HANDLE_APPEND} = new DummyIOHandle;
    $self->log_config(
#              LOG_DISPATCH_OPTIONS => {
#                        callbacks => sub { my %h = @_; chomp $h{message}; return $h{message}.$/; },
#              },
              LOG_DISPATCH_MODULES => [
                          {
                            module         => 'Log::Dispatch::Handle',
                            name           => 'handle',
                            min_level      => 'debug',
                            handle         => $self->{__LOG_MESSAGES}->{HANDLE},
                          },
                          {
                            module         => 'Log::Dispatch::Handle',
                            append_newline => 1,
                            name           => 'handle_append',
                            min_level      => 'info',
                            handle         => $self->{__LOG_MESSAGES}->{HANDLE_APPEND},
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

    $self->log->debug("log debug1");
    $self->log->debug("log debug2$/");
    $self->log->info('log info1');
    $self->log->info('log info2');
    return "test_mode return value";
}

1;
