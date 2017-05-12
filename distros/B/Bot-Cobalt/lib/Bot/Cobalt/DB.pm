package Bot::Cobalt::DB;
$Bot::Cobalt::DB::VERSION = '0.021003';
## Uses proper retie-after-lock technique for locking

use v5.10;
use strictures 2;
use Carp;

use List::Objects::WithUtils;

use DB_File;
use Fcntl qw/:DEFAULT :flock/;
use IO::File;

use Bot::Cobalt::Serializer;
use Bot::Cobalt::Common ':types';

use Time::HiRes 'sleep';


use Moo;

has file => (
  required  => 1,
  is        => 'rw',
  isa       => (Str | Object),
);
{ no warnings 'once'; *File = *file; }

has perms => (
  is        => 'rw',
  builder   => sub { 0644 },
);
{ no warnings 'once'; *Perms = *perms; }

has raw => (
  is        => 'rw',
  isa       => Bool,
  builder   => sub { 0 },
);
{ no warnings 'once'; *Raw = *raw; }

has timeout => (
  is        => 'rw',
  isa       => Num,
  builder   => sub { 5 },
);
{ no warnings 'once'; *Timeout = *timeout; }

has serializer => (
  lazy      => 1,
  is        => 'rw',
  isa       => Object,
  builder   => sub {
    Bot::Cobalt::Serializer->new(Format => 'JSON')
  },
);
{ no warnings 'once'; *Serializer = *serializer; }

## _orig is the original tie().
has _orig => (
  is        => 'rw',
  isa       => HashRef,
  builder   => sub { {} },
);

## tied is the re-tied DB hash.
has tied  => (
  is        => 'rw',
  isa       => HashRef,
  builder   => sub { {} },
);
{ no warnings 'once'; *Tied = *tied; }

has _lockfh => (
  lazy      => 1,
  is        => 'rw',
  isa       => FileHandle,
  predicate => '_has_lockfh',
  clearer   => '_clear_lockfh',
);

## LOCK_EX or LOCK_SH for current open
has _lockmode => (
  lazy      => 1,
  is        => 'rw',
  predicate => '_has_lockmode',
  clearer   => '_clear_lockmode',
);

## DB object.
has DB     => (
  lazy      => 1,
  is        => 'rw',
  isa       => Object,
  predicate => 'has_DB',
  clearer   => 'clear_DB',
);

has is_open => (
  is        => 'rw',
  isa       => Bool,
  default   => sub { 0 },
);

sub BUILDARGS {
  my ($class, @args) = @_;
  return +{ file => $args[0] } if @args == 1;
  # Back-compat and I hate myself
  my %opt = @args;
  my $lower = array( qw/
    File
    Perms
    Raw
    Timeout
    Serializer
    Tied
  / );
  for my $key (%opt) {
    if ( $lower->has_any(sub { $_ eq $key }) ) {
      my $val = delete $opt{$key};
      $opt{lc $key} = $val
    }
  }
  \%opt
}

sub DESTROY {
  my ($self) = @_;
  $self->dbclose if $self->is_open;
}

