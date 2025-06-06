# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.08) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/nUm_LjpJ6O/northamerica.  Olson data version 2025b
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Merida;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '2.65';

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Merida::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
60620940000, #      utc_end 1922-01-01 06:00:00 (Sun)
DateTime::TimeZone::NEG_INFINITY, #  local_start
60620918492, #    local_end 1922-01-01 00:01:32 (Sun)
-21508,
0,
'LMT',
    ],
    [
60620940000, #    utc_start 1922-01-01 06:00:00 (Sun)
62513884800, #      utc_end 1981-12-26 08:00:00 (Sat)
60620918400, #  local_start 1922-01-01 00:00:00 (Sun)
62513863200, #    local_end 1981-12-26 02:00:00 (Sat)
-21600,
0,
'CST',
    ],
    [
62513884800, #    utc_start 1981-12-26 08:00:00 (Sat)
62540751600, #      utc_end 1982-11-02 07:00:00 (Tue)
62513866800, #  local_start 1981-12-26 03:00:00 (Sat)
62540733600, #    local_end 1982-11-02 02:00:00 (Tue)
-18000,
0,
'EST',
    ],
    [
62540751600, #    utc_start 1982-11-02 07:00:00 (Tue)
62964547200, #      utc_end 1996-04-07 08:00:00 (Sun)
62540730000, #  local_start 1982-11-02 01:00:00 (Tue)
62964525600, #    local_end 1996-04-07 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
62964547200, #    utc_start 1996-04-07 08:00:00 (Sun)
62982082800, #      utc_end 1996-10-27 07:00:00 (Sun)
62964529200, #  local_start 1996-04-07 03:00:00 (Sun)
62982064800, #    local_end 1996-10-27 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
62982082800, #    utc_start 1996-10-27 07:00:00 (Sun)
62995996800, #      utc_end 1997-04-06 08:00:00 (Sun)
62982061200, #  local_start 1996-10-27 01:00:00 (Sun)
62995975200, #    local_end 1997-04-06 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
62995996800, #    utc_start 1997-04-06 08:00:00 (Sun)
63013532400, #      utc_end 1997-10-26 07:00:00 (Sun)
62995978800, #  local_start 1997-04-06 03:00:00 (Sun)
63013514400, #    local_end 1997-10-26 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63013532400, #    utc_start 1997-10-26 07:00:00 (Sun)
63027446400, #      utc_end 1998-04-05 08:00:00 (Sun)
63013510800, #  local_start 1997-10-26 01:00:00 (Sun)
63027424800, #    local_end 1998-04-05 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63027446400, #    utc_start 1998-04-05 08:00:00 (Sun)
63044982000, #      utc_end 1998-10-25 07:00:00 (Sun)
63027428400, #  local_start 1998-04-05 03:00:00 (Sun)
63044964000, #    local_end 1998-10-25 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63044982000, #    utc_start 1998-10-25 07:00:00 (Sun)
63058896000, #      utc_end 1999-04-04 08:00:00 (Sun)
63044960400, #  local_start 1998-10-25 01:00:00 (Sun)
63058874400, #    local_end 1999-04-04 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63058896000, #    utc_start 1999-04-04 08:00:00 (Sun)
63077036400, #      utc_end 1999-10-31 07:00:00 (Sun)
63058878000, #  local_start 1999-04-04 03:00:00 (Sun)
63077018400, #    local_end 1999-10-31 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63077036400, #    utc_start 1999-10-31 07:00:00 (Sun)
63090345600, #      utc_end 2000-04-02 08:00:00 (Sun)
63077014800, #  local_start 1999-10-31 01:00:00 (Sun)
63090324000, #    local_end 2000-04-02 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63090345600, #    utc_start 2000-04-02 08:00:00 (Sun)
63108486000, #      utc_end 2000-10-29 07:00:00 (Sun)
63090327600, #  local_start 2000-04-02 03:00:00 (Sun)
63108468000, #    local_end 2000-10-29 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63108486000, #    utc_start 2000-10-29 07:00:00 (Sun)
63124819200, #      utc_end 2001-05-06 08:00:00 (Sun)
63108464400, #  local_start 2000-10-29 01:00:00 (Sun)
63124797600, #    local_end 2001-05-06 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63124819200, #    utc_start 2001-05-06 08:00:00 (Sun)
63137516400, #      utc_end 2001-09-30 07:00:00 (Sun)
63124801200, #  local_start 2001-05-06 03:00:00 (Sun)
63137498400, #    local_end 2001-09-30 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63137516400, #    utc_start 2001-09-30 07:00:00 (Sun)
63153849600, #      utc_end 2002-04-07 08:00:00 (Sun)
63137494800, #  local_start 2001-09-30 01:00:00 (Sun)
63153828000, #    local_end 2002-04-07 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63153849600, #    utc_start 2002-04-07 08:00:00 (Sun)
63171385200, #      utc_end 2002-10-27 07:00:00 (Sun)
63153831600, #  local_start 2002-04-07 03:00:00 (Sun)
63171367200, #    local_end 2002-10-27 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63171385200, #    utc_start 2002-10-27 07:00:00 (Sun)
63185299200, #      utc_end 2003-04-06 08:00:00 (Sun)
63171363600, #  local_start 2002-10-27 01:00:00 (Sun)
63185277600, #    local_end 2003-04-06 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63185299200, #    utc_start 2003-04-06 08:00:00 (Sun)
63202834800, #      utc_end 2003-10-26 07:00:00 (Sun)
63185281200, #  local_start 2003-04-06 03:00:00 (Sun)
63202816800, #    local_end 2003-10-26 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63202834800, #    utc_start 2003-10-26 07:00:00 (Sun)
63216748800, #      utc_end 2004-04-04 08:00:00 (Sun)
63202813200, #  local_start 2003-10-26 01:00:00 (Sun)
63216727200, #    local_end 2004-04-04 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63216748800, #    utc_start 2004-04-04 08:00:00 (Sun)
63234889200, #      utc_end 2004-10-31 07:00:00 (Sun)
63216730800, #  local_start 2004-04-04 03:00:00 (Sun)
63234871200, #    local_end 2004-10-31 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63234889200, #    utc_start 2004-10-31 07:00:00 (Sun)
63248198400, #      utc_end 2005-04-03 08:00:00 (Sun)
63234867600, #  local_start 2004-10-31 01:00:00 (Sun)
63248176800, #    local_end 2005-04-03 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63248198400, #    utc_start 2005-04-03 08:00:00 (Sun)
63266338800, #      utc_end 2005-10-30 07:00:00 (Sun)
63248180400, #  local_start 2005-04-03 03:00:00 (Sun)
63266320800, #    local_end 2005-10-30 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63266338800, #    utc_start 2005-10-30 07:00:00 (Sun)
63279648000, #      utc_end 2006-04-02 08:00:00 (Sun)
63266317200, #  local_start 2005-10-30 01:00:00 (Sun)
63279626400, #    local_end 2006-04-02 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63279648000, #    utc_start 2006-04-02 08:00:00 (Sun)
63297788400, #      utc_end 2006-10-29 07:00:00 (Sun)
63279630000, #  local_start 2006-04-02 03:00:00 (Sun)
63297770400, #    local_end 2006-10-29 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63297788400, #    utc_start 2006-10-29 07:00:00 (Sun)
63311097600, #      utc_end 2007-04-01 08:00:00 (Sun)
63297766800, #  local_start 2006-10-29 01:00:00 (Sun)
63311076000, #    local_end 2007-04-01 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63311097600, #    utc_start 2007-04-01 08:00:00 (Sun)
63329238000, #      utc_end 2007-10-28 07:00:00 (Sun)
63311079600, #  local_start 2007-04-01 03:00:00 (Sun)
63329220000, #    local_end 2007-10-28 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63329238000, #    utc_start 2007-10-28 07:00:00 (Sun)
63343152000, #      utc_end 2008-04-06 08:00:00 (Sun)
63329216400, #  local_start 2007-10-28 01:00:00 (Sun)
63343130400, #    local_end 2008-04-06 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63343152000, #    utc_start 2008-04-06 08:00:00 (Sun)
63360687600, #      utc_end 2008-10-26 07:00:00 (Sun)
63343134000, #  local_start 2008-04-06 03:00:00 (Sun)
63360669600, #    local_end 2008-10-26 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63360687600, #    utc_start 2008-10-26 07:00:00 (Sun)
63374601600, #      utc_end 2009-04-05 08:00:00 (Sun)
63360666000, #  local_start 2008-10-26 01:00:00 (Sun)
63374580000, #    local_end 2009-04-05 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63374601600, #    utc_start 2009-04-05 08:00:00 (Sun)
63392137200, #      utc_end 2009-10-25 07:00:00 (Sun)
63374583600, #  local_start 2009-04-05 03:00:00 (Sun)
63392119200, #    local_end 2009-10-25 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63392137200, #    utc_start 2009-10-25 07:00:00 (Sun)
63406051200, #      utc_end 2010-04-04 08:00:00 (Sun)
63392115600, #  local_start 2009-10-25 01:00:00 (Sun)
63406029600, #    local_end 2010-04-04 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63406051200, #    utc_start 2010-04-04 08:00:00 (Sun)
63424191600, #      utc_end 2010-10-31 07:00:00 (Sun)
63406033200, #  local_start 2010-04-04 03:00:00 (Sun)
63424173600, #    local_end 2010-10-31 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63424191600, #    utc_start 2010-10-31 07:00:00 (Sun)
63437500800, #      utc_end 2011-04-03 08:00:00 (Sun)
63424170000, #  local_start 2010-10-31 01:00:00 (Sun)
63437479200, #    local_end 2011-04-03 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63437500800, #    utc_start 2011-04-03 08:00:00 (Sun)
63455641200, #      utc_end 2011-10-30 07:00:00 (Sun)
63437482800, #  local_start 2011-04-03 03:00:00 (Sun)
63455623200, #    local_end 2011-10-30 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63455641200, #    utc_start 2011-10-30 07:00:00 (Sun)
63468950400, #      utc_end 2012-04-01 08:00:00 (Sun)
63455619600, #  local_start 2011-10-30 01:00:00 (Sun)
63468928800, #    local_end 2012-04-01 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63468950400, #    utc_start 2012-04-01 08:00:00 (Sun)
63487090800, #      utc_end 2012-10-28 07:00:00 (Sun)
63468932400, #  local_start 2012-04-01 03:00:00 (Sun)
63487072800, #    local_end 2012-10-28 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63487090800, #    utc_start 2012-10-28 07:00:00 (Sun)
63501004800, #      utc_end 2013-04-07 08:00:00 (Sun)
63487069200, #  local_start 2012-10-28 01:00:00 (Sun)
63500983200, #    local_end 2013-04-07 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63501004800, #    utc_start 2013-04-07 08:00:00 (Sun)
63518540400, #      utc_end 2013-10-27 07:00:00 (Sun)
63500986800, #  local_start 2013-04-07 03:00:00 (Sun)
63518522400, #    local_end 2013-10-27 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63518540400, #    utc_start 2013-10-27 07:00:00 (Sun)
63532454400, #      utc_end 2014-04-06 08:00:00 (Sun)
63518518800, #  local_start 2013-10-27 01:00:00 (Sun)
63532432800, #    local_end 2014-04-06 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63532454400, #    utc_start 2014-04-06 08:00:00 (Sun)
63549990000, #      utc_end 2014-10-26 07:00:00 (Sun)
63532436400, #  local_start 2014-04-06 03:00:00 (Sun)
63549972000, #    local_end 2014-10-26 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63549990000, #    utc_start 2014-10-26 07:00:00 (Sun)
63563904000, #      utc_end 2015-04-05 08:00:00 (Sun)
63549968400, #  local_start 2014-10-26 01:00:00 (Sun)
63563882400, #    local_end 2015-04-05 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63563904000, #    utc_start 2015-04-05 08:00:00 (Sun)
63581439600, #      utc_end 2015-10-25 07:00:00 (Sun)
63563886000, #  local_start 2015-04-05 03:00:00 (Sun)
63581421600, #    local_end 2015-10-25 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63581439600, #    utc_start 2015-10-25 07:00:00 (Sun)
63595353600, #      utc_end 2016-04-03 08:00:00 (Sun)
63581418000, #  local_start 2015-10-25 01:00:00 (Sun)
63595332000, #    local_end 2016-04-03 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63595353600, #    utc_start 2016-04-03 08:00:00 (Sun)
63613494000, #      utc_end 2016-10-30 07:00:00 (Sun)
63595335600, #  local_start 2016-04-03 03:00:00 (Sun)
63613476000, #    local_end 2016-10-30 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63613494000, #    utc_start 2016-10-30 07:00:00 (Sun)
63626803200, #      utc_end 2017-04-02 08:00:00 (Sun)
63613472400, #  local_start 2016-10-30 01:00:00 (Sun)
63626781600, #    local_end 2017-04-02 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63626803200, #    utc_start 2017-04-02 08:00:00 (Sun)
63644943600, #      utc_end 2017-10-29 07:00:00 (Sun)
63626785200, #  local_start 2017-04-02 03:00:00 (Sun)
63644925600, #    local_end 2017-10-29 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63644943600, #    utc_start 2017-10-29 07:00:00 (Sun)
63658252800, #      utc_end 2018-04-01 08:00:00 (Sun)
63644922000, #  local_start 2017-10-29 01:00:00 (Sun)
63658231200, #    local_end 2018-04-01 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63658252800, #    utc_start 2018-04-01 08:00:00 (Sun)
63676393200, #      utc_end 2018-10-28 07:00:00 (Sun)
63658234800, #  local_start 2018-04-01 03:00:00 (Sun)
63676375200, #    local_end 2018-10-28 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63676393200, #    utc_start 2018-10-28 07:00:00 (Sun)
63690307200, #      utc_end 2019-04-07 08:00:00 (Sun)
63676371600, #  local_start 2018-10-28 01:00:00 (Sun)
63690285600, #    local_end 2019-04-07 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63690307200, #    utc_start 2019-04-07 08:00:00 (Sun)
63707842800, #      utc_end 2019-10-27 07:00:00 (Sun)
63690289200, #  local_start 2019-04-07 03:00:00 (Sun)
63707824800, #    local_end 2019-10-27 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63707842800, #    utc_start 2019-10-27 07:00:00 (Sun)
63721756800, #      utc_end 2020-04-05 08:00:00 (Sun)
63707821200, #  local_start 2019-10-27 01:00:00 (Sun)
63721735200, #    local_end 2020-04-05 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63721756800, #    utc_start 2020-04-05 08:00:00 (Sun)
63739292400, #      utc_end 2020-10-25 07:00:00 (Sun)
63721738800, #  local_start 2020-04-05 03:00:00 (Sun)
63739274400, #    local_end 2020-10-25 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63739292400, #    utc_start 2020-10-25 07:00:00 (Sun)
63753206400, #      utc_end 2021-04-04 08:00:00 (Sun)
63739270800, #  local_start 2020-10-25 01:00:00 (Sun)
63753184800, #    local_end 2021-04-04 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63753206400, #    utc_start 2021-04-04 08:00:00 (Sun)
63771346800, #      utc_end 2021-10-31 07:00:00 (Sun)
63753188400, #  local_start 2021-04-04 03:00:00 (Sun)
63771328800, #    local_end 2021-10-31 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63771346800, #    utc_start 2021-10-31 07:00:00 (Sun)
63784656000, #      utc_end 2022-04-03 08:00:00 (Sun)
63771325200, #  local_start 2021-10-31 01:00:00 (Sun)
63784634400, #    local_end 2022-04-03 02:00:00 (Sun)
-21600,
0,
'CST',
    ],
    [
63784656000, #    utc_start 2022-04-03 08:00:00 (Sun)
63802796400, #      utc_end 2022-10-30 07:00:00 (Sun)
63784638000, #  local_start 2022-04-03 03:00:00 (Sun)
63802778400, #    local_end 2022-10-30 02:00:00 (Sun)
-18000,
1,
'CDT',
    ],
    [
63802796400, #    utc_start 2022-10-30 07:00:00 (Sun)
DateTime::TimeZone::INFINITY, #      utc_end
63802774800, #  local_start 2022-10-30 01:00:00 (Sun)
DateTime::TimeZone::INFINITY, #    local_end
-21600,
0,
'CST',
    ],
];

sub olson_version {'2025b'}

sub has_dst_changes {27}

sub _max_year {2035}

sub _new_instance {
    return shift->_init( @_, spans => $spans );
}



1;

