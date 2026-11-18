package API::Docker::Type::ContainerTopResponse;
# ABSTRACT: Container "top" response
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker titles => [Str], since => '1.51';


docker processes => [[Str]], since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerTopResponse - Container "top" response

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerTopResponse> definition of C<spec/v1.51.yaml>.

=head2 titles

The ps column titles.

=head2 processes

Each process running in the container, where each process is an array of
values corresponding to the titles.

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
