package Authen::Htpasswd::Trac;
use strict;
use warnings;
use Carp;
use DBI;
use SQL::Abstract;
use base qw( Authen::Htpasswd );
__PACKAGE__->mk_accessors($_) for qw( dbh table sql );

our $VERSION = '0.00004';

sub new {
    my $class = shift;
    my $file  = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new( $file, $args );

    unless ( exists $args->{trac} ) {
        croak "trac is empty.";
    }

    unless ( -f $args->{trac} ) {
        croak "could not find trac database.";
    }

    $self->sql( SQL::Abstract->new );
    $self->table( $args->{table} ? $args->{table} : 'permission' );
    $self->dbh( $self->_dbh( $args->{trac} ) );
    $self;
}

sub _dbh {
    my $self = shift;
    my $db   = shift;

    my $connect_info
        = [ 'dbi:SQLite:dbname=' . $db, '', '', { AutoCommit => 1 } ];

    my $dbh = DBI->connect(@$connect_info)
        || croak "could not connect database($db)";

    $self->dbh($dbh);
}

sub find_user_permissions {
    my ( $self, $username, $password ) = @_;
    my $user = $self->lookup_user($username);
    croak "could not find user $username" unless $user;

    if ( $user->check_password($password) ) {
        return $self->_find_permissions($username);
    }

    return ();
}

sub _find_permissions {
    my $self     = shift;
    my $username = shift;

    my ( $stmt, @binds )
        = $self->sql->select( $self->table, 'action',
        { username => $username } );

    my $sth = $self->dbh->prepare($stmt);
    $sth->execute(@binds);

    return map { $_->[0] } @{ $sth->fetchall_arrayref };
}

sub add_permission {
    my ( $self, $username, $action ) = @_;

    my ( $stmt, @binds )
        = $self->sql->insert( $self->table, [ $username, $action ], );

    my $sth = $self->dbh->prepare($stmt);
    return $sth->execute(@binds);
}

sub remove_permission {
    my ( $self, $username, $action ) = @_;

    my ( $stmt, @binds ) = $self->sql->delete(
        $self->table,
        {   username => $username,
            action   => $action
        }
    );

    my $sth = $self->dbh->prepare($stmt);
    return $sth->execute(@binds);
}

1;
__END__

=head1 NAME

Authen::Htpasswd::Trac - interface to read and modify Trac password files

=head1 SYNOPSIS

  use Authen::Htpasswd::Trac;

  my $auth = Authen::Htpasswd::Trac->new( '/path/to/.htpasswd', { trac => '/path/to/trac.db'} );
  my @rs   = $auth->find_user_permissions($username, $password);

  $auth->add_permission('myuser', 'TRAC_ADMIN');
  $auth->remove_permission('myuser', 'TRAC_ADMIN');

=head1 DESCRIPTION

This module based on Authen::Htpasswd.
And interface to trac with account-manager plugin.

=head1 METHODS

=head2 new( password file, { trac => 'database file of trac' })

=head2 find_user_permissions( username, password )

  Returns trac permission names.

=head2 add_permission( username, action )

  Add permission to trac.

=head2 remove_permission

  Remove permission to trac.

=head2 other methods

  $ perldoc Authen::Htpasswd

=head1 AUTHOR

Kazuhiro Nishikawa E<lt>kazuhiro.nishikawa@gmail.comE<gt>

=head1 SEE ALSO

L<Authen::Htpasswd>, L<http://trac.edgewall.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
