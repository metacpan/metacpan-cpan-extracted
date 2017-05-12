#!/usr/bin/perl -w
# $Id: track.pl,v 1.9 2004/08/09 16:07:14 jay.powers Exp $
use Business::FedEx::DirectConnect;
use strict;
my $t = new Business::FedEx::DirectConnect(uri=> ''
                ,acc => '' #FedEx account Number
                ,meter => '' #FedEx Meter Number (this is given after you subscribe to FedEx)
                ,referer => 'Vermonster LLC' # Name or company
                ,Debug=>1
                );

$t->set_data(5002, 1534 =>'Y', 1537 =>'[tracking#]') or die $t->errstr;

$t->transaction or die $t->errstr;


my $stuff= $t->hash_ret;

foreach (keys %{$stuff}) {
    print $_. ' => ' . $stuff->{$_} . "\n";
}
