package API::Docker::Type::Mount::TmpfsOptions;
# ABSTRACT: Optional configuration for the C<tmpfs> type
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker size_bytes => Int;


docker mode => Int;


docker options => [[Str]], since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::Mount::TmpfsOptions - Optional configuration for the C<tmpfs> type

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the inline C<TmpfsOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>.

=head2 size_bytes

The size for the tmpfs mount in bytes.

=head2 mode

The permission mode for the tmpfs mount in an integer. The value must not be
in octal format (e.g. 755) but rather the decimal representation of the
octal value (e.g. 493).

=head2 options

The options to be passed to the tmpfs mount. An array of arrays. Flag
options should be provided as 1-length arrays. Other types should be
provided as as 2-length arrays, where the first item is the key and the
second the value. For example: C<< [["noexec"], ["size", "64m"]] >>.

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
