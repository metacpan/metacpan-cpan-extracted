# -*- perl -*-
# example myself

# $Id: myself.pm,v 1.1 2010/11/01 19:04:21 jaw Exp $

package Local::MrGamoo::MySelf;
use Sys::Hostname;
use strict;

my $SERVERID;

sub init {
    my $class = shift;
    my $port  = shift;	# our tcp port
    my $id    = shift;  # from cmd line

    $SERVERID = $id;
    unless( $SERVERID ){
        (my $h = hostname()) =~ s/\.example.com//;	# remove domain
        $SERVERID = "mrm/$h";
    }
    verbose("system persistent-id: $SERVERID");
}

sub my_server_id {
    return $SERVERID;
}

1;

