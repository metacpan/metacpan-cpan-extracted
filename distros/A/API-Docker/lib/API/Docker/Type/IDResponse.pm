package API::Docker::Type::IDResponse;
# ABSTRACT: Response to an API call that returns just an Id
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker id => Str, since => '1.51', required => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::IDResponse - Response to an API call that returns just an Id

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<IDResponse> definition of C<spec/v1.51.yaml>.

=head2 id

The id of the newly created object. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

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
