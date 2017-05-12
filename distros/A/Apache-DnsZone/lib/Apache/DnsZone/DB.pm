package Apache::DnsZone::DB;

# $Id: DB.pm,v 1.6 2001/06/03 11:10:24 thomas Exp $

use strict;
use vars qw($VERSION);
use Apache::DnsZone;
use Apache::DnsZone::Config;
use DBI;

($VERSION) = qq$Revision: 1.6 $ =~ /([\d\.]+)/;

sub new {
    my $class = shift;
    my $cfg = shift;
    my $dbsrc = $cfg->{cfg}->{DnsZoneDBsrc};
    my $dbuser = $cfg->{cfg}->{DnsZoneDBuser};
    my $dbpass = $cfg->{cfg}->{DnsZoneDBpass};
    my $dbh = db_conn($dbsrc, $dbuser, $dbpass);
    return bless { dbh => $dbh, dbsrc => $dbsrc, dbuser => $dbuser, dbpass => $dbpass }, $class;
}

sub db {
    my $self = shift;
    return $self->{'dbh'};
}

sub close {
    my $self = shift;
    $self->{'dbh'}->disconnect();
}

1;
