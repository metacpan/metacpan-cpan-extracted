package API::Docker::Type::Limit;
# ABSTRACT: An object describing a limit on resources which can be requested by a task
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker nano_cpus => Int, wire => 'NanoCPUs';


docker memory_bytes => Int;


docker pids => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Limit - An object describing a limit on resources which can be requested by a task

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Limit> definition of C<spec/v1.51.yaml>.

=head2 nano_cpus

Undocumented upstream. A CPU quota in units of 10^-9 CPUs, which is how the
swagger describes the same measure under
L<API::Docker::Type::Resources/nano_cpus>. The example C<4000000000> is four
whole CPUs. Serialised as C<NanoCPUs> -- spelled out, because deriving it
from the Perl name would produce C<NanoCpus>.

=head2 memory_bytes

Undocumented upstream. A memory limit in bytes, the measure the swagger
describes under L<API::Docker::Type::Resources/memory>. The example
C<8272408576> is roughly 7.7 GiB.

=head2 pids

Limits the maximum number of PIDs in the container. Set C<0> for unlimited.
The daemon defaults it to 0.

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
