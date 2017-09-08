package BioX::Workflow::Command::Utils::Log;

use Moose::Role;
use namespace::autoclean;

use Log::Log4perl qw(:easy);
use DateTime;

has 'app_log' => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        Log::Log4perl->init( \ <<'EOT');
  log4perl.category = DEBUG, Screen
  log4perl.appender.Screen = \
      Log::Log4perl::Appender::ScreenColoredLevels
  log4perl.appender.Screen.layout = \
      Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = \
      [%d] %m %n
EOT
        return get_logger();
    },
    lazy => 1,
);

1;
