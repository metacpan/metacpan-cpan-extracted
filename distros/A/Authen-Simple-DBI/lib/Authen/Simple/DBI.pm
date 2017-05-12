package Authen::Simple::DBI;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use DBI              qw[SQL_CHAR];
use Params::Validate qw[];

our $VERSION = 0.2;

__PACKAGE__->options({
    dsn => {
        type     => Params::Validate::SCALAR,
        optional => 0
    },
    statement => {
        type     => Params::Validate::SCALAR,
        optional => 0
    },
    username => {
        type     => Params::Validate::SCALAR,
        optional => 1
    },
    password => {
        type     => Params::Validate::SCALAR,
        optional => 1
    },
    attributes => { # undocumented for now
        type     => Params::Validate::HASHREF,
        default  => { ChopBlanks => 1, PrintError => 0, RaiseError => 0 },
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my ( $dsn, $dbh, $sth, $encrypted ) = ( $self->dsn, undef, undef, undef );

    unless ( $dbh = DBI->connect_cached( $dsn, $self->username, $self->password, $self->attributes ) ) {

        my $error = DBI->errstr;

        $self->log->error( qq/Failed to connect to database using dsn '$dsn'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    unless ( $sth = $dbh->prepare_cached( $self->statement ) ) {

        my $error     = $dbh->errstr;
        my $statement = $self->statement;

        $self->log->error( qq/Failed to prepare statement '$statement'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    unless ( $sth->bind_param( 1, $username, SQL_CHAR ) ) {

        my $error     = $sth->errstr;
        my $statement = $self->statement;

        $self->log->error( qq/Failed to bind param '$username' to statement '$statement'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    unless ( $sth->execute ) {

        my $error     = $sth->errstr;
        my $statement = $self->statement;

        $self->log->error( qq/Failed to execute statement '$statement'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    unless ( $sth->bind_col( 1, \$encrypted ) ) {

        my $error     = $sth->errstr;
        my $statement = $self->statement;

        $self->log->error( qq/Failed to bind column. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    unless ( $sth->fetch ) {

        my $statement = $self->statement;

        $self->log->debug( qq/User '$username' was not found with statement '$statement'./ )
          if $self->log;

        return 0;
    }

    $sth->finish;

    unless ( defined $encrypted && length $encrypted ) {

        $self->log->debug( qq/Encrypted password for user '$username' is null./ )
          if $self->log;

        return 0;
    }

    unless ( $self->check_password( $password, $encrypted ) ) {

        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: 'Invalid credentials'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::DBI - Simple DBI authentication

=head1 SYNOPSIS

    use Authen::Simple::DBI;
    
    my $dbi = Authen::Simple::DBI->new(
        dsn       => 'dbi:SQLite:dbname=database.db',
        statement => 'SELECT password FROM users WHERE username = ?'
    );
    
    if ( $dbi->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler

    PerlModule Apache::DBI
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::DBI

    PerlSetVar AuthenSimpleDBI_dsn       "dbi:SQLite:dbname=database.db"
    PerlSetVar AuthenSimpleDBI_statement "SELECT password FROM users WHERE username = ?"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::DBI
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

DBI authentication.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * dsn

Database Source Name. Required.

    dsn => 'dbi:SQLite:dbname=database.db'
    dsn => 'dbi:mysql:database=database;host=localhost;'

=item * statement

SQL statement. The statement must take a single string argument (username) and 
return a single value (password). Required.

    statement => 'SELECT password FROM users WHERE username = ?'

=item * username

Database username.

    username => 'username'
    
=item * password

Database password.

    password => 'secret'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::DBI')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Simple::Password>.

L<DBI>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
