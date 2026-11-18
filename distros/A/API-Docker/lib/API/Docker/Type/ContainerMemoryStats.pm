package API::Docker::Type::ContainerMemoryStats;
# ABSTRACT: Aggregates all memory stats since container inception on Linux
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker usage => Int, wire => 'usage', since => '1.51';


docker max_usage => Int, wire => 'max_usage', since => '1.51';


docker stats => { Str, Int }, wire => 'stats', since => '1.51';


docker failcnt => Int, wire => 'failcnt', since => '1.51';


docker limit => Int, wire => 'limit', since => '1.51';


docker commitbytes => Int, wire => 'commitbytes', since => '1.51';


docker commitpeakbytes => Int, wire => 'commitpeakbytes', since => '1.51';


docker privateworkingset => Int, wire => 'privateworkingset', since => '1.51';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ContainerMemoryStats - Aggregates all memory stats since container inception on Linux

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ContainerMemoryStats> definition of C<spec/v1.51.yaml>.

Windows returns stats for commit and private working set only.

=head2 usage

Current C<res_counter> usage for memory.

This field is Linux-specific and omitted for Windows containers. Serialised
as C<usage> -- spelled out, because deriving it from the Perl name would
produce C<Usage>.

=head2 max_usage

Maximum usage ever recorded.

This field is Linux-specific and only supported on cgroups v1. It is omitted
when using cgroups v2 and for Windows containers. Serialised as C<max_usage>
-- spelled out, because deriving it from the Perl name would produce
C<MaxUsage>.

=head2 stats

All the stats exported via memory.stat.

The fields in this object differ between cgroups v1 and v2. On cgroups v1,
fields such as C<cache>, C<rss>, C<mapped_file> are available. On cgroups
v2, fields such as C<file>, C<anon>, C<inactive_file> are available.

This field is Linux-specific and omitted for Windows containers. B<The keys
are the caller's data> and are never translated. Serialised as C<stats> --
spelled out, because deriving it from the Perl name would produce C<Stats>.

=head2 failcnt

Number of times memory usage hits limits.

This field is Linux-specific and only supported on cgroups v1. It is omitted
when using cgroups v2 and for Windows containers. Serialised as C<failcnt>
-- spelled out, because deriving it from the Perl name would produce
C<Failcnt>.

=head2 limit

This field is Linux-specific and omitted for Windows containers. Serialised
as C<limit> -- spelled out, because deriving it from the Perl name would
produce C<Limit>.

=head2 commitbytes

Committed bytes.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<commitbytes> -- spelled out, because deriving it from the Perl name
would produce C<Commitbytes>.

=head2 commitpeakbytes

Peak committed bytes.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<commitpeakbytes> -- spelled out, because deriving it from the Perl name
would produce C<Commitpeakbytes>.

=head2 privateworkingset

Private working set.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<privateworkingset> -- spelled out, because deriving it from the Perl
name would produce C<Privateworkingset>.

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
