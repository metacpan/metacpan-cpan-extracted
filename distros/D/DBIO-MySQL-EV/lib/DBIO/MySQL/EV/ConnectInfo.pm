package DBIO::MySQL::EV::ConnectInfo;
# ABSTRACT: MySQL/MariaDB connection-info utilities for DBIO async driver

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
use DBIO::Util ();
use DBIO::Storage ();

our @EXPORT_OK = qw( dbi_to_conninfo );

# What EV::MariaDB->new takes besides its callbacks and loop (EV::MariaDB 0.08,
# %ALLOWED_ARGS). db, its alias of database, is read as database.
my %NATIVE = map { $_ => 1 } qw(
  host port user password database unix_socket
  connect_timeout read_timeout write_timeout
  compress multi_statements charset init_command
  ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher ssl_verify_server_cert
  utf8 found_rows
);

# The DSN keys of DBD::mysql and DBD::MariaDB that EV::MariaDB has a parameter
# for, by the part after the mysql_ / mariadb_ prefix (both DBDs read their
# connect attributes out of the DSN too, and out of the attribute hash).
# mysql_ssl has no parameter of its own, and mysql_enable_utf8mb4 /
# mysql_enable_utf8 (DBD::mysql only; DBD::MariaDB has no such attribute, it is
# always utf8mb4) stand for two parameters, charset and utf8: both are handled
# apart. The other attributes of the DBDs (mariadb_auto_reconnect,
# mysql_ssl_optional, mysql_read_default_file, ...) have nothing to be
# translated into and are refused, in the DSN and among the attributes alike.
# The one exception is *_auto_reconnect with a false value (0, ''): it asks
# for nothing and is let through, leaving no key (karr k80).
my %DBD_KEY = (
  socket                 => 'unix_socket',
  connect_timeout        => 'connect_timeout',
  read_timeout           => 'read_timeout',
  write_timeout          => 'write_timeout',
  compression            => 'compress',
  init_command           => 'init_command',
  multi_statements       => 'multi_statements',
  client_found_rows      => 'found_rows',
  ssl_ca_file            => 'ssl_ca',
  ssl_ca_path            => 'ssl_capath',
  ssl_client_key         => 'ssl_key',
  ssl_client_cert        => 'ssl_cert',
  ssl_cipher             => 'ssl_cipher',
  ssl_verify_server_cert => 'ssl_verify_server_cert',
);

# The attributes the storage takes out of the connect attributes itself
# (DBIO::Storage::Async::_strip_private_connect_attrs). A broker's DBI-form
# answer may carry them: a Vault broker selects this transport with
# async => 'ev'.
sub _dbio_private_attr {
  my ($name) = @_;
  return scalar grep { $_ eq $name } 'async', 'ignore_version', 'cursor_class',
    DBIO::Storage->_dbio_storage_option_names,
    DBIO::Storage->_dbio_sql_maker_option_names;
}

# Every refusal reads alike, so a caller reading another's answer (the broker's)
# can tell it from a DSN that is no DSN of this driver. Names and keys only.
sub _refuse {
  my ($what) = @_;
  die "MySQL ev refuses the connect info: $what\n";
}

sub _sorted_unique { sort keys %{{ map { $_ => 1 } @_ }} }

# The parameters of a DSN's tail (after dbi:mysql:) as EV::MariaDB named
# parameters.
sub _dsn_parameters {
  my ($params) = @_;
  my %h;

  if ($params !~ /=/) {
    # database[:host[:port]], read the way both DBDs read it and the way
    # dbio-mysql reads it (karr k98).
    _refuse('a positional part beside a semicolon') if $params =~ /;/;
    my @part;
    my $left = $params;
    while (length $left) {
      my $val;
      if ($left =~ /([^:;]*\[.*]|[^:;]*)[:;](.*)/) {
        ($val, $left) = ($1, $2);
      }
      else {
        ($val, $left) = ($left, '');
      }
      $val =~ s/\[|]//g;
      push @part, $val;
    }
    _refuse('a positional DSN with more than database, host and port') if @part > 3;
    for my $name (qw( database host port )) {
      my $val = shift @part;
      $h{$name} = $val if defined $val && length $val;
    }
    return { h => \%h, from => {}, src => {}, unknown => [], twice => [] };
  }

  my %st = ( h => \%h, from => {}, src => {}, unknown => [], twice => [] );
  for my $kv (split /;/, $params) {
    next unless $kv =~ /\S/;
    _refuse('a positional part beside key=value parts') unless $kv =~ /^[^=]+=/;
    my ($k, $v) = split /=/, $kv, 2;
    _absorb(\%st, 'dsn', lc $k, $v);
  }
  return \%st;
}

