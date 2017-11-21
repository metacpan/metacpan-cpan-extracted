{

    package DBIx::MysqlCoroAnyEvent;

    our $VERSION = "0.02";
    use base 'DBI';

=head1 NAME
 
DBIx::MysqlCoroAnyEvent - DBD::mysql + Coro + AnyEvent
 
=head1 SYNOPSIS
 
  use DBI;
  $dbh = DBI->connect("dbi:mysql:dbname=$dbname", $username, $auth, { RootClass =>"DBIx::MysqlCoroAnyEvent",  %rest_attr});

=cut

}
{

    package DBIx::MysqlCoroAnyEvent::db;
    use DBD::mysql;
    use DBI;
    use base 'DBI::db';
    use strict;
    use warnings;

    sub prepare {
        my ($dbh, $statement, @attribs) = @_;
        return undef if !defined $statement;
        $attribs[0]{async} = 1;
        $dbh->SUPER::prepare($statement, @attribs);
    }

    sub do {
        my ($dbh, $statement, $attr, @params) = @_;
        my $sth = prepare($dbh, $statement, $attr) or return;
        $sth->execute(@params) or return;
        my $rows = $sth->rows;
        ($rows == 0) ? "0E0" : $rows;
    }

    BEGIN {
        no warnings 'once';
        *selectrow_array    = \&DBD::_::db::selectrow_array;
        *selectrow_arrayref = \&DBD::_::db::selectrow_arrayref;
        *selectall_arrayref = \&DBD::_::db::selectall_arrayref;
    }
}

{

    package DBIx::MysqlCoroAnyEvent::st;
    use Coro;
    use AnyEvent;
    use Coro::AnyEvent;
    use base 'DBI::st';

    sub execute {
        my ($sth, @vars) = @_;
        my $res = $sth->SUPER::execute(@vars);
        my $dbh = $sth->{Database};
        Coro::AnyEvent::readable $dbh->mysql_fd while !$sth->mysql_async_ready;
        $sth->mysql_async_result;
    }
}

1;
