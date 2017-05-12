package Brackup::InventoryDatabase;
use strict;
use Brackup::Dict::SQLite;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, $file, $tconf) = @_;
    my $self = bless {}, $class;

    my $type = $tconf->value('inventorydb_type') || 'SQLite';

    my $dict_class = "Brackup::Dict::$type";
    eval "require $dict_class";
    $self->{dict} = $dict_class->new(table => "target_inv", file => $file);

    return $self;
}

# proxy through to underlying dictionary
sub get { shift->{dict}->get(@_) }
sub set { shift->{dict}->set(@_) }
sub each { shift->{dict}->each(@_) }
sub delete { shift->{dict}->delete(@_) }
sub count { shift->{dict}->count(@_) }
sub backing_file { shift->{dict}->backing_file(@_) }


1;
__END__

=head1 NAME

Brackup::InventoryDatabase - track what chunks are already on a target

=head1 DESCRIPTION

The Brackup InventoryDatabase keeps track of which chunks (files) are
already on a given target, speeding up future iterative backups,
negating the need to ask the target for each chunk whether it exists
or not (which may be a lot of network roundtrips, slow even in the
best of network conditions).

Unlike the L<Digest Cache|Brackup::DigestCache>, the inventory
database is not a cache... its contents matter.  Consider what happens
when the inventory database doesn't match reality:

=over

=item B<1) Exists in inventory database; not on target>

If a chunk exists in the inventory database, but not on the target, brackup
won't store it on the target, and you'll think a backup succeeded, but
it's not actually there.

=item B<2a) Exists on target; not in inventory database (without encryption)>

You re-upload it to the target, so you waste time & bandwidth, but no
extra disk space is wasted, and no chunks are orphaned.  Actually,
chunks are un-orphaned, as the inventory database is now updated and
contains the chunk you just uploaded.

=item B<2b) Exists on target; not in inventory database (with encryption)>

When using encryption, each time a chunk is encrypted with gpg, the
contents are different.  So if the inventory database says a given
chunk isn't already stored on the server, it will be re-encrypted and
stored (uploaded) again.  You may or may not have an orphaned chunk on
the server, depending on whether or not it's referenced by any other
*.brackup meta files.

=back

For those reasons, it's somewhat important that your inventory
database be kept around and not deleted.  If you're running brackup to
the same target from different computers, you might want to sync up
your inventory databases with each other, so you don't do unnecessary
uploads to the target.

Tools to rebuild your inventory database from the target's enumeration
of its chunks and the target's *.brackup metafiles isn't yet done, but
would be pretty easy.  (this is a TODO item)

In any case, it's not tragic if you lose your inventory database... it
just means you'll need to upload more stuff and maybe waste some disk
space until you next run a 'L<brackup-target> gc' garbage collection,
which cleans up orphaned chunks. If you're feeling paranoid, it's safer 
to delete your inventory database, tricking Brackup into thinking your
target is empty (even if it's not), rather than Brackup thinking your
target has something when it actually doesn't.

=head1 DETAILS

=head2 Storage type

The inventory database makes use of Dictionary modules (Brackup::Dict::*) 
to handle database storage. The default dictionary used is 
L<Brackup::Dict::SQLite>, which stores the cache as an SQLite database
in a single file. The schema is created automatically as needed... no 
database maintenance is required.

The dictionary type can be specified in the [TARGET] declaration in 
your brackup.conf file, using the 'inventorydb_type' property e.g.:

  [TARGET:amazon]
  type = Amazon
  aws_access_key_id  = ...
  aws_secret_access_key =  ...
  # specify the lighter/slower Brackup::Dict::SQLite2 instead of the default
  inventorydb_type = SQLite2

=head2 File location

The inventory database file (for file-based dictionaries) is stored in 
either the location specified in the 'inventorydb_file' property of a 
[TARGET] declaration in ~/.brackup.conf e.g.:

  [TARGET:amazon]
  type = Amazon
  aws_access_key_id  = ...
  aws_secret_access_key =  ...
  inventorydb_file = /home/bradfitz/.amazon-already-has-these-chunks.db

Or, more commonly (and recommended), is to not specify it and accept
the default location, which is ".brackup-target-TARGETNAME.invdb" in
your home directory (where it might be shared by multiple backup
roots).

=head2 SQLite Schema

This is made automatically for you, but if you want to look around in
it, the schema is:

  CREATE TABLE target_inv (
       key TEXT PRIMARY KEY,
       value TEXT
  )

=head2 Keys & Values stored in the database

B<Keys>

The key is the digest of the "raw" (pre-compression/encryption)
file/chunk (with GPG recipient, if using encryption), and the value is
the digest of the chunk stored on the target, which contains the raw
chunk.  The chunk stored on the target may contain other chunks, may
be compressed, encrypted, etc.

 <raw_digest>               --> <stored_digest> <stored_length>
 <raw_digest>;to=<gpg_rcpt> --> <stored_digest> <stored_length>

For example:

  sha1:e23c4b5f685e046e7cc50e30e378ab11391e528e;to=6BAFF35F =>
     sha1:d7257184899c9e6c4e26506f1c46f8b6562d9ee7 71223

Means that the chunk with sha1 contents "e23c4...", intended to be
en/de-crypted for 6BAFF35F, can be got by asking the target for the
chunk with digest "d72571848...", with length 71,223 bytes.

When using the Brackup feature which combines small files into larger
blobs, the inventory database instead stores values like:

  <raw_digest>[;to=<gpg_rcpt>] -->
     <stored_digest> <stored_length> <from_offset>-<to_offset>

Which is the same thing, but after fetching the composite chunk using
the stored digest provided, only the range provided from C<from_offset> to
C<to_offset> should be used.

=head1 SEE ALSO

L<Brackup>

L<Brackup::Target>

