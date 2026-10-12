package Dancer2::Session::Pg;

use strict;
use warnings;
use English qw( -no_match_vars );

# $data is what Dancer2::Core::Role::SessionFactory calls a session payload, in
# the very signatures this module exists to implement. Renaming it to satisfy
# Bangs::ProhibitVagueNames would make the two halves of the contract disagree,
# and a reader comparing them would have to translate.
## no critic (Bangs::ProhibitVagueNames)

use Moo;
use Carp                  qw( croak );
use DBI                   ();
use DBD::Pg               qw( :pg_types );
use Module::Runtime       qw( is_module_name use_module );
use Types::Standard       qw( CodeRef HashRef Int Maybe Object Str );
use Types::Common::String qw( NonEmptySimpleStr );
use Scalar::Util          qw( blessed );
use Crypt::Digest::SHA256 qw( sha256_hex );
use Crypt::PRNG           ();

# Core `use constant`, which is what Dancer2 itself uses.
use constant {

    # Every stored payload begins with three bytes -- format version, cipher id,
    # key id -- and every length after them comes from the cipher that id names.
    # So a cipher with a 24-byte nonce or a 32-byte tag needs no change here, and
    # a row says what wrote it instead of the configuration having to agree.
    FORMAT_VERSION => 1,
    HEADER_BYTES   => 3,

    # A session is not worth waiting on: a write that blocks indefinitely blocks
    # a worker indefinitely. Seconds and milliseconds respectively, matching what
    # DBD::Pg and PostgreSQL each expect.
    DEFAULT_CONNECT_TIMEOUT      => 2,
    DEFAULT_STATEMENT_TIMEOUT_MS => 2000,
};

our $VERSION = '0.002';

with 'Dancer2::Core::Role::SessionFactory';

# ---------------------------------------------------------------------------
# Authenticated encryption
# ---------------------------------------------------------------------------
#
# Authenticated modes only. A session that has been altered in the database must
# fail to decrypt rather than deserialise into a structure the application then
# trusts, so a mode without a tag is not offered here.
#
# A cipher is an object doing Dancer2::Session::Pg::Cipher, and the id it
# declares goes into every payload it writes. That is the whole mechanism behind
# replacing one: point `alg` at the new cipher and new sessions use it while rows
# written by the old one stay readable until they expire. A cipher revealed to be
# weak next year is then a configuration change, not a forced logout.

my %BUILTIN = (
    'AES-128-GCM'       => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 16 ],
    'AES-192-GCM'       => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 24 ],
    'AES-256-GCM'       => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 32 ],
    'ChaCha20-Poly1305' => ['Dancer2::Session::Pg::Cipher::ChaCha20Poly1305'],
);

sub algorithms {

    # Not `return sort ...`: that is undefined in scalar context.
    my @names = sort keys %BUILTIN;
    return @names;
}

# cipher_self_check is in the list on purpose: it is the one method a cipher gets
# only by consuming the role, so requiring it is how "do the role" is enforced
# without reaching into Role::Tiny.
my @CIPHER_CONTRACT = qw(
  cipher_id cipher_name key_bytes iv_bytes tag_bytes seal unseal cipher_self_check
);

# A class named in configuration may be anything at all, so say what went wrong
# rather than letting "Can't locate object method new" out of a module nobody asked
# to be a cipher.
sub _construct {
    my ( $class, @args ) = @_;
    my $cipher = eval { use_module($class)->new(@args) };
    croak sprintf 'Dancer2::Session::Pg: alg %s could not be constructed as a cipher: %s',
      "'$class'", ( $EVAL_ERROR || 'new returned no object' )
      if !blessed $cipher;
    return $cipher;
}

sub _resolve_cipher {
    my ($spec) = @_;

    my $cipher;
    if ( blessed $spec ) {
        $cipher = $spec;
    } elsif ( ref $spec eq 'ARRAY' ) {
        my ( $class, @args ) = @{$spec};
        croak sprintf 'Dancer2::Session::Pg: implausible cipher class %s', ( defined $class ? "'$class'" : 'undef' )
          if !defined $class || !is_module_name($class);
        $cipher = _construct( $class, @args );
    } elsif ( defined $spec && exists $BUILTIN{$spec} ) {
        my ( $class, @args ) = @{ $BUILTIN{$spec} };
        $cipher = _construct( $class, @args );
    } else {
        croak sprintf
          'Dancer2::Session::Pg: unknown alg %s (built in: %s -- or name a class that does Dancer2::Session::Pg::Cipher)',
          ( defined $spec ? "'$spec'" : 'undef' ), join q{, }, algorithms()
          if !defined $spec || ref $spec || !is_module_name($spec);
        $cipher = _construct($spec);
    }

    my @missing = grep { !$cipher->can($_) } @CIPHER_CONTRACT;
    croak sprintf 'Dancer2::Session::Pg: %s does not do %s (missing: %s)',
      ref $cipher, 'Dancer2::Session::Pg::Cipher', join q{, }, @missing
      if @missing;

    return $cipher;
}

# ---------------------------------------------------------------------------
# Connection
# ---------------------------------------------------------------------------

# Maybe[Str] rather than Str on the optional four, deliberately. An engine
# configured from YAML gets undef for a key that is present but empty --
# `dsn:` with nothing after it -- and undef there means "not set", which the
# checks in BUILD answer with a sentence an operator can act on. A bare Str
# would intercept that case and report a type constraint instead.
has dsn    => ( is => 'ro', isa => Maybe [Str] );
has dbuser => ( is => 'ro', isa => Maybe [Str] );
has dbpass => ( is => 'ro', isa => Maybe [Str] );

# NO DEFAULT SCHEMA. Assuming 'public' would be wrong wherever the default
# schema is called something else, and qualifying a name the deployment did not
# ask us to qualify takes a decision that belongs to search_path. Unset means the
# table is referenced bare and resolved by the connection's search_path.
has dbschema => ( is => 'ro', isa => Maybe [Str] );

# The table name, on the other hand, is not guessable and is not optional.
has dbtable => ( is => 'ro', required => 1, isa => NonEmptySimpleStr );

# An existing handle, or a coderef returning one -- so an application already
# holding a connection (Dancer2::Plugin::Database, DBIx::Class, a pool) can hand
# it over instead of opening a second one. A coderef is re-invoked on every
# access, which is what makes it safe with a pool that hands out live handles.
#
# Typed because the alternative is a string from a configuration file reaching
# the first query as a method call on an unblessed scalar, several minutes after
# the mistake was made.
has dbh => ( is => 'ro', predicate => 1, isa => CodeRef | Object );

# Int, because `connect_timeout: two` in YAML would otherwise be appended to the
# DSN verbatim and the engine would fail to connect for a reason the message does
# not mention.
has connect_timeout   => ( is => 'ro', isa => Int, default => sub { DEFAULT_CONNECT_TIMEOUT } );
has statement_timeout => ( is => 'ro', isa => Int, default => sub { DEFAULT_STATEMENT_TIMEOUT_MS } );

# ---------------------------------------------------------------------------
# The optional principal
# ---------------------------------------------------------------------------
#
# OFF by default: the principal column is an optional extra, and an application
# with no principal concept should not be asked to carry one -- not in its
# configuration and not in its table.

# A string names the session key whose value is copied. A coderef is handed the
# session data and returns the value, which is how an identity spread over
# several keys -- sub { $_[0]->{'user'}{'id'} } -- still becomes one indexable
# column.
has principal_key => ( is => 'ro', isa => Str | CodeRef );

# The column that value is written to. Separate from the session key because a
# deployment making it a foreign key will want it named after the table it
# references -- account_id, not principal_id.
has principal_column => ( is => 'ro', isa => NonEmptySimpleStr, default => sub { 'principal_id' } );

# The columns _flush writes itself. principal_column may not be one of them; see
# the check in BUILD for why.
our @RESERVED_COLUMNS = qw( id session_data created updated expires );
our %RESERVED_COLUMN  = map { $_ => 1 } @RESERVED_COLUMNS;

# ---------------------------------------------------------------------------
# Keys, and the cipher each one belongs to
# ---------------------------------------------------------------------------
#
# A SLOT pairs a key with the cipher it is used by. That pairing is the whole
# design, and it is worth saying why, because the obvious alternative -- a list
# of keys and a separate choice of cipher -- is what this replaced.
#
# Decoupled, nothing records which cipher a key was meant for, so key LENGTH
# becomes the only thing linking them and has to be re-derived at five separate
# points: validating the write key, catching a typo in a read key, deciding
# which ciphers are usable at all, checking a row's cipher against its key, and
# even deciding whether a configured string is hex or raw bytes. Paired, every
# one of those is one check in one place: this slot's key must fit this slot's
# cipher. A whole attribute went with it -- there is no `read_algs`, because a
# cipher you can still read but no longer write IS the other slot.
#
# Exactly one slot is `active`, and that is the one written with. Reading uses
# the slot the ROW names -- every payload carries its key id -- so it is one
# lookup and one decrypt attempt, not a try-every-key loop that would blur a
# misconfiguration into something that looks like tampering.
#
#   encryption_keys:
#     0:
#       key: "${ENV:SESSION_KEY_0}"
#       alg: "AES-256-GCM"
#       active: true
#     1:
#       key: "${ENV:SESSION_KEY_1}"
#       alg: "ChaCha20-Poly1305"

has encryption_keys => ( is => 'ro', required => 1, isa => HashRef );

has json_module => ( is => 'ro', isa => Str, default => sub { 'JSON::MaybeXS' } );

sub BUILD {
    my ($self) = @_;
    croak 'Dancer2::Session::Pg: pass either dsn or dbh'
      if !$self->has_dbh && !defined $self->dsn;

    # principal_key is checked by its type constraint, which says the same thing
    # earlier and in one line. principal_column needs more than a type: it has to
    # not collide with a column this module already writes.
    #
    # _flush builds one INSERT column list, so a principal_column of 'expires'
    # would emit that column twice and PostgreSQL would refuse every session
    # write with error 42701. Quoting does not help -- "expires" and expires are
    # the same column. It takes a nonsensical configuration to reach, but the
    # module's whole bargain is to fail at startup rather than at somebody's
    # first login, and this was the one place not holding up its end.
    croak sprintf q{Dancer2::Session::Pg: principal_column may not be '%s' -- this module }
      . q{writes that column itself, and _flush would name it twice in one INSERT. }
      . q{Reserved: %s}, $self->principal_column, join q{, }, @RESERVED_COLUMNS
      if defined $self->principal_key
      && exists $RESERVED_COLUMN{ lc $self->principal_column };

    # One call settles every slot: each alg names a real cipher, each cipher does
    # what it claims, each key is the length its own cipher needs, and exactly
    # one slot is active. A configuration that cannot work stops the process here
    # rather than at somebody's first login.
    $self->_slots;

    # A supplied handle is never modified, so if it is in manual-commit mode the
    # session write joins somebody else's transaction and is durable only when
    # they commit. Say so once, loudly, rather than let it surface later as a
    # login that mysteriously did not complete.
    #
    # Only a handle we can look at NOW. A coderef cannot be called here -- doing
    # so would open a connection at construction, which is the whole thing the
    # coderef form exists to avoid -- so that case is checked in _dbh instead,
    # at the first access, where the handle is in hand.
    $self->_warn_if_manual_commit( $self->dbh )
      if $self->has_dbh && ref $self->dbh ne 'CODE';

    return;
}

