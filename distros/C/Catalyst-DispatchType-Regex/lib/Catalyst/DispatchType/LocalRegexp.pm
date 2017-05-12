package Catalyst::DispatchType::LocalRegexp;

use Moose;
extends 'Catalyst::DispatchType::LocalRegex';
has '+_attr' => ( default => 'LocalRegexp' );
no Moose;

=head1 NAME

Catalyst::DispatchType::LocalRegexp - LocalRegexp DispatchType

=head1 SYNOPSIS

See L<Catalyst::DispatchType>.

=head1 DESCRIPTION

B<Status: Deprecated.> Regex dispatch types have been deprecated and removed
from Catalyst core. It is recommend that you use Chained methods or other
techniques instead. As part of the refactoring, the dispatch priority of
Regex vs Regexp vs LocalRegex vs LocalRegexp may have changed. Priority is now
influenced by when the dispatch type is first seen in your application.

When loaded, a warning about the deprecation will be printed to STDERR. To
suppress the warning set the CATALYST_NOWARN_DEPRECATE environment variable to
a true value.

Dispatch type managing path-matching behaviour using regexes. This simply
supports the alternate spelling of C<LocalRegex>. All the work is done in
L<Catalyst::DispatchType::LocalRegex>.  For more information on dispatch types,
see:

=over 4

=item * L<Catalyst::Manual::Intro> for how they affect application authors

=item * L<Catalyst::DispatchType> for implementation information.

=back

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
