package Apache::Session::Browseable::PgJSON;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::Store::Postgres;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;

our $VERSION = '1.3.9';
our @ISA     = qw(Apache::Session);

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
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $selectField =~ s/'/''/g;
    my $query =
      { query => "a_session ->> '$selectField' =?", values => [$value] };
    return $class->_query( $args, $query, @fields );
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $selectField =~ s/'/''/g;
    $value       =~ s/\*/%/g;
    my $query =
      { query => "a_session ->> '$selectField' like ?", values => [$value] };
    return $class->_query( $args, $query, @fields );
}

sub _query {
    my ( $class, $args, $query, @fields ) = @_;
    my %res = ();

    my $dbh        = $class->_classDbh($args);
    my $table_name = $args->{TableName}
      || $Apache::Session::Store::DBI::TableName;

    my $sth;
    my $fields =
      @fields
      ? join( ',', 'id', map { s/'//g; "a_session ->> '$_' AS $_" } @fields )
      : '*';
    $sth =
      $dbh->prepare("SELECT $fields from $table_name where $query->{query}");
    $sth->execute( @{ $query->{values} } );

    # In this case, PostgreSQL change field name in lowercase
    my $res = $sth->fetchall_hashref('id') or return {};
    if (@fields) {
        foreach (@fields) {
            if ( $_ ne lc($_) ) {
                foreach my $s ( keys %$res ) {
                    $res->{$s}->{$_} = delete $res->{$s}->{ lc $_ };
                }
            }
        }
    }
    else {
        my $self = eval "&${class}::populate();";
        my $sub  = $self->{unserialize};
        foreach my $s ( keys %$res ) {
            eval {
                my $tmp = &$sub( { serialized => $res->{$s}->{a_session} } );
                $res->{$s} = $tmp;
            };
            if ($@) {
                print STDERR "Error in session $s: $@\n";
                delete $res->{$s};
            }
        }
    }
    return $res;
}

sub deleteIfLowerThan {
    my ( $class, $args, $rule ) = @_;
    my $query;
    if ( $rule->{or} ) {
        $query = join ' OR ',
          map { "cast(a_session ->> '$_' as bigint) < $rule->{or}->{$_}" }
          keys %{ $rule->{or} };
    }
    elsif ( $rule->{and} ) {
        $query = join ' AND ',
          map { "cast(a_session ->> '$_' as bigint) < $rule->{or}->{$_}" }
          keys %{ $rule->{or} };
    }
    if ( $rule->{not} ) {
        $query = "($query) AND "
          . join( ' AND ',
            map { "a_session ->> '$_' <> '$rule->{not}->{$_}'" }
              keys %{ $rule->{not} } );
    }
    return 0 unless ($query);
    my $dbh        = $class->_classDbh($args);
    my $table_name = $args->{TableName}
      || $Apache::Session::Store::DBI::TableName;
    my $rows = $dbh->do("DELETE FROM $table_name WHERE $query");
    return 0 unless defined $rows;

    if (wantarray) {
        $rows = 0 if $rows == -1;
        return ( 1, $rows );
    }
    else {
        return 1;
    }
}

sub get_key_from_all_sessions {
    my ( $class, $args, $data ) = @_;

    my $table_name = $args->{TableName}
      || $Apache::Session::Store::DBI::TableName;
    my $dbh = $class->_classDbh($args);
    my $sth;

    # Special case if all wanted fields are indexed
    if ( $data and ref($data) ne 'CODE' ) {
        $data = [$data] unless ( ref($data) );
        my $fields = join ',', 'id',
          map { s/'//g; "a_session ->> '$_' AS \"$_\"" } @$data;
        $sth = $dbh->prepare("SELECT $fields from $table_name");
        $sth->execute;
        return $sth->fetchall_hashref('id');
    }
    $sth = $dbh->prepare_cached("SELECT id,a_session from $table_name");
    $sth->execute;
    my %res;
    while ( my @row = $sth->fetchrow_array ) {
        no strict 'refs';
        my $self = eval "&${class}::populate();";
        eval {
            my $sub = $self->{unserialize};
            my $tmp = &$sub( { serialized => $row[1] } );
            if ( ref($data) eq 'CODE' ) {
                $tmp = &$data( $tmp, $row[0] );
                $res{ $row[0] } = $tmp if ( defined($tmp) );
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                $res{ $row[0] }->{$_} = $tmp->{$_} foreach (@$data);
            }
            else {
                $res{ $row[0] } = $tmp;
            }
        };
        if ($@) {
            print STDERR "Error in session $row[0]: $@\n";
            delete $res{ $row[0] };
        }
    }
    return \%res;
}

sub _classDbh {
    my ( $class, $args ) = @_;

    my $datasource = $args->{DataSource} or die "No datasource given !";
    my $username   = $args->{UserName};
    my $password   = $args->{Password};
    my $dbh =
      DBI->connect_cached( $datasource, $username, $password,
        { RaiseError => 1, AutoCommit => 1 } )
      || die $DBI::errstr;
    $dbh->{pg_enable_utf8} = 1;
    return $dbh;
}

1;
__END__

=head1 NAME

Apache::Session::Browseable::PgJSON - Hstore type support for
L<Apache::Session::Browseable::Postgres>

=head1 SYNOPSIS

Create table:

  CREATE UNLOGGED TABLE sessions (
      id varchar(64) not null primary key,
      a_session jsonb,
  );

Optionally, add indexes on some fields. Example for Lemonldap::NG:

  CREATE INDEX uid1 ON sessions USING BTREE ( (a_session ->> '_whatToTrace') );
  CREATE INDEX  s1  ON sessions ( (a_session ->> '_session_kind') );
  CREATE INDEX  u1  ON sessions ( ( cast(a_session ->> '_utime' AS bigint) ) );
  CREATE INDEX ip1  ON sessions USING BTREE ( (a_session ->> 'ipAddr') );

Use it like L<Apache::Session::Browseable::Postgres> except that you don't
need to declare indexes

=head1 DESCRIPTION

Apache::Session::Browseable provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Apache::Session::Browseable::PgJSON implements it for PosqtgreSQL databases
using "json" or "jsonb" type to be able to browse sessions.

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
