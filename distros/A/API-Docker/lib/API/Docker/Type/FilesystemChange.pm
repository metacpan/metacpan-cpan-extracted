package API::Docker::Type::FilesystemChange;
# ABSTRACT: Change in the container's filesystem
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker path => Str, since => '1.44', required => 1;


docker kind => Int, since => '1.44', required => 1, enum => [qw( 0 1 2 )];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::FilesystemChange - Change in the container's filesystem

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<FilesystemChange> definition of C<spec/v1.51.yaml>.

=head2 path

Path to file or directory that has changed. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=head2 kind

Kind of change

Can be one of:

=over 4

=item * C<0>: Modified ("C")

=item * C<1>: Added ("A")

=item * C<2>: Deleted ("D")

=back

The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

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
