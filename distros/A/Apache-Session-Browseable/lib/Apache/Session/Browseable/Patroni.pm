package Apache::Session::Browseable::Patroni;

use strict;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::PgJSON;
use Apache::Session::Browseable::Store::Patroni;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;

our @ISA     = qw(Apache::Session::Browseable::PgJSON);
our $VERSION = '1.3.17';

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Apache::Session::Browseable::Store::Patroni $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSON::unserialize;

    return $self;
}

1;
__END__

=head1 NAME

Apache::Session::Browseable::Patroni - PostgreSQL/Patroni cluster support
for L<Apache::Session::Browseable::PgJSON>

=head1 SYNOPSIS

  CREATE UNLOGGED TABLE sessions (
      id varchar(64) not null primary key,
      a_session jsonb,
  );

Optionally, add indexes on some fields. Example for Lemonldap::NG:

  CREATE INDEX uid1 ON sessions USING BTREE ( (a_session ->> '_whatToTrace') );
  CREATE INDEX  s1  ON sessions ( (a_session ->> '_session_kind') );
  CREATE INDEX  u1  ON sessions ( ( cast(a_session ->> '_utime' AS bigint) ) );
  CREATE INDEX ip1  ON sessions USING BTREE ( (a_session ->> 'ipAddr') );

Use it with Perl:

  use Apache::Session::Browseable::Postgres;

  my $args = {
       DataSource => 'dbi:Pg:sessions',
       UserName   => $db_user,
       Password   => $db_pass,
       Commit     => 1,

       # List all Patroni API available (to avoid any haproxy and/or floating IP)
       PatroniUrl => 'http://1.2.3.4:8008/cluster http://2.3.4.5:8008/cluster',
  };

  # Use it like L<Apache::Session::Browseable::Postgres>

=head1 DESCRIPTION

Apache::Session::Browseable provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Apache::Session::Browseable::Patroni implements it for PosqtgreSQL databases
using "json" or "jsonb" type to be able to browse sessions and is able to dial
directly with Patroni API to find the master node of PostgreSQL cluster in
case of error.

=head1 SEE ALSO

L<http://lemonldap-ng.org>, L<Apache::Session::Postgres>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

=over

=item 2009-2025 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2025 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
