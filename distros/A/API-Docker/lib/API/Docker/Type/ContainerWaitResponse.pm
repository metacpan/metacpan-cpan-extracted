package API::Docker::Type::ContainerWaitResponse;
# ABSTRACT: OK response to ContainerWait operation
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::ContainerWaitExitError;
use namespace::clean;


docker status_code => Int, required => 1;


docker error => 'ContainerWaitExitError';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerWaitResponse - OK response to ContainerWait operation

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerWaitResponse> definition of
C<spec/v1.51.yaml>.

=head2 status_code

Exit code of the container. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 error

Container waiting error, if any. See
L<API::Docker::Type::ContainerWaitExitError>.

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
