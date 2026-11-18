package API::Docker::Type::ContainerStorageStats;
# ABSTRACT: StorageStats is the disk I/O stats for read/write on Windows
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker read_count_normalized => Int,
  wire => 'read_count_normalized', since => '1.51';


docker read_size_bytes => Int, wire => 'read_size_bytes', since => '1.51';


docker write_count_normalized => Int,
  wire => 'write_count_normalized', since => '1.51';


docker write_size_bytes => Int, wire => 'write_size_bytes', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerStorageStats - StorageStats is the disk I/O stats for read/write on Windows

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerStorageStats> definition of
C<spec/v1.51.yaml>.

This type is Windows-specific and omitted for Linux containers. None of its
four fields is described. They are two counts and two byte totals, one pair
per direction, every one of them nullable and every one of them given
C<7593984> as its example.

=head2 read_count_normalized

Undocumented upstream. The count of the read pair, beside the byte total in
L</read_size_bytes>. Serialised as C<read_count_normalized> -- spelled out,
because deriving it from the Perl name would produce C<ReadCountNormalized>.

=head2 read_size_bytes

Undocumented upstream. The bytes read, the other half of that pair.
Serialised as C<read_size_bytes> -- spelled out, because deriving it from
the Perl name would produce C<ReadSizeBytes>.

=head2 write_count_normalized

Undocumented upstream. The write counterpart of L</read_count_normalized>.
Serialised as C<write_count_normalized> -- spelled out, because deriving it
from the Perl name would produce C<WriteCountNormalized>.

=head2 write_size_bytes

Undocumented upstream. The write counterpart of L</read_size_bytes>.
Serialised as C<write_size_bytes> -- spelled out, because deriving it from
the Perl name would produce C<WriteSizeBytes>.

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
