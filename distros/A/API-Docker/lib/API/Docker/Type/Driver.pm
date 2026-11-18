package API::Docker::Type::Driver;
# ABSTRACT: A driver (network, logging, secrets)
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker name => Str, required => 1;


docker options => { Str, Str };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Driver - A driver (network, logging, secrets)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<Driver> definition of C<spec/v1.51.yaml>.

=head2 name

Name of the driver. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=head2 options

Key/value map of driver-specific options. B<The keys are the caller's data>
and are never translated.

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
