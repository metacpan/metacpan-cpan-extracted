package DBIO::Sybase::Storage;
# ABSTRACT: Base class for drivers using L<DBD::Sybase>

use strict;
use warnings;

our $VERSION = '0.900004';

use Try::Tiny;
use DBIO::Util qw(old_mro);
use DBIO::Storage::Composed ();
use namespace::clean;

use base qw/DBIO::Storage::DBI/;
__PACKAGE__->register_driver('Sybase' => __PACKAGE__);

sub dbio_deploy_class { 'DBIO::Sybase::Deploy' }



sub _adapt_to_access_path {
  my ($self, $dbd) = @_;

  # Only the declared base moves. A subclass pinned by hand has to stay an
  # instance of itself -- core checks that after the hook and throws. A storage
  # pinned to the ASE class itself is where it was put, but the placeholder
  # decision is taken for it (karr k78); a class below that, and the NoBindVars
  # class the decision may end in, are left alone.
  my $composition = DBIO::Storage::Composed->composition_of(ref $self);
  my $declared    = $composition ? $composition->{base} : ref $self;
  my $ase         = __PACKAGE__ . '::ASE';
  my $pinned_ase  = $declared eq $ase;
  return unless $declared eq __PACKAGE__ or $pinned_ase;

  # A connection coderef names no DBD until it has run, and core does not run
  # it for the hook.
  $dbd = $self->_get_dbh->{Driver}{Name}
    if not defined $dbd and ref $self->_dbi_connect_info->[0];

  # The DBD of another driver, or one nobody knows: core judges that, and the
  # ASE class is built on DBD::Sybase.
  return unless defined $dbd and $dbd eq 'Sybase';

  if ($pinned_ase) {
    # The writer and the bulk storage ASE's _init makes of its own class have
    # a parent that decided already, and auto_cast is copied from it: they
    # decide nothing, and probe nothing.
    return if $self->_parent_storage;

    # The server is looked at before the placeholder decision (karr k94): the
    # declared base does it, and a pinned class meets the same server. A
    # refusal (driver_strict) must come before anything is probed.
    $self->_reject_foreign_server;
    $self->_adapt_to_placeholder_support;
    return;
  }

  # The storage connects here, while it still has its layers: what is left to
  # decide is the client library's to answer, and ASE's _init needs the handle
  # in any case.
  $self->_reject_foreign_server;

  $self->ensure_class_loaded($ase);
  bless $self, $ase;

  $self->_adapt_to_placeholder_support;

  return;
}

# DBD::Sybase sends "select @@version" by itself at every login and keeps
# the answer. Nothing is asked for this.
sub _reject_foreign_server {
  my $self = shift;
  my $server = $self->_get_dbh->{syb_server_version_string};

  $self->_driver_mismatch(
    'the server answers as Microsoft SQL Server, not as Sybase ASE'
  ) if defined $server and $server =~ /\bMicrosoft SQL Server\b/i;

  return;
}


sub _init {
  # once the driver is determined see if we need to insert the DBD::Sybase w/ FreeTDS fixups
  # this is a dirty version of "instance role application", \o/ DO WANT Moo \o/
  my $self = shift;
  # Only synthesize a "<ref>::FreeTDS" trait once we have reblessed into a
  # concrete server subclass. On the bare base the synthetic trait name would
  # collide with the real DBIO::Sybase::Storage::FreeTDS module and its @ISA
  # rewrite would make that class inherit from itself (recursive inheritance).
  if (
    ref($self) ne __PACKAGE__
      and
    ! $self->isa('DBIO::Sybase::Storage::FreeTDS')
      and
    $self->_using_freetds
  ) {
    require DBIO::Sybase::Storage::FreeTDS;

    # A layered storage is an instance of a DBIO::Storage::Composed class. The
    # trait goes over the BASE of the composition, and the layers are composed
    # again over the trait class, so they stay ahead of the driver -- the
    # FreeTDS class included -- and core still knows the class (karr k77).
    my $entry_class = ref $self;
    my $composition = DBIO::Storage::Composed->composition_of($entry_class);

    my @isa = @{mro::get_linear_isa($composition ? $composition->{base} : $entry_class)};
    my $class = shift @isa; # this is the class the trait goes over

    my $trait_class = $class . '::FreeTDS';
    mro::set_mro ($trait_class, 'c3');
    no strict 'refs';
    @{"${trait_class}::ISA"} = ($class, 'DBIO::Sybase::Storage::FreeTDS', @isa);

    bless ($self, $composition
      ? DBIO::Storage::Composed->recompose($entry_class, $trait_class)
      : $trait_class
    );

    Class::C3->reinitialize() if old_mro();

    # No $self->_init(@_) on the new class (karr k68): this is the _init that
    # is running, and the chain it was reached through goes on below with
    # next::method -- which follows the new class, whose only additions are the
    # trait classes, and neither has an _init. Calling it again ran the whole
    # chain twice: ASE's _init above this one did its work a second time
    # (_set_max_connect, the writer storage), and with a broker that was one
    # login more.
  }

  $self->next::method(@_);
}

