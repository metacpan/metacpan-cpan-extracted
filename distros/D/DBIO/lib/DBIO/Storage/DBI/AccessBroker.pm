package DBIO::Storage::DBI::AccessBroker;
# ABSTRACT: DBI-specific AccessBroker integration for DBIO storage

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage';
use mro 'c3';

use Scalar::Util qw(blessed refaddr);
use namespace::clean;


sub _is_access_broker_connect_info {
  my ($self, $info) = @_;

  return 0 unless ref $info eq 'ARRAY';
  return 0 unless @$info == 1 || (@$info == 2 && ref $info->[1] eq 'HASH');
  return 0 unless blessed($info->[0]);

  return $info->[0]->isa('DBIO::AccessBroker');
}


sub _access_broker_call_info {
  my ($self, $info) = @_;

  return undef unless $self->_is_access_broker_connect_info($info);
  my %beside = %{ $info->[1] || {} };
  return undef unless %beside;

  my @identity = grep { exists $beside{$_} } $self->_access_broker_identity_keys;
  $self->throw_exception(
    'With an AccessBroker, the hash beside the broker takes connect options, '
  . 'not the connection itself: ' . join(', ', @identity) . '. Which database, '
  . "and as whom, is the broker's answer."
  ) if @identity;

  return $self->_normalize_connect_info([ \%beside ]);
}


sub _access_broker_identity_keys { qw( dsn user password dbh_maker dbname host port ) }


