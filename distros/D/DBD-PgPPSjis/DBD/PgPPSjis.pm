package DBD::PgPPSjis;
use strict;

use DBI;
use Carp ();
use IO::Socket ();

=head1 NAME

DBD::PgPPSjis - Pure Perl PostgreSQL driver for (not raw) ShiftJIS

=head1 SYNOPSIS

  use DBI;

  my $dbh = DBI->connect('dbi:PgPPSjis:dbname=$dbname', '', '');

  # See the DBI module documentation for full details

=cut

use vars qw($VERSION);
$VERSION = '0.08010001';
my $BUFFER_LEN = 1500;
my $DEBUG;

my $sjis_leading_byte  = '[\\x81-\\x9F\\xE0-\\xFC]';
my $sjis_trailing_byte = '[\\x00-\\xFF]';
my $sjis_mbcs = $sjis_leading_byte . $sjis_trailing_byte;

my %BYTEA_DEMANGLE = (
    '\\' => '\\',
    map { sprintf('%03o', $_) => chr $_ } 0 .. 255,
);

{
    my $drh;
    sub driver {
        my ($class, $attr) = @_;
        return $drh ||= DBI::_new_drh("$class\::dr", {
            Name        => 'PgPPSjis',
            Version     => $VERSION,
            Err         => \(my $err    = 0),
            Errstr      => \(my $errstr = ''),
            State       => \(my $state  = undef),
            Attribution => 'DBD::PgPPSjis by Hiroyuki OYAMA and ShiftJIS support by INABA Hitoshi',
        }, {});
    }
}

sub pgppsjis_server_identification { $_[0]->FETCH('pgppsjis_connection')->{server_identification} }
sub pgppsjis_server_version_num    { $_[0]->FETCH('pgppsjis_connection')->{server_version_num} }
sub pgppsjis_server_version        { $_[0]->FETCH('pgppsjis_connection')->{server_version} }

sub _parse_dsn {
    my ($class, $dsn, $args) = @_;

    return if !defined $dsn;

    my ($hash, $var, $val);
    while (length $dsn) {
        if ($dsn =~ /([^:;]*)[:;](.*)/) {
            $val = $1;
            $dsn = $2;
        }
        else {
            $val = $dsn;
            $dsn = '';
        }
        if ($val =~ /([^=]*)=(.*)/) {
            $var = $1;
            $val = $2;
            if ($var eq 'hostname' || $var eq 'host') {
                $hash->{'host'} = $val;
            }
            elsif ($var eq 'db' || $var eq 'dbname') {
                $hash->{'database'} = $val;
            }
            else {
                $hash->{$var} = $val;
            }
        }
        else {
            for $var (@$args) {
                if (!defined($hash->{$var})) {
                    $hash->{$var} = $val;
                    last;
                }
            }
        }
    }
    return $hash;
}

sub _parse_dsn_host {
    my ($class, $dsn) = @_;
    my $hash = $class->_parse_dsn($dsn, ['host', 'port']);
    return @$hash{qw<host port>};
}


package DBD::PgPPSjis::dr;

$DBD::PgPPSjis::dr::imp_data_size =
$DBD::PgPPSjis::dr::imp_data_size = 0;

sub connect {
    my ($drh, $dsn, $user, $password, $attrhash) = @_;

    my $data_source_info
        = DBD::PgPPSjis->_parse_dsn($dsn, ['database', 'host', 'port']);
    $user     ||= '';
    $password ||= '';

    my $dbh = DBI::_new_dbh($drh, { Name => $dsn, USER => $user }, {});
    eval {
        my $pgsql = DBD::PgPPSjis::Protocol->new(
            hostname => $data_source_info->{host},
            port     => $data_source_info->{port},
            database => $data_source_info->{database},
            user     => $user,
            password => $password,
            debug    => $data_source_info->{debug},
            path     => $data_source_info->{path},
        );
        $dbh->STORE(pgppsjis_connection => $pgsql);

# DBD::PgPPSjis (1 of 6)

        $dbh->do(q{SET NAMES 'SJIS'});
    };
    if ($@) {
        $dbh->DBI::set_err(1, $@);
        return undef;
    }

    return $dbh;
}

sub data_sources { 'dbi:PgPPSjis:' }

sub disconnect_all {}


package DBD::PgPPSjis::db;

$DBD::PgPPSjis::db::imp_data_size =
$DBD::PgPPSjis::db::imp_data_size = 0;