sub _ping {
  my $self = shift;

  my $dbh = $self->_dbh or return 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;

  ( try { $dbh->do('select 1'); 1 } )
    ? 1
    : 0
  ;
}

sub _set_max_connect {
  my $self = shift;
  my $val  = shift // 256;

  my $dsn = $self->_dbi_connect_info->[0];

  return if ref($dsn) eq 'CODE';

  # remembered for _finish_connect_dsn: with an AccessBroker the stored DSN
  # patched below is not the one connected with (karr k60)
  $self->_max_connect_value($val);

  if ($dsn !~ /maxConnect=/) {
    $self->_dbi_connect_info->[0] = "$dsn;maxConnect=$val";
    my $connected = defined $self->_dbh;
    $self->disconnect;
    $self->ensure_connected if $connected;
  }
}

# Core asks this for the DSN of every connect with a string DSN, a broker's
# answer included (karr k60). maxConnect, once _set_max_connect has run, and
# bulkLogin for the bulk storage are added here, so they reach DBI->connect
# whether the DSN comes from the stored connect info or is formed anew by a
# broker. Idempotent: a part the DSN carries is not added again. Bulk storages
# exist on DBIO::Sybase::Storage::ASE only, hence the can().
sub _finish_connect_dsn {
  my ($self, $dsn) = @_;

  $dsn = $self->next::method($dsn);

  my $max = $self->_max_connect_value;
  $dsn .= ";maxConnect=$max" if defined $max and $dsn !~ /maxConnect=/i;

  $dsn .= ';bulkLogin=1'
    if $self->can('_is_bulk_storage') and $self->_is_bulk_storage
      and $dsn !~ /bulkLogin=/i;

  return $dsn;
}

__PACKAGE__->mk_group_accessors(simple => '_max_connect_value');

sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  # server=NAME names an entry of the interfaces file or freetds.conf, which
  # holds no host to replace. Core declines it too, but this driver can say
  # what to write instead. The form is named, never the DSN: it may carry a
  # password.
  # Only DBD::Sybase's own form: DBIO::MSSQL::Storage::Sybase inherits this
  # seam ahead of DBIO::MSSQL::Storage, whose ODBC DSNs name Server=.
  if (defined $driver and lc $driver eq 'sybase'
      and defined $dsn and $dsn =~ /^dbi:[^:]*:(.*)\z/is) {
    for my $token (grep { length } split /;/, $1) {
      return (undef, "the key 'server', a name of the interfaces file or "
        . 'freetds.conf that holds no host to replace (write host=<host>;'
        . 'port=<port> in the DSN to have a host bound)')
        if $token =~ /^\s*server\s*=/i;
    }
  }

  # host= and port= are DBD::Sybase's keys and what core's default translates.
  return $self->next::method($driver, $dsn, $host, $port);
}


sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;

  # host=, port= and database= are DBD::Sybase's keys, so the DSN names
  # DBD::Sybase rather than $driver -- which is 'Sybase' whenever core asks.
  my ($dbname, $host, $port) = @{$params}{qw(dbname host port)};

  my $pair = 'DBD::Sybase reaches a server by its address only when it has '
    . 'both (dbi:Sybase:host=<host>;port=<port>)';
  my $way_out = 'supply a dsn instead (dbi:Sybase:server=<name>;... for a '
    . 'server the interfaces file or freetds.conf knows by name)';

  $self->throw_exception(
    'Cannot build a DBD::Sybase DSN from the connection parameter host '
  . "without a port: $pair, and a host alone it ignores. No port is assumed "
  . "here -- a server listens where it was configured to. Give port as well, "
  . "or $way_out."
  ) if defined $host && !defined $port;

  $self->throw_exception(
    'Cannot build a DBD::Sybase DSN from the connection parameter port '
  . "without a host: $pair, and a port alone it ignores. Give host as well, "
  . "leave port out, or $way_out."
  ) if defined $port && !defined $host;

  return 'dbi:Sybase:' . join ';',
    ( defined $host   ? ("host=$host", "port=$port") : () ),
    ( defined $dbname ? "database=$dbname"           : () );
}


# Whether or not DBD::Sybase was compiled against FreeTDS. If false, it means
# the Sybase OpenClient libraries were used.
sub _using_freetds {
  my $self = shift;
  return ($self->_get_dbh->{syb_oc_version}||'') =~ /freetds/i;
}

# Either returns the FreeTDS version against which DBD::Sybase was compiled,
# 0 if can't be determined, or undef otherwise
sub _using_freetds_version {
  my $inf = shift->_get_dbh->{syb_oc_version};
  return undef unless ($inf||'') =~ /freetds/i;
  return $inf =~ /v([0-9\.]+)/ ? $1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage - Base class for drivers using L<DBD::Sybase>

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Base storage class for L<DBD::Sybase>-based connections, and the class a
schema declares: the L<DBIO::Sybase> component and the C<-syb> shortcut pin
it. It has nothing of an engine itself. A connected storage is one of its
subclasses: at the first use that needs the driver, the schema that declares
this driver has said what the server is, and the storage becomes
L<DBIO::Sybase::Storage::ASE> without asking it (L</_adapt_to_access_path>),
never the class of another product.

If L<DBD::Sybase> was compiled against FreeTDS, the FreeTDS fixups from
L<DBIO::Sybase::Storage::FreeTDS> are mixed in automatically.

=head1 METHODS

=head2 _adapt_to_access_path

The hook of L<DBIO::Storage::DBI/_adapt_to_access_path> (core ADR 0059). A
schema declares this driver by loading the L<DBIO::Sybase> component or by the
C<-syb> shortcut, and both pin this class, which is no engine's. Core calls
the hook at the first use that needs the driver -- not at C<connect> -- with
the name of the DBD the connect info leads through, and on C<Sybase> the
storage becomes L<DBIO::Sybase::Storage::ASE>.

B<The server is not asked what it is.> A schema that declared this driver has
answered that question, and is taken at its word.

What the storage does ask is the client library, through the handle -- so the
first use connects. L<DBIO::Sybase::Storage::ASE> decides from it whether the
connection takes placeholders: it turns C<auto_cast> on, or moves on to
L<DBIO::Sybase::Storage::ASE::NoBindVars>. C<_init> then mixes the FreeTDS
class in.

The storage B<never becomes the class of another product>, and that includes
L<DBIO::MSSQL::Storage::Sybase>, which inherits this class and which core's
own check would therefore let pass. L<DBD::Sybase> sends C<select @@version>
by itself at every login and keeps the answer
(C<syb_server_version_string>); when that names Microsoft SQL Server, the
hook reports it through L<DBIO::Storage::DBI/_driver_mismatch> -- a warning,
an error with L<DBIO::Schema/driver_strict>, nothing with
L<DBIO::Schema/driver_warnings> off -- and the storage becomes the ASE class
all the same, unless that threw. A schema for Microsoft SQL Server declares
L<DBIO::MSSQL>. No other product is recognised, and none is asked for.

Three things the hook leaves alone:

=over

=item * B<A class that is not this one.> A subclass of this class pinned by
hand through L<DBIO::Schema/storage_type> stays what it is: core requires the
storage to remain an instance of the class that was declared. A storage pinned
to L<DBIO::Sybase::Storage::ASE> itself is of the class it was put in, but
meets the server like the declared base does -- a server that names
Microsoft SQL Server is reported through C<_driver_mismatch> first, before
anything is probed, and the storage stays the ASE class -- and then takes the
placeholder decision the declared base takes: the same
code, on the same connection, so it ends in the class the declared base ends
in -- auto_cast on where the declared base turns it on (never across the board:
under FreeTDS a connection that takes typeless placeholders gets none, CAST(?
AS ..) dies there with Msg 12828), or the NoBindVars class. It is the one
connection the storage uses anyway. A class below the ASE class, which could
not become the NoBindVars class and stay itself, and a pinned
L<DBIO::Sybase::Storage::ASE::NoBindVars> are left as they are. The writer and
the bulk storage L<DBIO::Sybase::Storage::ASE> makes for itself decide nothing:
their parent has decided, auto_cast is copied from it, and they go through the
hook unchanged, so the hook can run any number of times.

=item * B<Another DBD.> On a DSN that leads through any other DBD the storage
stays this class. If that DBD belongs to another driver, core reports it
(L<DBIO::Storage::DBI/_driver_mismatch>); a DBD nothing is registered for is
not judged.

=item * B<Storage layers.> The storage connects before it leaves the class it
was composed in, and core composes the same layers over the class it became.
Under FreeTDS C<_init> builds its FreeTDS class over the base of the
composition and composes the layers again over it: the layers stay B<ahead> of
the methods of L<DBIO::Sybase::Storage::FreeTDS>, so a layer that overrides a
method the FreeTDS class has is asked first, and
L<DBIO::Storage::Composed/composition_of> knows the storage's class (base C<<
<class>::FreeTDS >>, the same layers). The same holds for
L<DBIO::MSSQL::Storage::Sybase>, which inherits C<_init>
(F<t/59-component-rebless.t>).

=back

A connection coderef names no DBD until it has run, so core hands the hook
none. The hook then runs it -- one connection, the one the storage goes on
using -- and reads the DBD off the handle. A schema connected without any
connect info is never sent through driver determination and stays this class.

Read from the upstream source of L<DBD::Sybase> (F<dbdimp.c>,
C<get_server_version> called from C<syb_db_login>), not from the 1.27
tarball: that the version string is fetched at login and reading the
attribute sends nothing. Measured on 2026-10-07 against SAP ASE 16.0 SP02 with
DBD::Sybase 1.27 on FreeTDS 1.3.17 (F<t/62-component-rebless-live.t>): the
attribute is set after the connect and names C<Adaptive Server Enterprise>,
and a declared storage works as the ASE class. B<Not verified:> anything
with the Open Client libraries. The mismatch is pinned against a handle that
plays Microsoft SQL Server (F<t/59-component-rebless.t>,
F<t/92-pinned-ase-placeholders.t>). Measured on 2026-10-25 against
Microsoft SQL Server 2022 (16.0.4295) with DBD::Sybase 1.27 on FreeTDS 1.3.17:
the attribute is set after the connect and begins C<Microsoft SQL Server 2022>;
the declared base and the storage pinned to the ASE class both warn (with
C<driver_strict>, throw) and both then die of Msg 195 (C<CHAINED> is not
recognized) in the first C<set>, which is ASE's.

=head2 _bind_host_into_dsn

The HostBound seam of L<DBIO::Storage::DBI/_bind_host_into_dsn>: how a
L<DBIO::AccessBroker::HostBound> view -- a host of its own per replicant, one
set of credentials -- puts its host (and port) into a DSN that is already
written.

DBD::Sybase takes its server address from the keys C<host=> and C<port=>
(C<dbi:Sybase:host=E<lt>hostE<gt>;port=E<lt>portE<gt>;database=...>), which is
the form core's default translates: they are replaced where they stand and put
in front where they are missing, and the rest of the DSN stays as it is.

C<server=E<lt>nameE<gt>> is B<declined>. It names an entry of the interfaces
file or F<freetds.conf>, not a host, so there is nothing to replace, and
binding a host into such a DSN would leave the connection on the server the
entry names -- the answer's. The view refuses the connection, and the message
names the form and points at C<host=>/C<port=>, never the DSN (it may hold a
password). Only a C<dbi:Sybase:> DSN is looked at; any other DBD goes to the
next class's seam. The classes this storage becomes inherit the seam, and so
does L<DBIO::MSSQL::Storage::Sybase>.