sub dbopen {
  my ($self, %args) = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  ## per-open timeout was specified:
  $self->timeout( $args{timeout} ) if $args{timeout};

  if ($self->is_open) {
    carp "Attempted dbopen() on already-open DB";
    return
  }

  my ($lflags, $fflags);
  if ($args{ro} || $args{readonly}) {
    $lflags = LOCK_SH | LOCK_NB  ;
    $fflags = O_CREAT | O_RDONLY ;
    $self->_lockmode(LOCK_SH);
  } else {
    $lflags = LOCK_EX | LOCK_NB;
    $fflags = O_CREAT | O_RDWR ;
    $self->_lockmode(LOCK_EX);
  }

  my $path = $self->file;

 ## proper DB_File locking:
  ## open and tie the DB to _orig
  ## set up object
  ## call a sync() to create if needed
  my $orig_db = tie %{ $self->_orig }, "DB_File", $path,
      $fflags, $self->perms, $DB_HASH
      or confess "failed db open: $path: $!" ;
  $orig_db->sync();

  ## dup a FH to $db->fd for _lockfh
  my $fd = $orig_db->fd;
  my $fh = IO::File->new("<&=$fd")
    or confess "failed dup in dbopen: $!";

  my $timer = 0;
  my $timeout = $self->timeout;

  ## flock _lockfh
  until ( flock $fh, $lflags ) {
    if ($timer > $timeout) {
      warn "failed lock for db $path, timeout (${timeout}s)\n";
      undef $orig_db; undef $fh;
      untie %{ $self->_orig };
      return
    }

    sleep 0.01;
    $timer += 0.01;
  }

  ## reopen DB to Tied
  my $db = tie %{ $self->tied }, "DB_File", $path,
      $fflags, $self->perms, $DB_HASH
      or confess "failed db reopen: $path: $!";

  ## preserve db obj and lock fh
  $self->is_open(1);
  $self->_lockfh($fh);
  $self->DB($db);
  undef $orig_db;

  ## install filters
  ## null-terminated to be C-compat
  $self->DB->filter_fetch_key(
    sub { s/\0$// }
  );
  $self->DB->filter_store_key(
    sub { $_ .= "\0" }
  );

  ## JSONified values
  $self->DB->filter_fetch_value(
    sub {
      s/\0$//;
      $_ = $self->serializer->ref_from_json($_)
        unless $self->raw;
    }
  );
  $self->DB->filter_store_value(
    sub {
      $_ = $self->serializer->json_from_ref($_)
        unless $self->raw;
      $_ .= "\0";
    }
  );

  1
}

sub dbclose {
  my ($self) = @_;

  unless ($self->is_open) {
    carp "attempted dbclose on unopened db";
    return
  }

  if ($self->_lockmode == LOCK_EX) {
    $self->DB->sync();
  }

  $self->clear_DB;
  untie %{ $self->tied }
    or carp "dbclose: untie tied: $!";

  flock( $self->_lockfh, LOCK_UN )
    or carp "dbclose: unlock: $!";

  untie %{ $self->_orig }
    or carp "dbclose: untie _orig: $!";

  $self->_clear_lockfh;
  $self->_clear_lockmode;

  $self->is_open(0);

  return 1
}

sub get_tied {
  my ($self) = @_;
  confess "attempted to get_tied on unopened db"
    unless $self->is_open;

  $self->tied
}

sub get_db {
  my ($self) = @_;
  confess "attempted to get_db on unopened db"
    unless $self->is_open;

  $self->DB
}

sub dbkeys {
  my ($self) = @_;
  confess "attempted 'dbkeys' on unopened db"
    unless $self->is_open;

  wantarray ? 
    (keys %{ $self->tied })
    : scalar keys %{ $self->tied }
}

sub get {
  my ($self, $key) = @_;
  confess "attempted 'get' on unopened db"
    unless $self->is_open;

  exists $self->Tied->{$key} ? $self->tied->{$key} : ()
}

sub put {
  my ($self, $key, $value) = @_;
  confess "attempted 'put' on unopened db"
    unless $self->is_open;

  $self->tied->{$key} = $value
}

sub del {
  my ($self, $key) = @_;
  confess "attempted 'del' on unopened db"
    unless $self->is_open;

  return unless exists $self->tied->{$key};

  delete $self->tied->{$key};

  1
}

sub dbdump {
  my ($self, $format) = @_;
  confess "attempted dbdump on unopened db"
    unless $self->is_open;
  $format = 'YAMLXS' unless $format;

  ## shallow copy to drop tied()
  my %copy = %{ $self->tied };
  return \%copy if lc($format) eq 'hash';

  my $dumper = Bot::Cobalt::Serializer->new( Format => $format );

  $dumper->freeze(\%copy)
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::DB - Locking Berkeley DBs with serialization

=head1 SYNOPSIS

  use Bot::Cobalt::DB;

  ## ... perhaps in a Cobalt_register ...
  my $db_path = $core->var ."/MyDatabase.db";
  my $db = Bot::Cobalt::DB->new(
    file => $db_path,
  );

  ## Open (and lock):
  $db->dbopen;

  ## Do some work:
  $db->put( SomeKey => $some_deep_structure );

  for my $key ($db->dbkeys) {
    my $this_hash = $db->get($key);
  }

  ## Close and unlock:
  $db->dbclose;


=head1 DESCRIPTION

B<Bot::Cobalt::DB> provides a simple object-oriented interface to basic
L<DB_File> (Berkeley DB 1.x) usage.

BerkDB is a fast and simple key/value store. This module uses JSON to
store nested Perl data structures, providing easy database-backed
storage for L<Bot::Cobalt> plugins.

=head2 Constructor

B<new()> is used to create a new Bot::Cobalt::DB object representing your
Berkeley DB:

  my $db = Bot::Cobalt::DB->new(
    file => $path_to_db,

   ## Optional arguments:

    # Database file mode
    perms => $octal_mode,

    ## Locking timeout in seconds
    ## Defaults to 5s:
    timeout => 10,

    ## Normally, references are serialized transparently.
    ## If raw is enabled, no serialization filter is used and you're
    ## on your own.
    raw => 0,
  );

=head2 Opening and closing

Database operations should be contained within a dbopen/dbclose:

  ## open, put, close:
  $db->dbopen || croak "dbopen failure";
  $db->put($key, $data);
  $db->dbclose;

  ## open for read-only, read, close:
  $db->dbopen(ro => 1) || croak "dbopen failure";
  my $data = $db->get($key);
  $db->dbclose;

Methods will fail if the DB is not open.

If the DB for this object is open when the object is DESTROY'd, Bot::Cobalt::DB
will attempt to close it safely.

=head2 Locking

Proper locking is done -- that means the DB is 're-tied' after a lock is
granted and state cannot change between database open and lock time.

The attempt to gain a lock will time out after five seconds (and
L</dbopen> will return boolean false).

The lock is cleared on L</dbclose>.

If the Bot::Cobalt::DB object is destroyed, it will attempt to dbclose
for you, but it is good practice to keep track of your open/close
calls and attempt to close as quickly as possible.


=head2 Methods

=head3 dbopen

B<dbopen> opens and locks the database. If 'ro => 1' is specified,
this is a LOCK_SH shared (read) lock; otherwise it is a LOCK_EX
exclusive (write) lock.

Try to call a B<dbclose> as quickly as possible to reduce locking
contention.

dbopen() will return false (and possibly warn) if the database could
not be opened (probably due to lock timeout).

=head3 is_open

Returns a boolean value representing whether or not the DB is currently
open and locked.

=head3 dbclose

B<dbclose> closes and unlocks the database.

=head3 put

The B<put> method adds an entry to the database:

  $db->put($key, $value);

The value can be any data structure serializable by L<JSON::MaybeXS>.

Note that keys should be properly encoded:

  my $key = "\x{263A}";
  utf8::encode($key);
  $db->put($key, $data);

=head3 get

The B<get> method retrieves a (deserialized) key.

  $db->put($key, { Some => 'hash' } );
  ## . . . later on . . .
  my $ref = $db->get($key);

=head3 del

The B<del> method removes a key from the database.

  $db->del($key);

=head3 dbkeys

B<dbkeys> will return a list of keys in list context, or the number
of keys in the database in scalar context.

=head3 dbdump

You can serialize/export the entirety of the DB via B<dbdump>.

  ## Export to a HASH
  my $dbcopy = $db->dbdump('HASH');
  ## YAML::Syck
  my $yamlified = $db->dbdump('YAML');
  ## YAML::XS
  my $yamlified = $db->dbdump('YAMLXS');
  ## JSON::MaybeXS
  my $jsonified = $db->dbdump('JSON');

See L<Bot::Cobalt::Serializer> for more on C<freeze()> and valid formats.

A tool called B<cobalt2-dbdump> is available as a
simple frontend to this functionality. See C<cobalt2-dbdump --help>

=head1 FORMAT

B<Bot::Cobalt::DB> databases are Berkeley DB 1.x, with NULL-terminated records
and values stored as JSON. They're intended to be easily portable to
other non-Perl applications.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
