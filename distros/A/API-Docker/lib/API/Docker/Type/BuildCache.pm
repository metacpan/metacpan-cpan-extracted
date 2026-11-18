package API::Docker::Type::BuildCache;
# ABSTRACT: Information about a build cache record
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker id => Str, wire => 'ID';


docker parents => [Str], since => '1.44';


docker type => Str,
  enum => [qw(
    internal frontend source.local source.git.checkout exec.cachemount regular
  )];


docker description => Str;


docker in_use => Bool;


docker shared => Bool;


docker size => Int;


docker created_at => Str;


docker last_used_at => Str;


docker usage_count => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::BuildCache - Information about a build cache record

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<BuildCache> definition of C<spec/v1.51.yaml>.

=head2 id

Unique ID of the build cache record. Serialised as C<ID> -- spelled out,
because deriving it from the Perl name would produce C<Id>.

=head2 parents

List of parent build cache record IDs.

=head2 type

Cache record type. The swagger enumerates C<internal>, C<frontend>,
C<source.local>, C<source.git.checkout>, C<exec.cachemount> and C<regular>.

=head2 description

Description of the build-step that produced the build cache.

=head2 in_use

Indicates if the build cache is in use.

=head2 shared

Indicates if the build cache is shared.

=head2 size

Amount of disk space used by the build cache (in bytes).

=head2 created_at

Date and time at which the build cache was created in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 last_used_at

Date and time at which the build cache was last used in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 usage_count

Undocumented upstream. A count of uses, C<26> in the swagger's example. The
record's two other usage fields, L</in_use> and L</last_used_at>, are
described upstream; this one is not.

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