# Shared by BUILD and _dbh so the two cannot drift, and keyed on one message so
# `_report_once` suppresses the second of them.
#
# carp AND log_cb, deliberately: carp reaches an engine built by hand, where
# log_cb is the role's no-op default and a warning would otherwise vanish; log_cb
# reaches the application log of an engine Dancer2 built from config, where
# STDERR may go nowhere anybody reads.
sub _warn_if_manual_commit {
    my ( $self, $handle ) = @_;

    return if !$handle || $handle->{'AutoCommit'};

    my $message =
        'the supplied dbh has AutoCommit off. Session writes will join the '
      . q{caller's transaction and are not durable until the caller commits. This }
      . 'module will not commit a handle it does not own. See "SHARING A HANDLE" '
      . 'in the docs.';

    return if $self->_reported->{$message};
    Carp::carp "Dancer2::Session::Pg: $message";
    $self->_report_once( 'warning', $message );
    return;
}

# id => { key => raw bytes, cipher => object }, and which id is written with.
#
# Everything knowable before the first request is settled here, so a
# configuration that cannot work stops the process at startup rather than at
# somebody's first login. Under Kubernetes that is the behaviour you want: the
# pod refuses to start, the rollout halts, and the previous generation carries
# on serving.
has _slots => ( is => 'lazy' );

has _write_slot_id => ( is => 'lazy' );

sub _build__slots {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- a Moo lazy builder, reached through the attribute and never by name
    my ($self) = @_;

    my $configured = $self->encryption_keys;
    croak 'Dancer2::Session::Pg: encryption_keys has no entries. One slot is enough: '
      . '{ 0 => { key => ..., alg => ..., active => 1 } }'
      if !keys %{$configured};

    my ( %slot, @active, %class_for_id );
    for my $id ( sort keys %{$configured} ) {

        # CANONICAL decimal, not merely digits. A slot id of '00' would pass a
        # digits-only check, be packed into the header as the byte 0, and then be
        # looked up on read as the integer 0 -- which misses a %slot keyed by the
        # string '00'. Writes would succeed and every read would fail.
        croak sprintf 'Dancer2::Session::Pg: key id %s must be a canonical integer in 0..255'
          . ' -- it is one byte of every stored payload', "'$id'"
          if $id !~ m/\A(?:0|[1-9][0-9]*)\z/msx || $id > 255;    ## no critic (RegularExpressions::ProhibitEnumeratedClasses) -- [0-9] is ASCII-only; \d and [[:digit:]] both match Unicode digits

        my $spec = $configured->{$id};
        croak "Dancer2::Session::Pg: encryption_keys entry $id must be a hash with 'key' and 'alg'"
          if ref $spec ne 'HASH';

        my $cipher = _resolve_cipher( $spec->{'alg'} );
        $cipher->cipher_self_check;

        # One cipher id, one implementation. Several slots may share a cipher --
        # that is an ordinary key rotation -- but two DIFFERENT classes claiming
        # one id would defeat the header's cross-check, which is the only thing
        # that diagnoses a slot whose alg was edited in place: both would agree
        # on the id while disagreeing about everything else.
        my $claimed = $cipher->cipher_id;
        croak sprintf 'Dancer2::Session::Pg: cipher id %d is claimed by both %s and %s. '
          . 'An id identifies one implementation, and the stored header cannot tell them apart.',
          $claimed, ref $class_for_id{$claimed}, ref $cipher
          if exists $class_for_id{$claimed} && ref $class_for_id{$claimed} ne ref $cipher;
        $class_for_id{$claimed} = $cipher;

        $slot{$id} = { key => $self->_slot_key( $id, $spec->{'key'}, $cipher ), cipher => $cipher };
        push @active, $id if $spec->{'active'};
    }

    croak sprintf 'Dancer2::Session::Pg: no slot in encryption_keys is active, so there is '
      . 'nothing to write sessions with. Mark one with active => 1 (have: %s)', join q{, }, sort { $a <=> $b } keys %slot
      if !@active;

    # NOT "use the first one". Perl randomises hash order per process, so a
    # silent choice would differ between pods and between restarts of one pod --
    # every pod writing a different key, which is the rolling outage the slots
    # exist to prevent, made permanent.
    #
    # And even in a defined order, picking silently is the worst failure here:
    # activating a new slot while forgetting to deactivate the old one would
    # leave the rotation NOT DONE while looking done, and the operator would
    # then retire the old slot on schedule and lose every live session at once.
    # If the reason for rotating was that the old key leaked, it would also mean
    # quietly continuing to use the leaked key.
    croak sprintf 'Dancer2::Session::Pg: slots %s are both active, and exactly one must be. '
      . 'The active slot is the one sessions are WRITTEN with; the others stay to be read '
      . 'until their sessions expire.', join q{ and }, sort { $a <=> $b } @active
      if @active > 1;

    return \%slot;
}

sub _build__write_slot_id {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- a Moo lazy builder, reached through the attribute and never by name
    my ($self)     = @_;
    my $configured = $self->encryption_keys;
    my ($id)       = grep { ref $configured->{$_} eq 'HASH' && $configured->{$_}{'active'} }
      sort keys %{$configured};
    $self->_slots;             # so an invalid configuration croaks with ITS message, not undef
    return $id;
}

sub _slot_key {
    my ( $self, $id, $raw, $cipher ) = @_;

    croak "Dancer2::Session::Pg: the key in slot $id is empty"
      if !defined $raw || !length $raw;

    # Hex detection is EXACT here, which it could not be before: this slot names
    # its cipher, so the one correct length is known rather than guessed at from
    # a set of plausible ones.
    my $wanted = $cipher->key_bytes;
    $raw = pack 'H*', $raw
      if $raw =~ m/\A(?:[0-9a-fA-F]{2})+\z/msx && length($raw) == 2 * $wanted;    ## no critic (RegularExpressions::ProhibitEnumeratedClasses) -- [0-9] is ASCII-only; \d and [[:digit:]] both match Unicode digits

    croak sprintf 'Dancer2::Session::Pg: the key in slot %d is %d bytes, but %s needs %d. '
      . 'Generate one with: openssl rand -hex %d', $id, length $raw, $cipher->cipher_name, $wanted, $wanted
      if length($raw) != $wanted;

    return $raw;
}

has _json => ( is => 'lazy' );

sub _build__json {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- a Moo lazy builder, reached through the attribute and never by name
    my ($self) = @_;
    my $module = $self->json_module;
    croak "Dancer2::Session::Pg: implausible json_module '$module'"
      if $module !~ m/\A[[:alpha:]_]\w*(?:::[[:alpha:]_]\w*)*\z/msx;
    return use_module($module)->new->utf8(1)->canonical(1);
}

has _own_dbh => ( is => 'lazy', clearer => 1, predicate => 1 );

sub _build__own_dbh {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- a Moo lazy builder, reached through the attribute and never by name
    my ($self) = @_;
    my $dsn = $self->dsn;
    $dsn .= ';connect_timeout=' . $self->connect_timeout
      if $self->connect_timeout && $dsn !~ m/connect_timeout=/msx;

    my $dbh = DBI->connect(
        $dsn,
        $self->dbuser,
        $self->dbpass,
        {
            RaiseError     => 1,
            PrintError     => 0,
            AutoCommit     => 1,
            pg_enable_utf8 => 1,
        },
    );

    $dbh->do( sprintf 'SET statement_timeout = %d', $self->statement_timeout )
      if $self->statement_timeout;

    return $dbh;
}

sub _dbh {
    my ($self) = @_;

    # A handle we were given belongs to the caller: its attributes, its
    # transaction, its lifetime. We neither reconfigure nor reconnect it.
    #
    # RaiseError is the one exception, and it is a refusal rather than a warning
    # because without it this module reports nonsense instead of failing. With
    # DBI's default of RaiseError => 0, `do` and `execute` return undef on
    # error: a lost session write looks like a successful one, and
    # destroy_for_principal answers "0 sessions revoked" when the DELETE
    # actually failed. Being told an account's sessions are gone when they are
    # not is worse than any error this could raise.
    #
    # Checked on every access rather than memoised: a pool may hand out a
    # different handle each time, and one attribute read is cheap beside the
    # queries that follow.
    if ( $self->has_dbh ) {
        my $handle = $self->dbh;
        $handle = $handle->() if ref $handle eq 'CODE';

        croak 'Dancer2::Session::Pg: the supplied dbh has RaiseError off. This module '
          . 'checks no DBI return values of its own, so a failed write would be reported '
          . 'as a success and a failed revocation as "0 sessions". Set RaiseError => 1 on '
          . 'the handle you pass, or pass a dsn and let this module open its own.'
          if !$handle->{'RaiseError'};

        # The coderef case BUILD could not reach. Warn rather than croak:
        # AutoCommit off is a legitimate choice by the caller, who then owns the
        # commit -- unlike RaiseError off, which leaves this module reporting
        # nonsense. Once per worker, via the same message BUILD would have used.
        $self->_warn_if_manual_commit($handle);

        return $handle;
    }

    my $dbh = $self->_own_dbh;
    return $dbh if $dbh && $dbh->ping;

    # One reconnect: a process should survive a database restart without a
    # rollout, but a connection failing twice is a fault and must surface.
    #
    # Reported, because a silent reconnect is indistinguishable from nothing
    # happening. One of these after a database restart is the system working;
    # one in every process, repeatedly, is a connection being killed by
    # something -- an idle timeout, a pooler, a firewall -- and without a line
    # in the log there is nothing to notice.
    $self->_report_once( 'info', 'the database connection had gone away and was reopened (reported once per worker)' );
    $self->_clear_own_dbh;
    return $self->_own_dbh;
}

has _table => ( is => 'lazy' );

sub _build__table {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- a Moo lazy builder, reached through the attribute and never by name
    my ($self) = @_;
    my $schema = $self->dbschema;
    return $self->_dbh->quote_identifier( $self->dbtable )
      if !defined $schema || !length $schema;
    return $self->_dbh->quote_identifier( undef, $schema, $self->dbtable );
}

has _principal_column => ( is => 'lazy' );

sub _build__principal_column {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- a Moo lazy builder, reached through the attribute and never by name
    my ($self) = @_;

    # An identifier cannot be a bind parameter, so the only safe way to put a
    # configured column name into SQL is to let the driver quote it.
    return $self->_dbh->quote_identifier( $self->principal_column );
}

sub _principal_of {
    my ( $self, $data ) = @_;
    my $key   = $self->principal_key;
    my $value = ref $key eq 'CODE' ? $key->($data) : $data->{$key};

    # Only a scalar is worth indexing, and a reference is not an identifier.
    #
    # REPORTED, because this is a configuration mistake that disables a security
    # feature in silence. principal_key pointing at a structure leaves the column
    # NULL, destroy_for_principal then never finds the session, and suspending
    # the account quietly fails to end it. The VALUE is not logged -- it is
    # session content, and some of it is the reason this module encrypts.
    if ( ref $value ) {
        $self->_report_once( 'warning',
                'principal_key produced a '
              . ref($value)
              . ' reference rather than a value, so '
              . 'the principal column was left NULL. Sessions written this way cannot be found '
              . 'by destroy_for_principal. Give principal_key a coderef that returns one scalar.' );
        return ();
    }

    return $value;
}

# ---------------------------------------------------------------------------
# Payload
# ---------------------------------------------------------------------------
#
# Layout: version || cipher id || key id || iv || tag || ciphertext.

has _reported => ( is => 'ro', default => sub { {} } );

# ---------------------------------------------------------------------------
# What this module logs, and the much longer list of what it does not
# ---------------------------------------------------------------------------
#
# THE SESSION ID IS A BEARER TOKEN. Dancer2::Core::App::_build_session takes it
# straight from the session cookie, so an id in a log file is a live credential
# in a log file, and read access to the log becomes session hijacking. That one
# fact rules out most of what a store like this would otherwise report: no id on
# a retrieve, a write, a destroy or a decrypt failure. The principal is out for
# the same reason plus a second one -- it names a person, and the clear column
# exists so that revocation needs no decryption, not so that every request
# writes an account identifier to disk.
#
# So nothing here is logged per session. What IS logged is per PROCESS and
# per CONFIGURATION: states an operator can act on, each reported once, with
# counts and integers rather than identifiers.
#
# `report_once` and not `log`: anything on the request path can fire on every
# request, and a message repeated ten thousand times is a message nobody reads.
sub _report_once {
    my ( $self, $level, $message ) = @_;
    return if $self->_reported->{$message}++;
    $self->log_cb->( $level, "Dancer2::Session::Pg: $message" );
    return;
}

# An unreadable row is not an error: it is a session this engine does not have,
# and Dancer2 answers that by starting a fresh one. But silence here is how a
# changed key becomes "everybody keeps getting logged out" with nothing written
# down anywhere.
sub _unreadable {
    my ( $self, $message ) = @_;
    $self->_report_once( 'warning', "a stored session could not be read: $message" );
    return;
}

# THE PAYLOAD IS SEALED AGAINST THE SESSION IT BELONGS TO. The header and the
# session id go in as additional authenticated data: authenticated, not
# encrypted, so they are covered by the tag without being stored twice.
#
# Without this the tag covers the payload and nothing else, and a payload is
# then portable between rows. Somebody with UPDATE on this table and NO
# ENCRYPTION KEY AT ALL could copy an administrator's sealed session_data into
# their own row and their cookie would open it -- the bytes verify, because
# nothing in them says which session they were for. Binding the id makes that
# copy fail to decrypt, which is the same answer the module gives to any other
# alteration.
# WHAT GOES IN THE `id` COLUMN IS A DIGEST, NOT THE COOKIE.
#
# The session id IS a bearer token: Dancer2 takes it straight off the cookie and
# this module hands back whatever it unlocks. Storing it verbatim would mean a
# database dump contained a working credential for every unexpired session --
# readable without the encryption key and replayable against any reachable
# instance of the application. Encrypting the payload while storing the id in
# the clear protects what is inside the house and leaves the front door key
# under the mat.
#
# So the column holds SHA-256 of the id. The cookie is unchanged, every lookup
# hashes first, and a dump yields digests that cannot be replayed.
#
# UNKEYED, deliberately. A keyed digest would also stop an attacker confirming a
# guessed id, but Dancer2's ids are long and random -- the same reason an API
# token needs no salt. And a key here could never be rotated: rotating it would
# orphan every live session, in a module whose entire design is that keys
# rotate. One un-rotatable key hiding among the rotatable ones is a worse trap
# than the attack it would prevent.
#
# The payload binding in _aad still uses the RAW id, so a sealed payload stays
# tied to the session it was written for rather than to its digest.
sub _row_id {
    my ( $self, $id ) = @_;
    return sha256_hex( defined $id ? $id : q{} );
}

sub _aad {
    my ( $self, $header, $id ) = @_;
    return $header . ( defined $id ? $id : q{} );
}

sub _encrypt {
    my ( $self, $id, $data ) = @_;

    my $slot_id = $self->_write_slot_id;
    my $slot    = $self->_slots->{$slot_id};
    my $cipher  = $slot->{'cipher'};

    my $iv     = Crypt::PRNG::random_bytes( $cipher->iv_bytes );
    my $header = pack 'C3', FORMAT_VERSION, $cipher->cipher_id, $slot_id;
    my ( $ciphertext, $tag ) = $cipher->seal( $slot->{'key'}, $iv, $self->_json->encode($data), $self->_aad( $header, $id ) );
    return $header . $iv . $tag . $ciphertext;
}

sub _decrypt {
    my ( $self, $id, $blob ) = @_;
    return () if !defined $blob || length $blob < HEADER_BYTES;

    my ( $version, $cipher_id, $key_id ) = unpack 'C3', $blob;

    return $self->_unreadable("stored format version $version is not one this release writes")
      if $version != FORMAT_VERSION;

    # The row names its slot, so this is one lookup. Not a loop over every key:
    # trying them all would turn a misconfiguration into something that looks
    # exactly like a tampered row.
    my $slot = $self->_slots->{$key_id};
    return $self->_unreadable(
        "key id $key_id is not configured" . ' -- keep the retired slot in encryption_keys until its sessions have expired' )
      if !$slot;

    my $cipher = $slot->{'cipher'};

    # The cipher id is a CROSS-CHECK rather than a selector: the slot already
    # says which cipher it uses. They disagree only when a slot's alg was edited
    # in place while rows written under the old one were still alive, which is
    # the one rotation mistake the slots cannot prevent -- so say exactly that
    # instead of letting it surface as a decrypt failure.
    return $self->_unreadable(
        sprintf 'slot %d now says %s, but this row was written with '
          . 'cipher id %d. Changing a slot\'s alg in place strands its sessions; give the '
          . 'new cipher a slot of its own',
        $key_id, $cipher->cipher_name, $cipher_id )
      if $cipher_id != $cipher->cipher_id;

    my $key = $slot->{'key'};

    my $tag_at  = HEADER_BYTES + $cipher->iv_bytes;
    my $body_at = $tag_at + $cipher->tag_bytes;
    return () if length $blob <= $body_at;

    my $plain = eval {
        $cipher->unseal(
            $key,
            substr( $blob, HEADER_BYTES, $cipher->iv_bytes ),
            substr( $blob, $body_at ),
            substr( $blob, $tag_at, $cipher->tag_bytes ),
            $self->_aad( substr( $blob, 0, HEADER_BYTES ), $id ),
        );
    };
    return $self->_unreadable(
        sprintf '%s did not authenticate it -- the key of its slot in encryption_keys'
          . ' has changed, the row was altered, or the payload belongs to a different session id',
        $cipher->cipher_name
    ) if !defined $plain;

    my $data = eval { $self->_json->decode($plain) };
    return $self->_unreadable('it decrypted, but is not the JSON this module wrote')
      if !defined $data;

    return $data;
}

# ---------------------------------------------------------------------------
# Dancer2::Core::Role::SessionFactory
# ---------------------------------------------------------------------------

sub _retrieve {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- required by Dancer2::Core::Role::SessionFactory, which is what calls it
    my ( $self, $id ) = @_;
    my $table = $self->_table;

    # Expiry is decided by the server's clock. Application clocks drift, and two
    # processes disagreeing about whether a session is alive makes the answer
    # depend on which one the request reached.
    my $row =
      $self->_dbh->selectrow_arrayref( "SELECT session_data FROM $table WHERE id = ? AND (expires IS NULL OR expires > now())",
        undef, $self->_row_id($id), );

    return () if !$row;
    return $self->_decrypt( $id, $row->[0] );
}

sub _flush {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- required by Dancer2::Core::Role::SessionFactory, which is what calls it
    my ( $self, $id, $data ) = @_;
    my $table = $self->_table;

    my $seconds = $self->has_session_duration ? $self->session_duration              : undef;
    my $expires = defined $seconds            ? q{now() + (? * interval '1 second')} : 'NULL';

    my ( @columns, @values, @bind );
    push @columns, 'id';
    push @values,  q{?};
    push @bind,    [ $self->_row_id($id), undef ];
    if ( defined $self->principal_key ) {

        # Assigned to a scalar first, ON PURPOSE. _principal_of returns a bare
        # `return;` when the value is not a scalar, which in LIST context is an
        # empty list -- so inlining the call would collapse the pair to a
        # one-element arrayref. It binds NULL either way today, which is the
        # intended result, but by luck rather than by design.
        my $principal = $self->_principal_of($data);
        push @columns, $self->_principal_column;
        push @values,  q{?};
        push @bind,    [ $principal, undef ];
    }
    push @columns, 'session_data';
    push @values,  q{?};
    push @bind,    [ $self->_encrypt( $id, $data ), { pg_type => PG_BYTEA } ];
    push @columns, 'created';
    push @values,  'now()';
    push @columns, 'updated';
    push @values,  'now()';
    push @columns, 'expires';
    push @values,  $expires;
    push @bind,    [ $seconds, undef ] if defined $seconds;

    # `expires` is NOT reassigned on conflict, and that is the whole point of the
    # cap. Dancer2::Core::Role::SessionFactory documents session_duration as a
    # limit on session validity regardless of the cookie; a limit that every
    # write pushes further away is not a limit, and the session that would never
    # reach it is exactly the one an attacker holding stolen cookies is using.
    # The row keeps the expiry it was created with.
    my $assignments = join ",\n       ", map { "$_ = EXCLUDED.$_" }
      grep { $_ ne 'id' && $_ ne 'created' && $_ ne 'updated' && $_ ne 'expires' } @columns;

    my $sql = sprintf <<'SQL', $table, join( q{, }, @columns ), join( q{, }, @values ), $assignments;
INSERT INTO %s (%s)
VALUES (%s)
ON CONFLICT (id) DO UPDATE
   SET %s,
       updated = now()
SQL

    my $sth = $self->_dbh->prepare($sql);
    my $n   = 0;
    for my $b (@bind) {
        $n++;
        $b->[1] ? $sth->bind_param( $n, $b->[0], $b->[1] ) : $sth->bind_param( $n, $b->[0] );
    }
    $sth->execute;
    return;
}

sub _destroy {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- required by Dancer2::Core::Role::SessionFactory, which is what calls it
    my ( $self, $id ) = @_;
    croak 'Dancer2::Session::Pg: no session id passed to _destroy' if !defined $id;
    my $table = $self->_table;
    $self->_dbh->do( "DELETE FROM $table WHERE id = ?", undef, $self->_row_id($id) );
    return;
}

sub _change_id {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- required by Dancer2::Core::Role::SessionFactory, which is what calls it
    my ( $self, $old_id, $new_id ) = @_;
    my $table = $self->_table;

    # A rename cannot be a rename any more. The payload is sealed against its
    # session id, so moving the row to a new id means RE-SEALING it -- which is
    # the price of making a payload unportable between rows, and it is charged
    # on login, where one extra round trip is affordable.
    my $row  = $self->_dbh->selectrow_arrayref( "SELECT session_data FROM $table WHERE id = ?", undef, $self->_row_id($old_id) );
    my $data = $row ? $self->_decrypt( $old_id, $row->[0] ) : undef;

    if ( !defined $data ) {

        # Nothing readable to carry across. Delete rather than rename: a payload
        # nobody can open is worth less under a new id than it is gone, and the
        # caller still holds the session, so the next flush writes it afresh.
        $self->_dbh->do( "DELETE FROM $table WHERE id = ?", undef, $self->_row_id($old_id) );
        return;
    }

    my $sth = $self->_dbh->prepare("UPDATE $table SET id = ?, session_data = ?, updated = now() WHERE id = ?");
    $sth->bind_param( 1, $self->_row_id($new_id) );
    $sth->bind_param( 2, $self->_encrypt( $new_id, $data ), { pg_type => PG_BYTEA } );
    $sth->bind_param( 3, $self->_row_id($old_id) );
    $sth->execute;
    return;
}

sub _sessions {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) -- required by Dancer2::Core::Role::SessionFactory, which is what calls it
    my ($self) = @_;
    my $table  = $self->_table;
    my $ids    = $self->_dbh->selectcol_arrayref("SELECT id FROM $table WHERE expires IS NULL OR expires > now()");
    return $ids || [];
}

