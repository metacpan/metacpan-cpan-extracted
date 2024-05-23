package CLI::Simple::Constants;

use strict;
use warnings;

use Log::Log4perl::Level;

use parent qw(Exporter);

our $VERSION = '0.0.6'; ## no critic (RequireInterpolationOfMetachars)

use Readonly;

Readonly::Hash our %LOG_LEVELS => (
  debug => $DEBUG,
  trace => $TRACE,
  warn  => $WARN,
  error => $ERROR,
  fatal => $FATAL,
  info  => $INFO,
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

foreach my $k ( keys %EXPORT_TAGS ) {
  push @EXPORT_OK, @{ $EXPORT_TAGS{$k} };
}

$EXPORT_TAGS{'all'} = [@EXPORT_OK];

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CLI::Simple::Constants

=head1 SYNOPSIS

 use CLI::Simple::Constants qw(:booleans)

=head1 DESCRIPTION

This class provides a set of exportable constants commonly used in
writing command line scripts.

=head1 EXPORTABLE TAGS

=over 5

=item booleans

  $TRUE    => 1
  $FALSE   => 0
  $SUCCESS => 0 # shell success
  $FAILURE => 1 # shell failure

=item all

Import all constants.

=item chars

  $AMPERSAND          => q{&};
  $COLON              => q{:};
  $COMMA              => q{,};
  $DOUBLE_COLON       => q{::};
  $DASH               => q{-};
  $DOT                => q{.};
  $EMPTY              => q{};
  $EQUALS_SIGN        => q{=};
  $OCTOTHORP          => q{#};
  $PERIOD             => q{.};
  $QUESTION_MARK      => q{?};
  $SLASH              => q{/};
  $SPACE              => q{ };
  $TEMPLATE_DELIMITER => q{@};
  $UNDERSCORE         => q{_};

=item log-levels

Names for Log::Log4perl log level

 %LOG_LEVELS => (
    debug => $DEBUG,
    trace => $TRACE,
    warn  => $WARN,
    error => $ERROR,
    fatal => $FATAL,
    info  => $INFO,
 );

=back

=head1 AUTHOR

Rob Lauer - rlauer6@comcast.net

=cut
