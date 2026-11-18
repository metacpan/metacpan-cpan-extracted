package API::Docker::Type::ConfigSpec;
# ABSTRACT: The body of a C<POST /configs/create> request
our $VERSION = '0.006';
use API::Docker::Type;
use API::Docker::Type::Driver;
use namespace::clean;


docker name => Str;


docker labels => { Str, Str };


docker data => Str;


docker templating => 'Driver';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ConfigSpec - The body of a C<POST /configs/create> request

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ConfigSpec> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/configs/create> request and a C<POST /configs/{id}/update> request.

=head2 name

User-defined name of the config.

=head2 labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=head2 data

Data is the data to store as a config, formatted as a standard
base64-encoded (L<RFC 4648|https://tools.ietf.org/html/rfc4648#section-4>)
string. The maximum allowed size is 1000KB, as defined in
L<MaxConfigSize|https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0-20250103191802-8c1959736554/manager/controlapi#MaxConfigSize>.

=head2 templating

Templating driver, if applicable

Templating controls whether and how to evaluate the config payload as a
template. If no driver is set, no templating is used. See
L<API::Docker::Type::Driver>.

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
