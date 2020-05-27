package Data::AnyXfer::Log4perl;

use strict;
use warnings;

our $VERSION = '0.24';

use base 'Exporter';
our @EXPORT = qw( get_logger );
our @EXPORT_OK = ( @EXPORT, qw( log_level_from_opts ) );

use Log::Log4perl qw( :levels );
use List::Util qw( first );
use File::Find::Rule;


=head1 NAME

Data::AnyXfer::Log4perl - Unified logging system

=head1 SYNOPSIS

  use Data::AnyXfer::Log4perl;    # exports 'get_logger'

  my $logger = get_logger();
  $logger->debug( 'Eeep! Someone pressed the 'wings fall off' button!' );

=head1 DESCRIPTION

This module provides an easy and centralized way to do logging, which will
probably be most useful during development and when trying to track down
issues in code.

=head1 SWITCHING ON LOGGING

By default all logging is suppressed, which is probably what you want during
production. However there are several ways to switch on the logging:

When this module is first used it looks for a config file to read in. It tries
the following in order:

  $ENV{HHOLDINGS_LOGGING_CONFIG_FILE}
  '~/hholdings_logging.conf'
  '/etc/hholdings_logging.conf'

The first one to be found is used and the search stops. The contents are as
described in L<Log::Log4perl::Config>. If no file is found then a default
config is used which suppresses all output - as if the logging didn't exist.

If you are on a dev box and want to enable logging for all the *.pm files in
your working dir then you can use the C<DATA_ANYXFER_LOG_LEVEL> environment variable to
switch on logging:

  DATA_ANYXFER_LOG_LEVEL=INFO perl t/your_test.t

If you want to set the logging config from a file in the code remember to use
a C<BEGIN> block so that the $ENV is set before this module is compiled.

=cut

my $DEFAULT_CONFIG = '
log4perl.logger = OFF, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %p %rms %C %m%n

# Suppress unwanted duplicate messages
log4perl.oneMessagePerAppender = 1
';

# find the log file to use:
sub _potential_files_to_eval {
    return (
        '$ENV{DATA_ANYXFER_LOGGING_CONFIG_FILE}',
        '"$ENV{HOME}/data_anyxfer_logging.conf"',
        '"/etc/data_anyxfer_logging.conf"',
    );
}

sub _potential_files {
    return map { eval $_ } _potential_files_to_eval;
}

{    # Get the first one that exists on disk.
    my $file = first { -e $_ } grep {$_} _potential_files;
    Log::Log4perl->init($file || \$DEFAULT_CONFIG);
}

=head1 CONFIG FILE FORMAT

For full details see L<Log::Log4perl::Config> and
L<Log::Log4perl::Layout::PatternLayout>. Below is a sample config that will be
a good place to start:

  # Switch everything off by default
  log4perl.logger = OFF, Screen

  # log everything of DEBUG and above in Buggy
  log4perl.logger.Buggy = DEBUG, Screen

  # Set up simple logging to the screen (with coloured output)
  log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
  log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = %p %rms %C %m%n

  # Set up the file logging
  log4perl.appender.A1 = Log::Log4perl::Appender::File
  log4perl.appender.A1.filename = /tmp/hholdings.log
  log4perl.appender.A1.mode = append
  log4perl.appender.A1.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.A1.layout.ConversionPattern = %p %d %C %m%n

  # Suppress unwanted duplicate messages
  log4perl.oneMessagePerAppender = 1

=head1 METHODS

=head2 get_logger
 =>
    $logger = get_logger();

Returns a correctly configured L<Log::Log4perl> object using a config found as
described above. Always exported.

=cut

sub get_logger {
    my $category = shift;
    ($category) = caller() if !defined $category;

    # local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    # local $Log::Log4perl::caller_depth = 2;

    # warn Dumper $category;
    # return Log::Log4perl::get_logger();
    return Log::Log4perl::get_logger($category);
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

