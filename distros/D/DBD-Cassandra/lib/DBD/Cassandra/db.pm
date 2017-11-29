package DBD::Cassandra::db;
our $AUTHORITY = 'cpan:TVDW';
$DBD::Cassandra::db::VERSION = '0.57';
# ABSTRACT: DBD::Cassandra database handle

use 5.010;
use strict;
use warnings;

use Devel::GlobalDestruction;

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

    return if in_global_destruction;

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

__END__

=pod

=head1 NAME

DBD::Cassandra::db - DBD::Cassandra database handle

=head1 VERSION

version 0.57

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
