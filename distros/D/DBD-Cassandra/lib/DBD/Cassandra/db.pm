package DBD::Cassandra::db;
use 5.010;
use strict;
use warnings;

# This cargocult comes straight from DBI::DBD docs. No idea what it does.
$DBD::Cassandra::db::imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, $attribs)= @_;

    if ($attribs->{server_side_prepare}) {
        my $client= $dbh->{cass_client};

        my ($error)= $client->call_prepare($statement);
        if ($error) {
            return $dbh->set_err($DBI::stderr, $error);
        }
    }

    my ($outer, $sth)= DBI::_new_sth($dbh, { Statement => $statement });
    $sth->{cass_consistency}= $attribs->{consistency} || $attribs->{Consistency};
    $sth->{cass_page_size}= $attribs->{perpage} || $attribs->{PerPage} || $attribs->{per_page};
    $sth->{cass_async}= $attribs->{async};

    return $outer;
}

sub commit {
    my ($dbh)= @_;
    if ($dbh->FETCH('Warn')) {
        warn "Commit ineffective while AutoCommit is on";
    }
    0;
}

sub rollback {
    my ($dbh)= @_;
    if ($dbh->FETCH('Warn')) {
        warn "Rollback ineffective while AutoCommit is on";
    }
    0;
}

sub STORE {
    my ($dbh, $attr, $val)= @_;
    if ($attr eq 'AutoCommit') {
        if (!$val) { die "DBD::Cassandra does not support transactions"; }
        return 1;
    }
    if ($attr =~ m/\Acass_/) {
        $dbh->{$attr}= $val;
        return 1;
    }
    return $dbh->SUPER::STORE($attr, $val);
}

sub FETCH {
    my ($dbh, $attr)= @_;
    return 1 if $attr eq 'AutoCommit';
    return $dbh->{$attr} if $attr =~ m/\Acass_/;

    # Sort of a workaround for unrecoverable errors in st.pm
    if ($attr eq 'Active') {
        return $dbh->{cass_client}->is_active;
    }
    return $dbh->SUPER::FETCH($attr);
}

sub disconnect {
    my ($dbh)= @_;
    $dbh->STORE('Active', 0);

    $dbh->{cass_client}->shutdown;
}

sub ping {
    my ($dbh)= @_;
    return $dbh->FETCH('Active');
}

sub x_wait_for_schema_agreement {
    my ($dbh)= @_;
    my ($error)= $dbh->{cass_client}->call_wait_for_schema_agreement;
    if ($error) {
        return $dbh->set_err($DBI::stderr, $error);
    }
    return 1;
}

1;
