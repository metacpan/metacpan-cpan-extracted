package DBIx::Handler::Sunny;
use strict;
use warnings;

our $VERSION = '0.02';

# cpan
use parent qw(DBIx::Handler);

sub _do_selectrow { # see DBI::_do_selectrow
    my ($self, $method, @args) = @_;
    my $sth = $self->query(@args)
        or return undef;
    my $row = $sth->$method()
        and $sth->finish;
    return $row;
}

sub select_one {
    my ($self, @args) = @_;
    my $row = $self->_do_selectrow('fetchrow_arrayref', @args);
    return undef unless $row;
    return $row->[0];
}

sub select_row {
    my ($self, @args) = @_;
    my $row = $self->_do_selectrow('fetchrow_hashref', @args);
    return unless $row;
    return $row;
}

sub select_all {
    my ($self, @args) = @_;
    my $sth = $self->query(@args)
        or return [];
    return $sth->fetchall_arrayref({});
}

sub last_insert_id {
    my $self = shift;
    my $dsn = $self->{_connect_info}->[0];
    if ($dsn =~ /^(?i:dbi):SQLite\b/) {
        return $self->dbh->func('last_insert_rowid');
    }
    elsif ( $dsn =~ /^(?i:dbi):mysql\b/) {
        return $self->dbh->{mysql_insertid};
    }
    $self->dbh->last_insert_id(@_);
}

sub txn {
    my ($self, $coderef) = @_;
    $self->SUPER::txn(sub { $coderef->($self) });
}

1;
__END__

=head1 NAME

DBIx::Handler::Sunny - DBIx::Handler meets Sunny

=head1 SYNOPSIS

    use DBIx::Handler::Sunny;
    my $handler = DBIx::Handler::Sunny->new($dsn, $user, $pass, $opts);
    my $col = $handler->select_one('SELECT ...');
    my $row = $handler->select_row('SELECT ...');
    my $rows = $handler->select_all('SELECT ...');

=head1 DESCRIPTION

C<DBIx::Handler::Sunny> is a DBI handler with some useful interface.
It ads L<DBIx::Handler> to methods for selecting a column or row(s).

The methods are taken from L<DBIx::Sunny>.

=head1 METHODS

=over 4

=item select_one

    $col = $handler->select_one($query, @bind);

Shortcut for C<prepare>, C<execute> and C<fetchrow_arrayref-E<gt>[0]>.

=item select_row

    $row = $handler->select_row($query, @bind);

Shortcut for C<prepare>, C<execute> and C<fetchrow_hashref>.

=item select_all

    $rows = $handler->select_all($query, @bind);

Shortcut for C<prepare>, C<execute> and C<selectall_arrayref(..., { Slice =E<gt> {} }, ...)>.

=item last_insert_id

    $id = $handler->last_insert_id

Retrieve the last insert ID by suitable way for the DB driver.
Supported drivers are SQLite and MySQL.

=back

=head1 SEE ALSO

L<DBIx::Handler>

L<DBIx::Sunny>

=head1 LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut
