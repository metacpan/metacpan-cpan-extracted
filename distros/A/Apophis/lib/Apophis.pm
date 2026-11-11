package Apophis;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('Apophis', $VERSION);

sub import { $^H{'Apophis/ops'} = 1; return }

sub unimport { delete $^H{'Apophis/ops'}; return }

for my $name (qw(identify store exists fetch verify remove)) {
    no strict 'refs';
    *{"B::Deparse::pp_apophis_$name"} = sub { $_[0]->pp_entersub($_[1], $_[2]) };
}

1;

__END__

=encoding utf8

=head1 NAME

Apophis - Content addressable storage with deterministic UUID v5 identifiers

=head1 VERSION

Version 1.01

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
A blob that is there but cannot be opened or read is an error, not a miss.

=head2 meta

    my $meta = $ca->meta($id);
    my $meta = $ca->meta($id, store_dir => '/other');

Returns a hash reference of the metadata stored beside the content, or
C<undef> when there is none.

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

=head2 op_identify, op_store, op_exists, op_fetch, op_verify, op_remove

    my $id = $ca->op_identify(\$content);

Aliases of C<identify>, C<store>, C<exists>, C<fetch>, C<verify> and
C<remove>, kept from when they were the only way to the fused bodies, see
L</CUSTOM OPS>.

=head1 CUSTOM OPS

    use Apophis;
    my $id = $ca->store(\$content);     # a custom op, not a sub call

    { no Apophis; $ca->store(\$content) }   # an ordinary method call

Under C<use Apophis>, a call to C<identify>, C<store>, C<exists>, C<fetch>,
C<verify> or C<remove> with its one argument is compiled to a custom op in
place of the usual C<entersub>. The op keeps the kids of the call it
replaced, so the method is still looked up on the invocant at run time.
When it resolves to this module's own XSUB, the op runs the body straight off
the stack: no sub call, no C<@_>, and the result is written into the pad slot
the call site already owns, so a call makes no new value to return.

When it resolves to anything else, the op runs C<entersub> itself and the
call behaves exactly as it would have. That covers a subclass that overrides
the method, a sub installed over it, and a call that turns out to carry
options, which the op does not take. A call made with C<&>, through a code
ref, or with the method name in a variable is never converted. Nor is one
compiled under the debugger.

The conversion is lexical. C<no Apophis> ends it for the rest of the block
or file, and C<use Apophis ()> loads the module without it. Calls compiled
before the module was loaded stay ordinary calls.

The C<op_identify>, C<op_store>, C<op_exists>, C<op_fetch>, C<op_verify> and
C<op_remove> methods are aliases of the six, kept from when they were the
only way to the fused bodies. They take the same options and are converted
the same way.

B names the ops C<apophis_identify> and so on, and C<B::Deparse> shows each
as the method call it was. A perl before 5.14 cannot describe a custom op to
B, so there the calls stay ordinary method calls. F<bench/ops.pl> measures
each op against the same call made as an ordinary method call.

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
