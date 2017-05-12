package Catalyst::Plugin::Log::Log4perlSimple;
BEGIN {
  $Catalyst::Plugin::Log::Log4perlSimple::VERSION = '0.3';
}

# ABSTRACT: Simple Log4perl plugin for Catalyst

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Catalyst::Log::Log4perlSimple;

=head1 NAME

Catalyst::Plugin::Log::Log4perlSimple

=head1 SYNOPSIS

  # in MyApp.pm

  use Catalyst qw( Log::Log4perlSimple );

  # in myapp.conf

  # note that this configuration is entirely optional. The block below is
  # indicating the default values for everything, so if they look okay to you,
  # just omit the configuration entirely.

  <Plugin Log::Log4perlSimple>

      # Set this to 0 or 1 to indicate if you would like Catalyst debugging output.
      catalyst_debug 0

      # Set this to 0 or 1 to indicate if you would like Catalyst statistics output.
      catalyst_stats 0

      # What is the lowest level of debugging information you would like output
      # by by Log4perl (trace, debug, info, or warn)
      log_level debug

      # Boolean to control if we want to log to screen
      screen 1

      # Optional control specifying a filename to write log data to (comment this
      # out to disable writing to a file)
      #file /path/to/somefile.log

  </Plugin>

=head1 DESCRIPTION

Provides a zero configuration alternative to L<Catalyst::Log>.

Instantly gives you coloured terminal output and timestamps on your development
server.

Provides a trivial mechanism for routing log messages to a file (configurable
via your application's config file).

=head1 AUTHOR

Martyn Smith <martyn@dollyfish.net.nz>

=head1 METHODS

=head2 setup()

Implementation of the setup callback for L<Catalyst> plugins. This is used to
setup up the logging object.

=cut

sub setup {
    my ($class) = @_;

    my $defaults = {
        catalyst_debug => 0,
        catalyst_stats => 0,
        log_level => 'debug',
        screen => 1,
        file => undef,
    };

    my $config = $class->config->{'Plugin::Log::Log4perlSimple'};
    $config = {} unless UNIVERSAL::isa($config, 'HASH');

    $class->log(Catalyst::Log::Log4perlSimple->new);

    foreach my $key ( keys %{$defaults} ) {
        $config->{$key} = $defaults->{$key} unless exists $config->{$key};
    }

    if ( $config->{catalyst_debug} ) {
        Class::MOP::get_metaclass_by_name($class)->add_method('debug' => sub { 1 });
    }

    if ( $config->{catalyst_stats} ) {
        Class::MOP::get_metaclass_by_name($class)->add_method('use_stats' => sub { 1 });
    }

    if ( $config->{screen} ) {
        $class->log->screen_output(1);
    }

    if ( $config->{file} ) {
        $class->log->file_output($config->{file});
    }

    $class->maybe::next::method(@_);
};

1;