# We need to implement ->quote, because otherwise we get the default DBI
# one, which ignores backslashes.  The DBD::Pg implementation doubles all
# backslashes and apostrophes; this version backslash-protects all of them.
# XXX: What about byte sequences that don't form valid characters in the
# relevant encoding?
# XXX: What about type-specific quoting?
sub quote {
    my ($dbh, $s) = @_;

    if (!defined $s) {
        return 'NULL';
    }
    else {
        # In PostgreSQL versions before 8.1, plain old string literals are
        # assumed to use backslash escaping.  But that's incompatible with
        # the SQL standard, which admits no special meaning for \ in a
        # string literal, and requires the single-quote character to be
        # doubled for inclusion in a literal.  So PostgreSQL 8.1 introduces
        # a new extension: an "escaped string" syntax E'...'  which is
        # unambiguously defined to support backslash sequences.  The plan is
        # apparently that some future version of PostgreSQL will change
        # plain old literals to use the SQL-standard interpretation.  So the
        # only way I can quote reliably on both current versions and that
        # hypothetical future version is to (a) always put backslashes in
        # front of both single-quote and backslash, and (b) use the E'...'
        # syntax if we know we're speaking to a version recent enough to
        # support it.
        #
        # Also, it's best to always quote the value, even if it looks like a
        # simple integer.  Otherwise you can't compare the result of quoting
        # Perl numeric zero to a boolean column.  (You can't _reliably_
        # compare a Perl scalar to a boolean column anyway, because there
        # are six Postgres syntaxes for TRUE, and six for FALSE, and
        # everything else is an error -- but that's another story, and at
        # least if you quote '0' it looks false to Postgres.  Sigh.  I have
        # some plans for a pure-Perl DBD which understands the 7.4 protocol,
        # and can therefore fix up bools in _both_ directions.)

# DBD::PgPPSjis (2 of 6)

        my @char = ();
        while ($s =~ /\G ( $sjis_mbcs | [\x00-\xFF] )/gsx) {
            push @char,
                {
                    # escape "C-style backslash escape sequences"
                    # to include a backslash character, write two backslashes (\\)
                    qq(\\) => q(\\\\),

                    # a single quote can be included in an escape string by writing ('')
                    qq(')  => q(''), # works even if backslash_quote is off

                    # the character with the code zero cannot be in a string constant
                    qq(\0) => q(\\0),

                }->{$1} || $1;
        }
        $s = join '', @char;

        # works even if standard_conforming_strings is any of on, off, and undef
        my $version = $dbh->FETCH('pgppsjis_connection')->{server_version_num};
        return $version >= 80100 ? "E'$s'" : "'$s'";
    }
}

sub prepare {
    my ($dbh, $statement, @attribs) = @_;

    die 'PostgreSQL does not accept queries containing \0 bytes'
        if $statement =~ /\0/;

    my $pgsql = $dbh->FETCH('pgppsjis_connection');
    my $parsed = $pgsql->parse_statement($statement);

    my $sth = DBI::_new_sth($dbh, { Statement => $statement });
    $sth->STORE(pgppsjis_parsed_stmt => $parsed);
    $sth->STORE(pgppsjis_handle => $pgsql);
    $sth->STORE(pgppsjis_params => []);
    $sth->STORE(NUM_OF_PARAMS => scalar grep { ref } @$parsed);
    $sth;
}

sub commit {
    my ($dbh) = @_;

    my $pgsql = $dbh->FETCH('pgppsjis_connection');
    eval {
        my $pgsth = $pgsql->prepare('COMMIT');
        $pgsth->execute;
    };
    if ($@) {
        $dbh->DBI::set_err(1, $@); # $pgsql->get_error_message ???
        return undef;
    }
    return 1;
}

sub rollback {
    my ($dbh) = @_;
    my $pgsql = $dbh->FETCH('pgppsjis_connection');
    eval {
        my $pgsth = $pgsql->prepare('ROLLBACK');
        $pgsth->execute;
    };
    if ($@) {
        $dbh->DBI::set_err(1, $@); # $pgsql->get_error_message ???
        return undef;
    }
    return 1;
}

sub disconnect {
    my ($dbh) = @_;

    if (my $conn = $dbh->FETCH('pgppsjis_connection')) {
        $conn->close;
        $dbh->STORE('pgppsjis_connection', undef);
    }

    return 1;
}

sub FETCH {
    my ($dbh, $key) = @_;

    return $dbh->{$key} if $key =~ /^pgppsjis_/;
    return $dbh->{AutoCommit} if $key eq 'AutoCommit';
    return $dbh->SUPER::FETCH($key);
}

sub STORE {
    my ($dbh, $key, $new) = @_;

    if ($key eq 'AutoCommit') {
        my $old = $dbh->{$key};
        my $never_set = !$dbh->{pgppsjis_ever_set_autocommit};

        # This logic is stolen from DBD::Pg
        if (!$old && $new && $never_set) {
            # Do nothing; fall through
        }
        elsif (!$old && $new) {
            # Turning it on: commit
            # XXX: Avoid this if no uncommitted changes.
            # XXX: Desirable?  See dbi-dev archives.
            # XXX: Handle errors.
            my $st = $dbh->{pgppsjis_connection}->prepare('COMMIT');
            $st->execute;
        }
        elsif ($old && !$new   ||  !$old && !$new && $never_set) {
            # Turning it off, or initializing it to off at
            # connection time: begin a new transaction
            # XXX: Handle errors.
            my $st = $dbh->{pgppsjis_connection}->prepare('BEGIN');
            $st->execute;
        }

        $dbh->{pgppsjis_ever_set_autocommit} = 1;
        $dbh->{$key} = $new;

        return 1;
    }

    if ($key =~ /^pgppsjis_/) {
        $dbh->{$key} = $new;
        return 1;
    }

    return $dbh->SUPER::STORE($key, $new);
}

sub last_insert_id {
    my ($db, undef, $schema, $table, undef, $attr) = @_;
    # DBI uses (catalog,schema,table,column), but we don't make use of
    # catalog or column, so don't bother storing them.

    my $pgsql = $db->FETCH('pgppsjis_connection');

    if (!defined $attr) {
        $attr = {};
    }
    elsif (!ref $attr && $attr ne '') {
        # If not a hash, assume it is a sequence name
        $attr = { sequence => $attr };
    }
    elsif (ref $attr ne 'HASH') {
        return $db->set_err(1, "last_insert_id attrs must be a hashref");
    }

    # Catalog and col are not used
    $schema = '' if !defined $schema;
    $table = ''  if !defined $table;

    # Cache all of our table lookups? Default is yes
    my $use_cache = exists $attr->{pgppsjis_cache} ? $attr->{pgppsjis_cache} : 1;

    # Cache key.  Note we must distinguish ("a.b", "c") from ("a", "b.c")
    # (and XXX: we ought really to have tests for that)
    my $cache_key = join '.', map { quotemeta } $schema, $table;

    my $sequence;
    if (defined $attr->{sequence}) {
        # Named sequence overrides any table or schema settings
        $sequence = $attr->{sequence};
    }
    elsif ($use_cache && exists $db->{pgppsjis_liicache}{$cache_key}) {
        $sequence = $db->{pgppsjis_liicache}{$cache_key};
    }
    else {
        # At this point, we must have a valid table name
        return $db->set_err(1, "last_insert_id needs a sequence or table name")
            if $table eq '';

        my @args = $table;

        # Only 7.3 and up can use schemas
        my $pg_catalog;
        if ($pgsql->{server_version_num} < 70300) {
            $schema = '';
            $pg_catalog = '';
        }
        else {
            $pg_catalog = 'pg_catalog.';
        }

        # Make sure the table in question exists and grab its oid
        my ($schemajoin, $schemawhere) = ('','');
        if (length $schema) {
            $schemajoin =
                ' JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace';
            $schemawhere = ' AND n.nspname = ?';
            push @args, $schema;
        }

        my $st = $db->prepare(qq[
            SELECT c.oid FROM ${pg_catalog}pg_class c $schemajoin
            WHERE relname = ? $schemawhere
        ]);
        my $count = $st->execute(@args);
        if (!defined $count) {
            $st->finish;
            my $message = qq{Could not find the table "$table"};
            $message .= qq{ in the schema "$schema"} if $schema ne '';
            return $db->set_err(1, $message);
        }
        my $oid = $st->fetchall_arrayref->[0][0];
        # This table has a primary key. Is there a sequence associated with
        # it via a unique, indexed column?
        $st = $db->prepare(qq[
            SELECT a.attname, i.indisprimary, substring(d.adsrc for 128) AS def
            FROM ${pg_catalog}pg_index i
            JOIN ${pg_catalog}pg_attribute a ON a.attrelid = i.indrelid
                                            AND a.attnum   = i.indkey[0]
            JOIN ${pg_catalog}pg_attrdef d   ON d.adrelid = a.attrelid
                                            AND d.adnum   = a.attnum
            WHERE i.indrelid = $oid
              AND a.attrelid = $oid
              AND i.indisunique IS TRUE
              AND a.atthasdef IS TRUE
              AND d.adsrc ~ '^nextval'
        ]);
        $count = $st->execute;
        if (!defined $count) {
            $st->finish;
            return $db->set_err(1, qq{No suitable column found for last_insert_id of table "$table"});
        }
        my $info = $st->fetchall_arrayref;

        # We have at least one with a default value. See if we can determine
        # sequences
        my @def;
        for (@$info) {
            my ($seq) = $_->[2] =~ /^nextval\('([^']+)'::/ or next;
            push @def, [@$_, $seq];
        }

        return $db->set_err(1, qq{No suitable column found for last_insert_id of table "$table"\n})
            if !@def;

        # Tiebreaker goes to the primary keys
        if (@def > 1) {
            my @pri = grep { $_->[1] } @def;
            return $db->set_err(1, qq{No suitable column found for last_insert_id of table "$table"\n})
                if @pri != 1;
            @def = @pri;
        }

        $sequence = $def[0][3];

        # Cache this information for subsequent calls
        $db->{pgppsjis_liicache}{$cache_key} = $sequence;
    }

    my $st = $db->prepare("SELECT currval(?)");
    $st->execute($sequence);
    return $st->fetchall_arrayref->[0][0];
}

sub DESTROY {
    my ($dbh) = @_;
    $dbh->disconnect;
}

package DBD::PgPPSjis::st;

$DBD::PgPPSjis::st::imp_data_size =
$DBD::PgPPSjis::st::imp_data_size = 0;

