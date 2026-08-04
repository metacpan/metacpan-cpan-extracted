package CLI::Simple::Constants;

use strict;
use warnings;

use parent qw(Exporter);

our $VERSION = '2.2.0';

use Readonly;

Readonly::Scalar our $LOG4PERL_COLOR_DEBUG => 'magenta';
Readonly::Scalar our $LOG4PERL_COLOR_INFO  => 'green';
Readonly::Scalar our $LOG4PERL_COLOR_WARN  => 'yellow';
Readonly::Scalar our $LOG4PERL_COLOR_ERROR => 'red';
Readonly::Scalar our $LOG4PERL_COLOR_FATAL => 'bold red';
Readonly::Scalar our $LOG4PERL_COLOR_TRACE => 'bold magenta';

Readonly::Scalar our $LOG4PERL_CONF => <<'END_OF_CONF';
log4perl.logger = INFO, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = [%%d] %%m%%n
log4perl.appender.Screen.color.DEBUG=%s
log4perl.appender.Screen.color.INFO=%s
log4perl.appender.Screen.color.WARN=%s
log4perl.appender.Screen.color.ERROR=%s
log4perl.appender.Screen.color.FATAL=%s
log4perl.appender.Screen.color.TRACE=%s
END_OF_CONF

# this bad but let's avoid load Log::Log4perl::Level
Readonly::Hash our %LOG_LEVELS => (
  trace => 5000,
  debug => 10_000,
  info  => 20_000,
  warn  => 30_000,
  error => 40_000,
  fatal => 50_000,
);

our @EXPORT_OK = ();

our %EXPORT_TAGS = (
  'log-levels' => [qw(%LOG_LEVELS)],

  'booleans' => [
    qw{
      $TRUE
      $FALSE
      $SUCCESS
      $FAILURE
    }
  ],

  'chars' => [
    qw{
      $AMPERSAND
      $COLON
      $COMMA
      $DOUBLE_COLON
      $DASH
      $DOT
      $EMPTY
      $EQUALS_SIGN
      $EQUALS
      $FAT_ARROW
      $OCTOTHORP
      $PERIOD
      $QUESTION_MARK
      $SLASH
      $SPACE
      $TEMPLATE_DELIMITER
      $UNDERSCORE
    }
  ],
  'strings' => [
    qw{
      $PADDING
    }
  ],
  'color-config' => [
    qw(
      $LOG4PERL_CONF
      $LOG4PERL_COLOR_DEBUG
      $LOG4PERL_COLOR_INFO
      $LOG4PERL_COLOR_WARN
      $LOG4PERL_COLOR_ERROR
      $LOG4PERL_COLOR_FATAL
      $LOG4PERL_COLOR_TRACE
    )
  ],
);

# chars
Readonly::Scalar our $AMPERSAND          => q{&};
Readonly::Scalar our $COLON              => q{:};
Readonly::Scalar our $COMMA              => q{,};
Readonly::Scalar our $DOUBLE_COLON       => q{::};
Readonly::Scalar our $DASH               => q{-};
Readonly::Scalar our $DOT                => q{.};
Readonly::Scalar our $EMPTY              => q{};
Readonly::Scalar our $EQUALS_SIGN        => q{=};
Readonly::Scalar our $EQUALS             => q{=};
Readonly::Scalar our $FAT_ARROW          => q{=>};
Readonly::Scalar our $OCTOTHORP          => q{#};
Readonly::Scalar our $PERIOD             => q{.};
Readonly::Scalar our $QUESTION_MARK      => q{?};
Readonly::Scalar our $SLASH              => q{/};
Readonly::Scalar our $SPACE              => q{ };
Readonly::Scalar our $TEMPLATE_DELIMITER => q{@};
Readonly::Scalar our $UNDERSCORE         => q{_};

# strings
Readonly::Scalar our $PADDING => $SPACE x 4;

# booleans
Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

# shell booleans
Readonly::Scalar our $SUCCESS => 0;
Readonly::Scalar our $FAILURE => 1;

# valid args
Readonly::Array our @VALID_OPTIONS => qw(
  abbreviations
  alias
  commands
  default_options
  error_handler
  extra_options
  option_specs
  validate_command
);

foreach my $k ( keys %EXPORT_TAGS ) {
  push @EXPORT_OK, @{ $EXPORT_TAGS{$k} }, '@VALID_OPTIONS', qw(
    $LOG4PERL_CONF
    $LOG4PERL_COLOR_DEBUG
    $LOG4PERL_COLOR_INFO
    $LOG4PERL_COLOR_WARN
    $LOG4PERL_COLOR_ERROR
    $LOG4PERL_COLOR_FATAL
    $LOG4PERL_COLRO_TRACE
  );
}

$EXPORT_TAGS{'all'} = [@EXPORT_OK];

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CLI::Simple::Constants - Exportable constants for CLI::Simple-based applications

=head1 SYNOPSIS

  use CLI::Simple::Constants qw(:booleans :chars :log-levels);

  return $SUCCESS if $flag;
  print $PADDING, "=>", $SPACE, $EQUALS_SIGN, "\n" if $DEBUG;

=head1 DESCRIPTION

This module provides a collection of constants commonly needed when building
command-line tools, especially those using C<CLI::Simple>.

It includes:

=over 4

=item *

Boolean values for use in control flow or shell-style success/failure

=item *

Character constants for formatting and CLI-friendly output

=item *

Predefined log level names for use with Log::Log4perl

=item *

Export tags for grouping constants by intent

=back

=head1 EXPORT TAGS

=over 4

=item * :booleans

Semantic truthy and shell-style constants:

  $TRUE    => 1
  $FALSE   => 0
  $SUCCESS => 0   # shell success
  $FAILURE => 1   # shell failure

=item * :chars

Export commonly used single-character string constants:

  $AMPERSAND          => '&'
  $COLON              => ':'
  $COMMA              => ','
  $DOUBLE_COLON       => '::'
  $DASH               => '-'
  $DOT                => '.'
  $EMPTY              => ''
  $EQUALS_SIGN        => '='
  $OCTOTHORP          => '#'
  $PERIOD             => '.'
  $QUESTION_MARK      => '?'
  $SLASH              => '/'
  $SPACE              => ' '
  $TEMPLATE_DELIMITER => '@'
  $UNDERSCORE         => '_'

Note: C<$DOT> and C<$PERIOD> are synonyms provided for semantic clarity.

=item * :strings

String constants used for formatting:

  $PADDING => '    '   # 4 spaces, commonly used for indentation

=item * :log-levels

Provides a hash mapping symbolic log level names to L<Log::Log4perl> constants:

  %LOG_LEVELS => (
    debug => $DEBUG,
    trace => $TRACE,
    info  => $INFO,
    warn  => $WARN,
    error => $ERROR,
    fatal => $FATAL,
  )

=item * :all

Exports all constants from the above tags.

=back

=head1 SEE ALSO

L<Log::Log4perl>, L<CLI::Simple>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 LICENSE

Same terms as Perl itself.

=cut