# ---------------------------------------------------------------------------
# What the clear columns make possible
# ---------------------------------------------------------------------------

sub _require_principal {
    my ( $self, $method ) = @_;
    croak sprintf
      'Dancer2::Session::Pg: %s needs principal_key to be configured, and a %s column in the table',
      $method, $self->principal_column
      if !defined $self->principal_key;
    return;
}

sub destroy_for_principal {
    my ( $self, $principal ) = @_;
    $self->_require_principal('destroy_for_principal');
    croak 'Dancer2::Session::Pg: destroy_for_principal needs a principal'
      if !defined $principal || !length $principal;
    my $table  = $self->_table;
    my $column = $self->_principal_column;
    return 0 + $self->_dbh->do( "DELETE FROM $table WHERE $column = ?", undef, $principal );
}

# THE OTHER HALF OF sessions(). _sessions returns what the id column holds,
# which is a digest, and Dancer2::Core::Role::SessionFactory documents those
# values as the input to a cleaning script. Hashing is what breaks that: handing
# a digest back to destroy() would hash it a second time and match no row, so
# the script would report success having deleted nothing.
#
# So the pair is explicit rather than clever. destroy() takes a session id and
# hashes it; this takes a value the id column already holds and does not. Each
# method has ONE input language, and passing the wrong one croaks instead of
# quietly doing nothing.
#
# Deliberately NOT a shape check inside destroy(): a digest is 64 hex characters
# and a Dancer2 id is 32 base64url ones, so they cannot collide today -- but
# generate_id is overridable, and a heuristic in the main delete path would turn
# somebody's custom id format into a silent no-op. A separate method cannot.
sub destroy_row {
    my ( $self, $row_id ) = @_;

    croak 'Dancer2::Session::Pg: destroy_row needs a row id from sessions() or '
      . 'sessions_for_principal() -- 64 hex characters. To delete by SESSION id, '
      . 'which is what a cookie holds, use destroy() instead'
      if !defined $row_id
      || $row_id !~ m/\A[0-9a-f]{64}\z/msx;    ## no critic (RegularExpressions::ProhibitEnumeratedClasses) -- sha256_hex output is ASCII lower-case hex; [[:xdigit:]] is Unicode-aware and allows A-F

    my $table = $self->_table;
    return 0 + $self->_dbh->do( "DELETE FROM $table WHERE id = ?", undef, $row_id );
}