sub bind_param {
    my ($sth, $index, $value, $attr) = @_;
    my $type = ref($attr) ? $attr->{TYPE} : $attr;
    my $dbh = $sth->{Database};
    my $params = $sth->FETCH('pgppsjis_params');
    $params->[$index - 1] = $value;
}

sub execute {
    my ($sth, @args) = @_;

    my $pgsql = $sth->FETCH('pgppsjis_handle');
    die "execute on disconnected database" if $pgsql->{closed};

    my $num_params = $sth->FETCH('NUM_OF_PARAMS');

    if (@args) {
        return $sth->set_err(1, "Wrong number of arguments")
            if @args != $num_params;
    }
    else {
        my $bind_params = $sth->FETCH('pgppsjis_params');
        return $sth->set_err(1, "Wrong number of bound parameters")
            if @$bind_params != $num_params;

        # They've already been quoted by ->bind_param
        @args = @$bind_params;
    }

    my $parsed_statement = $sth->FETCH('pgppsjis_parsed_stmt');
    my $dbh = $sth->{Database};
    my $statement = join '', map { ref() ? $dbh->quote($args[$$_]) : $_ } @$parsed_statement;

    my $result;
    eval {
        $sth->{pgppsjis_record_iterator} = undef;
        my $pgsql_sth = $pgsql->prepare($statement);
        $pgsql_sth->execute;
        $sth->{pgppsjis_record_iterator} = $pgsql_sth;
        my $dbh = $sth->{Database};

        if (defined $pgsql_sth->{affected_rows}) {
            $sth->{pgppsjis_rows} = $pgsql_sth->{affected_rows};
            $result = $pgsql_sth->{affected_rows};
        }
        else {
            $sth->{pgppsjis_rows} = 0;
            $result = $pgsql_sth->{affected_rows};
        }
        if (!$pgsql_sth->{row_description}) {
            $sth->STORE(NUM_OF_FIELDS => 0);
            $sth->STORE(NAME          => []);
        }
        else {
            $sth->STORE(NUM_OF_FIELDS => scalar @{$pgsql_sth->{row_description}});
            $sth->STORE(NAME => [ map {$_->{name}} @{$pgsql_sth->{row_description}} ]);
        }
    };
    if ($@) {
        $sth->DBI::set_err(1, $@);
        return undef;
    }

    return $pgsql->has_error ? undef
         : $result           ? $result
         :                     '0E0';
}

sub fetch {
    my ($sth) = @_;

    my $iterator = $sth->FETCH('pgppsjis_record_iterator');
    return undef if $iterator->{finished};

    if (my $row = $iterator->fetch) {
        if ($sth->FETCH('ChopBlanks')) {
            s/\s+\z// for @$row;
        }
        return $sth->_set_fbav($row);
    }

    $iterator->{finished} = 1;
    return undef;
}
*fetchrow_arrayref =
*fetchrow_arrayref = \&fetch;

sub rows {
    my ($sth) = @_;
    return defined $sth->{pgppsjis_rows} ? $sth->{pgppsjis_rows} : 0;
}

sub FETCH {
    my ($dbh, $key) = @_;

    # return $dbh->{AutoCommit} if $key eq 'AutoCommit';
    return $dbh->{NAME} if $key eq 'NAME';
    return $dbh->{$key} if $key =~ /^pgppsjis_/;
    return $dbh->SUPER::FETCH($key);
}

sub STORE {
    my ($sth, $key, $value) = @_;

    if ($key eq 'NAME') {
        $sth->{NAME} = $value;
        return 1;
    }
    elsif ($key =~ /^pgppsjis_/) {
        $sth->{$key} = $value;
        return 1;
    }
    elsif ($key eq 'NUM_OF_FIELDS') {
        # Don't set this twice; DBI doesn't seem to like it.
        # XXX: why not?  Perhaps this conceals a PgPPSjis bug.
        my $curr = $sth->FETCH($key);
        return 1 if $curr && $curr == $value;
    }
    return $sth->SUPER::STORE($key, $value);
}

sub DESTROY { return }


package DBD::PgPPSjis::Protocol;

use constant DEFAULT_UNIX_SOCKET => '/tmp';
use constant DEFAULT_PORT_NUMBER => 5432;
use constant DEFAULT_TIMEOUT     => 60;

use constant AUTH_OK                 => 0;
use constant AUTH_KERBEROS_V4        => 1;
use constant AUTH_KERBEROS_V5        => 2;
use constant AUTH_CLEARTEXT_PASSWORD => 3;
use constant AUTH_CRYPT_PASSWORD     => 4;
use constant AUTH_MD5_PASSWORD       => 5;
use constant AUTH_SCM_CREDENTIAL     => 6;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        hostname              => $args{hostname},
        path                  => $args{path}     || DEFAULT_UNIX_SOCKET,
        port                  => $args{port}     || DEFAULT_PORT_NUMBER,
        database              => $args{database} || $ENV{USER} || '',
        user                  => $args{user}     || $ENV{USER} || '',
        password              => $args{password} || '',
        args                  => $args{args}     || '',
        tty                   => $args{tty}      || '',
        timeout               => $args{timeout}  || DEFAULT_TIMEOUT,
        'socket'              => undef,
        backend_pid           => '',
        secret_key            => '',
        selected_record       => undef,
        error_message         => '',
        last_oid              => undef,
        server_identification => '',
        server_version        => '0.0.0',
        server_version_num    => 0,
    }, $class;
    $DEBUG = 1 if $args{debug};
    $self->_initialize;
    return $self;
}

sub close {
    my ($self) = @_;
    my $socket = $self->{'socket'} or return;
    return if !fileno $socket;

    my $terminate_packet = 'X' . pack 'N', 5;
    print " ==> Terminate\n" if $DEBUG;
    _dump_packet($terminate_packet);
    $socket->send($terminate_packet, 0);
    $socket->close;
    $self->{closed} = 1;
}

sub DESTROY {
    my ($self) = @_;
    $self->close if $self;
}

sub _initialize {
    my ($self) = @_;
    $self->_connect;
    $self->_do_startup;
    $self->_find_server_version;
}

