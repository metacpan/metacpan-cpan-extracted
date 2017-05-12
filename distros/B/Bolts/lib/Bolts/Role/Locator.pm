package Bolts::Role::Locator;
$Bolts::Role::Locator::VERSION = '0.143171';
# ABSTRACT: Interface for locating artifacts in a bag

use Moose::Role;


requires 'acquire';


requires 'acquire_all';


requires 'resolve';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Role::Locator - Interface for locating artifacts in a bag

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This is the interface that any locator must implement. A locator's primary job is to provide a way to find artifacts within a bag or selection of bags. This performs the acquisition and resolution process.

The reference implementation of this interface is found in L<Bolts::Role::RootLocator>.

=head1 REQUIRED METHODS

Note that the behavior described here is considered the ideal and correct behavior. If it works within your application to fudge on this specifications a little bit, that's your choice, but the implementations provided by the Bolts library itself should adhere to these requirements perfectly.

=head2 acquire

    my $artifact = $loc->acquire(@path, \%options);

Given a C<@path> of symbol names to traverse, this goes through each artifact in turn, resolves it, if necessary, and then continues to the next path component.

The final argument, C<\%options>, is optional. It must be a reference to a hash to pass through to the final component to aid with resolution.

When complete, the complete, resolved artifact found is returned.

=head2 acquire_all

    my @artifacts = @{ $loc->acquire_all(@path, \%options) };

This is similar to L<acquire>, but performs an extra step, the behavior of which varies slightly depending on what artifact is resolved on the component of C<@path>:

=over

=item *

If the last resolved artifact is a reference to an array, then all the artifacts within that bag are acquired, resolved, and returned as a reference to an array.

=item *

If the last resolved artifact is a reference to a hash, then all the values within are pulled, resolved, and returned as a reference to an array.

=item *

In any other case, the final resolved artifact is returned as a single item list.

=back

The final argument is optional. As with L</acquire>, it is must be a hash reference and is passed to each of the artifacts during their resolution.

=head2 resolve

    my $resolved_artifact = $loc->resolve($bag, $artifact, \%options);

After the artifact has been found, this method resolves the a partial artifact implementing the L<Bolts::Role::Artifact> and turns it into the complete artifact.

This method is called during each step of acquisition to resolve the artifact (which might be a bag) at each step, including the final step. The given C<%options> are required. They are derefenced and passed to the L<Bolts::Role::Artifact/get> method, if the artifact being resolved implements L<Bolts::Role::Artifact>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
