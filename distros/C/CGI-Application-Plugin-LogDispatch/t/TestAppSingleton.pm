package TestAppSingleton;

use strict;
use vars qw($HANDLE);

use DummyIOHandle;
BEGIN { $HANDLE = new DummyIOHandle; };
use CGI::Application;
use CGI::Application::Plugin::LogDispatch (
              LOG_DISPATCH_MODULES => [
                          {
                            module         => 'Log::Dispatch::Handle',
                            name           => 'handle',
                            min_level      => 'info',
                            handle         => $HANDLE,
                          },
              ],
);
@TestAppSingleton::ISA = qw(CGI::Application);

sub setup {
    my $self = shift;
    $self->start_mode('test_mode');
    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;

    $self->log->debug("log singleton debug");
    $self->log->info('log singleton info');
    return "test_mode return value";
}

package TestAppSingleton::Sub;

use strict;
use vars qw($HANDLE);

use DummyIOHandle;
BEGIN { $HANDLE = new DummyIOHandle; };
use CGI::Application;
use CGI::Application::Plugin::LogDispatch (
              LOG_DISPATCH_OPTIONS => {
                        callbacks => sub { my %h = @_; chomp $h{message}; return $h{message}.'EXTRA'; },
              },
              LOG_DISPATCH_MODULES => [
                          {
                            module         => 'Log::Dispatch::Handle',
                            name           => 'handle',
                            min_level      => 'info',
                            handle         => $HANDLE,
                          },
              ],
);
@TestAppSingleton::Sub::ISA = qw(TestAppSingleton);

package TestAppSingleton::Sub2;

use strict;
use vars qw($HANDLE);

use CGI::Application;
@TestAppSingleton::Sub2::ISA = qw(TestAppSingleton);

sub test_mode {
    my $self = shift;

    $self->log->info('log subsingleton info');
    return "test_mode return value";
}

1;
