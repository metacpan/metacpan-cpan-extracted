package Datahub::Factory::CLI;

use strict;
use warnings;

use Datahub::Factory::Sane;

use Datahub::Factory;
use Log::Any::Adapter;
use Log::Log4perl;
use namespace::clean;
use DateTime;


use parent qw(App::Cmd);

sub default_command {'commands'}

sub plugin_search_path {'Datahub::Factory::Command'}

sub global_opt_spec {
    return (
      ['log_level|L:i', "Log level (1 - 3) with 3 the chattiest."],
      ['log_output|O:s', "Log output handler: STDERR, STDOUT or the STATISTICS log file."]
    );
}

sub default_log4perl_config {
    my ($level, $appender) = @_;
    if (!defined($level)) {
      $level = 'WARN';
    }
    if (!defined($appender)) {
      $appender = 'STDERR';
    }

    my $date = DateTime->now()->dmy();
    my $import_log_header = sprintf('DATAHUB FACTORY IMPORT LOG FOR %s', DateTime->now()->datetime());

    my $config = <<EOF;
log4perl.rootLogger=$level,$appender
log4perl.category.datahub=$level,$appender

log4perl.appender.STDOUT=Log::Log4perl::Appender::Screen
log4perl.appender.STDOUT.stderr=0
log4perl.appender.STDOUT.utf8=1
log4perl.appender.STDOUT.layout=PatternLayout
log4perl.appender.STDOUT.layout.ConversionPattern=%d [%P] - %p : %m%n

log4perl.appender.STDERR=Log::Log4perl::Appender::Screen
log4perl.appender.STDERR.stderr=1
log4perl.appender.STDERR.utf8=1
log4perl.appender.STDERR.layout=PatternLayout
log4perl.appender.STDERR.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

log4perl.appender.STATISTICS=Log::Log4perl::Appender::File
log4perl.appender.STATISTICS.filename=logs/import_$date.log
log4perl.appender.STATISTICS.utf8=1
log4perl.appender.STATISTICS.mkpath=1
log4perl.appender.STATISTICS.header_text=$import_log_header
log4perl.appender.STATISTICS.layout=PatternLayout
log4perl.appender.STATISTICS.layout.ConversionPattern=%d [%P] - %p : %m%n

EOF
    return \$config;
}

sub setup_logging {
  my ($logging, $appender) = @_;
  my %LEVELS = (1 => 'WARN', 2 => 'INFO', 3 => 'DEBUG');
  my $level  = $LEVELS{$logging};

  Log::Log4perl::init(default_log4perl_config($level, $appender));
  Log::Any::Adapter->set('Log4perl');

  if ($level eq 'DEBUG') {
    Datahub::Factory->log->warn(
      "Logger activated - level $level"
    );
  }
}

sub run {
  my ($class) = @_;
  my ($global_opts, $argv)
    = $class->_process_args([@ARGV],
      $class->_global_option_processing_params);

  # Setup logging
  setup_logging($global_opts->{'log_level'}, $global_opts->{'log_output'});

  my $self = ref $class ? $class : $class->new;
  $self->set_global_options($global_opts);

  my ($cmd, $opt, @args) = $self->prepare_command(@$argv);

  # ...and then run it
  $self->execute_command($cmd, $opt, @args);

  return 1;
}

1;

__END__

=head1 NAME

Datahub::Factory::CLI - The App::Cmd class for the Datahub::Factory aplpication

=head1 SEE ALSO

L<factory>

=cut