sub set_access_broker {
  my $self = shift;

  $self->next::method(@_);

  # The connect info this storage keeps is what a backend is built from
  # anew, after disconnect or before its first use. It names the broker
  # attached last, so that backend does not fall back to the DSN (or the
  # broker) the storage was given before. What stood beside a broker there
  # stays. A storage that was never given connect info has nothing to
  # amend (karr k331).
  my $stored = $self->_connect_info;
  if (defined $stored) {
    my $broker = $_[0];
    if ($self->_is_access_broker_connect_info($stored)) {
      # [ $broker ] or [ $broker, \%options ]: the options stay
      $self->_connect_info([ $broker, @{$stored}[1 .. $#$stored] ])
        unless refaddr($stored->[0]) == refaddr($broker);
    }
    else {
      $self->{_connect_info_before_broker} = $stored;
      $self->_connect_info([ $broker ]);
    }
  }

  my $async = $self->{_async_storage_obj};
  $async->set_access_broker(@_)
    if blessed($async) && $async->can('set_access_broker');

  return $self;
}


sub clear_access_broker {
  my $self = shift;

  if ($self->access_broker) {
    my $async = $self->{_async_storage_obj};
    $async->clear_access_broker
      if blessed($async) && $async->can('clear_access_broker');

    # Static connect info a broker attach replaced stands again (karr k331).
    $self->_connect_info(delete $self->{_connect_info_before_broker})
      if $self->{_connect_info_before_broker};
  }

  return $self->next::method(@_);
}


sub _merge_access_broker_call_info {
  my ($self, $info, $beside) = @_;

  my %merged = %$info;

  if (defined $beside->{async_mode}) {
    $self->throw_exception(
      "Two async modes for one connection: '$beside->{async_mode}' beside the "
    . "AccessBroker, '$info->{async_mode}' in the broker's answer"
    ) if defined $info->{async_mode} && $info->{async_mode} ne $beside->{async_mode};
    $merged{async_mode} = $beside->{async_mode};
  }

  for my $part (qw( storage_options sql_maker_options attributes )) {
    next unless $beside->{$part};
    $merged{$part} = $self->_merge_access_broker_settings(
      $info->{$part}, $beside->{$part},
    );
  }

  # The async options are the async backend's and no DBI attributes of an
  # async owner (karr k211, k397). _normalize_connect_info drops them only when
  # the mode sits in the same hash; here the mode may have come from the other.
  if (defined $merged{async_mode} && $merged{attributes}) {
    my %attributes = %{ $merged{attributes} };
    delete @attributes{ $self->_async_option_names($merged{async_mode}) };
    $merged{attributes} = \%attributes;
  }

  return \%merged;
}


sub _access_broker_backend_settings {
  my ($self, $info) = @_;

  my $beside = $self->_access_broker_call_info($info) or return;

  my %names = %{ $beside->{attributes} || {} };
  delete $names{ignore_version};
  $names{pool_size} = 1 if exists $info->[1]{pool_size};

  # The other async options are read off the storage by the backend and its
  # pool (L<DBIO::Storage::Async/async_option>); no transport capability is
  # needed for them (karr core k397). L</_access_broker_async_options> hands
  # them on.
  delete @names{ grep { $_ ne 'pool_size' } $self->_async_option_names($self->_async_mode) };

  return sort keys %names;
}


sub _access_broker_async_options {
  my ($self, $info) = @_;

  return {} unless ref $info eq 'ARRAY' && ref $info->[1] eq 'HASH';
  my %names = map { $_ => 1 } grep { $_ ne 'pool_size' } $self->_async_option_names($self->_async_mode);
  return { map { $_ => $info->[1]{$_} } grep { $names{$_} } keys %{ $info->[1] } };
}


sub _current_dbi_connect_info {
  my ($self, $mode) = @_;

  return $self->_dbi_connect_info unless $self->access_broker;

  my $answer = $self->current_access_broker_connect_info($mode);
  return $answer if ref $answer eq 'HASH' or ref $answer eq 'ARRAY';

  my $shape = !ref $answer      ? 'a plain scalar'
            : blessed($answer)  ? 'an object of class ' . ref $answer
            :                     'a ' . ref($answer) . ' reference';

  $self->throw_exception(
    'AccessBroker ' . ref($self->access_broker) . ' answered connect info a DBI '
  . "storage cannot connect from ($shape). It takes a hash of connection "
  . 'parameters, or the DBI form [ $dsn, $user, $password, \%attrs ].'
  );
}


sub _access_broker_dbi_args {
  my ($self, $mode, %for) = @_;

  my $info = $self->_normalized_access_broker_connect_info($mode, %for);

  # the settings beside the broker join every answer, not only the first
  # (see connect_info); that also keeps pool_size out once there is a mode
  if (my $beside = $self->_access_broker_call_info($self->_connect_info)) {
    $self->_assert_access_broker_options_apply($info, $beside)
      if $for{connecting};
    $info = $self->_merge_access_broker_call_info($info, $beside);
  }

  return $self->_dbi_args_from_info($info);
}


sub _normalized_access_broker_connect_info {
  my ($self, $mode, %for) = @_;

  my $answer = $self->_current_dbi_connect_info($mode);
  # a hash is the single-hash form of connect_info
  $answer = [ $answer ] if ref $answer eq 'HASH';

  my $hash = ref $answer->[0] eq 'HASH' && !$answer->[0]{dbh_maker}
    ? $answer->[0] : undef;
  my $shape;

  if ($hash && !exists $hash->{dsn} && !exists $hash->{dbname}) {
    my @parts = grep { exists $hash->{$_} } qw(host port);
    $shape = 'a hash with ' . (@parts ? join(' and ', @parts) . ', but ' : '')
           . 'neither a dsn nor a dbname key';
  }
  else {
    my $info = $self->_normalize_connect_info($answer);
    my $dsn  = $info->{arguments}[0];
    if (defined $dsn && length $dsn) {
      $self->_assert_access_broker_parameters_apply($info)
        if $hash && $for{connecting};
      return $info;
    }

    $shape = ($hash ? 'a hash' : 'the DBI form') . ' with '
           . (defined $dsn ? 'an empty' : 'an undefined') . ' DSN';
  }

  $self->throw_exception(
    'AccessBroker ' . ref($self->access_broker) . ' answered connect info '
  . "without a DSN ($shape). A DBI storage connects with a broker's "
  . 'credentials only to the DSN the broker answers, never to the one in '
  . '$ENV{DBI_DSN}: answer a dsn, or a dbname.'
  );
}


sub _assert_access_broker_parameters_apply {
  my ($self, $info) = @_;

  my @unapplied = $self->_access_broker_unapplied_parameters(
    $info->{attributes}, $info->{arguments}[0],
  ) or return;

  $self->throw_exception(
    'AccessBroker ' . ref($self->access_broker) . ' answered connect info with '
  . 'parameter(s) a DBI storage does not apply (' . join(', ', @unapplied) . '). '
  . 'Of a hash it builds only dbname, host and port into the DSN, and what is '
  . 'no DBI attribute is not read by DBI->connect: the connection would be '
  . 'opened without ' . (@unapplied > 1 ? 'them' : 'it') . '. Answer the DBI '
  . 'form [ $dsn, $user, $password, \%attrs ] with a parameter of the database '
  . "client inside the DSN ('dbi:<DBD>:...;<parameter>=...') -- its \\%attrs "
  . 'take any DBI attribute -- or answer by the storage that asks '
  . '(connect_info_for_storage): a DBI storage without the parameter, or with '
  . 'it inside the DSN.'
  );
}


sub _assert_access_broker_options_apply {
  my ($self, $info, $beside) = @_;

  my $dsn = $info->{arguments}[0];

  # code opens the connection: the storage applies none of the attributes to
  # it, so every key it does not consume itself is lost (karr k310)
  my @unapplied = ref $dsn eq 'CODE'
    ? $self->_access_broker_unconsumed_options($beside->{attributes})
    : $self->_access_broker_unapplied_parameters($beside->{attributes}, $dsn);
  @unapplied or return;

  $self->throw_exception(
    'A DBI storage does not apply parameter(s) given beside AccessBroker '
  . ref($self->access_broker) . ' (' . join(', ', @unapplied) . '). What is no '
  . 'DBI attribute is not read by DBI->connect: the connection would be opened '
  . 'without ' . (@unapplied > 1 ? 'them' : 'it') . '. A parameter of the '
  . "database client is the broker's to answer, not a connect option beside "
  . 'it: in the DBI form [ $dsn, $user, $password, \%attrs ] inside the DSN '
  . "('dbi:<DBD>:...;<parameter>=...') -- its \\%attrs take any DBI attribute "
  . '-- or by the storage that asks (connect_info_for_storage).'
  . $self->_driver_switch_hint(@unapplied)
  );
}


sub _access_broker_unapplied_parameters {
  my ($self, $attrs, $dsn) = @_;

  return unless $attrs;
  my %consumed = map { $_ => 1 } $self->_access_broker_consumed_keys;

  my @lowercase = grep {
    !$consumed{$_} && defined $attrs->{$_} && length $attrs->{$_}
      && !/^(?:[A-Z]|private_|dbi_|dbd_)/
  } keys %$attrs;
  return unless @lowercase;

  # the DBD as DBI itself reads it off the DSN (see
  # _extract_driver_from_connect_info)
  my ($driver) = $dsn =~ /^dbi:(\w+)/i;
  my @prefixes = grep { defined && length } $self->_dbd_attribute_prefixes($driver);

  return sort grep {
    my $name = $_;
    !grep { index($name, $_) == 0 } @prefixes;
  } @lowercase;
}


sub _access_broker_unconsumed_options {
  my ($self, $attrs) = @_;

  return unless $attrs;
  my %consumed = map { $_ => 1 } $self->_access_broker_consumed_keys;

  return sort grep {
    !$consumed{$_} && defined $attrs->{$_} && length $attrs->{$_}
  } keys %$attrs;
}


sub _access_broker_consumed_keys {
  my $self = shift;
  my $mode = $self->_async_mode;
  return (
    $self->_access_broker_identity_keys,
    ( defined $mode ? $self->_async_option_names($mode) : 'pool_size' ),
    'ignore_version',
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::AccessBroker - DBI-specific AccessBroker integration for DBIO storage

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Mixin for L<DBIO::Storage::DBI> that provides the DBI-level
L<DBIO::AccessBroker> integration: connect-info detection and
mode-based credential routing.

The abstract broker management API (C<set_access_broker>,
C<clear_access_broker>, C<current_access_broker_connect_info>,
C<_assert_transaction_safe_access_broker>) lives in
L<DBIO::Storage>.

=head2 _is_access_broker_connect_info

Returns true when the supplied connect_info looks like a broker-style
invocation: an arrayref whose first member is a blessed L<DBIO::AccessBroker>
instance, either alone or followed by one plain hashref -- the connect call's
own settings beside the broker, read by L</_access_broker_call_info>.

=head2 _access_broker_call_info

  my $beside = $self->_access_broker_call_info([ $broker, \%options ]);

The connect call's own settings beside the broker, normalised the way the
attribute hash of every other connect form is (C<_normalize_connect_info>:
C<async_mode>, C<storage_options>, C<sql_maker_options>, C<attributes>), or
C<undef> when the broker stands alone or beside an empty hash.

The hash takes every connect option (ADR 0030 addendum) except
those naming the connection itself -- C<dsn>, C<user>, C<password>,
C<dbh_maker> and the connection parameters C<dbname>, C<host>, C<port>.
Which database, and as whom, is the broker's answer (ADR 0013); naming it
beside the broker throws.

A key left among the C<attributes> that the storage would not apply to a
connection of its own is not refused here but where that connection is opened
(L</_assert_access_broker_options_apply>).

=head2 _access_broker_identity_keys

  my @keys = $self->_access_broker_identity_keys;

The connect-info keys naming the connection itself -- C<dsn>, C<user>,
C<password>, C<dbh_maker>, C<dbname>, C<host>, C<port> -- which only the
broker's answer gives. L</_access_broker_call_info> refuses them beside a
broker; L<DBIO::Replicated::Storage> leaves them behind when it hands a
broker-backed replicant the master's connect options, and hands any other
replicant none of them but the master's credentials
(L<DBIO::Replicated::Storage/connect_replicants>).

=head2 set_access_broker

  $storage->set_access_broker($broker);
  $storage->set_access_broker($broker, $mode);

Attaches the broker (L<DBIO::Storage/set_access_broker>). An embedded async
backend this storage has already built gets it too
(L<DBIO::Storage::Async/set_access_broker>): its built pool asks
the new broker for every connection it opens from then on, where it used to
go on asking the broker before, or the static connect info. Connections that
are open stay open and a transaction running on one stays with the broker it
began with; nothing is torn down. A backend not built yet needs nothing: it
is built from what this storage holds.

The connect info this storage keeps names the broker as well: a
backend built anew after L<DBIO::Storage::DBI/disconnect>, or built for the first time after the
attach, is made from it and not from the DSN or the broker the storage was
given before. Settings that stood beside a broker there stay; a storage
that was never given connect info is left as it is.

A broker attached over static connect info remembers it: L</clear_access_broker>
puts it back, so the storage falls back to that DSN, sync and async alike. What
the static connect info held beside the DSN (C<pool_size>, DBD attributes) is
not carried to a backend built from the broker; it is built from the broker
alone, as a backend that has the broker attached is.

L<DBIO::Storage::DBI> names C<set_access_broker> itself and calls this one,
for the reason given at L</clear_access_broker>.

=head2 clear_access_broker

Detaches the broker (L<DBIO::Storage/clear_access_broker>). A storage with a
broker attached holds nothing of its answer -- DSN, user, password -- so there
is nothing a connection opened without the broker could be opened with. A
storage with no broker attached keeps its connect info.

An embedded async backend goes with it: it asks the same broker
for every pool and listen connection it opens, and once the broker is detached
from this storage nothing more is to be opened from it. The backend this
storage has built is detached too (L<DBIO::Storage::Async/clear_access_broker>):
its next connection fails saying that no broker is attached, and the
connections it has open stay open, as this storage keeps its handle. A backend
not built yet is not built from the detached broker either -- the first
C<*_async> call throws instead (C<_async_storage> in L<DBIO::Storage::DBI>).
Connect info that a C<set_access_broker> replaced -- the static DSN the
storage was given -- is the exception: it is restored, and a backend built
after the detach is made from it.
Give the storage connect info again to go on.

L<DBIO::Storage::DBI> names C<clear_access_broker> itself and calls this one.
It has to: this mixin stands behind L<DBIO::Storage> in the method resolution
order of a driver storage class that does not declare C<c3> -- the first base
of C<DBIO::Storage::DBI>, L<DBIO::Storage::QueryRewrite>, inherits
C<DBIO::Storage> -- so such a class found the bare
L<DBIO::Storage/clear_access_broker> first and never ran this method.
C<clear_access_broker> was the one method of the mixins shadowed that way.

=head2 _merge_access_broker_call_info

  $info = $self->_merge_access_broker_call_info($answer_info, $beside);

The broker's normalised answer with the settings beside the broker
(L</_access_broker_call_info>) joined in. A setting given in both places must
have the same value in both, or this throws naming it
(C<DBIO::Storage::_merge_access_broker_settings>); the async mode keeps the
message naming both modes. C<pool_size> leaves the attributes once the
connection has a mode, whichever of the two hashes gave it.

=head2 _access_broker_backend_settings

  my @names = $self->_access_broker_backend_settings([ $broker, \%options ]);

The names of the settings beside the broker that an async backend applies
itself: DBD attributes and C<pool_size>. Every other setting there -- the
async mode, the storage options (C<on_connect_do>, C<on_connect_call>, ...),
the SQL maker options (C<quote_names>, ...), C<cursor_class> and
C<ignore_version> -- is this storage's to apply, and a backend reads none of
them from its own connect info whichever form it comes in: the pooled
connections replay the connection actions from this storage (ADR 0049). Sorted;
empty when there is nothing for the backend.

=head2 _access_broker_async_options

  my $options = $self->_access_broker_async_options([ $broker, \%options ]);

The async options beside the broker other than C<pool_size> --
C<acquire_timeout>, C<max_waiters>, C<txn_timeout> and those the mode's
backend declares -- as a hash reference, empty when there are none. A backend
built from the broker alone is given these in C<< [ $broker, \%options ] >>:
it applies them without declaring C<broker_connect_options>.

=head2 _current_dbi_connect_info

Returns the connect info to use for the current connection attempt: with a
broker attached, its current answer for the requested mode; without one, the
stored C<_dbi_connect_info>.

With a broker attached, only its current answer will do. A broker that answers
nothing throws (C<DBIO::Storage::current_access_broker_connect_info>) rather
than hand the connection the storage's previous, static connection; the
storage keeps no earlier answer to fall back to.

An answer that is neither a hash of connection parameters nor the DBI form
C<< [ $dsn, $user, $password, \%attrs ] >> throws as well, naming the broker
class and the shape of the answer, never a value of it: a plain
string is taken for neither, and may be a DSN carrying a password.

=head2 _access_broker_dbi_args

  my ($args, $attrs) = $self->_access_broker_dbi_args($mode);
  my ($args, $attrs) = $self->_access_broker_dbi_args($mode, connecting => 1);

The broker's current answer joined with the settings beside the broker, as
the arguments of C<< DBI->connect >> (C<$args>) and the full attribute set
(C<$attrs>). Formed anew at every call and kept nowhere: a
connection (C<_connect>) is opened with it, and C<_dbi_connect_info> reads it.

With C<< connecting => 1 >> the assertions of a connection of the storage's
own apply (L</_normalized_access_broker_connect_info>,
L</_assert_access_broker_options_apply>); a plain read makes none.

=head2 _normalized_access_broker_connect_info

  my $info = $self->_normalized_access_broker_connect_info($mode);
  my $info = $self->_normalized_access_broker_connect_info($mode, connecting => 1);

The broker's current answer (L</_current_dbi_connect_info>), normalised the
way L<DBIO::Storage::DBI/connect_info> normalises every connect form. Both
C<connect_info> and every new connection build on it.

An answer without a DSN throws, naming the broker class and the shape of the
answer, never a value of it: a hash with neither a C<dsn>
nor a C<dbname> key -- with or without C<host> and C<port> -- and a hash or
the DBI form whose DSN is undefined or empty. An answer giving a code
reference (C<dbh_maker>) needs none. The credentials are the broker's, for the
database the broker names: a storage with a broker attached never connects to
C<$ENV{DBI_DSN}> instead.

With C<< connecting => 1 >> -- the storage is about to open a connection of
its own with the answer -- a hash answer carrying a key this storage would not
apply throws too, naming the broker class and the keys
(L</_assert_access_broker_parameters_apply>). C<connect_info> does
not pass it: an answer the storage is merely configured with may be for an
async backend, which asks the broker itself.

=head2 _assert_access_broker_parameters_apply

  $self->_assert_access_broker_parameters_apply($info);

Throws when a broker's hash answer -- C<$info> is its normalised form --
carries a key this storage would not apply. Of a hash, a DBI
storage builds C<dbname>, C<host> and C<port> into the DSN and nothing else;
what it does not consume itself goes to C<< DBI->connect >> as an attribute,
and a DBD keeps a lowercase attribute it does not know without a word. A
parameter of the database client -- C<sslmode>, C<connect_timeout>,
C<sslrootcert>, ... -- would be lost there and the connection opened without
it, while an async transport hands the same key to its client. So the storage
does not connect with the answer.

It is asked where the storage opens a connection of its own, for every
connection (C<_connect>, through
L</_normalized_access_broker_connect_info>), and not by C<connect_info>: the
same answer may be all an async backend needs, and the storage that owns the
backend then never connects with it itself. Until it does, nothing is refused.

A key of the answer passes when it is one of:

=over 4

=item * what the storage consumes: the connection itself
(L</_access_broker_identity_keys>), the storage options, the SQL maker
options, C<cursor_class>, C<async>, C<pool_size> and C<ignore_version>;

=item * the name of a L<DBI> attribute: one starting with an uppercase letter
(L<DBI>'s own are C<MixedCase>), one starting with C<private_>, C<dbi_> or
C<dbd_>, or one starting with a prefix of the DBD the answer's DSN names
(L<DBIO::Storage::DBI/_dbd_attribute_prefixes>) -- C<pg_> for C<dbi:Pg:>;

=item * set to C<undef> or to the empty string, which names no parameter.

=back

Every other key is refused: any other lowercase name, the prefix of another
DBD and a lowercase name on a DBD whose prefix is not known among them, since
neither can be told from a client parameter. The error names the broker class
and the keys, never a value, and the two ways out. One is the DBI form
C<< [ $dsn, $user, $password, \%attrs ] >>, which takes a client parameter
inside its DSN and, in its attribute hash -- not looked into -- a DBI
attribute the storage does not recognise as one. The other is a broker
answering by the storage that asks
(L<DBIO::AccessBroker/connect_info_for_storage>): the DBI storage an answer it
applies in full, an async transport the hash with its client's parameters.

An answer giving a code reference (C<dbh_maker>) is not looked into either:
the code opens the connection, and the storage applies nothing of the answer
to it.

=head2 _assert_access_broker_options_apply

  $self->_assert_access_broker_options_apply($info, $beside);

Throws when the hash beside the broker -- C<$beside> is its normalised form,
as L</_access_broker_call_info> returns it -- carries a key this storage would
not apply to a connection opened with the broker's answer C<$info>. What
stands beside a broker and is not consumed by the storage joins the DBI
attributes of every answer (L</_merge_access_broker_call_info>), so a
parameter of the database client given there -- C<< [ $broker, { sslmode =>
'require' } ] >> -- is lost the way one in a hash answer is, and the storage
does not connect with it either.

Which key passes is decided as for a hash answer
(L</_assert_access_broker_parameters_apply>), the DBD being the one the DSN of
the answer names -- the answer in whichever form, a hash or the DBI form. And
it is asked at the same place: where the storage opens a connection of its
own, for every connection, never by C<connect_info>. The options beside a
broker also go to an async backend, which takes or refuses them itself
(L<DBIO::Storage::Async/_access_broker_call_options>).

The error names the broker class and the keys, never a value, and says that
they stand beside the broker. A parameter of the database client is the
broker's to answer: inside the DSN of the DBI form, or by the storage that
asks (L<DBIO::AccessBroker/connect_info_for_storage>).

Beside an answer giving a code reference (C<dbh_maker>) the yardstick is
stricter: the code opens the connection, and the storage applies
nothing that stands beside the broker to it, a DBI attribute no more than a
client parameter. So every key the storage does not consume itself
(L</_access_broker_unconsumed_options>) throws, C<LongReadLen> as much as
C<sslmode>; the storage options, the SQL maker options, C<async>,
C<pool_size> and C<ignore_version> still pass. The options are judged before
they are set against the answer (L</_merge_access_broker_call_info>), so this
error wins over a conflict between the two.

=head2 _access_broker_unapplied_parameters

  my @names = $self->_access_broker_unapplied_parameters(\%attributes, $dsn);

The keys of C<\%attributes> -- what a normalised connect info leaves for
C<< DBI->connect >> -- that a connection to C<$dsn> would not apply, sorted;
none when C<\%attributes> is undefined. The yardstick of
L</_assert_access_broker_parameters_apply> and
L</_assert_access_broker_options_apply>, described with the former.

=head2 _access_broker_unconsumed_options

  my @names = $self->_access_broker_unconsumed_options(\%attributes);

The keys of C<\%attributes> that name something -- defined and not empty --
and that the storage consumes itself neither
(L</_access_broker_consumed_keys>), sorted. What stands beside a broker
answering a code reference (C<dbh_maker>) is judged by it: the code opens the
connection and no DBI attribute goes to it, so every other key is lost, a
DBI attribute as much as a client parameter.

=head2 _access_broker_consumed_keys

  my @keys = $self->_access_broker_consumed_keys;

What the storage consumes itself of a normalised attribute hash, whatever the
DBD: the connection itself (L</_access_broker_identity_keys>), C<pool_size>,
C<ignore_version> and -- with an async mode -- the async options
(C<acquire_timeout>, C<max_waiters>, C<txn_timeout> and those the backend of
the mode declares). Without a mode they are no DBIO options and the DBD
decides.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