sub sessions_for_principal {
    my ( $self, $principal ) = @_;
    $self->_require_principal('sessions_for_principal');
    my $table  = $self->_table;
    my $column = $self->_principal_column;
    my $ids = $self->_dbh->selectcol_arrayref( "SELECT id FROM $table WHERE $column = ? AND (expires IS NULL OR expires > now())",
        undef, $principal, );
    return $ids || [];
}

sub reap {
    my ($self) = @_;
    my $table = $self->_table;
    return 0 + $self->_dbh->do("DELETE FROM $table WHERE expires IS NOT NULL AND expires <= now()");
}

# THE NUMBERS IN ONE ROUND TRIP, because they are only useful together: live
# sessions say how many browsers are holding one, signed_in says how many belong
# to somebody, and expired says how much reap() would remove right now -- a
# number that only grows if the reaping trigger has stopped working.
#
# NOTHING IS DECRYPTED and nobody is named. The clear columns answer all of them,
# which is what they are for.
#
# `signed_in` IS ABSENT when principal_key is unset, rather than zero or undef.
# The column need not exist in that configuration, so there is no query that
# could answer it -- asking anyway used to be a crash against the table this
# module's own documentation tells you to create.
sub count_sessions {
    my ($self)  = @_;
    my $table   = $self->_table;
    my $live    = 'count(*) FILTER (WHERE expires IS NULL OR expires > now())';
    my $expired = 'count(*) FILTER (WHERE expires IS NOT NULL AND expires <= now())';

    if ( !defined $self->principal_key ) {
        my ( $l, $e ) = $self->_dbh->selectrow_array("SELECT $live, $expired FROM $table");
        return { live => $l, expired => $e };
    }

    my $column = $self->_principal_column;
    my ( $l, $s, $e ) = $self->_dbh->selectrow_array(
        "SELECT $live,
                count(*) FILTER (WHERE (expires IS NULL OR expires > now())
                                   AND $column IS NOT NULL),
                $expired
           FROM $table"
    );
    return { live => $l, signed_in => $s, expired => $e };
}

1;
__END__

=encoding utf8

=for stopwords AEAD AES ChaCha DDL DSN GCM Kubernetes NIST OpenID Poly XHR unkeyed atomicity upsert upserting crashloops dbh dbpass dbschema dbtable dbuser decrypt decryptable decrypted decrypts deserialise deserialising diagnosable dsn encryptions nonces plaintext preforked rollout serialiser tablespace Koivunalho Mikko

=head1 NAME

Dancer2::Session::Pg - PostgreSQL session backend for Dancer2

=head1 VERSION

version 0.001

=head1 STATUS

Package Dancer2::Session::Pg is under development so changes in the API
are possible, though not likely.

=head1 SYNOPSIS

    use Dancer2::Session::Pg ();

    my $engine = Dancer2::Session::Pg->new(
        dsn              => 'dbi:Pg:dbname=app;host=db',
        dbuser           => 'app_web',
        dbpass           => $ENV{'APP_DB_PASSWORD'},
        dbtable          => 'sessions',          # required
        dbschema         => 'web',               # optional; else search_path
        session_duration => 900,

        # One or more SLOTS, each pairing a key with the cipher that uses it.
        # Exactly one is active: that is the one sessions are written with, and
        # the rest stay to be read. See SECURITY for where the key comes from.
        encryption_keys => {
            0 => {
                key    => $ENV{'SESSION_KEY_0'},
                alg    => 'AES-256-GCM',
                active => 1,
            },
        },

        # Optional; see THE PRINCIPAL COLUMN for whether you want it at all.
        principal_key    => 'principal',
        principal_column => 'account_id',
    );

Most applications configure this from F<config.yml> rather than in Perl -- see
L<Dancer2::Session::Pg/A configuration file>. Installing the engine by hand is
for when C<dbh> has to
be a coderef, something YAML cannot express, and there is a trap in doing it
which L<Dancer2::Session::Pg/CONNECTIONS> describes.

=head1 DESCRIPTION

Stores Dancer2 sessions in PostgreSQL, and uses PostgreSQL's own features to
make that storage safer than a serialised blob in a table.

A web session is not ordinary data. It frequently carries the credentials that
prove who somebody is -- with OpenID Connect, an access token and a refresh
token -- so the store is worth more than the account it belongs to. Three
properties follow from that, and each is provided by the database rather than by
convention:

=over 4

=item Authenticated encryption at rest

The payload is encrypted with an AEAD cipher, so a dump, a backup or a support
copy of the table does not hand over the contents of a session, and a row that
has been altered fails to decrypt instead of deserialising into a structure the
application would then trust.

Nor does it hand over a way in. B<The session id is stored as a SHA-256 digest,
not verbatim>, because the id is the session cookie: a table full of raw ids
would be a table full of working credentials, usable against the live
application by anyone who read a backup, no key required. What a dump contains
is digests, which open nothing.

The id is also authenticated with the payload, so a sealed payload opens only
under the session it was written for and cannot be moved from one row to
another.
L<Dancer2::Session::Pg/SECURITY> says what that stops, where the key should
live, and when to rotate
it.

Which cipher is a property of the key it is used with, and both are
B<replaceable>: every payload records the key and the cipher that sealed it, so
a cipher found wanting next year is three deployments rather than a forced
logout. See L<Dancer2::Session::Pg/THE STORED PAYLOAD>,
L<Dancer2::Session::Pg/Rotating the key> and
L<Dancer2::Session::Pg::Cipher>.

=item Expiry decided by the server's clock

C<expires> is a C<timestamptz> and every read filters on it. Application clocks
drift; the database's clock is the one every process shares, so all of them
agree about whether a session is still alive.

The expiry is set when the row is created and B<is not moved by later writes>.
C<session_duration> is therefore an absolute cap measured from creation, which is
what L<Dancer2::Core::Role::SessionFactory> describes: a limit on session
validity, regardless of the cookie. An idle timeout is a different thing and is
the cookie's job -- see C<cookie_duration>, which slides.

This matters more than it sounds. A cap that every request pushes further away is
never reached by a session in continuous use, and a session in continuous use is
what somebody holding stolen cookies has.

=item Atomic writes

Sessions are written with C<INSERT ... ON CONFLICT DO UPDATE>, which is atomic.
Any number of workers may write one session id concurrently without producing a
duplicate row, a unique violation or a deadlock, and without moving the expiry
cap.

That is a guarantee about database integrity, not about every write succeeding:
concurrent writers to one row serialise on its lock, and a waiter that exceeds
C<statement_timeout> is cancelled on purpose rather than holding a worker. See
L<Dancer2::Session::Pg/A blocked write fails rather than waiting>.

It does B<not> mean two workers cannot lose each other's changes. The payload is
one encrypted blob, so a write replaces all of it and the last writer wins. See
L<Dancer2::Session::Pg/CONCURRENCY>, which says exactly what is and is not
promised, and is backed by
a test rather than by this paragraph.

=back

On top of that, an B<optional> clear column beside the encrypted payload makes it
possible to find and end every session belonging to one account without
decrypting anything -- see L<Dancer2::Session::Pg/destroy_for_principal>.
Suspending an account has
little effect while the suspended user's cookie still works. That column is off
by default and need not exist; L<Dancer2::Session::Pg/THE PRINCIPAL COLUMN> is
about whether you want
it.

=head2 Why this is PostgreSQL and not portable SQL

A reasonable question, since a session row is four columns and a blob. The
answer is that the three guarantees above are not properties of the schema --
they are properties of statements and settings that standard SQL either does not
have or does not define strongly enough to rely on.

=over 4

=item C<INSERT ... ON CONFLICT DO UPDATE>, not C<MERGE>

The standard spells an upsert C<MERGE>, PostgreSQL has had it since 15, and it
is B<not a substitute here>. C<MERGE> decides between its C<WHEN MATCHED> and
C<WHEN NOT MATCHED> branches from a snapshot; it does not take the speculative
insertion lock that C<ON CONFLICT> does, so when two transactions pick the
C<NOT MATCHED> branch for the same key, one of them inserts and the other
raises a unique violation.

That is not a theoretical difference. Sixteen processes upserting one key forty
times each, on PostgreSQL 17:

    INSERT ... ON CONFLICT DO UPDATE    0 of 16 workers failed
    MERGE                               4 of 16 workers failed
                                        ERROR: duplicate key value violates
                                        unique constraint

A session is written on more or less every request, and concurrent writes to one
session id are the normal case, not the edge: a page with parallel C<XHR>s does
it by itself. With C<MERGE> a quarter of those workers would have had to carry
retry logic for a constraint violation that cannot happen with C<ON CONFLICT>.
Writing portable SQL here would mean writing C<SELECT>-then-C<INSERT>-or-C<UPDATE>
in the application, which has the same race and loses atomicity as well.

=item C<statement_timeout>, so a blocked write fails instead of hanging

L<Dancer2::Session::Pg/A blocked write fails rather than waiting> is a
guarantee about the worker,
not the row, and it rests on a PostgreSQL setting applied per connection. The
standard has no equivalent: there is no portable way to say "cancel this
statement after 400ms". Without it a writer that lands behind an open
transaction waits as long as that transaction lives, holding a web worker the
whole time -- and a handful of those is an outage, for a session that was not
worth waiting on.

=item C<bytea>, and a driver that binds it as binary

The sealed payload is ciphertext: arbitrary bytes, which must come back byte for
byte or the authentication tag fails and the session is lost. C<bytea> with
L<DBD::Pg>'s C<PG_BYTEA> binding does that with no encoding in the middle. The
standard C<BLOB> is spelled and handled differently by every engine, and the
usual portable workaround -- base64 into a text column -- inflates every row by
a third and adds a transform to each read and write of a credential store.

=item C<timestamptz> and the server clock

