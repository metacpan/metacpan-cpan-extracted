package Algorithm::Dependency::Item;
# ABSTRACT: Implements an item in a dependency hierarchy.

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod The Algorithm::Dependency::Item class implements a single item within the
#pod dependency hierarchy. It's quite simple, usually created from within a source,
#pod and not typically created directly. This is provided for those implementing
#pod their own source. ( See L<Algorithm::Dependency::Source> for details ).
#pod
#pod =head1 METHODS
#pod
#pod =cut

use 5.005;
use strict;
use Algorithm::Dependency ();

our $VERSION = '1.112';


#####################################################################
# Constructor

#pod =pod
#pod
#pod =head2 new $id, @depends
#pod
#pod The C<new> constructor takes as its first argument the id ( name ) of the
#pod item, and any further arguments are assumed to be the ids of other items that
#pod this one depends on.
#pod
#pod Returns a new C<Algorithm::Dependency::Item> on success, or C<undef>
#pod on error.
#pod
#pod =cut

sub new {
	my $class = shift;
	my $id    = (defined $_[0] and ! ref $_[0] and $_[0] ne '') ? shift : return undef;
	bless { id => $id, depends => [ @_ ] }, $class;
}

#pod =pod
#pod
#pod =head2 id
#pod
#pod The C<id> method returns the id of the item.
#pod
#pod =cut

sub id { $_[0]->{id} }

#pod =pod
#pod
#pod =head2 depends
#pod
#pod The C<depends> method returns, as a list, the names of the other items that
#pod this item depends on.
#pod
#pod =cut

sub depends { @{$_[0]->{depends}} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Dependency::Item - Implements an item in a dependency hierarchy.

=head1 VERSION

version 1.112

=head1 DESCRIPTION

The Algorithm::Dependency::Item class implements a single item within the
dependency hierarchy. It's quite simple, usually created from within a source,
and not typically created directly. This is provided for those implementing
their own source. ( See L<Algorithm::Dependency::Source> for details ).

=head1 METHODS

=head2 new $id, @depends

The C<new> constructor takes as its first argument the id ( name ) of the
item, and any further arguments are assumed to be the ids of other items that
this one depends on.

Returns a new C<Algorithm::Dependency::Item> on success, or C<undef>
on error.

=head2 id

The C<id> method returns the id of the item.

=head2 depends

The C<depends> method returns, as a list, the names of the other items that
this item depends on.

=head1 SEE ALSO

L<Algorithm::Dependency>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Dependency>
(or L<bug-Algorithm-Dependency@rt.cpan.org|mailto:bug-Algorithm-Dependency@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
