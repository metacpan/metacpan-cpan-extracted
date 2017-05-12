package DBIx::SQLHandler;

use warnings;
use strict;

use Abstract::Meta::Class ':all';
use vars qw($VERSION);

$VERSION = 0.03;

=head1 NAME

DBIx::SQLHandler - Sql statement handler.

=head1 SYNOPSIS

    use DBIx::SQLHandler
    my $sql_handler = new DBIx::SQLHandler(
      name        => 'emp_ins',
      connection  => $connection,
      sql         => "INSERT INTO emp(empno, ename) VALUES(?, ?)"
    );
    $sql_handler->execute(1, 'Smith');
    $sql_handler->execute(2, 'Witek');


    my $sql_handler = new DBIx::SQLHandler(
      name        => 'emp_upd',
      connection  => $connection,
      sql         => "UPDATE emp SET ename = ? WHERE empno = ?"
    );
    $sql_handler->execute('Smith2',1);

    or

    use DBIx::Connection;

    ...

    my $sql_handler = $connection->sql_handler(
       name => 'emp_ins'
       sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)",
    );
    $sql_handler->execute(1, 'Smith');


=head1 DESCRIPTION

Represents wrapper for sql statments.
It manages sql statement's information within its state.
If an error occurs on any stage (prepare, execute, binding) you will get full information
including connection name, sql, binding variables.
Caching statements (if using name).
It gathers performance statistics (optionaly).

=head1 EXPORT

None.

=head2 ATTRIBUTES

=over

=item name

Statement name.

=cut

has '$.name';

=item connection

Database connection.

=cut

has '$.connection' => (associated_class => 'DBIx::Connection');


=item sth

Cursor handler.

=cut

has '$.sth';


=item sql

SQL text for cursor.

=cut

has '$.sql';


=back

=head2 METHODS

=over

=item initialise

Prepares the sql statement.

=cut

sub initialise {
    my ($self) = @_;
    $self->prepare();
}


=item prepare

Prepare the statement.

=cut

sub prepare {
    my ($self) = @_;
    my $connection = $self->connection;
    $connection->record_action_start_time;
    my $sth = $connection->dbh->prepare($self->sql)
      or $self->error_handler;
    $connection->record_action_end_time($self->sql);
    $self->set_sth($sth);
}


=item execute

Executes the statement.

=cut

sub execute {
    my $self = shift;
    my $connection = $self->connection;
    my $sth = $self->sth;
    $connection->record_action_start_time;
    $sth->execute(@_) 
      or $self->error_handler(\@_);
    $connection->record_action_end_time($self->sql);
}


=item bind_columns

Binds column to the statement.

=cut

sub bind_columns {
    my ($self, $bind_results) = @_;
    if ($bind_results) {
        my $sth = $self->sth;
        $sth->bind_columns(
          ref($bind_results) eq 'HASH' 
            ? \(@{$bind_results}{@{$sth->{NAME_lc}}}) 
            :  ref($bind_results) eq 'ARRAY' 
              ? \(@{$bind_results}[0..$#{$sth->{NAME_lc}}])
              : ()
        ) or $self->error_handler;
    }
}


=item bind_params_inout

Bind parameters to the statement.

=cut

sub bind_params_inout {
    my ($self, $params) = @_;
    my $sth = $self->sth;
    eval {
        $sth->bind_param_inout(":".$_, \$params->{$_}, 32000) 
          for keys %$params;
        $self;
    } or $self->error_handler;
}


=item bind_params

Bind parameters to the statement.

=cut

sub bind_params {
    my ($self, $params) = @_;
    my $sth = $self->sth;
    eval {
        $sth->bind_param(":".$_, $params->{$_})
          for keys %$params;
          $self;
    } or $self->error_handler;
}



=item error_handler

Returns error messagem, takes error message, and optionally bind variables.
If bind variables are passed in the sql's place holders are replaced with the bind_variables.

=cut

sub error_handler {
    my ($self, $bind_params) = @_;
    my $connection = $self->connection;
    my $sql = $self->sql;
    if (defined($bind_params)) {
        $sql =~ s/\?/'$_'/  
          for map {ref($_) eq 'CODE' ? $_->() : defined $_ ? $_ : ''} @$bind_params
    }
    $connection->error_handler($sql);
}


=item cleanup

=cut

sub cleanup {
    my ($self) = @_;
    $self->finish;
    $self->set_sth;
    $self->set_dbh;
}

1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::SQLHandler module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also B<DBIx::Connection> B<DBIx::QueryCursor> B<DBIx::PLSQLHandler>.

=cut
