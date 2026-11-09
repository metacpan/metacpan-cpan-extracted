package DBIO::PostgreSQL::EV::ConnectInfo;
# ABSTRACT: PostgreSQL connection string utilities for DBIO async driver

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
use DBIO::Util ();

our @EXPORT_OK = qw(
  escape_conninfo conninfo_string with_connect_timeout dbi_to_conninfo dbi_dsn_parts is_libpq_parameter
);


sub escape_conninfo {
  my ($val, $key) = @_;
  _refuse_nul($key) if defined $val && $val =~ /\0/;
  return "''" unless defined $val && length $val;
  return $val unless $val =~ /[\s'\\]/;
  $val =~ s/\\/\\\\/g;
  $val =~ s/'/\\'/g;
  return "'$val'";
}


sub conninfo_string {
  my ($ci) = @_;
  return $ci unless ref $ci;

  return join(' ', map { "$_=" . escape_conninfo($ci->{$_}, $_) }
    grep { defined $ci->{$_} } keys %$ci);
}

# A NUL byte ends the C string libpq reads, and the parameters behind it are
# lost without a word (karr k100). Refused as the transport refuses, naming
# the parameter and never its value. The transport is loaded here and not
# above: it loads this module.
sub _refuse_nul {
  my ($key) = @_;
  require DBIO::PostgreSQL::EV::Storage;
  DBIO::PostgreSQL::EV::Storage::_pg_refuse(
    defined $key && length $key && $key !~ /\0/
      ? "connection parameter '$key' holds a NUL byte, which ends the string libpq reads"
      : 'a connection parameter holds a NUL byte, which ends the string libpq reads'
  );
}


sub with_connect_timeout {
  my ($conninfo) = @_;
  return $conninfo unless defined $conninfo && !ref $conninfo;
  return $conninfo if $conninfo =~ m{\A\s*postgres(?:ql)?://}i;
  while ($conninfo =~ /\G\s*([^\s=]+)\s*=\s*(?:'(?:[^'\\]|\\.)*'|(?:[^\s\\]|\\.)*)/gc) {
    return $conninfo if lc $1 eq 'connect_timeout';
  }
  return $conninfo unless $conninfo =~ /\G\s*\z/gc;
  return $conninfo =~ /\S/ ? "$conninfo connect_timeout=10" : 'connect_timeout=10';
}


my %LIBPQ_PARAMETER = map { $_ => 1 } qw(
  service user password passfile channel_binding connect_timeout dbname host
  hostaddr port client_encoding options application_name
  fallback_application_name keepalives keepalives_idle keepalives_interval
  keepalives_count tcp_user_timeout sslmode requiressl sslnegotiation
  sslcompression sslcert sslkey sslcertmode sslpassword sslrootcert sslcrl
  sslcrldir sslsni sslkeylogfile requirepeer require_auth
  ssl_min_protocol_version ssl_max_protocol_version min_protocol_version
  max_protocol_version gssencmode krbsrvname gsslib gssdelegation replication
  target_session_attrs load_balance_hosts oauth_issuer oauth_client_id
  oauth_client_secret oauth_scope scram_client_key scram_server_key
);

sub is_libpq_parameter {
  my ($name) = @_;
  return defined $name && !ref $name && $LIBPQ_PARAMETER{lc $name} ? 1 : 0;
}


sub dbi_to_conninfo {
  my ($info, %opt) = @_;
  # Copies: a slice of @$info itself would create the slots it looks at, and
  # the array is the caller's.
  my ($dsn, $user, $pass, $attrs, $extra_attrs) = @$info;
  my ($driver, $in_dsn, $params) = dbi_dsn_parts($dsn);
  # The DSN is named, never its password (karr k78): masked as core masks
  # connect info in every message, given the connect info it belongs to.
  die DBIO::Util::mask_connect_secrets(
    'expected dbi:Pg:... DSN, got: ' . (defined $dsn ? $dsn : '(undef)') . "\n", $info,
  ) unless defined $driver && $driver =~ /\APg\z/i;

  # DBI->connect (DBI.pm): the attributes are \%attr -- for the sync storage
  # \%attrs and \%extra_attributes merged, the later one winning -- and then
  # those in front of the DSN, split the way DBI splits them; a name without
  # a value is an attribute that is undefined.
  my @in_dsn = $in_dsn ? split(/\s*=>?\s*|\s*,\s*/, $in_dsn, -1) : ();
  push @in_dsn, undef if @in_dsn % 2;
  my @attributes = ((grep { ref $_ eq 'HASH' } $attrs, $extra_attrs), { @in_dsn });
  my %dbi        = map { %$_ } @attributes;

  # A libpq parameter among the attributes (karr k80): DBI takes any name
  # for an attribute, and a pool connecting from the DSN alone would be
  # connecting without it -- silently, where it was given for the connection.
  # DBI's Password is both, and read below. Names only, never a value.
  my %refused;
  for my $given (@attributes) {
    $refused{$_} = 1 for grep {
      is_libpq_parameter($_) && $_ ne 'Password'
        && defined $given->{$_} && length $given->{$_}
    } keys %$given;
  }
  die 'the connect info gives libpq connection parameter(s) among its DBI '
    . 'attributes (' . join(', ', sort keys %refused) . '): DBI takes '
    . (keys %refused > 1 ? 'them for attributes' : 'it for an attribute') . ' and the pool '
    . 'would connect without ' . (keys %refused > 1 ? 'them' : 'it') . ". A libpq parameter belongs in "
    . "the DSN, 'dbi:Pg:...;<parameter>=...'\n"
    if %refused;

  # ... and "$user = $attr->{Username} if defined $attr->{Username}", the
  # same for the password: what DBI hands DBD::Pg in place of its arguments.
  $user = $dbi{Username} if defined $dbi{Username};
  $pass = $dbi{Password} if defined $dbi{Password};

  # ... and then DBI::dr::default_user: DBI_USER and DBI_PASS for what is
  # still undefined (karr k66), for static connect info only (option env):
  # never for a broker's answer, whose values the broker decides (core k271).
  # DBI_DSN is not read: core refuses a DSN that is not given
  # (DBIO::Storage::DBI::_assert_static_connect_info_has_dsn).
  if ($opt{env}) {
    $user = $ENV{DBI_USER} unless defined $user;
    $pass = $ENV{DBI_PASS} unless defined $pass;
  }

  my %h = %{ _dbd_pg_params($params, $user, $pass) };
  # pool_size is an attribute of the connect info (karr k66): libpq refuses
  # it as a connection parameter, so the dbh of the same connect info fails
  # of it, and the pool must not connect from what the dbh cannot.
  die "the dbi:Pg: DSN names pool_size, which is an attribute of the connect info "
    . "and no DSN parameter: give it as { pool_size => N } or among the DBI "
    . "attributes in front of the DSN\n"
    if exists $h{pool_size};
  my %opts;
  # Of those that give a pool size, the later one wins.
  for my $given (@attributes) {
    $h{pool_size} = $given->{pool_size} if $given->{pool_size};
  }
  return [ \%h, \%opts ];
}


sub dbi_dsn_parts {
  my ($dsn) = @_;
  return unless defined $dsn && !ref $dsn
    && $dsn =~ /^dbi:(\w*?)(?:\((.*?)\))?:/i;
  return ($1, $2, substr($dsn, $+[0]));
}

# The libpq parameters DBD::Pg connects with, given what follows "dbi:Pg:" in
# a DSN and the user and password beside it. A port of what DBD::Pg does to
# the three and of how libpq reads the result, step by step and not a grammar
# of its own, so that it agrees with them where they are odd as well
# (DBD::Pg 3.20.2, libpq 17).
sub _dbd_pg_params {
  my ($conn_str, $user, $pass) = @_;

  # DBD::Pg::dr::connect (Pg.pm): "db" and "database" are synonyms for
  # "dbname" -- the first one found, wherever it stands -- and a database name
  # in double quotes is one in single quotes.
  $conn_str =~ s/\b(?:db|database)\s*=/dbname=/;
  $conn_str =~ s/dbname\s*=\s*"(.+?)"/dbname='$1'/;

  # dbd_db_login6 (dbdimp.c): every ';' outside single quotes becomes a space.
  # A backslash takes the next character along, so \' opens and closes nothing.
  my $in_quote = 0;
  $conn_str =~ s{(\\.|'|;)}{
    $in_quote = !$in_quote if $1 eq "'";
    $1 eq ';' && !$in_quote ? ' ' : $1;
  }gse;

  # A postgresql:// URI where the parameters stand (karr k66): libpq takes one
  # whole as a conninfo, and DBD::Pg hands it through -- after the two rewrites
  # above, which is why they come first here. Read here into parameters, and
  # not handed on as a string, so that a user and a password beside it count
  # as they do beside "keyword=value" parameters (the dbh fails of them: it
  # appends them to the URI, which is then none), and so that the pool size
  # and the AccessBroker merge find a hash. libpq tells a URI by its start, in
  # lower case and with nothing before it.
  if ($conn_str =~ m{\Apostgres(?:ql)?://}) {
    my %h = %{ _uri_params($conn_str) };
    for my $given ([ user => $user ], [ password => $pass ]) {
      my ($keyword, $value) = @$given;
      _refuse_nul($keyword) if defined $value && $value =~ /\0/;
      $h{$keyword} = $value if defined $value && length $value;
    }
    return \%h;
  }

  # ... and a user and a password that are not empty are appended, quoted.
  # Behind the DSN's parameters, which is why they win: libpq keeps the later
  # of two values. As text, which is why a DSN ending in "keyword=" takes the
  # appended user for that keyword's value.
  for my $given ([ user => $user ], [ password => $pass ]) {
    my ($keyword, $value) = @$given;
    next unless defined $value && length $value;
    _refuse_nul($keyword) if $value =~ /\0/;
    $conn_str .= " $keyword='" . ($value =~ s/(['\\])/\\$1/gr) . "'";
  }

  # libpq's conninfo_parse (fe-connect.c): keyword = value, separated by
  # whitespace; a value in single quotes or bare, a backslash escaping the
  # next character in both. Whitespace is what isspace() says in the C
  # locale, hence /a.
  my %h;
  $conn_str =~ /\G\s+/agc;
  while ((pos($conn_str) // 0) < length $conn_str) {
    $conn_str =~ /\G([^=\s]*)\s*=\s*/agc
      or die qq{the dbi:Pg: DSN cannot be read as libpq parameters: missing "=" after a parameter name\n};
    my $keyword = $1;
    # Quoted when it starts with a quote, and then up to the closing one.
    $conn_str =~ /\G(?:'((?:[^'\\]|\\.)*)'|(?!')((?:[^\s\\]|\\.|\\\z)*))/agcs
      or die "the dbi:Pg: DSN cannot be read as libpq parameters: unterminated quoted value\n";
    my $value = $1 // $2;
    $value =~ s/\\(.?)/$1/gs;
    _refuse_nul($keyword) if $value =~ /\0/;
    $h{$keyword} = $value;
    $conn_str =~ /\G\s+/agc;
  }
  return \%h;
}

# A postgresql:// or postgres:// URI as the libpq parameters it stands for,
# read the way libpq's conninfo_uri_parse does (libpq 17, fe-connect.c; held
# against DBD::Pg's connect to a live server in t/72):
#
#   postgresql://[user[:password]@][host[:port][,host[:port]...]][/dbname][?keyword=value[&...]]
#
# Every part is percent-decoded ("%40" is "@"); a "+" is a plus. A part that
# is empty sets nothing. The credentials are looked for first, and up to the
# first "@" before a "/" -- so a "?" in front of the "@" belongs to the user
# or the password, as it does for libpq. The host may be an IPv6 address in
# brackets; several hosts make one "host" of comma-separated names and "port"
# a list of as many ports. In the query "ssl=true" is "sslmode=require", as
# libpq has it for JDBC's sake, and a keyword given twice has its later value.
# A keyword libpq does not know is not checked here, as it is not for
# keyword=value parameters: libpq refuses it when the connection is opened.
#
# Dies where libpq refuses to read the URI, saying why and nothing of the URI:
# libpq's own message quotes it whole, password included.
sub _uri_params {
  my ($uri) = @_;
  my $fail = sub { die "the dbi:Pg: DSN cannot be read as a libpq URI: $_[0]\n" };
  my $decode = sub {
    my ($part) = @_;
    $part =~ s{%([0-9A-Fa-f]{2})?}{
      defined $1 ? chr hex $1 : $fail->('invalid percent-encoded token');
    }gse;
    $fail->('a percent-encoded NUL is forbidden') if $part =~ /\0/;
    # What was encoded is UTF-8: a character string where it is valid, as
    # EV::Pg hands libpq the bytes of the string it is given.
    utf8::decode($part);
    return $part;
  };

  my %h;
  my $rest = $uri =~ s{\Apostgres(?:ql)?://}{}r;

  # The credentials, "user[:password]@", where an "@" comes before a "/".
  if ($rest =~ m{\A([^@/]*)\@}s) {
    my $cred = $1;
    $rest = substr $rest, $+[0];
    my ($user, $password) = split /:/, $cred, 2;
    $h{user}     = $decode->($user)     if defined $user     && length $user;
    $h{password} = $decode->($password) if defined $password && length $password;
  }

  # The hosts, each with its port.
  my (@hosts, @ports);
  while (1) {
    my ($host, $port) = ('', '');
    if ($rest =~ s{\A\[}{}) {
      $rest =~ s{\A([^\]]*)\]}{}s
        or $fail->('the IPv6 host address in brackets is not closed');
      $host = $1;
      length $host or $fail->('the IPv6 host address in brackets is empty');
      $rest =~ m{\A(?:[:/?,]|\z)}
        or $fail->('an IPv6 host address in brackets must be followed by ":", "/" or "?"');
    }
    else {
      $rest =~ s{\A([^:/?,]*)}{};
      $host = $1;
    }
    $port = $1 if $rest =~ s{\A:([^/?,]*)}{};
    push @hosts, $decode->($host);
    push @ports, $decode->($port);
    last unless $rest =~ s{\A,}{};
  }
  my $hosts = join ',', @hosts;
  my $ports = join ',', @ports;
  $h{host} = $hosts if length $hosts;
  $h{port} = $ports if $ports =~ /[^,]/;

  # The database, up to the query.
  if ($rest =~ s{\A/([^?]*)}{}) {
    $h{dbname} = $decode->($1) if length $1;
  }

  # The query.
  if ($rest =~ s{\A\?}{}) {
    for my $pair (split /&/, $rest) {
      next unless length $pair;
      my ($keyword, $value) = split /=/, $pair, 2;
      defined $value or $fail->('a query parameter without "="');
      ($keyword, $value) = ($decode->($keyword), $decode->($value));
      ($keyword, $value) = (sslmode => 'require') if $keyword eq 'ssl' && $value eq 'true';
      $h{$keyword} = $value;
    }
  }
  return \%h;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::ConnectInfo - PostgreSQL connection string utilities for DBIO async driver

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 escape_conninfo

  my $escaped = escape_conninfo($value);

Escape a single connection parameter value for use in a libpq conninfo string.
Handles whitespace, single quotes, and backslashes. A NUL byte in the value is
refused, naming the optional C<$key> and never the value: libpq reads the
string as a C string, so every parameter behind the NUL would be lost.

=head2 conninfo_string

  my $str = conninfo_string({ host => 'localhost', port => 5432 });

Convert a hashref of connection parameters into a libpq connection string.
Skips undefined values. Dies with a refusal naming the key when a value holds
a NUL byte.

=head2 with_connect_timeout

  my $str = with_connect_timeout("host=db1 dbname=app");
  # "host=db1 dbname=app connect_timeout=10"

Every connection this transport opens has a connect timeout: a conninfo
string that sets no C<connect_timeout> gets C<connect_timeout=10> (seconds),
one that sets it is returned as it is, whatever the value. libpq's own default
waits for ever. A C<postgresql://> URI and a string this function cannot read
as C<keyword=value> pairs come back unchanged.

=head2 is_libpq_parameter

  is_libpq_parameter('sslmode');   # true
  is_libpq_parameter('Sslmode');   # true, in whatever case
  is_libpq_parameter('pool_size'); # false

True when C<$name>, lower-cased, is the name of a libpq connection parameter.
Used to tell a connection parameter that stands where only DBI attributes are
read from the attribute it is spelled like. The list is the keyword list of
libpq's C<PQconninfoOptions> (C<PQconndefaults>, libpq 17, read from the
installed library), with the keywords the PostgreSQL 18 documentation adds
(C<min_protocol_version>, C<max_protocol_version>, C<sslkeylogfile>, the
C<oauth_*> keywords, C<scram_client_key>, C<scram_server_key>) and
C<requiressl>, which libpq still accepts. It is a superset on purpose: a name
libpq does not know it refuses when the connection is opened, so a name here
that the linked libpq lacks costs nothing.

=head2 dbi_to_conninfo

  my $async_info = dbi_to_conninfo([ 'dbi:Pg:dbname=test;host=localhost', $user, $pass, \%attrs ]);
  my $async_info = dbi_to_conninfo($connect_info, env => 1);   # DBI_USER, DBI_PASS
  my $async_info = dbi_to_conninfo([ $dsn, $user, $pass, \%attrs, \%extra_attributes ]);

Translate a DBI-style connect-info arrayref
(C<[$dsn, $user, $pass, \%attrs, \%extra_attributes]>, as produced by the sync
L<DBIO::PostgreSQL::Storage>) into the async C<[ \%conninfo, \%opts ]> shape
consumed by L<DBIO::PostgreSQL::EV::Storage>.

The connect info is read as L<DBI> and L<DBD::Pg> read it, so that the pool
connects where, and as whom, the owning storage's dbh does from the same
connect info (before it the DSN was split at every C<;> and at the
first C<=> of each piece). That reading is DBI's of the DSN and the
attributes, DBD::Pg's rewriting of what DBI hands it, and libpq's of the
result:

=over 4

=item * DBI attributes may stand in front of the parameters,
C<< dbi:Pg(RaiseError=>1,AutoCommit=>0):dbname=... >>. They are taken off as
DBI takes them off (L</dbi_dsn_parts>) and count as attributes, over the same
name in C<\%attrs> and C<\%extra_attributes>; what follows the C<:> behind
them is the DSN DBD::Pg gets.

=item * DBI's C<Username> and C<Password> attributes, when defined, are the
user and the password, in place of C<$user> and C<$pass>: DBI connects with
them, whether they stand in front of the DSN or in an attribute hash, the
later of C<\%attrs> and C<\%extra_attributes> winning and the DSN's over both.
Defined is enough: an empty C<Username> takes C<$user> away. Pool and dbh are
opened as the same user.

=item * The first C<db=> or C<database=> names the database, as C<dbname=>;
a database name in double quotes is one in single quotes.

=item * Parameters are separated by C<;> or by whitespace. Inside single
quotes a C<;> separates nothing.

=item * A parameter is C<keyword=value>, with whitespace allowed around the
C<=>. A value in single quotes is the value without them, and may hold
whitespace and C<;>; a backslash takes the next character as it is, quoted
or not, so C<\'> and C<\\> are a quote and a backslash. An empty value is
written C<''>: after C<host=;> libpq takes what follows as the host.

=item * A keyword is taken as written, in its case, and not checked: libpq
refuses one it does not know when the connection is opened. Of a keyword given
twice the later value counts.

=item * The user and the password -- C<$user> and C<$pass>, or DBI's
C<Username> and C<Password> in their place -- when defined and not empty, are
the C<user> and C<password>, over a C<user=> or C<password=> in the DSN, which
count only without them. DBD::Pg appends its two arguments, quoted, behind the
DSN's parameters, and so does this: a DSN that ends in C<keyword=> takes the
appended user for that keyword's value.

=back

Dies unless the DSN is one for DBD::Pg -- C<dbi:Pg:>, with or without DBI
attributes in front, and with or without parameters behind it, quoting the DSN
with its passwords shown as C<***> (C<DBIO::Util::mask_connect_secrets>): the
value of a C<password>, C<passwd>, C<pwd> or C<pass> key, DBI's C<Password>
attribute, the password of a URI, and the password beside the DSN wherever the
DSN repeats it. The driver and the rest of the DSN stay, so the message still
shows what was given -- another driver's DSN, say. Dies as well where libpq
would refuse to read the parameters -- one without C<=>, which is also what a
bare value with a blank in it leaves behind, or a quote that is never closed
-- saying which of the two and nothing of the DSN, where libpq's own message
quotes the piece it stopped at.

C<dbi:Pg:> with nothing behind it is a DSN: the dbh connects from it, libpq
filling the rest from its environment, and the parameters are the user and the
password alone, or none. This function translates it; the
transport does not connect from it: L<DBIO::PostgreSQL::EV::Storage/connect_info>
refuses a DSN that names no C<dbname>, C<host>, C<port>, C<service> or
C<hostaddr>. A DSN that names C<pool_size> among its
parameters dies, naming C<pool_size> and no value: libpq refuses it, so the
dbh of the same connect info fails; it is an attribute
(C<\%attrs>, C<\%extra_attributes> or in front of the DSN).

The environment is read for what DBI reads it for when C<< env => 1 >> is
given, and for nothing otherwise: C<DBI_USER> and C<DBI_PASS> are the user and
the password where they are still undefined, after DBI's C<Username> and
C<Password>. The caller gives it for static connect info; a broker's answer is
read without, the broker deciding what it answers. C<DBI_DSN> and
C<DBI_DRIVER> are not read: core refuses a DSN that is not given, and the
driver is the DSN's.

A C<postgresql://> or C<postgres://> URI in place of the parameters
(C<< dbi:Pg:postgresql://app:s%40cret@db1:5433/appdb?sslmode=require >>) is
read into the parameters it stands for, as libpq reads it
(C<conninfo_uri_parse>): C<user>, C<password>, C<host>, C<port>,
C<dbname> and the query's keywords, every part percent-decoded. An IPv6 host
is written in brackets; several hosts, C<h1:5432,h2:5433>, make a C<host> and
a C<port> of comma-separated lists, and C<ssl=true> is C<sslmode=require>.
An empty part sets nothing, and a keyword libpq does not know is left for
libpq to refuse when the connection is opened. The scheme counts in lower
case and at the start of the parameters only, as for libpq; the rewrites
DBD::Pg makes of every DSN's rest -- C<db=>, C<;> -- come first.

A user and a password beside the URI are read as they are beside
C<keyword=value> parameters: when not empty they win over the URI's own. The
dbh does not do that -- DBD::Pg appends them to the URI, which libpq then does
not read as one, and the connection fails -- so a schema connected like that
has a pool and no dbh. A URI libpq cannot read dies saying why, and nothing
of the URI: libpq's own message quotes it whole, password included.

The arrayref and the hashes in it are left as they were given.

Of the attributes -- the two hashes and those in front of the DSN -- three are
read: C<Username> and C<Password>, as above, and C<pool_size>, which is
carried into the conninfo hash; given more than once, C<\%extra_attributes>
wins over C<\%attrs>, as the sync storage merges the two
(L<DBIO::Storage::DBI/connect_info>), and the DSN's over both. Every other
attribute is dropped: they are DBD::Pg's or DBI's (C<pg_enable_utf8>,
C<AutoCommit>, ...) or the owning storage's own (C<async>, C<on_connect_do>,
C<quote_names>, ...), and libpq refuses a connection parameter it does not
know. A libpq parameter among them is not dropped but refused: C<sslmode>,
C<connect_timeout> and the like belong in the DSN, and DBI's attribute hash
would take one without a word and leave the pool connecting without it. This
dies naming the keys, never a value, in whichever of the three places the
attribute stands and whatever case it is spelled in (C<Sslmode> is a DBI
attribute by its capital and C<sslmode> to libpq; see L</is_libpq_parameter>).
DBI's own C<Password> is the one name that is both, and is read as above.
(Given beside an AccessBroker instead, such a parameter is refused by the
storage: L<DBIO::PostgreSQL::EV::Storage/connect_info>.)

=head2 dbi_dsn_parts

  my ($driver, $attributes, $parameters) = dbi_dsn_parts($dsn);
  # 'dbi:Pg(RaiseError=>1):dbname=app' -> ('Pg', 'RaiseError=>1', 'dbname=app')

A DSN taken apart the way L<DBI> does it before it calls the driver
(C<< DBI->connect >> and C<< DBI->parse_dsn >>, DBI 1.651): the driver's name,
the attributes in parentheses behind it as they are written -- undefined when
there are no parentheses -- and what follows the next C<:>, which is the
driver's. The pattern is DBI's own, so a DSN is cut where DBI cuts it: the
attributes end at the first C<):>, and a line break among them is no
attribute list. The empty list when DBI would find no C<dbi:driver:> in
front, or C<$dsn> is not a string. The environment is not read: a DSN that
names no driver (C<dbi::...>) has the empty string for one, where DBI takes
C<DBI_DRIVER>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
