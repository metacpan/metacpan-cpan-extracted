package API::Docker::Type::HostConfig::LogConfig;
# ABSTRACT: The logging configuration for this container
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker type => Str,
  enum => [qw(
    local json-file syslog journald gelf fluentd awslogs splunk etwlogs none
  )];


docker config => { Str, Str };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::HostConfig::LogConfig - The logging configuration for this container

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<LogConfig> schema of the C<HostConfig>
definition in C<spec/v1.51.yaml>.

=head2 type

Name of the logging driver used for the container or "none" if logging is
disabled. The swagger enumerates C<local>, C<json-file>, C<syslog>,
C<journald>, C<gelf>, C<fluentd>, C<awslogs>, C<splunk>, C<etwlogs> and
C<none>.

=head2 config

Driver-specific configuration options for the logging driver. The swagger's
example is C<< {"max-file": "5", "max-size": "10m"} >>. B<The keys are the
caller's data> and are never translated.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
