package App::ArduinoBuilder::Logger;

use strict;
use warnings;
use utf8;

use Carp qw(confess);
use Exporter 'import';

our @EXPORT = qw(fatal error warning info debug full_debug);
our @EXPORT_OK = (@EXPORT, qw(log_cmd set_log_level set_prefix print_stack_on_fatal_error));
our %EXPORT_TAGS = (all => [@EXPORT_OK], all_logger => [@EXPORT, 'log_cmd']);

my $LEVEL_FATAL = 0;  # Fatal errors, abort the program.
my $LEVEL_ERROR = 1;  # Recoverable errors (almost unused).
my $LEVEL_WARN = 2;  # Warnings about possible mis-configuration.
my $LEVEL_INFO = 3;  # Info about the main steps of the program.
my $LEVEL_DEBUG = 4;  # Any possibly lengthy debugging information.
my $LEVEL_CMD = 5;  # Command lines being executed (log method not exported by default).
my $LEVEL_FULL_DEBUG = 6;  # Any possibly very-lengthy debugging information.

my $default_level = $LEVEL_INFO;
my $current_level = $default_level;
my $prefix = '';
my $die_with_stack_trace = 0;

sub _level_to_prefix {
  my ($level) = @_;
  return 'FATAL: ' if $level == $LEVEL_FATAL;
  return 'ERROR: ' if $level == $LEVEL_ERROR;
  return 'WARNING: ' if $level == $LEVEL_WARN;
  return 'INFO: ' if $level == $LEVEL_INFO;
  return 'DEBUG: ' if $level == $LEVEL_DEBUG;
  return '' if $level == $LEVEL_CMD || $level == $LEVEL_FULL_DEBUG;
  error("Unknown log level: ${level}");
  return 'UNKNOWN';
}

sub _log {
  my ($level, $message, @args) = @_;
  return if $level > $current_level;
  @args = map { ref eq 'CODE' ? $_->() : $_ } @args;
  my $msg = sprintf "%s%s${message}\n", _level_to_prefix($level), $prefix, @args;
  if ($level == $LEVEL_FATAL) {
    if ($die_with_stack_trace) {
      confess $msg.'Died';  # Will print "message\nDied at foo.pm line 45\n..."
    } else {
      die $msg;
    }
  } else {
    warn $msg;
  }
  return;
}

# printf style method, you can also pass code reference they will be called
# and their return value used in the print command (useful to avoid expensive)
# method calls when not printing them.
sub fatal { _log($LEVEL_FATAL, @_) }
sub fatal_trace { _log($LEVEL_FATAL, @_) }
sub error { _log($LEVEL_ERROR, @_) }
sub warning { _log($LEVEL_WARN, @_) }
sub info { _log($LEVEL_INFO, @_) }
sub debug { _log($LEVEL_DEBUG, @_) }
sub log_cmd { _log($LEVEL_CMD, @_) }
sub full_debug { _log($LEVEL_FULL_DEBUG, @_) }

sub _string_to_level {
  my ($level) = @_;
  return $LEVEL_FATAL if $level =~ m/^FATAL$/i;
  return $LEVEL_ERROR if $level =~ m/^ERR(?:OR)?$/i;
  return $LEVEL_WARN if $level =~ m/^WARN(:?ING)?$/i;
  return $LEVEL_INFO if $level =~ m/^INFO?$/i;
  return $LEVEL_DEBUG if $level =~ m/^(?:DBG|DEBUG)$/i;
  return $LEVEL_CMD if $level =~ m/^(?:CMD|COMMAND)S?$/i;
  return $LEVEL_FULL_DEBUG if $level =~ m/^FULL(:?_?(?:DBG|DEBUG))?$/i;
  error "Unknown log level: ${level}";
  return $default_level;
}

sub set_log_level {
  my ($level) = @_;
  $current_level = _string_to_level($level);
  return;
}

sub print_stack_on_fatal_error {
  $die_with_stack_trace = $_[0];
}

1;
