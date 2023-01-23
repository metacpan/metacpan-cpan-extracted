package BoardStreams::DBUtil;

use Mojo::Base -strict, -signatures, -async_await;

use BoardStreams::Exceptions qw/ db_duplicate_error db_error /;
use BoardStreams::Util 'belongs_to';

use Mojo::Promise;
use Syntax::Keyword::Try;
use Carp 'croak';

use Exporter 'import';
our @EXPORT = qw/
    query_throwing_exception_object_p query_throwing_exception_object
    exists_p row_exists
/;

our $VERSION = "v0.0.31";

async sub exists_p ($db, $table_name, $where = undef, $options = undef) {
    my ($sql, @bind) = $db->pg->abstract->select($table_name, undef, $where, $options);
    $sql = "SELECT EXISTS ($sql)";
    my $results = await $db->query_p($sql, @bind);
    return $results->arrays->[0][0];
}

sub row_exists ($db, $table_name, $where = undef, $options = undef) {
    my ($sql, @bind) = $db->pg->abstract->select($table_name, undef, $where, $options);
    $sql = "SELECT EXISTS ($sql)";
    return $db->query($sql, @bind)->arrays->[0][0];
}

async sub query_throwing_exception_object_p ($db, $action, $args) {
    belongs_to($action, [qw/ insert_p update_p /])
        or croak "invalid action: '$action'";
    $action =~ s/_p\z//;

    my $p = Mojo::Promise->new;

    $db->$action(
        @$args,
        sub ($_db, $err, $results) {
            if ($err) {
                my $sth = $results->sth;
                if ($sth->err) {
                    # sth error codes are described here: https://www.postgresql.org/docs/14/errcodes-appendix.html
                    if ($sth->state eq '23505') {
                        # pg duplicate key error
                        my ($key_name) = $sth->errstr =~ /\"(.+?)\"/;
                        $err = db_duplicate_error $key_name;
                    } elsif ($sth->state !~ /^(00|01)/) {
                        # neither successful nor just a warning
                        $err = db_error undef, {
                            state  => $sth->state,
                            errstr => $sth->errstr,
                        };
                    }
                }
                $p->reject($err);
            } else {
                $p->resolve($results);
            }
        },
    );

    return $p;
}

sub query_throwing_exception_object ($db, $action, $args) {
    belongs_to($action, [qw/ insert update /])
        or croak "invalid action: '$action'";

    my $results = do {
        try {
            $db->$action(@$args);
        } catch ($err) {
            my $dbh = $db->dbh;
            if ($dbh->err) {
                if ($dbh->state eq '23505') {
                    # pg duplicate key error
                    my ($key_name) = $dbh->errstr =~ /\"(.+?)\"/;
                    $err = db_duplicate_error $key_name;
                } elsif ($dbh->state !~ /^(00|01)/) {
                    # neither successful nor just a warning
                    $err = db_error undef, {
                        state  => $dbh->state,
                        errstr => $dbh->errstr,
                    };
                }
            }
            die $err;
        };
    };

    return $results;
}

1;