Expiry is decided by C<now()> on the server, against C<timestamptz>, so one
clock decides whether a session is alive. Application clocks drift, and with
several workers the answer would otherwise depend on which machine the request
reached. C<timestamptz> also removes the zone question entirely, because
PostgreSQL stores it as an instant rather than a local time with an offset.

=back

None of this rules out a portable session store -- it rules out a portable one
with these properties. A session table meant to run on several engines is a
reasonable thing to want, and it is a different module from this one. This one
is for the case where the session store is the most security-sensitive table in
the database, and you would rather the database enforced that than your
application remembered to.

=head1 REQUIREMENTS

PostgreSQL B<9.5> or later, for C<INSERT ... ON CONFLICT DO UPDATE> -- see
L<Dancer2::Session::Pg/Why this is PostgreSQL and not portable SQL> for why
that statement and not
the standard C<MERGE>.

Perl B<v5.14> or later (Dancer2's required Perl as per L<Dancer2> B<v1.0.0>).

=head1 THE TABLE

Create it yourself. The DDL below is a starting point, not a mandate: schema
name, ownership, tablespace, index names, whether C<IF NOT EXISTS> suits your
deployment and whether the table joins an existing migration scheme are local
decisions this module has no business making.

Three things are actually required: the column B<names> and B<types> of the
columns this module writes, C<id> unique so C<ON CONFLICT (id)> has an arbiter,
and privilege to C<SELECT>, C<INSERT>, C<UPDATE> and C<DELETE>.

Put the result under whatever migration scheme you already use. A session table
that exists only in somebody's shell history disappears the next time the schema
is rebuilt, and the symptom at the far end is a login that never completes.

There are three variants below, and B<the second is the smallest thing that
works>. Start there unless you know you want the principal column.

=head2 DDL

With the optional principal column, as free text -- the general case, where the
identifier in the session is not a key of any table in this database (a
federated C<sub> claim, a tenant-scoped id, an opaque token):

    CREATE TABLE web.sessions (
        id           text        PRIMARY KEY,   -- SHA-256 hex of the session id
        principal_id text,
        session_data bytea       NOT NULL,
        created      timestamptz NOT NULL DEFAULT now(),
        updated      timestamptz NOT NULL DEFAULT now(),
        expires      timestamptz
    );

    COMMENT ON TABLE web.sessions IS
        'Dancer2 session store (Dancer2::Session::Pg). Rows hold authenticated-encrypted session payloads; treat as credential material.';

    COMMENT ON COLUMN web.sessions.id IS
        'SHA-256 of the Dancer2 session id -- NOT the id itself, which is the session cookie and would be replayable from a dump. Arbiter for ON CONFLICT.';
    COMMENT ON COLUMN web.sessions.principal_id IS
        'OPTIONAL -- drop this column if principal_key is not configured. Clear copy of the value named by principal_key, so sessions can be found and revoked without decrypting. May be free text as here, or a foreign key; see "THE PRINCIPAL COLUMN" in the module docs. NULL when the session has no such value.';
    COMMENT ON COLUMN web.sessions.session_data IS
        'AEAD-encrypted session payload: version || cipher id || key id || iv || tag || ciphertext. Unreadable without the application key, and tamper-evident.';
    COMMENT ON COLUMN web.sessions.created IS
        'When the row was first written. Server clock.';
    COMMENT ON COLUMN web.sessions.updated IS
        'When the row was last written. Server clock.';
    COMMENT ON COLUMN web.sessions.expires IS
        'When the session stops being valid. Every read filters on it. NULL means no expiry, which is rarely right for a session holding credentials.';

    CREATE INDEX sessions_principal_id_idx
        ON web.sessions (principal_id) WHERE principal_id IS NOT NULL;
    COMMENT ON INDEX web.sessions_principal_id_idx IS
        'OPTIONAL. Supports destroy_for_principal and sessions_for_principal. Partial: sessions without a principal id are not indexed.';

    CREATE INDEX sessions_expires_idx
        ON web.sessions (expires) WHERE expires IS NOT NULL;
    COMMENT ON INDEX web.sessions_expires_idx IS
        'Supports reap(). Partial: rows without an expiry are never reaped.';

=head2 DDL without the principal column

B<The smallest table this module can use.> Leave C<principal_key> unset and the
column is never written, never read and need not exist:

    CREATE TABLE web.sessions (
        id           text        PRIMARY KEY,   -- SHA-256 hex of the session id
        session_data bytea       NOT NULL,
        created      timestamptz NOT NULL DEFAULT now(),
        updated      timestamptz NOT NULL DEFAULT now(),
        expires      timestamptz
    );

    CREATE INDEX sessions_expires_idx
        ON web.sessions (expires) WHERE expires IS NOT NULL;

=head2 DDL with the principal column as a foreign key

When the identifier in the session B<is> a key of a table in this same database,
the column can be a real foreign key rather than free text. Name it after what
it references -- C<principal_column> exists for that -- and let the database
keep it honest:

    -- Your accounts table already exists. It is shown here only so that the
    -- example below is complete and can be applied as it stands.
    CREATE TABLE web.accounts (
        id    bigint PRIMARY KEY,
        email text   NOT NULL
    );

    CREATE TABLE web.sessions (
        id           text        PRIMARY KEY,   -- SHA-256 hex of the session id
        account_id   bigint      REFERENCES web.accounts(id) ON DELETE CASCADE,
        session_data bytea       NOT NULL,
        created      timestamptz NOT NULL DEFAULT now(),
        updated      timestamptz NOT NULL DEFAULT now(),
        expires      timestamptz
    );

    COMMENT ON COLUMN web.sessions.account_id IS
        'OPTIONAL. Foreign key to web.accounts(id), written by Dancer2::Session::Pg from the session key named by principal_key. ON DELETE CASCADE: deleting an account ends its sessions in the same statement.';

    CREATE INDEX sessions_account_id_idx
        ON web.sessions (account_id) WHERE account_id IS NOT NULL;

    CREATE INDEX sessions_expires_idx
        ON web.sessions (expires) WHERE expires IS NOT NULL;

=head2 Choosing a foreign key

The table above is configured as:

    principal_key:    "account_id"     # the session key to copy
    principal_column: "account_id"     # the column to copy it into

C<ON DELETE CASCADE> is the reason to do this: deleting an account ends its
sessions in the same statement, with no application code to forget. But a
foreign key is a constraint, and a constraint has consequences the free-text
column does not. Read these before choosing it:

=over 4

=item *

B<A session write fails if the principal is not a row in the referenced table.>
That is the point of a foreign key, and it is also a way to break every request
for one user: a subject id that has not been provisioned locally yet, a
soft-deleted account, an id from another tenant's table. If the identifier in
your session is not guaranteed to exist as a key right now, use free text.

=item *

B<The type must match the referenced key.> A C<bigint> column will reject a
non-numeric session value at write time -- C<'anonymous'> in a column
referencing C<bigint> is an error, not a C<NULL>. This module copies the value
it is given and does not coerce it.

=item *

B<Without> C<ON DELETE CASCADE> B<or> C<SET NULL>, the default is
C<NO ACTION>, and you will not be able to delete an account until its sessions
are gone. L</destroy_for_principal> then has to run first, which is the opposite
of the automation you wanted.

=item *

B<Every session write now checks the constraint.> That is a row lock on the
referenced table for the duration of the write, on a table that is read on every
authenticated request. It is cheap, but it is not free, and it couples session
writes to the availability of the accounts table.

=back

=head1 THE PRINCIPAL COLUMN

B<It is optional, off by default, and the column can be absent from the table
entirely.> This section is about whether you want it at all.

=head2 Leaving it out

Do not set C<principal_key>. Then:

=over 4

=item *

no principal column is written and none is read, so the table in
L</DDL without the principal column> -- which does not have one -- is complete;

=item *

L</destroy_for_principal> and L</sessions_for_principal> croak if called, naming
the configuration they need rather than failing in SQL;

=item *

L</count_sessions> returns C<live> and C<expired> and B<omits> C<signed_in>,
because there is no column that could answer it;

=item *

nothing else changes. Encryption, expiry, atomic writes, L</reap> and the rest
of the module do not involve the principal at all.

=back

=head2 What it is for

An application that already keeps a stable identifier for the signed-in party
somewhere in its session -- an account id, a user id, a principal -- can have
that one value copied into a plain column beside the encrypted payload. Nothing
else is exposed. What it buys is the ability to ask "which sessions belong to
this account?" and to end them all, without decrypting anything and without
scanning every row.

That matters when an account is suspended, deleted, or has its password or roles
changed. Until its sessions are gone, the change has not really taken effect --
the holder of the cookie carries on with the access they had. See
L</destroy_for_principal>.

=head2 Free text or a foreign key

Both work, and the module does not care which you chose: it writes the value and
reads it back, and the column's type and constraints are the database's business.

    free text      the identifier is not a key of any table HERE -- a federated
                   subject claim, an opaque id, a value from another service.
                   Nothing can go wrong at write time. Nothing keeps it honest
                   either: a typo is just a session nobody can revoke.

    foreign key    the identifier IS a key here. ON DELETE CASCADE ends an
                   account's sessions when the account goes, the database
                   guarantees the column means what it says, and a principal
                   that does not exist is refused at write time -- which is
                   either exactly what you want or an outage for one user.

See L</DDL with the principal column as a foreign key> for the trade-offs
spelled out.

=head2 When it will do nothing for you

=over 4

=item *

sessions are anonymous, as for a cart or a wizard, so there is no account to
revoke;

=item *

you never need to end sessions administratively, and expiry alone is enough;

=item *

the identity in the session is a structure rather than a value. A C<HASH> or
C<ARRAY> is skipped -- but if one scalar can be computed from it, give
C<principal_key> a coderef and that is no longer a limitation:

    principal_key => sub { return $_[0]->{'user'}{'id'} }

=back

To be plain about its provenance: this is a pattern that works, generalised from
one application. It is not an established convention of the Dancer2 session
engines, and it is offered as a capability rather than as advice about how your
sessions ought to be shaped. If it does not fit, leave C<principal_key> unset
and lose nothing else.

=head1 THE STORED PAYLOAD

    version (1 byte) || cipher id (1 byte) || key id (1 byte) || iv || tag || ciphertext
    \-------------------- 3-byte header --------------------/

Every row says what wrote it. The lengths of C<iv> and C<tag> are not in the
header: they come from the cipher the id names, so a cipher with a 24-byte nonce
needs no change to the format.

    version      1. A payload with any other version is refused, not guessed at.
    cipher id    which cipher sealed it; see Dancer2::Session::Pg::Cipher.
    key id       which SLOT sealed it -- the key and the cipher together,
                 so either can be replaced without logging anybody out.
                 See "Rotating the key".

=head2 Replacing a cipher

This is the whole reason the header exists. A cipher that turns out to be a bad
idea next year should cost a restart, not every session in the database.

    alg: "ChaCha20-Poly1305"     # was AES-256-GCM

B<Give the new cipher a slot of its own.> That is the whole procedure, and it is
the same one as changing a key, because the cipher belongs to the slot: add the
slot, move C<active>, and drop the old slot once its sessions have expired. New
sessions are sealed with the new cipher while rows written by the old one keep
decrypting until they expire, and nobody is logged out. The steps are in
L</Rotating the key>.

What you must B<not> do is edit a slot's C<alg> in place while its sessions are
still alive. The key would still be right, so the row would still find its slot,
but the cipher that wrote it would be gone. See
L</The one mistake slots cannot prevent>.

There is no separate list of readable ciphers to maintain. A cipher you can still
read but no longer write is the other slot.

=head2 Writing a cipher

A cipher is a class consuming L<Dancer2::Session::Pg::Cipher>, which is seven
small methods. A slot's C<alg> names it:

    encryption_keys:
      0: { key: "...", alg: "AES-256-GCM" }                  # kept, read only
      1:
        key:    "..."
        alg:    "My::Cipher::XChaCha20"
        active: true

In Perl, C<alg> also takes a C<[ class, %arguments ]> pair or an object already
built, for a cipher that needs constructing:

    alg => [ 'My::Cipher::XChaCha20', rounds => 20 ]
    alg => $cipher_object

Every slot's cipher is exercised when the engine is built -- a round trip, the
advertised tag length, a bit flipped in both the ciphertext and the tag, and the
additional authenticated data altered -- so a cipher that is not authenticated
encryption, or that silently drops the session-id binding, stops the process at
startup instead of accepting a forged session later. Cipher ids C<128..255> are
the third-party range.

=head1 CONFIGURATION

Most of these are type-checked with L<Type::Tiny>, which L<Dancer2> already
depends on, so nothing new is installed. The point is not tidiness: a session
engine is configured from a YAML file, and YAML produces the wrong B<shape>
easily. These are now refused when the engine is built rather than several
minutes later, somewhere less obvious:

    encryption_keys: "a key"    # a string where the slots belong
    connect_timeout: two        # would have been appended to the DSN verbatim
    dbh: "dbi:Pg:dbname=app"    # a string where a handle or coderef belongs
    principal_column: ""        # an empty identifier

A slot's C<alg> is deliberately B<not> type-checked, because it accepts four
different shapes and the cipher resolver has a specific message for each.
C<dsn>, C<dbuser>, C<dbpass> and C<dbschema> accept C<undef>, because a key
present but empty in YAML means "not set" and the checks below answer that with
a sentence you can act on.

=head2 A configuration file

The whole of it, for an application with no principal concept:

    # config.yml
    session: 'Pg'
    engines:
      session:
        Pg:
          dsn:     "dbi:Pg:dbname=app;host=db"
          dbuser:  "app_web"
          dbpass:  "..."
          dbtable: "sessions"     # required
          dbschema: "web"         # optional; omit to use search_path
          session_duration: 900

          encryption_keys:
            0:
              key:    "${ENV:SESSION_KEY_0}"
              alg:    "AES-256-GCM"
              active: true

          # and, if you want the optional principal column
          principal_key:    "principal"
          principal_column: "account_id"

          json_module:      "JSON::MaybeXS"

The C<${ENV:...}> placeholders are expanded by a config reader, which is how the
key reaches the process without being written down in the repository. See
L</Where the key should live>.

=head2 dsn, dbuser, dbpass

Passed to L<DBI>. C<connect_timeout> is appended to the DSN unless it is already
there. Required unless C<dbh> is given.

=head2 dbh

An existing C<DBI> handle, or a coderef returning one. Use this when the
application already has a connection -- from L<Dancer2::Plugin::Database>,
L<DBIx::Class>, or a pool -- rather than opening a second one.
B<A coderef cannot be written in YAML>, so this attribute means constructing the
engine in Perl: see L</CONNECTIONS>, including the one way of doing that which
fails silently.

=head3 SHARING A HANDLE

A handle you supply belongs to you. This module does not apply
C<statement_timeout>, does not reconnect it, and B<does not commit it>.

B<One requirement, and it is a refusal rather than a warning: C<RaiseError>
must be on.> This module checks no C<DBI> return value of its own, because a
handle that raises is the only arrangement in which it can report the truth. With
DBI's default of C<RaiseError =E<gt> 0>, C<execute> and C<do> answer C<undef> on
failure and carry on: a session write that never happened looks like one that
did, and L</destroy_for_principal> reports C<0> sessions revoked when the
C<DELETE> actually failed. Being told that an account's sessions are gone when
they are still live is a worse outcome than any exception. So the engine croaks
rather than proceed. Set C<RaiseError =E<gt> 1> on the handle you pass, or pass a
C<dsn> and let the module open its own.

That last one deserves a straight answer, because it is the obvious question. If
your handle has C<AutoCommit> off, a session write joins whatever transaction is
already open, and it becomes durable when you commit -- not before. It would be
easy for this module to call C<commit> and make the session "just work". It must
not: your transaction is not its transaction, and committing it would also commit
whatever unrelated work you had in flight. Silently turning somebody else's
half-finished unit of work into a permanent one is a worse failure than a session
that waits for its caller.

So the rule is: with C<AutoCommit> off on a shared handle, B<commit is yours>.
The module says so once per worker if it sees that state, because a session
write that is real in the process but not yet in the database is exactly the sort
of thing that resurfaces later as a login that did not complete.

B<When> it says so depends on which form you used, and the difference is not
cosmetic. A handle passed directly is inspected at construction, so the warning
arrives at startup. A B<coderef> cannot be: calling it there would open a
connection during construction, which is the one thing the coderef form exists
to avoid. So that handle is inspected at its first use instead, and the warning
arrives with the first request rather than at startup.

If you would rather not think about it, do not share the handle: give this module
a C<dsn> and it opens its own connection with C<AutoCommit> on, where the question
does not arise.

=head2 dbtable

The name of the table. B<Required>: there is no sensible default to guess.

=head2 dbschema

The schema the table lives in. B<Optional, and there is no default.>

When it is set, references are qualified as C<"schema"."table">. When it is not,
the table is referenced bare as C<"table"> and resolved by the connection's
C<search_path>.

This module deliberately does not assume C<public>. A deployment's default schema
may be called anything, and qualifying a name that the deployment never asked to
have qualified takes a decision that belongs to C<search_path> -- typically set
per role with C<ALTER ROLE ... SET search_path>, or per connection through the
DSN. If you rely on C<search_path>, make sure it is set somewhere durable: a
session engine that cannot find its table fails on every request.

=head2 encryption_keys

One or more B<slots>. Each slot pairs a key with the cipher that uses it, and
exactly one slot is C<active> -- the one sessions are B<written> with. The others
stay to be B<read>, until the sessions written under them have expired.

    encryption_keys:
      0:
        key:    "${ENV:SESSION_KEY_0}"
        alg:    "AES-256-GCM"
        active: true

Required, and one slot is a complete configuration: a deployment that never
rotates writes exactly that and nothing more.

=head3 Why a key and a cipher together

Because separating them makes key B<length> load-bearing, and that turns out to
infect everything. With a list of keys and one global choice of cipher, nothing
records which cipher a key was meant for, so length becomes the only thing
linking them -- and it then has to be re-derived when validating the written
key, when catching a typo in a read key, when deciding which ciphers are usable
at all, when checking a row's cipher against its key, and even when deciding
whether a configured string is hex or raw bytes.

Paired, all of that is one check in one place: B<this slot's key must fit this
slot's cipher>. Two slots may hold keys of different lengths without any of it
mattering, which is also what makes L</Changing the key length> possible.

It removes a whole attribute as well. An earlier draft had C<read_algs>, for
naming a cipher you can still read but no longer write. That B<is> the other
slot.

=head3 Each slot

=over 4

=item C<key>

The key, as raw bytes or as hex of exactly twice the length this slot's cipher
needs. Generate one with C<openssl rand -hex 32> for a 32-byte cipher. Checked
at startup against that cipher and nothing else.

=item C<alg>

Which authenticated cipher this slot uses: a built-in name, a class name, a
C<[ class, %arguments ]> pair, or an object.

    name                 key        cipher id
    AES-128-GCM          16 bytes   1
    AES-192-GCM          24 bytes   2
    AES-256-GCM          32 bytes   3
    ChaCha20-Poly1305    32 bytes   4

C<AES-256-GCM> is the usual answer: AES-NI makes it the fastest option on
essentially every server CPU in use, it is the most widely reviewed choice, and
it is the one most likely to be acceptable to whoever audits you. Prefer
C<ChaCha20-Poly1305> on hardware without AES acceleration.
C<< Dancer2::Session::Pg->algorithms >> lists the built-in names, and
L<Dancer2::Session::Pg::Cipher> is the contract for writing your own.

B<Do not edit a slot's C<alg> in place> while sessions written under it are
still alive. Give the new cipher a slot of its own; that is what slots are for,
and the engine will tell you if you do it the other way.

=item C<active>

True on exactly one slot. Not a pointer kept elsewhere, so it cannot dangle.

B<Two active slots is a startup error, and deliberately so.> Picking one
silently would be unsafe twice over: Perl randomises hash order per process, so
"the first" would differ between pods and between restarts of the same pod --
every pod writing a different key, which is the outage of
L</Rotating the key> made permanent. And even in a defined order, activating a
new slot while forgetting to deactivate the old one would leave the rotation
B<not done while looking done>; the old slot would then be retired on schedule
and every live session would die at once. If the reason for rotating was that
the old key leaked, it would also mean quietly continuing to use the leaked key.

A process that refuses to start is the better failure. Under Kubernetes the pod
crashloops, the rollout halts, and the previous generation carries on serving.

=back

The slot id is C<0 .. 255>, being one byte of every stored payload. It is the
structure's key rather than a position, so slots cannot be reordered into
meaning something else.

=head2 principal_key

What to copy into the principal column, or C<undef> -- the default -- to turn the
feature off entirely. Either the name of a session key, or a coderef handed the
session data:

    principal_key => 'account_id'                  # a session key name
    principal_column => 'account_id'

    principal_key => sub { $_[0]->{'user'}{'id'} }  # computed

A coderef must not throw: it runs inside the session write, so an exception there
fails the request. A non-scalar result from either form is skipped, the column is
left C<NULL>, and the fact is reported once through C<log_cb> -- see
L</THE PRINCIPAL COLUMN>, which is about whether you want any of this.

=head2 principal_column

The column C<principal_key>'s value is written to. Defaults to
C<principal_id>, and ignored entirely when C<principal_key> is unset.

Named separately from the session key because the two answer to different
things: the session key is the application's vocabulary, the column is the
database's. A deployment making the column a foreign key will want it named after
the table it references. The name is quoted by the driver, so it may be any legal
identifier -- except one this module writes itself (C<id>, C<session_data>,
C<created>, C<updated>, C<expires>), which is refused at construction because
C<_flush> would then name the same column twice in one C<INSERT>.

=head2 json_module

The module used to serialise the session before encryption. Default
L<JSON::MaybeXS>. Any module offering the L<JSON::XS> object interface --
C<new>, C<utf8>, C<canonical>, C<encode>, C<decode> -- will do, including
L<JSON::PP> and L<Cpanel::JSON::XS>.

Sessions written with one serialiser are readable by another, since the stored
form is plain JSON before encryption.

=head2 connect_timeout, statement_timeout

Seconds and milliseconds, defaulting to C<DEFAULT_CONNECT_TIMEOUT> (2) and
C<DEFAULT_STATEMENT_TIMEOUT_MS> (2000), applied only to a connection this
module opens. A session write that blocks indefinitely blocks a worker
indefinitely.

=head1 CONNECTIONS

Five ways to give this engine a database, in increasing order of how much Perl
you have to write. The first needs none and is the right answer unless you have
a reason.

=head2 1. Let the engine open its own connection

Give it C<dsn>, C<dbuser> and C<dbpass> and there is nothing else to do. It
opens one connection per worker process with C<AutoCommit> on, C<RaiseError> on,
a connect timeout and a statement timeout, reconnects once if the database
restarts, and commits its own writes. All of it fits in F<config.yml>:

    engines:
      session:
        Pg:
          dsn:            "dbi:Pg:dbname=app;host=db;port=5432"
          dbuser:         "app_web"
          dbpass:         "..."
          dbtable:        "sessions"
          encryption_keys:
            0:
              key:    "${ENV:SESSION_KEY}"
              alg:    "AES-256-GCM"
              active: true

The cost is one more connection per worker than the application strictly needs.
With a dozen workers that is a dozen connections; with a thousand it is a reason
to read on.

=head2 2. Share the application's handle

Everything below passes C<dbh>, and C<dbh> is either a handle or a coderef
returning one. B<Prefer the coderef.> It is re-invoked on every access, so it
keeps working with a pool that hands out a different handle over time, or after
a reconnect that replaced the handle the engine was given once.

A coderef cannot be expressed in YAML, so the engine has to be built in Perl.
Do that in the application package, and B<install it with
C<set_session_engine>>.

The examples below take the slots from C<< config->{'session_keys'} >>, meaning a
top-level key in F<config.yml> rather than one under C<engines>. The structure is
the same either way, and keeping it in the configuration is what lets the keys
themselves stay in the environment -- see L</Where the key should live>:

    # config.yml
    session_keys:
      0:
        key:    "${ENV:SESSION_KEY_0}"
        alg:    "AES-256-GCM"
        active: true

    package MyApp;
    use Dancer2;
    use Dancer2::Session::Pg ();

    app->set_session_engine(
        Dancer2::Session::Pg->new(
            dbh              => sub { MyApp::dbh() },
            dbtable          => 'sessions',
            dbschema         => 'web',
            encryption_keys  => config->{'session_keys'},
            session_duration => 900,
        )
    );

=head3 Why not "set session => $engine"

Because it is silently ignored half the time, and the half it is ignored in is
the dangerous one.

    set session => $engine;        # works ONLY if no session engine exists yet

Dancer2's config trigger for C<session> begins C<is_ref($value) and return
$value> and never installs the object; only the lazy builder honours a reference,
and only if it has not already run. So if anything has touched the session engine
first -- another C<set session> earlier in the file, a C<session:> key in
F<config.yml>, a plugin, any code that reads a session at startup -- the
assignment does nothing at all, B<no warning is issued>, and the application
carries on with L<Dancer2::Session::Simple>: sessions in memory, unencrypted, not
shared between workers, gone at restart.

An encrypted session store that has quietly become an unencrypted one is not a
failure you want to discover from a security review. C<set_session_engine>
installs the object unconditionally. Use it.

=head2 3. From Dancer2::Plugin::Database

    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::Database;
    use Dancer2::Session::Pg ();

    app->set_session_engine(
        Dancer2::Session::Pg->new(
            dbh             => sub { database('sessions') },
            dbtable         => 'sessions',
            encryption_keys => config->{'session_keys'},
        )
    );

with the connection itself still in F<config.yml>, where it belongs:

    plugins:
      Database:
        connections:
          sessions:
            dsn:      "dbi:Pg:dbname=app;host=db"
            username: "app_web"
            password: "..."
            dbi_params:
              AutoCommit: 1
              RaiseError: 1

Set both C<dbi_params> explicitly rather than relying on what the plugin
defaults to. C<RaiseError: 1> is B<required> -- the engine croaks without it,
for the reason in L</SHARING A HANDLE> -- and with C<AutoCommit> off this module
will not commit the handle, so your sessions wait for a commit that never comes.

=head2 4. From DBIx::Class

    dbh => sub { return $schema->storage->dbh }

C<< $storage->dbh >> re-establishes the connection if it has gone away, which is
why the coderef form matters here -- a handle fetched once and kept would be the
stale one. Note that L<DBIx::Class> does not run the session SQL: this module
talks to the handle directly, and your result classes need know nothing about a
C<sessions> table.

If your schema is wrapped in transactions -- C<txn_do>, or a test running inside
a rolled-back transaction -- read L</SHARING A HANDLE> first. Session writes join
that transaction.

=head2 5. A plain DBI handle

    package MyApp;
    use Dancer2;
    use DBI ();
    use Dancer2::Session::Pg ();

    my $dbh;
    sub dbh {
        $dbh = DBI->connect( $dsn, $user, $pass,
            { AutoCommit => 1, RaiseError => 1, PrintError => 0, pg_enable_utf8 => 1 } )
            if !$dbh || !$dbh->ping;
        return $dbh;
    }

    app->set_session_engine(
        Dancer2::Session::Pg->new(
            dbh => \&dbh, dbtable => 'sessions',
            encryption_keys => config->{'session_keys'} ) );

Note the C<ping>. A handle created at startup and never checked is a handle that
breaks every request after the first database restart -- which is the work the
engine does for you in option 1, and which becomes yours the moment you supply
the handle.

B<Do not connect at module scope and hand over the bare handle> if the
application is preforked: a connection made before the fork is shared by every
child, and two children using one PostgreSQL connection corrupt each other's
protocol state. Connect lazily, as above, so each worker opens its own.

=head1 METHODS

=head2 destroy_row

    my $deleted = $engine->destroy_row($row_id);

Deletes one row by the value its C<id> column holds -- a digest, as returned by
L</sessions> or L</sessions_for_principal>. Returns the number of rows removed,
so C<0> means there was nothing there.

This exists because the C<id> column stores a digest rather than the session id
(L</Why the session id is stored as a digest>), which makes the two deletes
different operations:

    $engine->destroy( id => $from_a_cookie );   # hashes its argument
    $engine->destroy_row($from_sessions);       # does not

Using the wrong one croaks rather than silently deleting nothing. That is the
whole point of the pair: C<destroy> would hash a digest a second time and match
no row, which a cleaning script would report as a successful deletion.

So the iteration that L<Dancer2::Core::Role::SessionFactory> describes works:

    for my $row_id ( @{ $engine->sessions } ) {
        $engine->destroy_row($row_id);
    }

Although for the two cases that actually come up, one statement is better than a
loop: L</reap> for everything expired, L</destroy_for_principal> for one account.

=head2 destroy_for_principal

    my $removed = $engine->destroy_for_principal($principal);

Deletes every session whose principal column matches. Returns the number
deleted. This is how an account suspension takes effect immediately.

Croaks if C<principal_key> is not configured -- there is no column to match
against, and failing with that sentence is more use than a SQL error.

=head2 sessions_for_principal

    my $digests = $engine->sessions_for_principal($principal);

Returns an arrayref of row identifiers for a principal's unexpired sessions.
Croaks if C<principal_key> is not configured.

B<Those are digests, not session ids>, for the reason in
L</Why the session id is stored as a digest>. A digest is what L</destroy_row>
takes, so a list from here can be iterated and deleted; it is B<not> what
C<destroy> takes, which expects the value out of a cookie.

To end a principal's sessions rather than look at them, L</destroy_for_principal>
does it in one statement and never puts them in a variable.

=head2 count_sessions

    my $counts = $engine->count_sessions;

    { live => 12, signed_in => 9, expired => 3 }    # with principal_key
    { live => 12,                 expired => 3 }    # without

One query, nothing decrypted, nobody named: the clear columns answer all of it.

C<live> counts sessions that have not expired, C<expired> the rows L</reap> would
remove now -- a number that only grows if reaping has stopped -- and
C<signed_in> those among the live ones carrying a principal.

B<C<signed_in> is absent, not zero, when C<principal_key> is unset.> The column
need not exist in that configuration, so there is no query that could answer it.
Test with C<exists> if your caller handles both:

    my $counts = $engine->count_sessions;
    say "signed in: $counts->{'signed_in'}" if exists $counts->{'signed_in'};

=head2 reap

    my $removed = $engine->reap;

Deletes rows whose C<expires> has passed, and returns the number deleted. An
expired row is still encrypted credential material, and keeping it serves no
purpose.

Something has to call it. A scheduled job is the obvious answer, but it is not
the only one, and this module does not care which you choose -- pruning can just
as well live in the database, as a C<pg_cron> job or as a sampled trigger on the
table. A database-side rule keeps the retention policy with the data and needs
nothing of the application; a trigger, though, prunes only when there is
activity, which is worth knowing before choosing one.

=head2 algorithms

    my @alg = Dancer2::Session::Pg->algorithms;

Returns the built-in cipher names, which are the values a slot's C<alg> accepts
by name. A cipher of your own is not listed, because nothing registers it
globally -- see L</Writing a cipher>.

=head1 CONCURRENCY

Measured with real processes in F<t/concurrency.t>, not reasoned about. At the
default size that is 8 processes making 200 writes to one session id, and the
two environment variables in that file turn it up.

=head2 What is promised

=over 4

=item *

B<One row.> Concurrent writers to one session id produce a single row. No
duplicate, no unique violation, no deadlock, no write that errors out.

=item *

B<The expiry cap holds.> C<expires> and C<created> are set by the first write and
excluded from the conflict update, so after any number of concurrent writes
C<expires> is still exactly C<created> plus C<session_duration>. This is the
invariant worth the most: a race that moved the cap would hand an attacker with
stolen cookies a session that never expires.

=item *

B<The payload is never torn.> A reader sees one writer's complete, decryptable
payload. It cannot see half of one write and half of another, because the blob is
written as a single value in a single statement.

=back

=head2 What is NOT promised

B<Two workers can lose each other's changes, and will.> The session is one
encrypted blob, so a write replaces the whole of it:

    worker A                        worker B
    read  { cart => [apple] }
                                    read  { cart => [apple] }
    write { cart => [apple, pear] }
                                    write { cart => [apple], step => address }

    # the result holds B's step and has lost A's pear

Last writer wins, outright. That is not a defect of this module -- it is what any
session store holding a serialised blob does, including
L<Dancer2::Session::Simple> and L<Dancer2::Session::YAML> -- but it is worth
knowing before putting something in the session that two concurrent requests
might both change. A counter, a running total or a list that several requests
append to belongs in a table of its own, where the database can do the arithmetic.
In practice this bites hardest with parallel XHR from one page.

B<Which worker wins is a race>, so nothing should depend on it.

=head2 A blocked write fails rather than waiting

A write that cannot proceed -- because some other transaction holds that session's
row and has not committed -- is cancelled by C<statement_timeout> and the request
fails. It does not wait for the commit. That is deliberate: a session is not worth
waiting on, and a worker blocked indefinitely is worse than a failed request. The
usual causes are outside the application: an administrative query, a migration, a
pool connection somebody left in a transaction.

The failure is transient and leaves nothing behind; once the other transaction
ends, the same session id writes normally. This is tested too.

Note that this applies only to a connection B<this module opened>. On a handle you
supplied, C<statement_timeout> is yours to set -- see L</SHARING A HANDLE> -- and
if you have not set one, a blocked session write waits as long as the database
makes it wait.

=head1 SECURITY

=head2 The threat this module is built for

Somebody reads the database and does not have the application. A backup, a
replica, a support copy of a table, a dump in a ticket, a stolen disk. The
payload is encrypted with an AEAD cipher, so what they get is the shape of your
session traffic and not the credentials in it.

B<It is not built for an attacker who has the application's memory or its
configuration.> The key is in the process, so anyone who can read the process or
the file the key came from can read every session. Encryption at rest moves the
secret from the database to the key store; it does not remove it.

=head2 Why the session id is stored as a digest

Encrypting the payload would be half a job. B<The session id is itself a bearer
token> -- L<Dancer2> reads it from the cookie and this module hands back
whatever it unlocks -- so a table storing ids verbatim would contain a working
credential for every unexpired session. Someone who read a backup could replay
any of them against a reachable instance of the application and be logged in as
that user, B<without the encryption key and without decrypting anything>. The
most carefully sealed payload in the world does not help if the key to the front
door is in the same dump.

So the C<id> column holds C<SHA-256> of the session id. The cookie is unchanged,
every lookup hashes first, and what a dump yields is digests.

The digest is B<unkeyed>, on purpose. A keyed digest would additionally stop an
attacker confirming a guessed id, but Dancer2's ids are long and random, which is
the same reason an API token needs no salt. More importantly a key here could
never be rotated -- rotating it would orphan every live session -- and the whole
design of L</Rotating the key> is that keys rotate. A key that cannot rotate,
sitting among keys that must, would be a worse trap than the attack it prevents.

Two consequences worth knowing:

=over 4

=item *

C<_sessions> returns what is in the column, so the values it hands back are
B<digests and not session ids>. They are useful for counting and for nothing
else; you cannot turn one back into a cookie, which is the point.

=item *

The column is 64 hex characters rather than Dancer2's id, so size your index
accordingly if you are tuning.

=back

=head2 Where the key should live

B<Not in a configuration file you commit.> A key in F<config.yml> is a key in
your version control history permanently, readable by everyone who can clone the
repository and by every CI job that ever checked it out -- and rotating it then
means rotating something that is still in the history.

Keep the key in the environment and have the configuration B<refer> to it.
L<Dancer2::ConfigReader::Config::Any> describes the mechanism in its own
C<DESCRIPTION>: a config reader that extends it and expands C<${ENV:NAME}>
placeholders as the configuration is read. The configuration then names the
variable and never holds the value:

    # config.yml -- committed, and contains no secret
    engines:
      session:
        Pg:
          dbtable:        "sessions"
          encryption_keys:
            0:
              key:    "${ENV:SESSION_KEY}"
              alg:    "AES-256-GCM"
              active: true

Select the reader with the C<DANCER_CONFIG_READERS> environment variable, or
from the configuration itself with an C<additional_config_readers> key. Under
Kubernetes the variable comes from a Secret, so the key reaches the process
without being written down anywhere in the image or the repository, and a
rotation is a Secret update and a rolling restart -- which is exactly what
L</Rotating the key> is about.

Generate a key with C<openssl rand -hex 32>. Do not share one between
deployments: two environments holding one key means a session row copied from
either is valid in the other.

=head2 Rotating the key

B<Changing a single key is not one clean logout. It is a rolling outage.>

That is worth stating plainly because it is easy to assume otherwise. During a
rolling redeploy two generations of the application serve at once. If they hold
different keys, each generation cannot read what the other wrote -- so a user is
thrown out, logs in again on a pod of the other generation, and is thrown out
again, for as long as the rollout takes. Measured against a half-rolled fleet:

    one slot, key replaced:       6 of 12 requests lost the session
    two slots, active moved:      0 of 12 requests lost the session

Slots are what make the second line possible, and B<the rotation can change the
cipher at the same time>, because the cipher belongs to the slot. A key that has
to be replaced and an algorithm that has to be replaced are the same operation,
which is convenient, since the reasons tend to arrive together.

=head3 The procedure

Three deployments. The middle one is the only one that changes behaviour, and no
session is lost at any point.

=over 4

=item 1. Add the new slot, leave the old one active

    encryption_keys:
      0:
        key:    "${ENV:SESSION_KEY_0}"
        alg:    "AES-256-GCM"
        active: true
      1:
        key:    "${ENV:SESSION_KEY_1}"
        alg:    "ChaCha20-Poly1305"      # changing the cipher too, if you like

Nothing changes yet. When this has finished rolling, B<every> pod can read both
slots, which is the condition the next step needs.

=item 2. Move C<active>

    encryption_keys:
      0:
        key: "${ENV:SESSION_KEY_0}"
        alg: "AES-256-GCM"
      1:
        key:    "${ENV:SESSION_KEY_1}"
        alg:    "ChaCha20-Poly1305"
        active: true

During the rollout the old generation writes slot 0 and the new one writes slot
1, and both read both, so a request landing on either finds its session. New
sessions are sealed with the new key, and the new cipher, from here.

=item 3. Drop the retired slot, once its sessions have expired

Wait longer than C<session_duration> -- after that no readable row can still be
under slot 0 -- then remove it and restart:

    encryption_keys:
      1:
        key:    "${ENV:SESSION_KEY_1}"
        alg:    "ChaCha20-Poly1305"
        active: true

Removing it earlier logs out whoever still holds a session written under it. The
engine says so when it meets one: C<key id 0 is not configured>.

=back

Each step is a configuration change and a rolling restart, which under
Kubernetes is a Secret update and C<kubectl rollout restart>. B<Do not collapse
steps 1 and 2 into one deployment>: that is the single-slot case again, because
the pods writing slot 1 roll out alongside pods that have never heard of it.

=head3 One slot is still the simple case

A deployment that never rotates configures one slot and is done. There is no
separate single-key form to migrate away from later: adding a second slot is
the first step above, and the slot already there keeps its id, so every row it
has written stays readable.

=head3 Changing the key length

Nothing special is needed, which is the point of pairing a key with its cipher.
Each slot's key is checked against that slot's cipher and nothing else, so two
slots may hold keys of different lengths:

    encryption_keys:
      0: { key: "${ENV:OLD_16_BYTE_KEY}", alg: "AES-128-GCM", active: true }
      1: { key: "${ENV:NEW_32_BYTE_KEY}", alg: "AES-256-GCM" }

Then move C<active> as in step 2. Getting off a 16-byte key without logging
anybody out was impossible in the draft that kept the key and the cipher apart.

=head3 The one mistake slots cannot prevent

Editing a slot's C<alg> in place, rather than giving the new cipher a slot of
its own. The key is still right, so the row's key id still finds its slot -- but
the cipher that wrote it is gone, and those sessions are stranded.

The cipher id in the header exists to make that diagnosable rather than
mysterious. The engine reports:

    slot 0 now says ChaCha20-Poly1305, but this row was written with cipher
    id 3. Changing a slot's alg in place strands its sessions; give the new
    cipher a slot of its own

=head2 Rotate before 2**32 writes

Every write draws a fresh 96-bit nonce from L<Crypt::PRNG|CryptX>. That is the
right construction, and it has a ceiling: with random nonces of that size, NIST
SP 800-38D limits a single key to B<2**32 encryptions>, after which a nonce
collision becomes likely enough to matter, and a collision in GCM is not a
degradation but a break.

2**32 is about 4.3 billion session writes. That sounds unreachable and is not: a
site writing a thousand sessions a second gets there in about seven weeks. Count
your own writes rather than assuming -- one per authenticated request is a fair
estimate, since Dancer2 flushes a session it considers dirty.

This is the reason slots exist rather than being a nicety. Reaching the ceiling
is not an emergency if rotation costs a rolling restart and nobody notices.

=head2 A payload is sealed against its session id

The header and the session id go into the cipher as additional authenticated
data, so a sealed payload B<only opens under the id it was written for>.

This matters more than it looks. Without it the tag covers the payload and
nothing else, which makes a payload portable between rows: somebody with
C<UPDATE> on the sessions table and B<no key at all> could copy an
administrator's C<session_data> into their own row, and their own cookie would
then open an administrator's session. Binding the id turns that copy into a row
that does not decrypt. It is tested, in F<t/cipher.t> and against a real
database in F<t/session_pg.t>.

The cost is that renaming a row is no longer a rename: L</destroy_for_principal>
is unaffected, but session-fixation protection -- C<change_id> on login -- has to
re-seal the payload under the new id, which is one extra round trip per login.

A cipher of your own must pass the additional data through. L<Dancer2::Session::Pg::Cipher>
tests that it does, because a cipher that accepts it and silently drops it would
remove this protection while everything appeared to work.

=head2 What the clear column discloses

If you use the principal column, understand what a database dump then contains:
B<which accounts had sessions, how many, and when they were created and last
used.> That is the trade. The ability to revoke an account's sessions without
decrypting anything is the same property as the ability to read that pattern off
a backup.

Nothing else leaves the payload. If even that pattern is too much, leave
C<principal_key> unset and revoke by expiry.

=head2 Configuration is trusted input

A slot's C<alg> and C<json_module> name a class that this module loads. A deployment that
lets an untrusted party influence its session configuration has already lost, but
to be explicit: these are not safe to take from a request, a database row, or a
file anybody else can write.

=head2 What is logged, and why it is so little

B<The session id is a bearer token.> L<Dancer2> takes it straight from the
session cookie, so an id written to a log is a live credential written to a log,
and read access to that log becomes session hijacking. The principal is out for
the same reason and for a second one: it names a person.

So this module logs B<nothing per session> -- no ids on a retrieve, a write, a
destroy, or a failure to decrypt. What it does log is per process and per
configuration, each message once, through the engine's C<log_cb>:

    warning   a stored session could not be read, and which of the
              reasons it was. No id, so a run of these means "the key
              changed" or "somebody is poking at cookies" without
              saying whose session.
    warning   principal_key produced a reference rather than a value,
              so the principal column was left NULL and
              destroy_for_principal will not find those sessions. The
              value is NOT logged; it is session content.
    warning   a supplied dbh has AutoCommit off, which is also carped
              so that it reaches an engine built outside Dancer2.
    info      the connection had gone away and was reopened. One after
              a database restart is the system working; a stream of
              them is something killing connections.

Each is reported once per engine rather than once per request, because anything
on the request path otherwise produces a log nobody can read -- and because a
repeated message is how an attacker poking at cookies fills your disk.

If you want per-session audit logging, do it in the application, where you have
the request, the user and a policy about retention. A session store is the wrong
layer to decide that credentials belong in a log file.

=head1 WHAT AN UNREADABLE ROW DOES

A row that cannot be decrypted -- wrong key, a cipher this engine cannot read, a
payload somebody has edited -- is treated as B<a session that does not exist>.
Dancer2 then starts a fresh one, so the user is logged out rather than shown an
error. That is deliberate: the alternative is handing the application a structure
whose integrity has not been established.

It is also reported, once per engine per distinct reason, through the engine's
C<log_cb>. Fail-closed without a trace is how a changed key in C<encryption_keys> becomes
"users keep getting logged out" with nothing written down anywhere; once per
reason rather than once per request is so the log stays readable when somebody is
poking at cookies.

=head1 LIMITATIONS

No cross-process invalidation. A logout deletes the row, so another process sees
it gone on its next read, but there is no push: PostgreSQL C<LISTEN>/C<NOTIFY>
would allow one, and C<_destroy> and C<_change_id> are where it would be emitted.

Key rotation needs three deployments and some patience, but it costs no
sessions: see L</Rotating the key>. The old key has to stay in C<encryption_keys>
until everything written under it has expired, so the whole exercise takes
longer than C<session_duration> from start to finish, and there is no way to
shorten that without logging those sessions out.

Changing the key B<length>, or the cipher, works the same way and in the same
step; see L</Changing the key length> and L</Replacing a cipher>.

The test suite needs a PostgreSQL cluster the test user may create databases on.
Where there is none it skips, which means a smoke-test report of "pass" from such
a machine has exercised the unit tests only.

=head1 SEE ALSO

=over 4

=item * L<Dancer2::Session::Pg::Cipher> -- the cipher contract, if you are writing one

=item * L<Dancer2::Session::Pg::Cipher::AESGCM>

=item * L<Dancer2::Session::Pg::Cipher::ChaCha20Poly1305>

=item * L<Dancer2::Core::Role::SessionFactory>

=item * L<Dancer2::Session::DBI>

=item * L<Dancer2::Plugin::Database>

=item * L<Dancer2::ConfigReader::Config::Any> -- how to keep the key out of the config file

=item * L<CryptX>

=back

=begin Pod::Coverage

BUILD
FORMAT_VERSION
HEADER_BYTES
DEFAULT_CONNECT_TIMEOUT
DEFAULT_STATEMENT_TIMEOUT_MS
has_dbh

=end Pod::Coverage

=head1 AUTHOR

Mikko Koivunalho <mikko.koivunalho@iki.fi>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
