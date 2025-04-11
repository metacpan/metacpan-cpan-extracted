package Apache::Session::Browseable::Postgres;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::Store::Postgres;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;
use Apache::Session::Browseable::DBI;

our $VERSION = '1.3.1';
our @ISA     = qw(Apache::Session::Browseable::DBI Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Apache::Session::Browseable::Store::Postgres $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSON::unserialize;

    return $self;
}

sub searchOn {
    my $class = shift;
    my ( $args, $selectField, $value, @fields ) = @_;
    my $res = $class->SUPER::searchOn(@_);

    # Ensure fields case is preserved
    foreach (@fields) {
        if ( $_ ne lc($_) ) {
            foreach my $s ( keys %$res ) {
                $res->{$s}->{$_} = delete $res->{$s}->{ lc $_ }
                  if $res->{$s}->{ lc $_ };
            }
        }
    }
    return $res;
}

sub searchOnExpr {
    my $class = shift;
    my ( $args, $selectField, $value, @fields ) = @_;
    my $res = $class->SUPER::searchOnExpr(@_);

    # Ensure fields case is preserved
    foreach (@fields) {
        if ( $_ ne lc($_) ) {
            foreach my $s ( keys %$res ) {
                $res->{$s}->{$_} = delete $res->{$s}->{ lc $_ }
                  if $res->{$s}->{ lc $_ };
            }
        }
    }
    return $res;
}

1;
__END__

=head1 NAME

Apache::Session::Browseable::Postgres - Add index and search methods to
L<Apache::Session::Postgres>

=head1 SYNOPSIS

Create table with columns for indexed fields. Example for Lemonldap::NG:

  CREATE UNLOGGED TABLE sessions (
      id varchar(64) not null primary key,
      a_session text,
      _whatToTrace text,
      _session_kind text,
      _utime bigint,
      ipAddr varchar(64)
  );

Add indexes:

  CREATE INDEX uid1 ON sessions USING BTREE (_whatToTrace);
  CREATE INDEX s1   ON sessions (_session_kind);
  CREATE INDEX u1   ON sessions (_utime);
  CREATE INDEX ip1  ON sessions USING BTREE (ipAddr);

Use it with Perl:

  use Apache::Session::Browseable::Postgres;

  my $args = {
       DataSource => 'dbi:Pg:sessions',
       UserName   => $db_user,
       Password   => $db_pass,
       Commit     => 1,

       # Choose your browseable fileds
       Index      => '_whatToTrace _session_kind _utime iAddr',
  };
  
  # Use it like Apache::Session
  my %session;
  tie %session, 'Apache::Session::Browseable::Postgres', $id, $args;
  $session{uid} = 'me';
  $session{mail} = 'me@me.com';
  $session{unindexedField} = 'zz';
  untie %session;
  
  # Apache::Session::Browseable add some global class methods
  #
  # 1) search on a field (indexed or not)
  my $hash = Apache::Session::Browseable::Postgres->searchOn( $args, 'uid', 'me' );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{mail} . "\n";
  }

  # 2) Parse all sessions
  # a. get all sessions
  my $hash = Apache::Session::Browseable::Postgres->get_key_from_all_sessions();

  # b. get some fields from all sessions
  my $hash = Apache::Session::Browseable::Postgres->get_key_from_all_sessions('uid', 'mail')

  # c. execute something with datas from each session :
  #    Example : get uid and mail if mail domain is
  my $hash = Apache::Session::Browseable::Postgres->get_key_from_all_sessions(
              sub {
                 my ( $session, $id ) = @_;
                 if ( $session->{mail} =~ /mydomain.com$/ ) {
                     return { $session->{uid}, $session->{mail} };
                 }
              }
  );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{uid} . "=>" . $hash->{$id}->{mail} . "\n";
  }

=head1 DESCRIPTION

Apache::Session::Browseable provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Apache::Session::Browseable::Postgres implements it for PosqtgreSQL databases.

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
