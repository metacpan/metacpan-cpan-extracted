package API::Docker::Type::TaskSpec::LogDriver;
# ABSTRACT: Specifies the log driver to use for tasks created from this spec
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str;


docker options => { Str, Str };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::TaskSpec::LogDriver - Specifies the log driver to use for tasks created from this spec

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<LogDriver> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

If not present, the default one for the swarm will be used, finally falling
back to the engine default if not specified.

=head2 name

Undocumented upstream. The driver, named the way
L<API::Docker::Type::HostConfig::LogConfig/type> names it for a container.
The field holding this object says an absent log driver falls back to the
swarm's default and then to the engine's.

=head2 options

Undocumented upstream. Driver-specific options, the same shape
L<API::Docker::Type::HostConfig::LogConfig/config> takes for a container,
whose example is C<< {"max-file": "5", "max-size": "10m"} >>. B<The keys are
the caller's data> and are never translated.

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
