# -*- perl -*-
# example filelist

# $Id: filelist.pm,v 1.1 2010/11/01 19:04:21 jaw Exp $

package Local::MrMagoo::FileList;
use AC::ISOTime;
use AC::Yenta::Direct;
use JSON;
use strict;

my $YDBFILE = "/data/files.ydb";

sub get_file_list {
    my $config = shift;

    # get files + metadata from yenta
    my $yenta = AC::Yenta::Direct->new( 'files', $YDBFILE );

    # the job config is asking for files that match:
    my $syst  = $config->{system};
    my $tmax  = $config->{end};		# time_t
    my $tmin  = $config->{start};	# time_t

    # the keys in  yenta are of the form: 20100126150139_[...]
    my $start = isotime($tmin);		# 1286819830       => 20101011T175710Z
    $start =~ s/^(\d+)T(\d+).*/$1$2/;	# 20101011T175710Z => 20101011175710


    my @files = grep {
        # does this file match the request?
        ($_->{subsystem}   eq $syst) &&
        ($_->{end_time}    >= $tmin) &&
        ($_->{start_time}  <= $tmax)
    } map {
        # get meta-data on this file. data is json encoded
        my $d = $yenta->get($_);
        $d = $d ? decode_json($d) : {};
        # convert space seperated locations to arrayref
        $d->{location} = [ (split /\s+/, $d->{location}) ];
        $d;
    } $yenta->getrange($start, undef);	# get all files from $start to now


    return \@files;
}


1;
