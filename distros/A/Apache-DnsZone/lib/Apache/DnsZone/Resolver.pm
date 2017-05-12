package Apache::DnsZone::Resolver;

# $Id: Resolver.pm,v 1.3 2001/05/05 18:44:41 thomas Exp $

use strict;
use vars qw($VERSION);
use Net::DNS;

($VERSION) = qq$Revision: 1.3 $ =~ /([\d\.]+)/;

sub new {
    my $class = shift;
    my $res = new Net::DNS::Resolver;
    return bless { res => $res }, $class;
}

sub res {
    my $self = shift;
    return $self->{'res'};
}

######################################################
# Dns resolver class for persistant resolver objects #
# Persistant objects are to be implemented           #
######################################################

1;
