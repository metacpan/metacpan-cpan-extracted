package DBD::Salesforce::db;

# ----------------------------------------------------------------------
# $Id: db.pm,v 1.1.1.1 2006/02/14 16:54:03 shimizu Exp $
# ----------------------------------------------------------------------
# The database handle (dbh)
# ----------------------------------------------------------------------

use strict;
use base qw(DBD::_::db);
use vars qw($VERSION $imp_data_size);

use DBI;
use SQL::Parser;

$VERSION = "0.01";
$imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, @attr) = @_;
    my ($sth, @parsed);

    my $parser = SQL::Parser->new;
    $parser->parse($statement)
        or die $parser->errstr;
    @parsed = [
        map { { FIELD    => $parser->structure->{'ORG_NAME'}->{$_},
                FUNCTION => $parser->structure->{'column_functions'}->{$_},
                ALIAS    => $parser->structure->{'column_aliases'}->{$_},
            } }          @{ $parser->structure->{'column_names'} }
    ];

    $sth = DBI::_new_sth($dbh, {
        'Statement' => $statement,
        'Columns'   => @parsed,
        'Parser'    => $parser->structure(),
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

#sub get_info {
#    my($dbh, $info_type) = @_;
#    require DBD::Salesforce::GetInfo;
#    my $v = $DBD::Salesforce::GetInfo::info{int($info_type)};
#    $v = $v->($dbh) if ref $v eq 'CODE';
#    return $v;
#}

1;

__END__
