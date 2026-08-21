package Apophis;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Apophis', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Apophis - Content addressable storage with deterministic UUID v5 identifiers

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Apophis;

    my $ca = Apophis->new(
        namespace => 'myapp-files',
        store_dir => '/var/store',
    );

    # Identify content — deterministic UUID v5
    my $id = $ca->identify(\$content);
    my $id = $ca->identify_file('/path/to/large-file');  # streaming, O(1) memory

    # Store (atomic write, CAS dedup)
    my $id = $ca->store(\$content);

    # Retrieve
    my $data = $ca->fetch($id);

    # Check / remove
    if ($ca->exists($id)) { ... }
    $ca->remove($id);

    # Integrity verification
    my $ok = $ca->verify($id);  # re-hash and compare

    # Sharded path
    my $path = $ca->path_for($id);
    # /var/store/a3/bb/a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a

    # Bulk operations
    my @ids = $ca->store_many(\@content_refs);
    my @missing = $ca->find_missing(\@ids);

    # Metadata
    $ca->store(\$content, meta => { mime_type => 'image/png' });

=head1 DESCRIPTION

Apophis is a XS content addressable storage library built on the
B<Horus> UUID library (RFC 9562).  It generates deterministic UUID v5
identifiers for arbitrary content using SHA-1 namespace hashing.

Same content always produces the same UUID.  Different namespaces produce
different UUIDs for the same content.

Stored objects are sharded across a 2-level hex directory tree (65,536
directories) for efficient filesystem access at scale.  Writes are atomic
(temp + rename).  CAS is naturally idempotent — no locking required.

=head1 METHODS

=head2 new

    my $ca = Apophis->new(
        namespace => 'myapp-files',    # required
        store_dir => '/var/store',     # optional default store path
    );

Creates a new Apophis instance.  The C<namespace> string is hashed via
UUID v5 (using DNS as root namespace) to produce a proper namespace UUID.

=head2 identify

    my $id = $ca->identify(\$content);

Returns a deterministic UUID v5 string for the given content.

=head2 identify_file

    my $id = $ca->identify_file('/path/to/file');

Streaming identification — reads the file in 64KB chunks via SHA-1.
Uses O(1) memory regardless of file size.  Returns the same UUID that
C<identify()> would for the same content.

=head2 store

    my $id = $ca->store(\$content);
    my $id = $ca->store(\$content, store_dir => '/other');
    my $id = $ca->store(\$content, meta => { mime_type => 'image/png' });

Identifies the content and writes it to the sharded store.  Returns the
UUID.  If the content already exists, returns immediately (CAS dedup).
Writes are atomic via temp file + rename.

=head2 fetch

    my $data_ref = $ca->fetch($id);

Returns a scalar reference to the stored content, or C<undef> if not found.

=head2 exists

    if ($ca->exists($id)) { ... }

Returns true if the content exists in the store.

=head2 remove

    $ca->remove($id);

Removes the content and its metadata sidecar (if any) from the store.

=head2 path_for

    my $path = $ca->path_for($id);

Returns the 2-level sharded filesystem path for the given UUID:

    a3bb189e-8bf9-... → /store/a3/bb/a3bb189e-8bf9-...

=head2 verify

    my $ok = $ca->verify($id);

Re-reads the stored content, re-identifies it, and compares the UUID.
Returns true if the content is intact.

=head2 store_many

    my @ids = $ca->store_many(\@content_refs);

Stores multiple content items.  Returns a list of UUIDs.

=head2 find_missing

    my @missing = $ca->find_missing(\@ids);

Returns the subset of IDs that do not exist in the store.

=head2 namespace

    my $ns = $ca->namespace();

Returns the namespace UUID string.

=head1 C ABI

Apophis publishes its content-addressing primitives as a C function-pointer
table, so another XS module can identify, shard and write a blob without a
Perl frame in between. The header is C<ap_abi.h>, installed through
L<ExtUtils::Depends>, and C<Apophis::_abi_ptr> returns the address of the
process-wide table as a UV.

This is for XS authors. Nothing in it is reachable or useful from Perl, and
the Perl API above remains the supported one.

    use ExtUtils::Depends;
    my $pkg = ExtUtils::Depends->new('My::Module', 'Apophis');

    #include "ap_abi.h"

    /* at boot, once */
    if (call_pv("Apophis::_abi_ptr", G_SCALAR | G_EVAL) > 0) {
        UV p = SvUV(POPs);
        const ap_abi *A = INT2PTR(const ap_abi *, p);
        if (A && A->abi_version >= AP_ABI_VERSION) ...
    }

The table is B<append only>: new members go at the end, C<AP_ABI_VERSION>
bumps, and a consumer requires C<< abi_version >= >> the version it compiled
against - never C<==>, which would make every release of this module a
breaking change for everything that uses it.

C<store_of> unpacks a blessed Apophis object into its namespace bytes and
store directory, and is the only member that touches the object. It never
croaks, so a consumer can probe with it before deciding whether the C path is
available at all. Everything else takes those two values directly, which
means there is still exactly one source of truth for what a store is.

A consumer must not reimplement C<build_path>. The sharded layout is this
module's to change, and a second copy of the rule means the day it changes,
every blob already on disk becomes unreachable through the consumer while
remaining perfectly findable here.

C<ap_abi.h> documents each member; L<Punk::Plugin::Blob> is the reference
consumer.

=head1 DEPENDENCIES

B<Horus> — pure C UUID library (header-only, RFC 9562).

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This module is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=cut