# One key of a DSN or of the attribute hash, by its lowercase name, into the
# state of the reading (%st). $src is 'dsn' or 'attr'. Only the keys of a DSN
# are bare EV::MariaDB names or the host / dbname aliases; both sources take
# the DBD ones under their mysql_ / mariadb_ prefix.
sub _absorb {
  my ($st, $src, $k, $v) = @_;
  my $target = $src ne 'dsn'                     ? undef
             : $k eq 'hostname'                  ? 'host'
             : $k eq 'dbname' || $k eq 'db'      ? 'database'
             : $NATIVE{$k}                       ? $k
             :                                     undef;
  if (!defined $target && $k =~ /^(?:mysql|mariadb)_(.+)$/) {
    my $name = $1;
    if ($name eq 'ssl') {
      $st->{ssl} = $v;
      return;
    }
    if (($k =~ /^mysql_/) && ($name eq 'enable_utf8mb4' || $name eq 'enable_utf8')) {
      # Two parameters at once, settled when everything is read.
      $st->{enable}{$name} = $v;
      return;
    }
    # auto_reconnect off asks for nothing: this transport never reconnects
    # silently. Only a true value is a request it cannot meet (karr k80).
    return if $name eq 'auto_reconnect' && !$v;
    $target = $DBD_KEY{$name};
  }
  unless (defined $target) {
    push @{ $st->{unknown} }, $k;
    return;
  }
  # The same parameter twice: under another name, or (DSN against attribute
  # hash) with another value. The attribute hash and the one beside it
  # override each other, as their other keys do.
  push @{ $st->{twice} }, $target
    if exists $st->{from}{$target}
      && ($st->{from}{$target} ne $k
          || ($st->{src}{$target} ne $src
              && (defined $v ? $v : '') ne (defined $st->{h}{$target} ? $st->{h}{$target} : '')));
  $st->{from}{$target} = $k;
  $st->{src}{$target}  = $src;
  $st->{h}{$target}    = $v;
  return;
}

# The reading done: what the DBD keys that stand for several parameters mean,
# and the refusals. Names keys, never a value.
sub _settle {
  my ($st) = @_;
  my $h = $st->{h};

  # mysql_enable_utf8mb4 (utf8mb4) wins over mysql_enable_utf8 (utf8), as in
  # DBD::mysql. Either asks for the charset and for the strings coming back
  # flagged as characters, which is what EV::MariaDB's utf8 => 1 does (karr k80).
  # An explicit charset / utf8 stands only if it says the same.
  my ($charset) = map { $_->[1] } grep { $st->{enable}{ $_->[0] } }
    [ enable_utf8mb4 => 'utf8mb4' ], [ enable_utf8 => 'utf8' ];
  if ($charset) {
    push @{ $st->{twice} }, 'charset' if defined $h->{charset} && $h->{charset} ne $charset;
    $h->{charset} //= $charset;
    $h->{utf8}    //= 1;
  }

  _refuse(sprintf 'key(s) EV::MariaDB has no parameter for (%s); a DSN or the attributes '
    . 'here take host, port, database (dbname), user, password, the EV::MariaDB '
    . 'parameter names (DSN only) and of the DBD ones mysql_enable_utf8mb4, '
    . 'mysql_enable_utf8 and %s (mariadb_ likewise, except those two)',
    join(', ', _sorted_unique(@{ $st->{unknown} })),
    join(', ', map { "mysql_$_" } sort keys %DBD_KEY)) if @{ $st->{unknown} };
  _refuse(sprintf 'DSN and attributes give (%s) more than once under different names or values',
    join(', ', _sorted_unique(@{ $st->{twice} }))) if @{ $st->{twice} };
  my $ssl = $st->{ssl};
  _refuse('mysql_ssl (mariadb_ssl) without any of mysql_ssl_ca_file, '
    . 'mysql_ssl_ca_path, mysql_ssl_client_cert, mysql_ssl_client_key or '
    . 'mysql_ssl_cipher: EV::MariaDB turns SSL on by those alone, so the '
    . 'connection would be opened without it')
    if defined $ssl && length $ssl && $ssl ne '0'
      && !grep { defined $h->{$_} } qw( ssl_ca ssl_capath ssl_cert ssl_key ssl_cipher );
  return $h;
}


