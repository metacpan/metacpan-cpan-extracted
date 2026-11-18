package API::Docker::Container;
# ABSTRACT: Removed in 0.004 -- replaced by API::Docker::Type::ContainerSummary and ContainerInspectResponse
our $VERSION = '0.006';
use strict;
use warnings;
use Carp qw( croak );

# A removed class, kept as a stub on purpose (karr k92). A module that
# disappears from a distribution does not disappear from the disks it was
# installed on: the old file stays behind and keeps loading, so deleting it
# here would leave a working API::Docker::Container shadowing this release for
# everyone who ever installed the last one. Shipping a file overwrites it;
# shipping nothing does not.
#
# It refuses instead of working, and it refuses at load rather than at the
# first method call, because that is the earliest point at which the caller
# can be told -- and because @Author::GETTY generates no compile-all author
# test that a dying module would fail. Measured on 2026-08-28: the bundle
# generates exactly xt/author/pod-syntax.t, which parses POD without loading
# anything, and xt/release/changes_has_content.t, which only reads Changes.
my $REFUSED =
  __PACKAGE__ . ' was removed in API::Docker 0.004 and this file is a stub'
  . ' with nothing in it: it ships only so that installing this'
  . ' release overwrites the working copy an earlier one left on'
  . ' disk. You have not hit a fault in the distribution. The'
  . ' containers the daemon answers with are'
  . ' API::Docker::Type::ContainerSummary (containers->list) and'
  . ' API::Docker::Type::ContainerInspectResponse'
  . ' (containers->inspect), with the field names the swagger\'s'
  . ' own in snake_case, and start, stop, logs, is_running and the'
  . ' rest are unchanged on them, composed in from'
  . ' API::Docker::Role::Entity::Container. This stub refuses';

# The croak below is what a caller normally hits. AUTOLOAD is for the one who
# swallowed it -- eval { require API::Docker::Container } and then called a
# method anyway; the answer has to be the same one, not a bare "Can't locate
# object method". DESTROY is defined so it does not reach AUTOLOAD.
sub AUTOLOAD { croak $REFUSED }
sub DESTROY  { }

croak $REFUSED;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Container - Removed in 0.004 -- replaced by API::Docker::Type::ContainerSummary and ContainerInspectResponse

=head1 VERSION

version 0.006

=head1 DESCRIPTION

B<This class is gone.> It has been replaced by the generated type model, and
this file is a stub: loading it croaks, and so does every method call on it.

This class was released in 0.003 and removed in 0.004. Installing 0.004
over it replaces the working copy with this stub, which is the only reason
the file is still in the distribution.

What to reach for instead:

=over

=item * L<API::Docker::Type::ContainerSummary> -- what C<< containers->list >> returns

=item * L<API::Docker::Type::ContainerInspectResponse> -- what C<< containers->inspect >> returns

=item * L<API::Docker::Role::Entity::Container> -- start, stop, logs, is_running and the rest,
unchanged, composed into the above at load time

=back

Where this class mirrored the daemon's CamelCase verbatim, the generated
classes carry the swagger's own names in snake_case.
L<API::Docker::API::Containers> documents the shape each method returns.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Containers> - the resource class these objects come from

=item * L<API::Docker::Role::Entity> - why the methods live in a role

=back

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
