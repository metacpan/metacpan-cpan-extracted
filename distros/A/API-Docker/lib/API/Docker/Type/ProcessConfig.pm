package API::Docker::Type::ProcessConfig;
# ABSTRACT: The C<ProcessConfig> field of the C<200> response to C<GET /exec/{id}/json>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker privileged => Bool, wire => 'privileged';


docker user => Str, wire => 'user';


docker tty => Bool, wire => 'tty';


docker entrypoint => Str, wire => 'entrypoint';


docker arguments => [Str], wire => 'arguments';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ProcessConfig - The C<ProcessConfig> field of the C<200> response to C<GET /exec/{id}/json>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ProcessConfig> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. C<paths:> says what it is: the
C<ProcessConfig> field of the C<200> response to C<GET /exec/{id}/json>. The
swagger describes none of its five fields, but the example response it gives
for that endpoint shows all five, and the body of C<POST
/containers/{id}/exec> describes the options they report back.

=head2 privileged

Undocumented upstream. Whether the process runs with extended privileges,
which is how the swagger describes C<Privileged> on the exec-create body.
C<false> in the example response. Serialised as C<privileged> -- spelled
out, because deriving it from the Perl name would produce C<Privileged>.

=head2 user

Undocumented upstream. The user, and optionally the group, the process runs
as inside the container -- one of C<user>, C<user:group>, C<uid> or
C<uid:gid>, as the swagger describes C<User> on the exec-create body.
C<"1000"> in the example response. Serialised as C<user> -- spelled out,
because deriving it from the Perl name would produce C<User>.

=head2 tty

Undocumented upstream. Whether a pseudo-TTY was allocated, which is what
C<Tty> asks for on the exec-create body. It decides how the output arrives:
with a TTY the stream is raw, without one it is the multiplexed frame
format, see L<API::Docker::Role::HTTP/"Detecting a framed stream">. C<true>
in the example response. Serialised as C<tty> -- spelled out, because
deriving it from the Perl name would produce C<Tty>.

=head2 entrypoint

Undocumented upstream. The program being run, C<"sh"> in the example
response. The exec-create body takes it together with L</arguments> as one
C<Cmd>, which the swagger describes as the command to run. Serialised as
C<entrypoint> -- spelled out, because deriving it from the Perl name would
produce C<Entrypoint>.

=head2 arguments

Undocumented upstream. Its arguments, C<< ["-c", "exit 2"] >> beside that
C<"sh"> in the example response. Serialised as C<arguments> -- spelled out,
because deriving it from the Perl name would produce C<Arguments>.

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
