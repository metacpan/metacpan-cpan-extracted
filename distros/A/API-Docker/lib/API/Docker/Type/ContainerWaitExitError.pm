package API::Docker::Type::ContainerWaitExitError;
# ABSTRACT: container waiting error, if any
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker message => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerWaitExitError - container waiting error, if any

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerWaitExitError> definition of
C<spec/v1.51.yaml>.

=head2 message

Details of an error.

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
