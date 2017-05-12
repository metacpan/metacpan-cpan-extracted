# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 17:04 (EST)
# Function: get list of files to map
#
# $Id: FileList.pm,v 1.3 2010/11/10 16:24:38 jaw Exp $

package AC::MrGamoo::AC::FileList;
use AC::MrGamoo::Debug 'files';
use AC::ISOTime;
use AC::Yenta::Direct;
use JSON;
use strict;

my $YDBFILE = "/home/acdata/logfile.ydb";

# return an array of:
#   {
#     filename    => www/2010/01/17/23/5943_prod_5x2N5qyerdeddsNi
#     location    => [ scrib@a2be021bd31c, scrib@a2be021ad31c ]
#     size        => 10863
#     [anything else]
#   }

# convert legacy scriblr ids
my %CONVERT = (
    'scrib@a2be021ad31c' => 'mrm@gefiltefish1-r3.ccsphl',
    'scrib@a2be021bd31c' => 'mrm@gefiltefish1-r4.ccsphl',
    'scrib@a2be021cd31c' => 'mrm@gefiltefish2-r3.ccsphl',
    'scrib@a2be021dd31c' => 'mrm@gefiltefish2-r4.ccsphl',
    'scrib@a2be021ed31c' => 'mrm@gefiltefish3-r3.ccsphl',
    'scrib@a2be021fd31c' => 'mrm@gefiltefish3-r4.ccsphl',
    'scrib@a2be0220d31c' => 'mrm@gefiltefish4-r3.ccsphl',
    'scrib@a2be0221d31c' => 'mrm@gefiltefish4-r4.ccsphl',
);

sub get_file_list {
    my $config = shift;

    my $yenta = AC::Yenta::Direct->new( 'logfile', $YDBFILE );

    my $mode  = $config->{datamode};
    my $syst  = $config->{system};
    my $tmax  = $config->{end};
    my $tmin  = $config->{start};
    my $start = isotime($tmin);
    $start =~ s/^(\d+)T(\d+).*/$1$2/;	# 20091109T123456... => 20091109123456

    # NB: keys in the yenta logfile map are of the form: 20100126150139_eqaB5uSerdeddsOw

    $syst = undef if $syst eq '*';
    $mode = undef if $mode eq '*';
    $syst =~ s/[ ,]/\|/g;
    if( $syst ){
        $syst = qr/^($syst)$/;
    }

    debug("mode=$mode, syst=$syst, tmin=$tmin, tmax=$tmax, start=$start");
    my @files = grep {
        (!$mode || ($_->{environment} eq $mode)) &&
        (!$syst || ($_->{subsystem}   =~ $syst)) &&
        ($_->{end_time}    >= $tmin) &&
        ($_->{start_time}  <= $tmax)
    } map {
        #debug("file: $_");
        my $d = $yenta->get($_);
        $d = $d ? decode_json($d) : {};
        $d->{location} = [ map { $CONVERT{$_} || $_ } (split /\s+/, $d->{location}) ];
        $d;
    } $yenta->getrange($start, undef);

    debug("found " .scalar(@files)." files");
    return \@files;
}


1;
