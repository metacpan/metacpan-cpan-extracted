package API::Docker::Type::SwarmSpec::TaskDefaults::LogDriver;
# ABSTRACT: The log driver to use for tasks created in the orchestrator if unspecified by a service
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

API::Docker::Type::SwarmSpec::TaskDefaults::LogDriver - The log driver to use for tasks created in the orchestrator if unspecified by a service

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<LogDriver> schema of C<SwarmSpec.TaskDefaults>
in C<spec/v1.51.yaml>.

Updating this value only affects new tasks. Existing tasks continue to use
their previously configured log driver until recreated.

=head2 name

The log driver to use as a default for new tasks.

=head2 options

Driver-specific options for the selected log driver, specified as key/value
pairs. B<The keys are the caller's data> and are never translated.

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
