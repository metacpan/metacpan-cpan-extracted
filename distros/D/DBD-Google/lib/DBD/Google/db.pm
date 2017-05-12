package DBD::Google::db;

# ----------------------------------------------------------------------
# The database handle (dbh)
# ----------------------------------------------------------------------

use strict;
use base qw(DBD::_::db);
use vars qw($VERSION $imp_data_size);

use DBI;
use DBD::Google::parser;

$VERSION = "2.00";
$imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, @attr) = @_;
    my ($sth, $parsed, $google, $search, $search_opts);

    my $parser = DBD::Google::parser->new;
    $parser->parse($statement)
        or die $parser->errstr;
    $parsed = $parser->decompose;

    # Get the google instance and %attr
    $google = $dbh->FETCH('driver_google');
    $search_opts = $dbh->FETCH('driver_google_opts');

    # Create the search object
    # XXX Start work here -- need a way to retrieve the column
    # names, limit items, and where clause from $parsed
    $search = $google->search(%$search_opts);
    $search->query($parsed->{'WHERE'});
    $search->starts_at($parsed->{'LIMIT'}->{'offset'});
    $search->max_results($parsed->{'LIMIT'}->{'limit'});

    $sth = DBI::_new_sth($dbh, {
        'Statement' => $statement,
        'Columns' => $parsed->{'COLUMNS'},
        'GoogleSearch' => $search,
    });

    # ?
    $sth->STORE('driver_params', [ ]);

    return $sth;
}

# ----------------------------------------------------------------------
# These next four methods are taken directly from DBI::DBD
# ----------------------------------------------------------------------
sub STORE {
    my ($dbh, $attr, $val) = @_;
    if ($attr eq 'AutoCommit') {
        return 1;
    }

    if ($attr =~ m/^driver_/) {
        $dbh->{$attr} = $val;
        return 1;
    }

    $dbh->SUPER::STORE($attr, $val);
}

sub FETCH {
    my ($dbh, $attr) = @_;

    if ($attr eq 'AutoCommit') {
        return 1
    }
    elsif ($attr =~ m/^driver_/) {
        return $dbh->{$attr};
    }

    $dbh->SUPER::FETCH($attr);
}

sub commit {
    my $dbh = shift;

    warn "Commit ineffective while AutoCommit is on"
        if $dbh->FETCH('Warn');

    1;
}

sub rollback {
    my $dbh = shift;

    warn "Rollback ineffective while AutoCommit is on"
        if $dbh->FETCH('Warn');

    0;
}

sub get_info {
    my($dbh, $info_type) = @_;
    require DBD::Google::GetInfo;
    my $v = $DBD::Google::GetInfo::info{int($info_type)};
    $v = $v->($dbh) if ref $v eq 'CODE';
    return $v;
}

1;
__END__
