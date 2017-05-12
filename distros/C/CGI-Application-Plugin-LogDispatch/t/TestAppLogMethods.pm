package TestAppLogMethods;

use strict;

use CGI::Application;
use CGI::Application::Plugin::LogDispatch;
use DummyIOHandle;
@TestAppLogMethods::ISA = qw(CGI::Application);

sub cgiapp_init {
    my $self = shift;

    $self->{__LOG_MESSAGES}->{HANDLE} = new DummyIOHandle;
    $self->log_config(
              LOG_DISPATCH_MODULES => [
                          {
                            module         => 'Log::Dispatch::Handle',
                            name           => 'handle',
                            min_level      => 'debug',
                            handle         => $self->{__LOG_MESSAGES}->{HANDLE},
                            append_newline => 1,
                          },
              ],
              LOG_METHOD_EXECUTION => [__PACKAGE__],
    );
}

sub setup {
    my $self = shift;
    $self->start_mode('test_mode');
    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;

    $self->log->debug("log debug");
    my $value = other_method('param1', 'param2');
    return "test_mode return value";
}

sub other_method {
  return "other_method return value";
}

1;