sub _connect {
    my ($self) = @_;

    my $sock;
    if ($self->{hostname}) {
        $sock = IO::Socket::INET->new(
            PeerAddr => $self->{hostname},
            PeerPort => $self->{port},
            Proto    => 'tcp',
            Timeout  => $self->{timeout},
        ) or Carp::croak("Couldn't connect to $self->{hostname}:$self->{port}/tcp: $!");
    }
    else {
        (my $path = $self->{path}) =~ s{/*\z}{/.s.PGSQL.$self->{port}};
        $sock = IO::Socket::UNIX->new(
            Type => IO::Socket::SOCK_STREAM,
            Peer => $path,
        ) or Carp::croak("Couldn't connect to $path: $!");
    }
    $sock->autoflush(1);
    $self->{socket} = $sock;
}

sub get_handle { $_[0]{socket} }

sub _do_startup {
    my ($self) = @_;

    # create message body
    my $packet = pack 'n n a64 a32 a64 a64 a64', (
        2,                      # Protocol major version - Int16bit
        0,                      # Protocol minor version - Int16bit
        $self->{database},      # Database name          - LimString64
        $self->{user},          # User name              - LimString32
        $self->{args},          # Command line args      - LimString64
        '',                     # Unused                 - LimString64
        $self->{tty}            # Debugging msg tty      - LimString64
    );

    # add packet length
    $packet = pack('N', length($packet) + 4). $packet;

    print " ==> StartupPacket\n" if $DEBUG;
    _dump_packet($packet);
    $self->{socket}->send($packet, 0);
    $self->_do_authentication;
}

sub _find_server_version {
    my ($self) = @_;
    eval {
        # If this function doesn't exist (as was the case in PostgreSQL 7.1
        # and earlier), we'll end up leaving the version as 0.0.0.  I can
        # live with that.
        my $st = $self->prepare(q[SELECT version()]);
        $st->execute;
        my $data = $st->fetch;
        1 while $st->fetch;
        my $id = $data->[0];
        $self->{server_identification} = $id;
        if (my ($ver) = $id =~ /\A PostgreSQL \s+ ([0-9._]+) (?:\s|\z)/x) {
            $self->{server_version} = $ver;
            if (my ($maj, $min, $sub)
                    = $ver =~ /\A ([0-9]+)\.([0-9]{1,2})\.([0-9]{1,2}) \z/x) {
                $self->{server_version_num} = ($maj * 100 + $min) * 100 + $sub;
            }
        }
    };
}

sub _dump_packet {
    return unless $DBD::PgPPSjis::Protocol::DEBUG or
                  $DBD::PgPPSjis::Protocol::DEBUG;

    my ($packet) = @_;

    printf "%s()\n", (caller 1)[3];

# DBD::PgPPSjis (3 of 6)

    while ($packet =~ m/([\x00-\xFF]{1,16})/g) {
        my $chunk = $1;
        print join ' ', map { sprintf '%02X', ord $_ } split //, $chunk;
        print '   ' x (16 - length $chunk);
        print '  ';
        print join '',
            map { sprintf '%s', (/[\x20-\x7F]/) ? $_ : '.' } split //, $chunk;
        print "\n";
    }
}

sub get_stream {
    my ($self) = @_;
    $self->{stream} = DBD::PgPPSjis::PacketStream->new($self->{'socket'})
        if !defined $self->{stream};
    return $self->{stream};
}

sub _do_authentication {
    my ($self) = @_;
    my $stream = $self->get_stream;
    while (1) {
        my $packet = $stream->each;
        last if $packet->is_end_of_response;
        Carp::croak($packet->get_message) if $packet->is_error;
        $packet->compute($self);
    }
}

sub prepare {
    my ($self, $sql) = @_;

    $self->{error_message} = '';
    return DBD::PgPPSjis::ProtocolStatement->new($self, $sql);
}

sub has_error {
    my ($self) = @_;
    return 1 if $self->{error_message};
}

sub get_error_message {
    my ($self) = @_;
    return $self->{error_message};
}

# DBD::PgPPSjis (4 of 6)

sub parse_statement {
    my ($invocant, $statement) = @_;

    my $param_num = 0;
    my $comment_depth = 0;
    my @tokens = ('');

    Parse: for ($statement) {

        # Observe the default action at the end
        if (m{\G \z}xmsgc) {
            last Parse;
        }

        # C-style block comments nest, as specified in the SQL standard but unlike C
        elsif (m{\G( /\* (?:$sjis_mbcs|[\x00-\xFF])*? ) (?= /\* | \*/ ) }xmsgc) {
            $comment_depth++;
        }
        elsif ($comment_depth && m{\G( (?:$sjis_mbcs|[\x00-\xFF])*? ) (?= /\* | \*/ )}xmsgc) {
        }
        elsif ($comment_depth && m{\G( \*/ )}xmsgc) {
            $comment_depth--;
        }

        # string constants with C-style escapes
        elsif (m{\G( ' (?: \\\\ | '' | \\' | \\0 | \\b | \\f | \\n | \\r | \\t | $sjis_mbcs | [^'] )* ' )}xmsgc) {
        }
        elsif (m{\G( ' )}xmsgc) {
        }
        elsif (m{\G( \\ )}xmsgc) {
        }

        # quoted identifiers can contain any character, except the character with code zero
        # to include a double quote, write two double quotes
        elsif (m{\G( " (?: "" | $sjis_leading_byte[^\x00] | [^\x00"] )* " )}xmsgc) {
        }
        elsif (m{\G( " )}xmsgc) {
        }

        # standard SQL comment
        elsif (m{\G( -- (?:$sjis_mbcs|[^\n])* )}xmsgc) {
        }

        # placeholder
        elsif (m{\G \?}xmsgc) {
            pop @tokens if $tokens[-1] eq '';
            push @tokens, \(my $tmp = $param_num++), '';
            redo Parse;
        }

        # key words, numeric constants, etc
###     elsif (m{\G( \s+             | \w+                                                         | ::? | \$[0-9]+ | [-/*\$] | [^[:ascii:]]+                            | [\0-\037\177]+ )}xmsgc) {
        elsif (m{\G( [\t\n\f\r\x20]+ | [_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0-9]+ | ::? | \$[0-9]+ | [-/*\$] | (?:$sjis_mbcs|[\x80\xA0-\xDF\xFD-\xFF])+ | [\0-\037\177]+ )}xmsgc) {
        }

        # operators are + - * / < > = ~ ! @ # % ^ & | ` ?
        # special characters are $ ( ) [ ] , ; : * .
        elsif (m{\G( [+<>=~!\@\#%^&|`,;.()\[\]{}]+ )}xmsgc) {
        }

        # panic
        else {
            die qq{BUG: Unknown cause syntax error occurs at @{[pos]}\n$statement\n};
        }

        $tokens[-1] .= $1;
        redo Parse;
    }

    pop @tokens if @tokens > 1 && $tokens[-1] eq '';

    return \@tokens;
}


package DBD::PgPPSjis::ProtocolStatement;

sub new {
    my ($class, $pgsql, $statement) = @_;
    bless {
        postgres  => $pgsql,
        statement => $statement,
        rows      => [],
    }, $class;
}

sub execute {
    my ($self) = @_;

    my $pgsql = $self->{postgres};
    my $handle = $pgsql->get_handle;

    my $query_packet = "Q$self->{statement}\0";
    print " ==> Query\n" if $DEBUG;
    DBD::PgPPSjis::Protocol::_dump_packet($query_packet);
    $handle->send($query_packet, 0);
    $self->{affected_rows} = 0;
    $self->{last_oid}      = undef;
    $self->{rows}          = [];

    my $stream = $pgsql->get_stream;
    my $packet = $stream->each;
    if ($packet->is_error) {
        $self->_to_end_of_response($stream);
        die $packet->get_message;
    }
    elsif ($packet->is_end_of_response) {
        return;
    }
    elsif ($packet->is_empty) {
        $self->_to_end_of_response($stream);
        return;
    }
    while ($packet->is_notice_response) {
        # XXX: discard it for now
        $packet = $stream->each;
    }
    if ($packet->is_cursor_response) {
        $packet->compute($pgsql);
        my $row_info = $stream->each; # fetch RowDescription
        if ($row_info->is_error) {
            $self->_to_end_of_response($stream);
            Carp::croak($row_info->get_message);
        }
        $row_info->compute($self);
        while (1) {
            my $row_packet = $stream->each;
            if ($row_packet->is_error) {
                $self->_to_end_of_response($stream);
                Carp::croak($row_packet->get_message);
            }
            $row_packet->compute($self);
            push @{ $self->{rows} }, $row_packet->get_result;
            last if $row_packet->is_end_of_response;
        }
        return;
    }
    else {                      # CompletedResponse
        $packet->compute($self);
        while (1) {
            my $end = $stream->each;
            if ($end->is_error) {
                $self->_to_end_of_response($stream);
                Carp::croak($end->get_message);
            }
            last if $end->is_end_of_response;
        }
        return;
    }
}

sub _to_end_of_response {
    my ($self, $stream) = @_;

    while (1) {
        my $packet = $stream->each;
        $packet->compute($self);
        last if $packet->is_end_of_response;
    }
}

sub fetch {
    my ($self) = @_;
    return shift @{ $self->{rows} }; # shift returns undef if empty
}


package DBD::PgPPSjis::PacketStream;

# Message Identifiers
use constant ASCII_ROW             => 'D';
use constant AUTHENTICATION        => 'R';
use constant BACKEND_KEY_DATA      => 'K';
use constant BINARY_ROW            => 'B';
use constant COMPLETED_RESPONSE    => 'C';
use constant COPY_IN_RESPONSE      => 'G';
use constant COPY_OUT_RESPONSE     => 'H';
use constant CURSOR_RESPONSE       => 'P';
use constant EMPTY_QUERY_RESPONSE  => 'I';
use constant ERROR_RESPONSE        => 'E';
use constant FUNCTION_RESPONSE     => 'V';
use constant NOTICE_RESPONSE       => 'N';
use constant NOTIFICATION_RESPONSE => 'A';
use constant READY_FOR_QUERY       => 'Z';
use constant ROW_DESCRIPTION       => 'T';

# Authentication Message specifiers
use constant AUTHENTICATION_OK                 => 0;
use constant AUTHENTICATION_KERBEROS_V4        => 1;
use constant AUTHENTICATION_KERBEROS_V5        => 2;
use constant AUTHENTICATION_CLEARTEXT_PASSWORD => 3;
use constant AUTHENTICATION_CRYPT_PASSWORD     => 4;
use constant AUTHENTICATION_MD5_PASSWORD       => 5;
use constant AUTHENTICATION_SCM_CREDENTIAL     => 6;

sub new {
    my ($class, $handle) = @_;
    bless {
        handle => $handle,
        buffer => '',
    }, $class;
}

sub set_buffer {
    my ($self, $buffer) = @_;
    $self->{buffer} = $buffer;
}

sub get_buffer { $_[0]{buffer} }

sub each {
    my ($self) = @_;
    my $type = $self->_get_byte;
    # XXX: This would perhaps be better as a dispatch table
    my $p  = $type eq ASCII_ROW             ? $self->_each_ascii_row
           : $type eq AUTHENTICATION        ? $self->_each_authentication
           : $type eq BACKEND_KEY_DATA      ? $self->_each_backend_key_data
           : $type eq BINARY_ROW            ? $self->_each_binary_row
           : $type eq COMPLETED_RESPONSE    ? $self->_each_completed_response
           : $type eq COPY_IN_RESPONSE      ? $self->_each_copy_in_response
           : $type eq COPY_OUT_RESPONSE     ? $self->_each_copy_out_response
           : $type eq CURSOR_RESPONSE       ? $self->_each_cursor_response
           : $type eq EMPTY_QUERY_RESPONSE  ? $self->_each_empty_query_response
           : $type eq ERROR_RESPONSE        ? $self->_each_error_response
           : $type eq FUNCTION_RESPONSE     ? $self->_each_function_response
           : $type eq NOTICE_RESPONSE       ? $self->_each_notice_response
           : $type eq NOTIFICATION_RESPONSE ? $self->_each_notification_response
           : $type eq READY_FOR_QUERY       ? $self->_each_ready_for_query
           : $type eq ROW_DESCRIPTION       ? $self->_each_row_description
           :         Carp::croak("Unknown message type: '$type'");
    if ($DEBUG) {
        (my $type = ref $p) =~ s/.*:://;
        print "<==  $type\n";
    }
    return $p;
}

sub _each_authentication {
    my ($self) = @_;

    my $code = $self->_get_int32;
    if ($code == AUTHENTICATION_OK) {
        return DBD::PgPPSjis::AuthenticationOk->new;
    }
    elsif ($code == AUTHENTICATION_KERBEROS_V4) {
        return DBD::PgPPSjis::AuthenticationKerberosV4->new;
    }
    elsif ($code == AUTHENTICATION_KERBEROS_V5) {
        return DBD::PgPPSjis::AuthenticationKerberosV5->new;
    }
    elsif ($code == AUTHENTICATION_CLEARTEXT_PASSWORD) {
        return DBD::PgPPSjis::AuthenticationCleartextPassword->new;
    }
    elsif ($code == AUTHENTICATION_CRYPT_PASSWORD) {
        my $salt = $self->_get_byte(2);
        return DBD::PgPPSjis::AuthenticationCryptPassword->new($salt);
    }
    elsif ($code == AUTHENTICATION_MD5_PASSWORD) {
        my $salt = $self->_get_byte(4);
        return DBD::PgPPSjis::AuthenticationMD5Password->new($salt);
    }
    elsif ($code == AUTHENTICATION_SCM_CREDENTIAL) {
        return DBD::PgPPSjis::AuthenticationSCMCredential->new;
    }
    else {
        Carp::croak("Unknown authentication type: $code");
    }
}

sub _each_backend_key_data {
    my ($self) = @_;
    my $process_id = $self->_get_int32;
    my $secret_key = $self->_get_int32;
    return DBD::PgPPSjis::BackendKeyData->new($process_id, $secret_key);
}

sub _each_error_response {
    my ($self) = @_;
    my $error_message = $self->_get_c_string;
    return DBD::PgPPSjis::ErrorResponse->new($error_message);
}

sub _each_notice_response {
    my ($self) = @_;
    my $notice_message = $self->_get_c_string;
    return DBD::PgPPSjis::NoticeResponse->new($notice_message);
}

sub _each_notification_response {
    my ($self) = @_;
    my $process_id = $self->_get_int32;
    my $condition = $self->_get_c_string;
    return DBD::PgPPSjis::NotificationResponse->new($process_id, $condition);
}

sub _each_ready_for_query {
    my ($self) = @_;
    return DBD::PgPPSjis::ReadyForQuery->new;
}

sub _each_cursor_response {
    my ($self) = @_;
    my $name = $self->_get_c_string;
    return DBD::PgPPSjis::CursorResponse->new($name);
}

sub _each_row_description {
    my ($self) = @_;
    my $row_number = $self->_get_int16;
    my @description;
    for my $i (1 .. $row_number) {
        push @description, {
            name     => $self->_get_c_string,
            type     => $self->_get_int32,
            size     => $self->_get_int16,
            modifier => $self->_get_int32,
        };
    }
    return DBD::PgPPSjis::RowDescription->new(\@description);
}

sub _each_ascii_row {
    my ($self) = @_;
    return DBD::PgPPSjis::AsciiRow->new($self);
}

sub _each_completed_response {
    my ($self) = @_;
    my $tag = $self->_get_c_string;
    return DBD::PgPPSjis::CompletedResponse->new($tag);
}

sub _each_empty_query_response {
    my ($self) = @_;
    my $unused = $self->_get_c_string;
    return DBD::PgPPSjis::EmptyQueryResponse->new($unused);
}

sub _get_byte {
    my ($self, $length) = @_;
    $length = 1 if !defined $length;

    $self->_if_short_then_add_buffer($length);
    return substr $self->{buffer}, 0, $length, '';
}

sub _get_int32 {
    my ($self) = @_;
    $self->_if_short_then_add_buffer(4);
    return unpack 'N', substr $self->{buffer}, 0, 4, '';
}

sub _get_int16 {
    my ($self) = @_;
    $self->_if_short_then_add_buffer(2);
    return unpack 'n', substr $self->{buffer}, 0, 2, '';
}

sub _get_c_string {
    my ($self) = @_;

    my $null_pos;
    while (1) {
        $null_pos = index $self->{buffer}, "\0";
        last if $null_pos >= 0;
        $self->_if_short_then_add_buffer(1 + length $self->{buffer});
    }
    my $result = substr $self->{buffer}, 0, $null_pos, '';
    substr $self->{buffer}, 0, 1, ''; # remove trailing \0
    return $result;
}

# This method means "I'm about to read *this* many bytes from the buffer, so
# make sure there are enough bytes available".  That is, on exit, you are
# guaranteed that $length bytes are available.
sub _if_short_then_add_buffer {
    my ($self, $length) = @_;
    $length ||= 0;

    my $handle = $self->{handle};
    while (length($self->{buffer}) < $length) {
        my $packet = '';
        $handle->recv($packet, $BUFFER_LEN, 0);
        DBD::PgPPSjis::Protocol::_dump_packet($packet);
        $self->{buffer} .= $packet;
    }
}


package DBD::PgPPSjis::Response;

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub compute            { return }
sub is_empty           { undef }
sub is_error           { undef }
sub is_end_of_response { undef }
sub get_result         { undef }
sub is_cursor_response { undef }
sub is_notice_response { undef }


package DBD::PgPPSjis::AuthenticationOk;
use base qw<DBD::PgPPSjis::Response>;


package DBD::PgPPSjis::AuthenticationKerberosV4;
use base qw<DBD::PgPPSjis::Response>;

sub compute { Carp::croak("authentication type 'Kerberos V4' not supported.\n") }


package DBD::PgPPSjis::AuthenticationKerberosV5;
use base qw<DBD::PgPPSjis::Response>;

sub compute { Carp::croak("authentication type 'Kerberos V5' not supported.\n") }


package DBD::PgPPSjis::AuthenticationCleartextPassword;
use base qw<DBD::PgPPSjis::Response>;

sub compute {
    my ($self, $pgsql) = @_;
    my $handle = $pgsql->get_handle;
    my $password = $pgsql->{password};

    my $packet = pack('N', length($password) + 4 + 1). $password. "\0";
    print " ==> PasswordPacket (cleartext)\n" if $DEBUG;
    DBD::PgPPSjis::Protocol::_dump_packet($packet);
    $handle->send($packet, 0);
}


package DBD::PgPPSjis::AuthenticationCryptPassword;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $salt) = @_;
    my $self = $class->SUPER::new;
    $self->{salt} = $salt;
    $self;
}

sub get_salt { $_[0]{salt} }

sub compute {
    my ($self, $pgsql) = @_;
    my $handle = $pgsql->get_handle;
    my $password = $pgsql->{password} || '';

    $password = _encode_crypt($password, $self->{salt});
    my $packet = pack('N', length($password) + 4 + 1). $password. "\0";
    print " ==> PasswordPacket (crypt)\n" if $DEBUG;
    DBD::PgPPSjis::Protocol::_dump_packet($packet);
    $handle->send($packet, 0);
}

sub _encode_crypt {
    my ($password, $salt) = @_;

    my $crypted = '';
    eval {
        $crypted = crypt($password, $salt);
        die "is MD5 crypt()" if _is_md5_crypt($crypted, $salt);
    };
    Carp::croak("authentication type 'crypt' not supported on your platform. please use  'trust' or 'md5' or 'ident' authentication")
          if $@;
    return $crypted;
}

sub _is_md5_crypt {
    my ($crypted, $salt) = @_;
    $crypted =~ /^\$1\$\Q$salt\E\$/;
}


package DBD::PgPPSjis::AuthenticationMD5Password;
use base qw<DBD::PgPPSjis::AuthenticationCryptPassword>;

sub new {
    my ($class, $salt) = @_;
    my $self = $class->SUPER::new;
    $self->{salt} = $salt;
    return $self;
}

sub compute {
    my ($self, $pgsql) = @_;
    my $handle = $pgsql->get_handle;
    my $password = $pgsql->{password} || '';

    my $md5ed_password = _encode_md5($pgsql->{user}, $password, $self->{salt});
    my $packet = pack('N', 1 + 4 + length $md5ed_password). "$md5ed_password\0";
    print " ==> PasswordPacket (md5)\n" if $DEBUG;
    DBD::PgPPSjis::Protocol::_dump_packet($packet);
    $handle->send($packet, 0);
}

sub _encode_md5 {
    my ($user, $password, $salt) = @_;

# DBD::PgPPSjis (5 of 6)

    my $md5 = '';
    eval {
        require Digest::MD5;
        $md5 = Digest::MD5->new;
    };
    if ($@) {
        $md5 = DBD::PgPPSjis::EncodeMD5->new();
    }

    $md5->add($password);
    $md5->add($user);

    my $tmp_digest = $md5->hexdigest;
    $md5->add($tmp_digest);
    $md5->add($salt);

    return 'md5' . $md5->hexdigest;
}


package DBD::PgPPSjis::AuthenticationSCMCredential;
use base qw<DBD::PgPPSjis::Response>;

sub compute { Carp::croak("authentication type 'SCM Credential' not supported.\n") }


package DBD::PgPPSjis::BackendKeyData;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $process_id, $secret_key) = @_;
    my $self = $class->SUPER::new;
    $self->{process_id} = $process_id;
    $self->{secret_key} = $secret_key;
    return $self;
}

sub get_process_id { $_[0]{process_id} }
sub get_secret_key { $_[0]{secret_key} }

sub compute {
    my ($self, $postgres) = @_;;

    $postgres->{process_id} = $self->get_process_id;
    $postgres->{secret_key} = $self->get_secret_key;
}


package DBD::PgPPSjis::ErrorResponse;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $message) = @_;
    my $self = $class->SUPER::new;
    $self->{message} = $message;
    return $self;
}

sub get_message { $_[0]{message} }
sub is_error    { 1 }


package DBD::PgPPSjis::NoticeResponse;
use base qw<DBD::PgPPSjis::ErrorResponse>;

sub is_error           { undef }
sub is_notice_response { 1 }


package DBD::PgPPSjis::NotificationResponse;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $process_id, $condition) = @_;
    my $self = $class->SUPER::new;
    $self->{process_id} = $process_id;
    $self->{condition} = $condition;
    return $self;
}

sub get_process_id { $_[0]{process_id} }
sub get_condition  { $_[0]{condition} }


package DBD::PgPPSjis::ReadyForQuery;
use base qw<DBD::PgPPSjis::Response>;

sub is_end_of_response { 1 }


package DBD::PgPPSjis::CursorResponse;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $name) = @_;
    my $self = $class->SUPER::new;
    $self->{name} = $name;
    return $self;
}

sub get_name           { $_[0]{name} }
sub is_cursor_response { 1 }

sub compute {
    my ($self, $pgsql) = @_;
    $pgsql->{cursor_name} = $self->get_name;
}


package DBD::PgPPSjis::RowDescription;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $row_description) = @_;
    my $self = $class->SUPER::new;
    $self->{row_description} = $row_description;
    return $self;
}

sub compute {
    my ($self, $pgsql_sth) = @_;
    $pgsql_sth->{row_description} = $self->{row_description};
}


package DBD::PgPPSjis::AsciiRow;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $stream) = @_;
    my $self = $class->SUPER::new;
    $self->{stream} = $stream;
    return $self;
}

sub compute {
    my ($self, $pgsql_sth) = @_;

    my $stream = $self->{stream};
    my $fields_length = @{ $pgsql_sth->{row_description} };
    my $bitmap_length = $self->_get_length_of_null_bitmap($fields_length);
    my $non_null = unpack 'B*', $stream->_get_byte($bitmap_length);

    my @result;
    for my $i (0 .. $fields_length - 1) {
        my $value;
        if (substr $non_null, $i, 1) {
            my $length = $stream->_get_int32;
            $value = $stream->_get_byte($length - 4);
            my $type_oid = $pgsql_sth->{row_description}[$i]{type};
            if ($type_oid == 16) { # bool
                $value = ($value eq 'f') ? 0 : 1;
            }
            elsif ($type_oid == 17) { # bytea
                $value =~ s{\\(\\|[0-7]{3})}{$BYTEA_DEMANGLE{$1}}g;
            }
        }
        push @result, $value;
    }

    $self->{result} = \@result;
}

sub _get_length_of_null_bitmap {
    my ($self, $number) = @_;
    use integer;
    my $length = $number / 8;
    ++$length if $number % 8;
    return $length;
}

sub get_result         { $_[0]{result} }
sub is_cursor_response { 1 }


package DBD::PgPPSjis::CompletedResponse;
use base qw<DBD::PgPPSjis::Response>;

sub new {
    my ($class, $tag) = @_;
    my $self = $class->SUPER::new;
    $self->{tag} = $tag;
    return $self;
}

sub get_tag { $_[0]{tag} }

sub compute {
    my ($self, $pgsql_sth) = @_;
    my $tag = $self->{tag};

# DBD::PgPPSjis (6 of 6)

    if ($tag =~ /^INSERT ([0-9]+) ([0-9]+)/) {
        $pgsql_sth->{affected_oid}  = $1;
        $pgsql_sth->{affected_rows} = $2;
    }
    elsif ($tag =~ /^DELETE ([0-9]+)/) {
        $pgsql_sth->{affected_rows} = $1;
    }
    elsif ($tag =~ /^UPDATE ([0-9]+)/) {
        $pgsql_sth->{affected_rows} = $1;
    }
}


package DBD::PgPPSjis::EmptyQueryResponse;
use base qw<DBD::PgPPSjis::Response>;

sub is_empty { 1 }


package DBD::PgPPSjis::EncodeMD5;

=pod

=begin wish

Please do not question closely about this source code ;-)

=end wish

=cut

use strict;
use vars qw($a $b $c $d);
my ($x, $n, $m, $l, $r, $z);

sub new {
    my $class = shift;
    bless {
        source => '',
    }, $class;
}

sub add {
    my $self = shift;
    $self->{source} .= join '', @_;
}

sub hexdigest {
    my $self = shift;

    my @A = unpack('N4C24', unpack 'u', 'H9T4C`>_-JXF8NMS^$#)4=@<,$18%"0X4!`L0%P8*#Q4``04``04#!P``');
    my @K = map { int abs 2 ** 32 * sin $_ } 1..64;
    my ($p);

    my $position = 0;
    do {
        $_ = substr $self->{source}, $position, 64;
        $position += 64;
        $l += $r = length $_;
        $r++, $_ .= "\x80" if $r < 64 && !$p++;
        my @W = unpack 'V16', $_. "\0" x 7;
        $W[14] = $l * 8 if $r < 57;
        ($a, $b, $c, $d) = @A;

        for (0..63) {
            #no warnings;
            local($^W) = 0;
            $a = _m($b +
                _l($A[4 + 4 * ($_ >> 4) + $_ % 4],
                    _m(&{(
                    sub {
                        $b & $c | $d & ~ $b;
                    },
                    sub {
                        $b & $d | $c & ~ $d;
                    },
                    sub {
                        $b ^ $c ^ $d;
                    },
                    sub {
                        $c ^ ($b | ~ $d);
                    }
                    )[$z = $_ / 16]}
                    + $W[($A[20 + $z] + $A[24 + $z] * ($_ % 16)) % 16] + $K[$_] + $a)
                )
            );
            ($a, $b, $c, $d) = ($d, $a, $b, $c)
        }

        my $i = $A[0];
        $A[0] = _m($A[0] + $a);
        $A[1] = _m($A[1] + $b);
        $A[2] = _m($A[2] + $c);
        $A[3] = _m($A[3] + $d);

    } while ($r > 56);

    ($x, $n, $m, $l, $r, $z) = ();
    $self->{source} = '';

    return unpack 'H32', pack 'V4', @A;
}

sub _l {
    ($x = pop @_) << ($n=pop) | 2 ** $n - 1 & $x >> 32 - $n;
}

sub _m {
    ($x = pop @_) - ($m = 1 + ~ 0) * int($x / $m);
}

1;

__END__

=head1 DESCRIPTION

This software was made from DBD::PgPP to support ShiftJIS scripting.

DBD::PgPPSjis is a pure-Perl client interface for the PostgreSQL database.
This module implements the network protocol that allows a client to
communicate with a PostgreSQL server, so you don't need an external PostgreSQL
client library like B<libpq> for it to work.  That means this module enables
you to connect to PostgreSQL server from platforms where there's no PostgreSQL
port, or where installing PostgreSQL is prohibitively hard.

=head1 MODULE DOCUMENTATION

This documentation describes driver specific behavior and restrictions; it
does not attempt to describe everything you might need to use DBD::PgPPSjis.
In particular, users are advised to be familiar with the DBI documentation.

=head1 THE DBI CLASS

=head2 DBI Class Methods

=over 4

=item B<connect>

At a minimum, you need to use code like this to connect to the database:

  $dbh = DBI->connect('dbi:PgPPSjis:dbname=$dbname', '', '');

This connects to the database $dbname on localhost without any user
authentication.  This may well be sufficient for some PostgreSQL
installations.

The following connect statement shows all possible parameters:

  $dbh = DBI->connect("dbi:PgPPSjis:dbname=$dbname", $username, $password);

  $dbh = DBI->connect("dbi:PgPPSjis:dbname=$dbname;host=$host;port=$port",
                      $username, $password);

  $dbh = DBI->connect("dbi:PgPPSjis:dbname=$dbname;path=$path;port=$port",
                      $username, $password);

      parameter | hard coded default
      ----------+-------------------
      dbname    | current userid
      host      | localhost
      port      | 5432
      path      | /tmp
      debug     | undef

If a host is specified, the postmaster on this host needs to be started with
the C<-i> option (TCP/IP socket).

For authentication with username and password appropriate entries have to be
made in pg_hba.conf.  Please refer to the PostgreSQL documentation for
pg_hba.conf and pg_passwd for the various types of authentication.

=back

=head1 DATABASE-HANDLE METHODS

=over 4

=item C<last_insert_id>

    $rv = $dbh->last_insert_id($catalog, $schema, $table, $field);
    $rv = $dbh->last_insert_id($catalog, $schema, $table, $field, \%attr);

Attempts to return the id of the last value to be inserted into a table.
Since PostgreSQL uses the C<sequence> type to implement such things, this
method finds a sequence's value using the C<CURRVAL()> PostgreSQL function.
This will fail if the sequence has not yet been used in the current database
connection.

DBD::PgPPSjis ignores the $catalog and $field arguments are ignored in all
cases, but they're required by DBI itself.

If you don't know the name of the applicable sequence for the table, you can
simply provide a table name (optionally qualified by a schema name), and
DBD::PgPPSjis will attempt to work out which sequence will contain the
correct value:

    $dbh->do(q{CREATE TABLE t (id serial primary key, s text not null)});
    my $sth = $dbh->prepare('INSERT INTO t (s) VALUES (?)');
    for my $value (@values) {
        $sth->execute($value);
        my $id = $dbh->last_insert_id(undef, undef, 't', undef);
        print "Inserted $id: $value\n";
    }

In most situations, that is the simplest approach.  However, it requires the
table to have at least one column which is non-null and unique, and uses a
sequence as its default value.  (If there is more than one such column, the
primary key is used.)

If those requirements aren't met in your situation, you can alternatively
specify the sequence name directly:

    $dbh->do(q{CREATE SEQUENCE t_id_seq START 1});
    $dbh->do(q{CREATE TABLE t (
      id int not null unique DEFAULT nextval('t_id_seq'),
      s text not null)});
    my $sth = $dbh->prepare('INSERT INTO t (s) VALUES (?)');
    for my $value (@values) {
        $sth->execute($value);
        my $id = $dbh->last_insert_id(undef, undef, undef, undef, {
            sequence => 't_id_seq',
        });
        print "Inserted $id: $value\n";
    }

If you adopt the simpler approach, note that DBD::PgPPSjis will have to
issue some queries to look things up in the system tables.  DBD::PgPPSjis
will then cache the appropriate sequence name for subsequent calls.  Should
you need to disable this caching for some reason, you can supply a true value
for the attribute C<pgppsjis_cache>:

    my $id = $dbh->last_insert_id(undef, undef, $table, undef, {
        pgppsjis_cache => 0,
    });

Please keep in mind that C<last_insert_id> is far from foolproof, so make
your program uses it carefully. Specifically, C<last_insert_id> should be
used only immediately after an insert to the table in question, and that
insert must not specify a value for the applicable column.

=back

=head1 OTHER FUNCTIONS

As of DBD::PgPP 0.06, you can use the following functions to determine the
version of the server to which a database handle is connected.  Note the
unusual calling convention; it may be changed in the future.

=over 4

=item C<DBD::PgPPSjis::pgppsjis_server_identification($dbh)>

The server's version identification string, as returned by the standard
C<version()> function available in PostgreSQL 7.2 and above.  If the server
doesn't support that function, returns an empty string.

=item C<DBD::PgPPSjis::pgppsjis_server_version($dbh)>

The server's version string, as parsed out of the return value of the
standard C<version()> function available in PostgreSQL 7.2 and above.  For
example, returns the string C<8.3.5> if the server is release 8.3.5.  If the
server doesn't support C<version()>, returns the string C<0.0.0>.

=item C<DBD::PgPPSjis::pgppsjis_server_version_num($dbh)>

A number representing the server's version number, as parsed out of the
return value of the standard C<version()> function available in PostgreSQL
7.2 and above.  For example, returns 80305 if the server is release 8.3.5.
If the server doesn't support C<version()>, returns zero.

=back

=head1 BUGS, LIMITATIONS, AND TODO

=over 4

=item *

The C<debug> DSN parameter is incorrectly global: if you enable it for one
database handle, it gets enabled for all database handles in the current
Perl interpreter.  It should probably be removed entirely in favour of DBI's
built-in and powerful tracing mechanism, but that's too hard to do in the
current architecture.

=item *

No support for Kerberos or SCM Credential authentication; and there's no
support for crypt authentication on some platforms.

=item *

Can't use SSL for encrypted connections.

=item *

Using multiple semicolon-separated queries in a single statement will cause
DBD::PgPPSjis to fail in a way that requires you to reconnect to the server.

=item *

No support for COPY, or LISTEN notifications, or for cancelling in-progress
queries.  (There's also no support for the "explicit function call" part of
the protocol, but there's nothing you can do that way that isn't more easily
achieved by writing SQL to call the function.)

=item *

There's currently no way to get informed about any warnings PostgreSQL may
issue for your queries.

=item *

No support for BLOB data types or long objects.

=item *

Currently assumes that the Perl code and the database use the same encoding
for text; probably also assumes that the encoding uses eight bits per
character.  Future versions are expected to support UTF-8-encoded Unicode
(in a way that's compatible with Perl's own string encodings).

=item *

You can't use any data type that (like bytea) requires C<< $dbh->quote >> to
use any syntax other than standard string literals.  Using booleans and
numbers works to the extent that PostgreSQL supports string-ish syntax for
them, but that varies from one version to another.  The only reliable way to
solve this and still support PostgreSQL 7.3 and below is to use the DBI
C<bind_param> mechanism and say which type you want; but typed bind_param
ignores the type at the moment.

=back

=head1 DEPENDENCIES

This module requires perl 5.00503 or higher, and these other modules and
libraries:

  DBI
  Digest::MD5 (or Digest::Perl::MD5)

This module enables you to connect to PostgreSQL server from some operation
systems which PostgreSQL is not ported. How nifty!

=head1 About ShiftJIS

The "ShiftJIS" in this software means widely codeset than general ShiftJIS.
When the character is taken out of the octet string, it is necessary to
distinguish a single octet character and the double octet character.
The distinction is done only by first octet.

    Single octet code is:
      0x00-0x7F, 0x81-0x9F and 0xA1-0xFC

    Double octet code is:
      First octet   0x81-0x9F, 0xE0-0xEF and 0xF0-0xFC
      Second octet  0x40-0x7E and 0x80-0xFC

    *MALFORMED* single octet code is:
      0x80, 0xA0 and 0xFD-0xFF
      Single octet code that cannot be used

See also code table:

         Single octet code

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x00-0x7F
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x81-0x9F
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xA1-0xFC
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


                                 Double octet code
            First octet                                     Second octet

   0 1 2 3 4 5 6 7 8 9 A B C D E F                 0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |              0| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |              1| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |              2| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |              3| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |              4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x40-0x7E
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |              5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |              6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |              7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x81-0x9F    8|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x80-0xFC
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|              9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| | | | | | | | | | | | | | | | |              A|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |              B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |              C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |              D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xE0-0xFC    E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |              F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


    *MALFORMED* Single octet code
    Single octet code that cannot be used

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8|M| | | | | | | | | | | | | | | | 0x80
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A|M| | | | | | | | | | | | | | | | 0xA0
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F| | | | | | | | | | | | | |M|M|M| 0xFD-0xFF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

=head1 SEE ALSO

L<DBI>, L<DBD::Pg>, L<DBD::PgPP>,
L<http://developer.postgresql.org/docs/postgres/protocol.html>

=head1 AUTHOR

Hiroyuki OYAMA E<lt>oyama@module.jpE<gt>

=head1 COPYRIGHT AND LICENCE

ShiftJIS support 2015 INABA Hitoshi
Copyright (C) 2004 Hiroyuki OYAMA.  All rights reserved.
Copyright (C) 2004, 2005, 2009, 2010 Aaron Crane.  All rights reserved.

DBD::PgPPSjis is free software; you can redistribute it and/or modify it
under the terms of Perl itself, that is to say, under the terms of either:

=over 4

=item *

The GNU General Public License as published by the Free Software Foundation;
either version 2, or (at your option) any later version, or

=item *

The "Artistic License" which comes with Perl.

=back

=cut