=head2 _connect_params_dsn

The DSN seam of L<DBIO::Storage::DBI/_connect_params_dsn> (ADR 0057) for
connection parameters that carry no DSN -- C<dbname>, C<host> and C<port>, as
L<DBIO::AccessBroker::Static> answers them, or a connect-info hash without a
C<dsn>. Overridden because core's default form names the database with
C<dbname=>, which L<DBD::Sybase> does not read: the connection would reach the
server and stay in the login's default database, without an error.

  dbi:Sybase:host=<host>;port=<port>;database=<dbname>

C<host> and C<port> go in as a pair, C<dbname> as C<database=>, and a part not
given is left out -- nothing is put into the DSN that the parameters do not
say:

=over

=item * without C<dbname> there is no C<database=>, and the server puts the
session into the login's default database;

=item * without C<host> and C<port> the DSN names no server, and DBD::Sybase
connects to its default one: C<$DSQUERY>, else the server called C<SYBASE>.

=back

Two combinations refuse, each error naming the ways out:

=over

=item * C<host> without C<port>. DBD::Sybase sets the server address only
when it has both; a lone C<host> is ignored and the connection goes to the
default server, silently. No port is assumed: DBD::Sybase supplies none, and
a server listens where it was configured to.

=item * C<port> without C<host>. Ignored the same way; the port given would be
dropped.

=back

Both stay refusals and are not read as C<server=E<lt>hostE<gt>> (maintainer's
decision): a lone C<host> or C<port> in a hand-written DSN is dropped by
DBD::Sybase, and the connection goes to the server C<$DSQUERY> names -- even
for a host that does not exist -- so a parameter would be accepted and not
honoured. C<server=> names an entry of the interfaces file or F<freetds.conf>,
not a host, and a host is not such a name. A server known by name goes in as
the whole DSN, as said below.

Anything these three parts cannot say goes in as the whole DSN: as C<dsn>, or
as a C<dbname> that starts with C<dbi:> (L<DBIO::AccessBroker::Static> passes
it on), which core takes as the DSN before this seam is asked. That is the way
in for a server reached by name, C<dbi:Sybase:server=E<lt>nameE<gt>;...>.

The classes this storage becomes inherit the seam, so a reconnect
builds the same DSN: L<DBIO::Sybase::Storage::ASE>, and
L<DBIO::MSSQL::Storage::Sybase>, which lists this class ahead of
L<DBIO::MSSQL::Storage> -- whose own override builds the same form.

How DBD::Sybase treats the keys is read from its documentation and from
F<dbdimp.c> of DBD::Sybase 1.27, and was connected with on 2026-10-05, against
SAP ASE 16.0 SP02 with DBD::Sybase 1.27 built against FreeTDS 1.3.17
(F<t/60-connect-params-live.t>). The forms above connect where this section
says they do: C<host>, C<port> and C<dbname> into the database named -- on the
first connect, on a reconnect, and on the connection of the ASE writer
storage; C<host> and C<port> alone into the login's default database;
C<dbname> alone to the server C<$DSQUERY> names. C<dbname=> in the place of
C<database=> connects without an error, into the login's default database. A
lone C<host> or C<port>, in a DSN written by hand, is dropped and the
connection goes to the C<$DSQUERY> server. Not connected with: a DBD::Sybase
built against the Sybase Open Client libraries.

That run also showed a limit of the C<host=...;port=...> form under FreeTDS: a
second statement while a result set is still being read is refused (C<Server
name not found in configuration files>). DBD::Sybase opens a connection of its
own for it and looks the server up by name, and this form names none: the
prepare of the second statement dies of that message. On the C<dbname>-alone
form the same statement runs. The second connection itself is made, and a
C<< $dbh->do >> goes through on it -- on another session of the server.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase> - Sybase schema component

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE storage

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

=item * L<DBIO::Storage::DBI> - Base DBI storage class

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
