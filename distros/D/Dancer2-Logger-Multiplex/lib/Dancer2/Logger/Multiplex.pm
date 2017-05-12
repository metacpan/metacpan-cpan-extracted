package Dancer2::Logger::Multiplex;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Moo;
use Dancer2::Core::Types;
with 'Dancer2::Core::Role::Logger';

has loggers => (
    is  => 'ro',
    isa => ArrayRef,
);

has logging_engines => (
    is  => 'lazy',
);

sub _build_logging_engines {
    my $self = shift;

    my ($app) = grep { $_->name eq $self->app_name } @{ $Dancer2::runner->apps };

    my @logging_engines = map {
        $app->_factory->create(
            logger          => $_,
            %{ $app->_get_config_for_engine( logger => $_, $app->config ) },
            location        => $app->config_location,
            environment     => $app->environment,
            app_name        => $app->name,
            postponed_hooks => $app->postponed_hooks
        )
    } @{ $self->loggers };

    return \@logging_engines;
}

sub log {
    my ($self, $level, $message) = @_;
    $_->log($level, $message) for @{ $self->logging_engines };
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Logger::Multiplex - Log to multiple Dancer2::Logger engines

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Dancer2::Logger::Multiplex;

=head1 DESCRIPTION

Implements a multiplexing logger engine to dispatch logs to multiple
backend L<Dancer2::Core::Role::Logger> engines.

=head1 METHODS

=head2 log($level, $message)

Writes the log message to multiple logger engines.

=head1 CONFIGURATION

The setting B<logger> should be set to C<Multiplex> in order to use this
logging engine in a Dancer2 application.

Below is a sample configuration:

  logger: "Multiplex"

  engines:
    logger:
      Multiplex:
        loggers:
          - Console
          - File
          - Fluent
      File:
        log_dir: "/var/log/myapp"
        file_name: "myapp.log"
      Fluent:
        tag_prefix: "myapp"
        host: "127.0.0.1"
        port: 24224

Allowed options are as follows:

=over 4

=item loggers

Specifies the list of L<Dancer2::Core::Role::Logger> backend engines to
dispatch log messages to.

Each logger engine will be initialized with their corresponding
configurations. As such, in the example above, L<Dancer2::Logger::File>
will be initialized with settings for I<log_dir> and I<file_name>, while
L<Dancer2::Logger::Fluent> will be initialized with settings for
I<tag_prefix>, I<host>, and I<port> as specified in the sample configuration.

=back

=head1 AUTHOR

Arnold Tan Casis E<lt>atancasis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Arnold Tan Casis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

See L<Dancer2> for details about logging in route handlers.

=cut