sub dbi_to_conninfo {
  my ($info) = @_;
  # Copies: a slice of @$info itself would create the slots it looks at, and
  # the array is the caller's.
  my ($dsn, $user, $pass, $attrs, $extra_attrs) = @$info;
  # The DSN is named, never its password (karr k76): masked as core masks
  # connect info in every message, given the connect info it belongs to.
  die DBIO::Util::mask_connect_secrets(
    'expected dbi:mysql:/dbi:MariaDB:... DSN, got: ' . (defined $dsn ? $dsn : '(undef)') . "\n", $info,
  ) unless defined $dsn && $dsn =~ s{^dbi:(?:mysql(?:\.\w+)?|mariadb):(.+)$}{$1}i;
  my $st = _dsn_parameters($1);
  my %h  = %{ $st->{h} };
  $st->{h} = \%h;
  # The explicit credentials beat the DSN's own (karr k64): a broker's answer
  # carries the credentials that rotate, a DSN written earlier does not.
  $h{user}     = $user if defined $user;
  $h{password} = $pass if defined $pass;
  my (%opts, @unapplied);
  # \%attrs, then \%extra_attributes: the later one wins.
  for my $given (grep { ref $_ eq 'HASH' } $attrs, $extra_attrs) {
    $h{pool_size} = $given->{pool_size} if $given->{pool_size};
    # The DBD attributes (mysql_*, mariadb_*) EV::MariaDB has a parameter for
    # are read like the same keys of the DSN; any other is refused, not
    # dropped (karr k80). An undef value names nothing.
    for my $k (sort grep { /^(?:mysql|mariadb)_/i && defined $given->{$_} } keys %$given) {
      _absorb($st, 'attr', lc $k, $given->{$k});
    }
    # A connection parameter among the attributes (charset, connect_timeout, ...)
    # is no DBI attribute and would be lost: refused (karr k80), by the measure
    # of the options beside an AccessBroker
    # (Storage::_mysql_refuse_parameters_beside_broker).
    push @unapplied, grep {
      $_ ne 'pool_size' && defined $given->{$_} && length $given->{$_}
        && !/^(?:[A-Z]|private_|dbi_|dbd_|mysql_|mariadb_)/ && !_dbio_private_attr($_)
    } keys %$given;
  }
  _settle($st);
  _refuse(sprintf 'connection parameter(s) given as connect attributes (%s) would '
    . 'be dropped, EV::MariaDB being no DBD. Give them in the DSN '
    . '(charset=...;connect_timeout=...); of the attributes only pool_size is '
    . 'read, and DBI attributes are dropped',
    join(', ', _sorted_unique(@unapplied))) if @unapplied;
  return [ \%h, \%opts ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::ConnectInfo - MySQL/MariaDB connection-info utilities for DBIO async driver

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 dbi_to_conninfo

  my $async_info = dbi_to_conninfo([ 'dbi:MariaDB:database=test;host=localhost', $user, $pass, \%attrs ]);
  my $async_info = dbi_to_conninfo([ $dsn, $user, $pass, \%attrs, \%extra_attributes ]);

Translate a DBI-style connect-info arrayref
(C<[$dsn, $user, $pass, \%attrs, \%extra_attributes]>, as produced by the sync
L<DBIO::MySQL::Storage>) into the async C<[ \%conninfo, \%opts ]> shape
consumed by L<DBIO::MySQL::EV::Storage>.

The C<dbi:mysql:> / C<dbi:MariaDB:> DSN is parsed into named L<EV::MariaDB>
parameters (C<host>, C<port>, C<database>, ...); C<dbname> is normalised to
C<database> (EV::MariaDB's spelling). A C<$user> / C<$pass> that is given is
C<user> / C<password> whatever the DSN says: the arguments, a
broker's rotated credentials among them, beat a C<user=> or C<password=> written
into the DSN, which stands only when no argument is given. Dies unless the DSN
is in a C<dbi:mysql:>-family form, since EV::MariaDB does not understand the DSN
string.
The message quotes the DSN with its passwords shown as C<***>
(C<DBIO::Util::mask_connect_secrets>): the value of a C<password>,
C<passwd>, C<pwd> or C<pass> key, DBI's C<Password> attribute, the password of
a URI, and the password beside the DSN wherever the DSN repeats it. The driver
and the rest of the DSN stay, so the message still shows what was given --
another driver's DSN, or one with DBI attributes in front
(C<< dbi:mysql(RaiseError=>1):... >>), which is not read here.

The DSN's keys are read as follows. What EV::MariaDB takes is passed
on under its own name: C<host> (C<hostname>), C<port>, C<database> (C<dbname>,
C<db>), C<user>, C<password>, C<unix_socket>, C<connect_timeout>,
C<read_timeout>, C<write_timeout>, C<compress>, C<multi_statements>,
C<charset>, C<init_command>, C<ssl_key>, C<ssl_cert>, C<ssl_ca>,
C<ssl_capath>, C<ssl_cipher>, C<ssl_verify_server_cert>, C<utf8>,
C<found_rows>. The keys DBD::mysql and DBD::MariaDB read out of the DSN under
their prefix (C<mysql_> or C<mariadb_>, both are read) and for which
EV::MariaDB has a parameter are translated:

  socket                  -> unix_socket
  connect_timeout         -> connect_timeout
  read_timeout            -> read_timeout
  write_timeout           -> write_timeout
  compression             -> compress
  init_command            -> init_command
  multi_statements        -> multi_statements
  client_found_rows       -> found_rows
  ssl_ca_file             -> ssl_ca
  ssl_ca_path             -> ssl_capath
  ssl_client_key          -> ssl_key
  ssl_client_cert         -> ssl_cert
  ssl_cipher              -> ssl_cipher
  ssl_verify_server_cert  -> ssl_verify_server_cert

C<mysql_ssl> (C<mariadb_ssl>) has no parameter of its own: EV::MariaDB turns
SSL on by any of the C<ssl_*> parameters above, so a true C<mysql_ssl> stands
only beside one of them and is refused without -- the connection would be
opened without SSL.

C<mysql_enable_utf8mb4> and C<mysql_enable_utf8> (DBD::mysql's; DBD::MariaDB
has neither -- it is always utf8mb4, and its DSN refuses them as an unknown
attribute, measured with 1.24) are two parameters at once: a true
C<mysql_enable_utf8mb4> is C<< charset => 'utf8mb4' >>, a true
C<mysql_enable_utf8> is C<< charset => 'utf8' >>, utf8mb4 winning when both
are true as in DBD::mysql, and either is also C<< utf8 => 1 >>, so the strings
come back as characters (EV::MariaDB flags the columns whose character set is
UTF-8) the way they do from the DBD with the switch. A false value asks for
nothing. A C<charset> in the same DSN or attribute hash must say the same, or
it is refused as given twice; an explicit C<utf8> stays. DBD::mysql 4.055
itself ignores the switch in the DSN (only the attribute hash turns it on,
measured); this transport honours both places. Measured live (MySQL 8.0 and
MariaDB 11) against DBD::mysql with C<mysql_enable_utf8mb4 =E<gt> 1> and DBD::MariaDB
(C<t/55-utf8-found-rows-live.t>): umlauts, CJK and a 4-byte emoji sent as
bind values and selected back are the same characters, the session character
set and the bytes the server stores are the same. Deviations: without the
switch this transport hands back byte strings (as DBD::mysql does without
C<mysql_enable_utf8mb4>, unlike DBD::MariaDB, which always decodes), and
C<mysql_enable_utf8> gives the C<utf8> session, whose 3-byte character set
cannot hold the emoji -- the same as under DBD::mysql. Every other key is
refused, naming the keys and no value:
the other attributes of the DBDs (C<mariadb_enable_utf8mb4>,
C<mysql_server_prepare>, C<mysql_ssl_optional>, C<mysql_read_default_file>,
...) have nothing in EV::MariaDB to be translated into, and EV::MariaDB croaks
on an argument it does not know. C<mysql_auto_reconnect> and
C<mariadb_auto_reconnect> are refused only with a true value, a reconnect the
transport does not do; set to C<0> (or empty), in the DSN or among the
attributes, they ask for nothing, are let through and leave no key in the
conninfo. The same parameter under two names
(C<mysql_connect_timeout> and C<connect_timeout>) is refused as well. A DSN
without a C<=> is the positional form C<database[:host[:port]]>, read as both
DBDs and L<DBIO::MySQL::Storage> read it (dbio-mysql): an empty part
names nothing, C<[...]> around an IPv6 host is taken off. A positional part
beside a semicolon or beside C<key=value> parts, and more than three, are
refused.

Of the two attribute hashes only C<pool_size> is read, and carried into the
conninfo hash; given in both, C<\%extra_attributes> wins, as the sync storage
merges the two (L<DBIO::Storage::DBI/connect_info>). The DBI attributes
(C<AutoCommit>, ...) and the owning storage's own (C<async>, C<on_connect_do>,
C<quote_names>, ...) are dropped, there being no DBD here to apply them. The
DBD attributes (C<mysql_*>, C<mariadb_*>, by their prefix) are not dropped:
those EV::MariaDB has a parameter for are read exactly like the same keys of
the DSN (above, C<mysql_enable_utf8mb4> and C<mysql_client_found_rows> among
them), and any other (C<mysql_server_prepare>, C<mariadb_auto_reconnect> with
a true value, ...) is refused, naming the attribute and no value -- also with
a false value (except C<*_auto_reconnect>, below), and not when it is
C<undef>. The same parameter in the DSN and among the attributes must have the
same name and value, or it is refused as given twice; the two attribute hashes
override each other as for C<pool_size>. A connection parameter among the
attributes -- C<charset>, C<utf8>, C<connect_timeout> and the like, any other
lowercase key set to a value -- is refused, naming the keys and no value: it
would not reach EV::MariaDB, and belongs in the DSN. The same line as beside
an AccessBroker (L<DBIO::MySQL::EV::Storage/connect_info>). The refusal dies
with C<MySQL ev refuses the connect info: ...>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
