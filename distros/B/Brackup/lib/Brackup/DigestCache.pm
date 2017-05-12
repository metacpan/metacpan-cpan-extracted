package Brackup::DigestCache;
use strict;
use warnings;

sub new {
    my ($class, $root, $rconf) = @_;
    my $self = bless {}, $class;

    my $file = $rconf->value('digestdb_file') || 
              ($root->path . '/' . default_filename());
    my $type = $rconf->value('digestdb_type') || 'SQLite';

    my $dict_class = "Brackup::Dict::$type";
    eval "require $dict_class";
    $self->{dict} = $dict_class->new(
        table => "digest_cache", 
        file => $file,
    );

    return $self;
}

sub default_filename { ".brackup-digest.db" };

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

Brackup::DigestCache - cache digests of file and chunk contents

=head1 DESCRIPTION

The brackup DigestCache caches the digests (currently SHA1) of files
and file chunks, to prevent untouched files from needing to be re-read
on subsequent, iterative backups.

The digest cache is I<purely> a cache. It has no critical data in it,
so if you lose it, subsequent backups will just take longer while the 
digest cache is re-built.

Note that you don't need the digest cache to do a restore.

=head1 DETAILS

=head2 Storage type

The digest cache makes use of Dictionary modules (Brackup::Dict::*) to 
handle the storage of the cache. The default dictionary used is 
L<Brackup::Dict::SQLite>, which stores the cache as an SQLite database
in a single file. The schema is created automatically as needed... no 
database maintenance is required.

The dictionary type can be specified in the [SOURCE] declaration in 
your brackup.conf file, using the 'digestdb_type' property e.g.:

  [SOURCE:home]
  path = /home/bradfitz/
  # specify the lighter/slower Brackup::Dict::SQLite2 instead of the default
  digestdb_type = SQLite2

=head2 File location

The cache database file is stored in either the location specified in 
a L<Brackup::Root>'s [SOURCE] declaration in ~/.brackup.conf, as:

  [SOURCE:home]
  path = /home/bradfitz/
  # be explicit if you want:
  digestdb_file = /var/cache/brackup-brad/digest-cache-bradhome.db

Or, more commonly (and recommended), is to not specify it and accept
the default location, which is ".brackup-digest.db" in the root's
root directory.

  [SOURCE:home]
  path = /home/bradfitz/
  # this is the default:
  # digestdb_file = /home/bradfitz/.brackup-digest.db

=head2 Keys & Values stored in the cache

B<Files digests keys>  (see L<Brackup::File>)

  [rootname]path/to/file.txt:<ctime>,<mtime>,<size>,<inodenum>

B<Chunk digests keys>  (see L<Brackup::PositionedChunk>)

  [rootname]path/to/file.txt:<ctime>,<mtime>,<size>,<inodenum>;o=<offset>;l=<length>

B<Values>

In both cases, the values are the digest of the chunk/file, in form:

   sha1:e23c4b5f685e046e7cc50e30e378ab11391e528e

=head1 SEE ALSO

L<brackup>

L<Brackup>

L<Brackup::Dict::SQLite>

L<Brackup::Dict::SQLite2>

