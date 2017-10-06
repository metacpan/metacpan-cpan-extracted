#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

use Test::Trap qw(:default);
use List::MoreUtils qw(firstidx each_array);
use Clone qw(clone);

use Data::SeaBASS qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));
my (@data_rows, @data_rows_sal_undef);
my @depth = qw(3.4 19.1 38.3 59.6);
my @wt    = qw(20.7320 20.7350 20.7400 20.7450);

my $iter = each_array(@depth, @wt);
while (my ($depth, $wt) = $iter->()) {
    push(@data_rows,                {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'wt' => $wt, 'sal' => '-999'});
    push(@data_rows_sal_undef,      {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'wt' => $wt, 'sal' => undef});
}

trap {
    my $sb_file = Data::SeaBASS->new(\$DATA[0], {});
    $sb_file->write();
};
is($trap->leaveby, 'return', "write trap 1");
is($trap->stdout,  $DATA[0], "write stdout 1");

trap {
    my $sb_file = Data::SeaBASS->new(\$DATA[1], {});
    $sb_file->write();
};
is($trap->leaveby, 'die', "strict write trap 1");

trap {
    my $sb_file = Data::SeaBASS->new(\$DATA[0], {strict => 0});
    $sb_file->write();
};
is($trap->leaveby, 'return', "nostrict write trap 1");

trap {
    my $sb_file = Data::SeaBASS->new({strict => 0, add_empty_headers => 1, preserve_case => 0});
    $sb_file->add_field('lat', 'degrees');
    $sb_file->add_field('lon', 'degrees');
    $sb_file->append({'lat' => 1, 'lon' => 2});
    $sb_file->append("3,4");
    $sb_file->write();
};
is($trap->leaveby, 'return', "write trap 2");
is($trap->stdout,  $DATA[4], "write stdout 2");

trap {
    my $sb_file = Data::SeaBASS->new({strict => 0});
    $sb_file->add_field('lat', 'degrees');
    $sb_file->add_field('lon', 'degrees');
    $sb_file->append({'lat' => 1, 'lon' => 2});
    $sb_file->append("3,4");
    $sb_file->write();
};
is($trap->leaveby, 'return', "write trap 3");
is($trap->stdout,  $DATA[5], "write stdout 3");

trap {
    my $sb_file = Data::SeaBASS->new({strict => 0});
    $sb_file->add_field('lat', 'degrees');
    $sb_file->add_field('lon', 'degrees');
    $sb_file->append({'lat' => 1, 'lon' => 2});
    $sb_file->append("3 4");
    $sb_file->write();
};
is($trap->leaveby, 'return', "write trap 4");
is($trap->stdout,  $DATA[6], "write stdout 4");

trap {
    my $sb_file = Data::SeaBASS->new({strict => 0, keep_slashes => 1});
    $sb_file->add_field('lat', 'degrees');
    $sb_file->add_field('lon', 'degrees');
    $sb_file->append({'lat' => 1, 'lon' => 2});
    $sb_file->append("3 4");
    $sb_file->write();
};
is($trap->leaveby, 'return', "write trap 5");
is($trap->stdout,  $DATA[6], "write stdout 5");

trap {
    my $sb_file = Data::SeaBASS->new(\$DATA[6], {strict => 0});
    $sb_file->where(sub {$_->{'lon'} *= 2;});
    $sb_file->write();
};
is($trap->leaveby, 'return', "nostrict write trap 1");
is($trap->stdout,  $DATA[7], "write stdout 5");

done_testing();

__DATA__
/begin_header
/investigators=Anthony_Michaels
/affiliations=Bermuda_Biological_Station_for_Research
/contact=rumorr@bbsr.edu
/experiment=BATS
/cruise=bats###
/station=NA
/data_file_name=bats92_hplc.txt
/documents=default_readme.txt
/calibration_files=missing_calibration.txt
/data_type=pigment
/data_status=final
/start_date=19920109
/end_date=19921207
/start_time=14:00:00[gmt]
/end_time=21:47:00[gmt]
/north_latitude=31.819[deg]
/south_latitude=31.220[deg]
/east_longitude=-63.978[deg]
/west_longitude=-64.702[deg]
/cloud_percent=NA
/measurement_depth=NA
/secchi_depth=NA
/water_depth=NA
/wave_height=NA
/wind_speed=NA
!
! Comments:
!
! 0 value = less than detection limit
! -999 value = no data
!
! This is BATS Core data
! See: http://www.bbsr.edu/cintoo/bats/bats.html for additional information and data
!
/missing=-999
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/units=yyyymmdd,hh:mm:ss,degrees,degrees,m,degreesc,psu
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
<BR/>
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
<BR/>
/units=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
<BR/>
/delimiter=notspace
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
<BR/>
/begin_header
/investigators=na
/affiliations=na
/contact=na
/experiment=na
/cruise=na
/station=na
/data_file_name=na
/documents=na
/calibration_files=na
/data_type=na
/data_status=na
/start_date=na
/end_date=na
/start_time=na[gmt]
/end_time=na[gmt]
/north_latitude=na[deg]
/south_latitude=na[deg]
/east_longitude=na[deg]
/west_longitude=na[deg]
/cloud_percent=na
/measurement_depth=na
/secchi_depth=na
/water_depth=na
/wave_height=na
/wind_speed=na
! Comments: 
!
/missing=-999
/delimiter=comma
/fields=lat,lon
/units=degrees,degrees
/end_header
1,2
3,4
<BR/>
/begin_header
/missing=-999
/delimiter=comma
/fields=lat,lon
/units=degrees,degrees
/end_header
1,2
3,4
<BR/>
/begin_header
/missing=-999
/delimiter=space
/fields=lat,lon
/units=degrees,degrees
/end_header
1 2
3 4
<BR/>
/begin_header
/missing=-999
/delimiter=space
/fields=lat,lon
/units=degrees,degrees
/end_header
1 4
3 8
