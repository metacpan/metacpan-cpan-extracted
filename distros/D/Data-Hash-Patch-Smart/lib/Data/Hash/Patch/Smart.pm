package Data::Hash::Patch::Smart;

use strict;
use warnings;

use Exporter 'import';
use Data::Hash::Patch::Smart::Engine ();

our @EXPORT_OK = qw(patch);

=head1 NAME

Data::Hash::Patch::Smart - Apply structural, wildcard, and array-aware patches to Perl data structures

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Hash::Patch::Smart qw(patch);

    my $data = {
        users => {
            alice => { role => 'user' },
            bob   => { role => 'admin' },
        }
    };

    my $changes = [
        { op => 'change', path => '/users/alice/role', to => 'admin' },
        { op => 'add',    path => '/users/bob/tags/0', value => 'active' },
        { op => 'remove', path => '/users/*/deprecated' },
    ];

    my $patched = patch($data, $changes, strict => 1);

=head1 DESCRIPTION

C<Data::Hash::Patch::Smart> applies structured patches to nested Perl
data structures. It is the companion to C<Data::Hash::Diff::Smart> and
supports:

=over 4

=item *

Hash and array navigation via JSON-Pointer-like paths

=item *

Index arrays (ordered semantics)

=item *

Unordered arrays (push/remove semantics)

=item *

Structural wildcards (C</foo/*/bar>)

=item *

C<create_missing> mode for auto-creating intermediate containers

=item *

C<strict> mode for validating paths

=item *

Cycle-safe wildcard traversal

=back

The goal is to provide a predictable, expressive patch engine suitable
for configuration management, data migrations, and diff/patch
round-tripping.

=head1 PATCH OPERATIONS

Each change is a hashref with:

=over 4

=item C<op>

One of C<add>, C<remove>, C<change>.

=item C<path>

Slash-separated path segments.
Numeric segments index arrays.

=item C<value> / C<from> / C<to>

Payload for the operation.

=back

=head2 Unordered array wildcard

A leaf C<*> applies unordered semantics:

    { op => 'add',    path => '/items/*', value => 'x' }
    { op => 'remove', path => '/items/*', from  => 'x' }

=head2 Structural wildcard

A C<*> in the parent path matches all children:

    /users/*/role
    /servers/*/ports/*

=head1 ERROR HANDLING

=head2 Strict mode

Strict mode enforces:

=over 4

=item *

Missing hash keys

=item *

Out-of-bounds array indices

=item *

Invalid array indices

=item *

Unsupported operations

=back

Wildcard segments do B<not> trigger strict errors when no matches exist.

=head1 CYCLE DETECTION

Wildcard traversal detects cycles and throws an exception in strict mode.

=head1 FUNCTIONS

=head2 patch( $data, \@changes, %opts )

Applies a list of changes to a data structure and returns a deep clone
with the modifications applied.

=head3 Options

=over 4

=item C<strict =E<gt> 1>

Die on invalid paths, missing keys,
or out-of-bounds array indices.

=item C<create_missing =E<gt> 1>

Auto-create intermediate hashes and arrays when walking a path.

=item C<arrays =E<gt> 'unordered'>

Enables unordered array semantics for leaf C<*> paths.

=back

=cut

sub patch {
	my ($data, $changes, %opts) = @_;

	die 'patch() expects an arrayref of changes' unless ref($changes) eq 'ARRAY';

	return Data::Hash::Patch::Smart::Engine::patch($data, $changes, %opts);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

L<Data::Hash::Diff::Smart>

=head1 REPOSITORY

L<https://github.com/nigelhorne/Data-Hash-Patch-Smart>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-data-hash-patch-smart at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Hash-Patch-Smart>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Data::Hash::Patch::Smart

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Data-Hash-Patch-Smart>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Hash-Patch-Smart>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Data-Hash-Patch-Smart>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Data::Hash::Patch::Smart>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
