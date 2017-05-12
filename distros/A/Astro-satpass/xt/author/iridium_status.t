package main;

use strict;
use warnings;

use POSIX qw{strftime};
use Test::More 0.88;
use Astro::Coord::ECI::Utils qw{ time_gm };

eval {
    require LWP::UserAgent;
    1;
} or do {
    plan skip_all => 'LWP::UserAgent not available';
    exit;
};

use constant TFMT => '%d %b %Y %H:%M:%S GMT';

my %mth;
{	# Local symbol block
    my $inx = 0;
    foreach my $nam (qw{jan feb mar apr may jun jul aug sep oct nov dec}) {
	$mth{$nam} = $inx++;
    }
}

my $fail = 0;
my $test = 0;
my $ua = LWP::UserAgent->new(
    ssl_opts	=> { verify_hostname	=> 0 },	# Necessary until Perl recognizes McCants' cert.
);
my $asof = time_gm( 0, 0, 0, 24, 3, 2017 );
foreach (["Mike McCants' Iridium status",
	'http://www.prismnet.com/~mmccants/tles/iridium.html',
	$asof,
	mccants => <<'MCCANTS'],
<html>
<head>
<title>
Status for Iridium payloads
</title>
</head>

<body>
<h2><center>Status for Iridium payloads</center></h2>
<p>
<pre>
Iridium status as of Novenber, 2012
===================================

Iridiums not listed in the following table are thought to be stable
in orbit and capable of generating flares.

Nov. 29, 2000: Iridium 79 (NCat 25470) decayed.
Dec. 30, 2000: Iridium 85 (NCat 25529) decayed.
May 5, 2001:   Iridium 48 (NCat 25107) decayed.
Jan. 31, 2002: Iridium 27 (NCat 24947) decayed.
Mar. 11, 2003: Iridium 9 (NCat 24838) decayed.
Jan. 29, 2004: Spacecom exchanged the names for objects 25577
               (now Iridium 20) and 25578 (now Iridium 11).
Aug. 2003:     Iridium 38 failed.
June 2004:     Iridiums 2, 38, 69 and 73 were changed to "failed".
Apr. 24, 2005: Iridium 16 has been replaced by Iridium 86.
June 14, 2005: Iridium 16 has been seen tumbling - changed to "tum".
June 2005:     Iridium 98 has changed its inclination so that it will
               drift between planes.
Aug. 2005:     Iridium 77 has been maneuvered into the orbital spot
               for Iridium 17.  Presumably, Iridium 17 has failed.
Oct. 2005:     Iridium 90 has changed its inclination so that it will
               drift between planes.
Jan. 2006:     Spacecom has switched the names for Iridium 91 and Iridium 90
Jan. 10, 2006: Iridium 74 has been moved into a lower orbit and Iridium 21
               was moved to take its place.
Jan. 10, 2007: From January 5 to January 9, 2007, Iridium 97 was moved from
               its lower orbit to an orbit "next to" Iridium 36.
Mar. 6, 2007:  Iridium 36 has not had an orbit maintenance maneuver since
               January and was observed to flash, so I assume it has failed.
May 4, 2007:   Iridium 98 has changed its inclination so that it is now
               a spare in its new plane.
Jan. 22, 2008: Iridium 90 has changed its inclination so that it is now
               a spare in its new plane.
Jul. 19, 2008: Unusual changes in mean motion by Iridium 28
Jul. 26, 2008: Iridium 95 moved to replace Iridium 28
Dec. 22, 2008: It is clear that Iridium 28 was no longer being controlled
               as of about Sep. 20, 2008 - probably since July 2008
Feb. 10, 2009: Collision between Iridium 33 and Cosmos 2251
Mar. 2, 2009:  Iridium 91 was placed into service to replace Iridium 33
Nov. 3, 2010:  Iridium 11 was placed into service next to Iridium 23
Aug. 8, 2011:  Iridium 26 apparently failed.  Replaced by Iridium 11.
July, 2012:    Iridium 51 was moved next to Iridium 7
July 20, 2012: Iridium 4 is no longer station keeping
Nov. 13, 2012: Iridium 94 was placed into service next to Iridium 23.

 NCat    Name           Status   Comment
 24796   Iridium 4      unc      Failed? No longer station keeping after July 20, 2012
 24836   Iridium 914    tum      Failed; was called Iridium 14
 24841   Iridium 16     tum      Removed from operation about April 7, 2005
 24842   Iridium 911    tum      Failed; was called Iridium 11
 24870   Iridium 17     tum      Failed in August 2005
 24871   Iridium 920    tum      Failed; was called Iridium 20
 24873   Iridium 921    tum      Failed; was called Iridium 21
 24906   Iridium 23              Partial failure? in November 2010
 24903   Iridium 26     unc      Apparently failed in August 2011.
 24946   Iridium 33     tum      Destroyed by a collision on Feb. 10, 2009
 24948   Iridium 28     unc      Assumed failed about July 19, 2008
 24967   Iridium 36     tum      Failed in January 2007
 25043   Iridium 38     tum      Failed in August 2003
 25078   Iridium 44     tum      Failed
 25105   Iridium 24     tum      Failed
 25262   Iridium 51              Moved next to Iridium 7 in July, 2012
 25319   Iridium 69     tum      Failed
 25320   Iridium 71     tum      Failed
 25344   Iridium 73     tum      Failed
 25345   Iridium 74     ?        Removed from operation about January 8, 2006
 25527   Iridium 2      tum      Failed
 25577   Iridium 20              was called Iridium 11
 25578   Iridium 11              was called Iridium 20
 25777   Iridium 14     ?        Spare   was called Iridium 14A
 25778   Iridium 21              Replaced Iridium 74   was called Iridium 21A
 27372   Iridium 91              Replaced Iridium 33 about Mar. 2, 2009   was called Iridium 90
 27373   Iridium 90     ?        Spare (new plane Jan. 2008)   was called Iridium 91
 27374   Iridium 94              Next to Iridium 23
 27375   Iridium 95              Replaced Iridium 28 about July 26, 2008
 27376   Iridium 96     ?        Inclination 87.2 - migrating between planes
 27450   Iridium 97              Replaced Iridium 36 on Jan. 10, 2007
 27451   Iridium 98     ?        Spare (new plane May 2007)

Status  Meaning
------  -------
blank   Object is operational

tum     tumbling - no flares, but flashes seen on favorable transits.

unc     uncontrolled

?       controlled, but not at operational altitude - flares may be unreliable.

===================================

Iridium Constellation Status information by Rod Sladen:
<a href="http://www.rod.sladen.org.uk/iridium.htm">Iridium Status</a>

===================================
</pre>
</body>
</html>
MCCANTS
	["T. S. Kelso's Iridium list",
	'http://celestrak.com/SpaceTrack/query/iridium.txt',
	$asof,
	kelso => <<'KELSO'],
24792IRIDIUM 8 [+]
24793IRIDIUM 7 [+]
24794IRIDIUM 6 [+]
24795IRIDIUM 5 [+]
24796IRIDIUM 4 [-]
24836IRIDIUM 914 [-]
24837IRIDIUM 12 [+]
24839IRIDIUM 10 [+]
24840IRIDIUM 13 [+]
24841IRIDIUM 16 [-]
24842IRIDIUM 911 [-]
24869IRIDIUM 15 [+]
24870IRIDIUM 17 [-]
24871IRIDIUM 920 [-]
24872IRIDIUM 18 [+]
24873IRIDIUM 921 [-]
24903IRIDIUM 26 [-]
24904IRIDIUM 25 [+]
24905IRIDIUM 46 [+]
24906IRIDIUM 23 [+]
24907IRIDIUM 22 [+]
24925DUMMY MASS 1 [-]
24926DUMMY MASS 2 [-]
24944IRIDIUM 29 [-]
24945IRIDIUM 32 [+]
24946IRIDIUM 33 [-]
24948IRIDIUM 28 [-]
24949IRIDIUM 30 [+]
24950IRIDIUM 31 [+]
24965IRIDIUM 19 [+]
24966IRIDIUM 35 [+]
24967IRIDIUM 36 [-]
24968IRIDIUM 37 [+]
24969IRIDIUM 34 [+]
25039IRIDIUM 43 [+]
25040IRIDIUM 41 [+]
25041IRIDIUM 40 [-]
25042IRIDIUM 39 [B]
25043IRIDIUM 38 [-]
25077IRIDIUM 42 [-]
25078IRIDIUM 44 [-]
25104IRIDIUM 45 [+]
25105IRIDIUM 24 [-]
25106IRIDIUM 47 [+]
25108IRIDIUM 49 [+]
25169IRIDIUM 52 [+]
25170IRIDIUM 56 [+]
25171IRIDIUM 54 [+]
25172IRIDIUM 50 [+]
25173IRIDIUM 53 [+]
25262IRIDIUM 51 [S]
25263IRIDIUM 61 [+]
25272IRIDIUM 55 [+]
25273IRIDIUM 57 [-]
25274IRIDIUM 58 [+]
25275IRIDIUM 59 [+]
25276IRIDIUM 60 [+]
25285IRIDIUM 62 [+]
25286IRIDIUM 63 [-]
25287IRIDIUM 64 [+]
25288IRIDIUM 65 [+]
25289IRIDIUM 66 [+]
25290IRIDIUM 67 [+]
25291IRIDIUM 68 [+]
25319IRIDIUM 69 [-]
25320IRIDIUM 71 [-]
25342IRIDIUM 70 [+]
25343IRIDIUM 72 [+]
25344IRIDIUM 73 [-]
25345IRIDIUM 74 [S]
25346IRIDIUM 75 [+]
25431IRIDIUM 3 [+]
25432IRIDIUM 76 [+]
25467IRIDIUM 82 [+]
25468IRIDIUM 81 [+]
25469IRIDIUM 80 [+]
25471IRIDIUM 77 [+]
25527IRIDIUM 2 [-]
25528IRIDIUM 86 [+]
25530IRIDIUM 84 [+]
25531IRIDIUM 83 [+]
25577IRIDIUM 20 [+]
25578IRIDIUM 11 [+]
25777IRIDIUM 14 [+]
25778IRIDIUM 21 [+]
27372IRIDIUM 91 [+]
27373IRIDIUM 90 [S]
27374IRIDIUM 94 [+]
27375IRIDIUM 95 [+]
27376IRIDIUM 96 [+]
27450IRIDIUM 97 [+]
27451IRIDIUM 98 [+]
KELSO
	["Rod Sladen's Iridium Constellation Status",
	'http://www.rod.sladen.org.uk/iridium.htm',
	$asof,
	sladen => <<'SLADEN'],
<html>

<head>
<meta http-equiv="Content-Type"
content="text/html; charset=iso-8859-1">
<meta name="GENERATOR" content="Microsoft FrontPage Express 2.0">
<title>Iridium Constellation Status</title>
</head>

<body bgcolor="#FFFFFF">

<h1 align="center">Iridium Constellation Status</h1>

<p align="center"><strong>** Updated 23 April 2017 **</strong></p>

<p align="left"><strong>Latest changes </strong>(see below for
earlier changes):</p>

<p align="left"><strong>*** The first eight Iridium Next
satellites are now in service ***<br>
</strong><em><strong>Note that the Iridium Next satellites are
not expected to produce flares from the Main Mission Antenna in
the same way as the original Iridium satellites.</strong></em></p>

<p>Iridium 111 (2017-003K) is <strong>in service</strong> at
Plane 6. Slot 11, replacing Iridium 43 (25039, 1997-069A).
Iridium 43 currently remains near its previous orbital position<br>
Iridium 102 (2017-003D) is <strong>in service</strong> at Plane
6. Slot 1, replacing Iridium 18 (24872, 1997-034D). Iridium 18
currently remains near its previous orbital position.<br>
Iridium 112 (2017-003J) is <strong>in service</strong> at Plane
6. Slot 2, replacing Iridium 98 (27451, 2002-031B). <strong>The
orbit of Iridium 98 has been lowered by 5km </strong>and it may
be moving to another slot in plane 6.<br>
Iridium 104 (2017-003F) is <strong>in service</strong> at Plane
6. Slot 3, replacing Iridium 40 (25041, 1997-069C). <strong><u>Iridium
40 is being de-orbited</u></strong><strong>.<br>
</strong>Iridium 114 (2017-003G) is <strong>in service</strong>
at Plane 6. Slot 4, replacing Iridium 15 (24869, 1997-034A). <strong>The
orbit of Iridium 15 has been lowered by 15km</strong> and it may
be being retained as a spare for plane 6.<br>
Iridium 103 (2017-003B) is <strong>in service</strong> at Plane
6. Slot 5, replacing Iridium 80 (25469, 1998-051C). <strong>The
orbit of Iridium 80 has been raised by 10km</strong> and it may
be being retained as a spare for plane 6.<br>
Iridium 109 (2017-003C) is <strong>in service</strong> at Plane
6. Slot 6, replacing Iridium 77 (25471, 1998-051E). Iridium 77
currently remains near its previous orbital position<br>
Iridium 106 (2017-003A) is <strong>in service</strong> at Plane
6, Slot 7.<br>
(First generation Iridium satellites remain active in Slot 8,
Slot 9 and Slot 10 of Plane 6)</p>

<p><strong>Iridium 105 (2017-003E) and Iridium 108 (2017-003H)
remain in the insertion orbit, but have now started migrating
from Orbital Plane 6 towards Orbital Plane 5</strong></p>

<p align="left">For a summary of the Iridium launch sequence, see
my <a href="iridium_launch.htm">Iridium Launch Chronology</a>.
There is now also a summary of <a href="iridfail.htm">Iridium
Failures</a>.</p>

<pre><em><strong>Note that the Iridium Next satellites are not expected to produce flares from the Main Mission Antenna in the same way as the original Iridium satellites.</strong></em></pre>

<pre>Orbital  &lt;-------------- Operational satellites --------------&gt;  Spares
Plane
Plane 1:  <a href="iridium74and21.htm">21</a>   72   75   70   62   14   64   65   66   67   68   <a
href="iridium74and21.htm">74</a> 					(note: Iridium 74 is probably a partial failure)
Plane 2:  22   <a href="iridium94.htm">94</a>   76   25   23   46   47   20   49   <a
href="iridium11and26.htm">11</a>    3          				(note: Iridium 23 is probably a partial failure)
Plane 3:  55   <a href="iridium28and95.htm">95</a>   45   <a
href="iridium30and31.htm">31</a>   <a href="iridium30and31.htm">30</a>   32   <a
href="iridium33collision.htm">91</a>   <em>  </em>   58   59   60   					
Plane 4:  19   34   35   <a href="iridium36and97.htm">97</a>    <a
href="iridium5and51.htm">5</a>  6/51   <a
href="iridium7and51.htm">7</a>    8   96   37   61   					(note: Iridiums 6, 7 and 51 are probably partial failures)
Plane 5:  50   56   52   53   <a href="iridium9and84.htm">84</a>   10   54   12   13   83   <a
href="iridium16and86.htm">86</a>   <a href="iridium91.htm">90 (launched to plane 3, but has been migrated to plane 5)</a>
Plane 6: <strong>102  112  104   114  103  109  106</strong>  81   <a
href="iridium38and82.htm">82</a>   41 <strong> 111</strong>  <strong> </strong>98; 80; 15; (18, <a
href="iridium17and77.htm">77</a>, 43) <strong>(plus 108, 105 now migrating from Plane 6 towards plane 5)
</strong></pre>

<pre>Original &lt;----- Failed -----&gt;                   &lt;- Failed -&gt;    <em>Note that some of the failed</em> <em>satellites have drifted from the original orbital planes</em>
Orbital  (but still in orbit)                    (decayed)
Plane                                	          <em>     </em>
Plane 1:  73t  63
Plane 2:  69t  24t  71t  <a href="iridium11and26.htm">26</a>           	 	48d
Plane 3:  <a href="iridium28and95.htm">28</a>   29<font
color="#FF0000">   </font><a href="iridium33collision.htm"><font
color="#FF0000">33</font></a>t  57           		27d           <em>Iridium 33 was fragmented by the collison with Cosmos 2251 on February 10, 2009</em>
Plane 4:   4   <a href="iridium36and97.htm">36</a>t
Plane 5:   2t 914t 911t  <a href="iridium16and86.htm">16</a>t          		85d   <a
href="iridium9and84.htm">9</a>d      <em>Iridium 2 has drifted far from</em> <em>its original launch plane, and continues to drift</em>
Plane 6: 920t 921t  44t  <a href="iridium38and82.htm">38</a>t  <a
href="iridium17and77.htm">17</a>t 42t 39  40    79d           (Iridium 40 is being deliberatly de-orbited)</pre>

<p>t indicates satellites that have been reported as tumbling out
of control. </p>

<p><strong>Notes:</strong></p>

<p>This is Rod Sladen's personal opinion of the status of the
Iridium constellation, and the information herein has not been
confirmed by the new owners, Iridium Satellite LLC, nor by Boeing
who are maintaining the system for them.</p>

<p>Iridium&nbsp;11 (until recently referred to by OIG as
Iridium&nbsp;20), Iridium&nbsp;14, Iridium&nbsp;20 (until
recently referred to by OIG as Iridium&nbsp;11) and
Iridium&nbsp;21 are the second (i.e. replacement) satellites
known by those names. They were previously known as
Iridium&nbsp;20a, Iridium&nbsp;14a, Iridium&nbsp;11a and
Iridium&nbsp;21a respectively. </p>

<p>Iridium&nbsp;911, Iridium&nbsp;914, Iridium&nbsp;920,
Iridium&nbsp;921 are the (failed) satellites originally known as
Iridium&nbsp;11, Iridium&nbsp;14, Iridium&nbsp;20 and
Iridium&nbsp;21 respectively. </p>

<p>d indicates satellites that have already decayed: <br>
Iridium 79 (25470, 1998-051D) decayed on 29 November 2000 <br>
(see <a href="http://www.satobs.org/seesat/Nov-2000/0256.html">http://www.satobs.org/seesat/Nov-2000/0256.html</a>),
<br>
Iridium 85 (25529, 1998-066C) decayed on 30 December 2000 <br>
(see <a href="http://www.satobs.org/seesat/Dec-2000/0409.html">http://www.satobs.org/seesat/Dec-2000/0409.html</a>),<br>
Iridium 48 (25107, 1997-082D) decayed on 5 May 2001 <br>
(see <a href="http://www.satobs.org/seesat/May-2001/0028.html">http://www.satobs.org/seesat/May-2001/0028.html</a>),
and<br>
Iridium 27 (24947, 1997-051D) decayed on 1 February 2002 <br>
(see <a href="http://www.satobs.org/seesat/Feb-2002/0002.html">http://www.satobs.org/seesat/Feb-2002/0002.html</a>)<br>
Iridium 9 (24838, 1997-030C) decayed on 11 March 2003<br>
(see <a href="http://www.satobs.org/seesat/Mar-2003/0116.html">http://www.satobs.org/seesat/Mar-2003/0116.html</a>)</p>

<p><a href="iridium5and51.htm">Iridium 5 and Iridium 51 were
confused</a> during August 2001.</p>

<p>Note that the identities of various members of the Iridium
constellation have been confused at various times in the past. <br>
Some interchanges of identities seems to have become permanent: <br>
Iridium 24 is tumbling, and correctly labelled by Spacecom as
Iridium 24, and correctly tracked, but under 25105 (1997-082B)
which are the catalog number and launch identifier which
originally belonged to Iridium 46. <br>
Iridium 46 is operational, and correctly labelled by Spacecom as
Iridium 46, and correctly tracked, but under 24905 (1997-043C)
which are the catalog number and launch identifier which
originally belonged to Iridium 24. <br>
Iridium 11 is operational, and is now correctly labelled by
Spacecom as Iridium 11, and correctly tracked, but under 25578
(1998-074B) which are the catalog number and launch identifier
which originally belonged to (the second) Iridium 20. <br>
Iridium 20 is operational, and is now correctly labelled by
Spacecom as Iridium 20, and correctly tracked, but under 25577
(1998-074A) which are the catalog number and launch identifier
which originally belonged to (the second) Iridium 11. </p>

<p><a name="Recent changes"><strong>Recent changes</strong></a>: </p>

<p>Iridium 111 (2017-003K) was raised to the operational orbit at
Plane 6. Slot 11, a few seconds behind Iridium 43 (25039,
1997-069A)<br>
Iridium 102 (2017-003D) was raised to the operational orbit at
Plane 6. Slot 1, a few seconds behind Iridium 18 (24872,
1997-034D)<br>
Iridium 112 (2017-003J) was raised to the operational orbit at
Plane 6. Slot 2, a few seconds behind Iridium 98 (27451,
2002-031B)<br>
Iridium 104 (2017-003F) was raised to the operational orbit at
Plane 6. Slot 3, a few seconds behind Iridium 40 (25041,
1997-069C)<br>
Iridium 114 (2017-003G) was raised to the operational orbit at
Plane 6. Slot 4, a few seconds behind Iridium 15 (24869,
1997-034A)<br>
Iridium 103 (2017-003B) was raised to the operational orbit at
Plane 6. Slot 5, a few seconds behind Iridium 80 (25469,
1998-051C)<br>
Iridium 109 (2017-003C) was raised to the operational orbit at
Plane 6. Slot 6, a few seconds behind Iridium 77 (25471,
1998-051E)</p>

<p>On 17 February 2017, Iridium Communications announced that the
launch of the second batch of 10 Iridium Next satellites was now
delayed until mid-June, 2017</p>

<p>It was also announced on 17 February 2017 that the first of
the Iridium Next satellites (i.e. Iridium 106) was expected to
begin providing service to customers in the next few days.</p>

<p>By 14 February 2017, Iridium 106 (2017-003A) had been raised
to the operational orbit to fill the gap at Plane 6, Slot 7,
which had been vacant since the failure of Iridium 39 (25042,
1997-069D) in June 2016<br>
Iridium 103 (2017-003B), Iridium 109 (2017-003C), Iridium 102
(2017-003D), Iridium 104 (2017-003F), Iridium 114 (2017-003G),
Iridium 112 (2017-003J), and Iridium 111 (2017-003K) were all in
the 700km * 705km storage orbit.<br>
Iridium 105 (2017-003E) and Iridium 108 (2017-003H) still
remained in the 605km * 625km insertion orbit.</p>

<p>The first Iridium Next launch (2017-003) took place on 14
January 2017, lifting the first ten Iridium Next satellites to
Orbital Plane 6.<br>
Initially all 10 Iridium Next satellites were in a 605km * 625km
insertion orbit.<br>
On 22 January 2017, Iridium 106 (2017-003A) was the first to have
its orbit raised by about 10km, presumably following a successful
initial check-out.<br>
On 24 January 2017, Iridium 103 (2017-003B) had its orbit raised
by about 10km.<br>
On 25 January 2017, Iridium 106 (2017-003A) was raised
significantly to a 700km * 705km storage orbit.<br>
By 28 January 2017, Iridium 103 (2017-003B) and Iridium 109
(2017-003C) had also been raised to the 700km * 705km storage
orbit., and Iridium 102 (2017-003D) was in the process of being
raised.<br>
Over the next few days, Iridium 102 (2017-003D), Iridium 104
(2017-003F), and Iridium 114 (2017-003G) were also raised to the
700km * 705km storage orbit.</p>

<p>It initially seemed unlikely that any of the Iridium Next
satellites launched to Oribital Plane 6 would be moved to other
orbital planes, as any gaps in those planes caould be filled more
quickly by the launches direct to those planes that are expected
to take place in the coming months.</p>

<p><strong>The status of the Iridium constellation </strong><strong><u>immediately
prior to the first Iridium Next launch</u></strong><strong>
appears to have been as follows:</strong></p>

<p>(At this time, it was reported that 64 of the original Iridium
satellites still remained operational)</p>

<pre>Orbital  &lt;-------------- Operational satellites --------------&gt;  Spares
Plane
Plane 1:  <a href="iridium74and21.htm">21</a>   72   75   70   62   14   64   65   66   67   68   <a
href="iridium74and21.htm">74</a> 					(note: Iridium 74 is probably a partial failure)
Plane 2:  22   <a href="iridium94.htm">94</a>   76   25   23   46   47   20   49   <a
href="iridium11and26.htm">11</a>    3          				(note: Iridium 23 is probably a partial failure)
Plane 3:  55   <a href="iridium28and95.htm">95</a>   45   <a
href="iridium30and31.htm">31</a>   <a href="iridium30and31.htm">30</a>   32   <a
href="iridium33collision.htm">91</a>   <em>  </em>   58   59   60   					
Plane 4:  19   34   35   <a href="iridium36and97.htm">97</a>    <a
href="iridium5and51.htm">5</a>  6/51   <a
href="iridium7and51.htm">7</a>    8   96   37   61   					(note: Iridiums 6, 7 and 51 are probably partial failures)
Plane 5:  50   56   52   53   <a href="iridium9and84.htm">84</a>   10   54   12   13   83   <a
href="iridium16and86.htm">86</a>   <a href="iridium91.htm">90 (launched to plane 3, but has been migrated to plane 5)</a>
Plane 6:  18   98   40   15   80   <a href="iridium17and77.htm">77</a>        81   <a
href="iridium38and82.htm">82</a>   41   43  <strong> 
</strong></pre>

<pre>Original &lt;----- Failed -----&gt;       	   &lt;- Failed -&gt;    <em>Note that some of the failed</em> <em>satellites have drifted from the original orbital planes</em>
Orbital  (but still in orbit)       	    (decayed)
Plane                                	          <em>     </em>
Plane 1:  73t  63
Plane 2:  69t  24t  71t  <a href="iridium11and26.htm">26</a>           	 	48d
Plane 3:  <a href="iridium28and95.htm">28</a>   29<font
color="#FF0000">   </font><a href="iridium33collision.htm"><font
color="#FF0000">33</font></a>t  57           		27d           <em>Iridium 33 was fragmented by the collison with Cosmos 2251 on February 10, 2009</em>
Plane 4:   4   <a href="iridium36and97.htm">36</a>t
Plane 5:   2t 914t 911t  <a href="iridium16and86.htm">16</a>t          		85d   <a
href="iridium9and84.htm">9</a>d      <em>Iridium 2 has drifted far from</em> <em>its original launch plane, and continues to drift</em>
Plane 6: 920t 921t  44t  <a href="iridium38and82.htm">38</a>t  <a
href="iridium17and77.htm">17</a>t 42t 39	79d           </pre>

<p>t indicates satellites that have been reported as tumbling out
of control. </p>

<p>In their quarterly report dated 30 June, 2016, Iridium
Satellite LLC acknowledged the failure of two satellites in the
preceding quarter year.</p>

<p>In June 2016, Iridium 15 (24869, 1997-034A) was moved from
Plane 6, Slot 7 to Plane 6, Slot 4, replacing Iridium 39 (25042,
1997-069D). The intention may have been to swap over the two
satellites but, in any case problems were experienced with with
Iridium 39, which was then removed from the operational
constellation, leaving a gap. No spare was available to replace
it.</p>

<p>In May 2016, Iridium 57 (25273, 1998-019B) began to drift away
slowly from its nominal position and has presumably failed. See<a
href="http://www.satobs.org/seesat/May-2016/0069.html"> Iridium
57 looks to have a bad attitude</a>.</p>

<p>In the middle of 2015, Iridium 45 (25104, 1997-082A) which had
been migrating from orbital plane 2 towards orbital plane 3 for
about 14 months, arrived in oribital plane 3. It appears to have
already been in operational use as part of orbital plane 3 for
some months previously, even though it was not in its final
orbital location.</p>

<p>In early December 2014, Space-Track catalogued four items of
debris (40324-40327, 2002-05G to 2002-05K) associated wth the
2002-05 launch .These are labelled by Space-Track as
&quot;IRIDIUM 91 DEB&quot;, and seem to be associated with
Iridium 91 (27372, 2002-005A) which appears, however, to remain
fully operational.</p>

<p>In early October 2014, <a href="iridium7and51.htm">Iridium 51
(25262, 1998-018A)</a>, which had been paired wth <a
href="iridium7and51.htm">Iridium 7 (24793, 1997-020B)</a> was
moved within orbital plane 4 to be paired with Iridium 6 (24794.
1997-020C).</p>

<p>At the end of August 2014, Iridium 14 (25777, 1999-032A) ,
whch had been spare in orbital plane 1 since launch, was raised
to operational altitude to replace Iridium 63 (25286. 1998-021B),
which had presumably failed.</p>

<p>At the end of August 2014, Iridium 98 (27451, 2002-301B) ,
whch had been spare in orbital plane 6 since migrating from plane
4, was raised to operational altitude a few seconds behind
Iridium 42 (25077. 1977-077)which had presumably failed. Iridium
42 has since been reported to be flashing..</p>

<p>By early 2014, Iridium 45 (25104, 1997-082A) was no longer
maintaining its place in orbital plane 2, and was evidently
migrating towards orbital plane 3. Its place in orbital plane 2
was taken by Iridium 23 (24906, 1997-043D).</p>

<p>By early 2014, Iridium 29 (24944, 1997-051A) had ceased to
maintain its position in the constellation, and had presumably
failed. At that time, there was no spare available in plane 3 to
replace it..</p>

<p>On 20 November, 2012, Iridium 96 (27376, 2002-005E),
previously spare in orbital place 3, began migrating towards
orbital plane 4, which had no on-orbit spare, This left orbital
place 3 without a spare. The migration took around twelve months.
Iridium 96 took over from failed Iridium 4 (24796, 1997-020E).
Iridium 96 was raised to operational altitude several months
before its arrival in plane 4 and appears to have been brought
into use at that time.</p>

<p>On 13 November, 2012, Iridium 94 (27374, 2002-005C), which had
been migrating over the past year from orbital place 3, arrived
at orbital plane 2, and was immediately raised to operational
altitude to replace Iridium 23 (24906, 1997-043D) which had
evidently failed, though retaining at least some functionality.
Iridium 23 initially remained at operational altitude a few
seconds behind Iridium 94, but was later used to replace Iridium
45 (25104, 1997-02A).</p>

<p>In mid 2012, Iridium 4 (24796, 1997-020E) ceased to maintain
its position in the constellation. At that time, Plane 4 had no
on-orbit spare</p>

<p>In late July 2012,<a href="iridium7and51.htm"> Iridium 51
(25262, 1998-018A). which had been out of the operational
constellation for many years, was moved in the position
previously occupied by Iridium 7 (24793, 1997-020B)</a>, while
Iridum 7 was moved to follow slightly behind it. The two
satellites were each providing some of the functionality for the
given slot. Orbital Plane 4 has no other spare satellite.</p>

<p>In early August 2011, Iridium 11 (originally 25577, 1998-074A,
but currently labelled by Space-Track as 25578, 1998-074B), <a
href="iridium11and23.htm">which had apparently taken over from
Iridium 23 (24906, 1997-043D) in November 2010</a>, was moved
around the plane, evidently to<a href="iridium11and26.htm"> take
over from Iridium 26</a> (24903, 1997-043A). <br>
This suggests that Iridium 26 must have failed on station, and
also that Iridium 23 retained some functionality. <br>
Orbital Plane 2 had no other spare satellite, but <a
href="iridium94.htm">Iridium 94 (27374, 2002-005C) was in process
of migrating</a> from Orbital Place 3.</p>

<p>In early November 2010, Iridium 11 (originally 25577,
1998-074A, but currently labelled by Space-Track as 25578,
1998-074B), previously spare, was raised to the operational
orbit, just a few seconds behind Iridium 23 (24906, 1997-043D).
This suggests that Iridium 23 must have failed on station, but
possibly only partially.</p>

<p>In early March 2009, Iridium 91 (27372, 2002-005A) [note that
some sources still label this satellite as Iridium 90] was raised
to the operational orbit to fill the gap left by the loss of
Iridium 33.</p>

<p>On February 10, 2009 at 16:56 UT, Iridium 33 (24946,
1997-051C) was in collision with Cosmos 2251 (22675, 1993-036A) .
See <a href="iridium33collision.htm">Iridium 33 collision</a>.
Iridium 33 is no longer functional.</p>

<p>In late July 2008, Iridium 95 (27375, 2002-005D), up till then
a spare satellite in orbital plane 3, entered the operational
constellation, evidently to <a href="iridium28and95.htm">replace</a>
Iridium 28 (24948, 1997-051E). Initially, Iridium 28 remained
close to its nominal position in the constellation, so had
presumably failed on station.</p>

<p>(January 2008) <a href="iridium91.htm">Iridium 90</a> <a
href="iridium90and%2091.htm">[previously labelled as Iridium 91]</a>
<a href="iridium91.htm">which had been manouvering since mid
October 2005, has arrived in orbital plane 5</a></p>

<p>(May 2007) <a href="iridium98.htm">Iridium 98, which had been
manouvering since late June 2005, has arrived in orbital plane 6</a></p>

<p>In early January 2007, Iridium 97 (27450,2002-031A), a spare
satellite in orbital plane 4, entered the operational
constellation, evidently to <a href="iridium36and97.htm">replace</a>
Iridium 36 (24967, 1997-056C). Iridium 36 initially remained
close to its nominal position in the constellation - it had
evidently failed on station. </p>

<p>On or about January 10, 2006, Iridium 21 (25778, 199-032B),
one of two spare satellites in orbital plane 1, was raised to
operational altitude, presumably to <a href="iridium74and21.htm">replace</a>
Iridium 74 (25345, 1998-032B),. which was lowered to the
engineering orbit. It is unclear whether Iridium 74 has failed
completely</p>

<p>On January 1, 2006, the Spacecom labelling of <a
href="iridium90and%2091.htm">Iridium 90 and Iridium 91</a> was
interchanged. There was no change to the operational
constellation.</p>

<p>In August 2005, <a href="iridium17and77.htm">Iridium 17
evidently failed</a>, and <a href="iridium17and77.htm">Iridium 77
took its place</a> in the operational constellation. This left
orbital plane 6 without a spare satellite.</p>

<p>In April 2005, <a href="iridium16and86.htm">Iridium 16 was
removed</a> from the operational constellation, and subsequently <a
href="iridium16and86.htm">Iridium 86 took its place</a> in the
operational constellation. This left orbital plane 5 without a
spare satellite.</p>

<p>On January 29, 2004, the OIG/Spacecom labelling of <a
href="iridium11and20.htm">Iridium 11 and Iridium 20</a> was
interchanged.<br>
There was no change to the operational constellation.</p>

<p><a href="iridium38and82.htm">Iridium 82 replaced Iridium 38</a>
in orbital plane 6 on or about September 17, 2003.</p>

<p><a href="iridium30and31.htm">Iridium 30 and 31 exchanged
places</a> in the constellation on September 19-22, 2002.</p>

<p>2 further spares (Iridium 97 and 98) were launched at 0933 UT
on 20 June 2002 from Plesetsk Cosmodrome by <a
href="http://www.eurockot.com/">Eurockot</a>.. This launch was
directed at orbital plane 4. Iridium 98 was subesquently moved to
orbital plane 6.</p>

<p>5 additional spare Iridium satellites (Iridium 90, 91, 94, 95
and 96) were launched from Vandenberg AFB aboard a Delta II
rocket on 11&nbsp;February 2002 at 17:43:44 UT. The originally
intended launch on 8 February 2002 at 18:00:30 UT was scrubbed at
the last moment, while the launch opportunities on
9&nbsp;February 2002 at 17:54:55 UT and 10 February 2002 at
17:49:19 UT also had to be scrubbed. See <a
href="http://www.boeing.com/news/releases/2002/q1/nr_020211s.html">http://www.boeing.com/news/releases/2002/q1/nr_020211s.html</a>
and <a href="http://spaceflightnow.com/delta/d290/status.html">http://spaceflightnow.com/delta/d290/status.html</a>
for more details on the launch. This launch was directed at
orbital plane 3, which previously had no spares. Perhaps
surprisingly, there was initially no indication that it was
intended to drift some of the spares to other orbital planes.
However, Iridium 90 (initially labelled as Iridium 91) was
subesquently moved to orbital plane 5, and Iridium 94 was later
moved to orbital plane 2. Iridium 96 is now being moved towards
plane 4.</p>

<p>@ <a href="iridium5and51.htm">Iridium 5 and Iridium 51 were
confused</a> during August 2001.</p>

<p>The previous change to the operational constellation was the <a
href="iridium9and84.htm">replacement of Iridium 9 by Iridium 84</a>.</p>

<p><strong>Additional Notes:</strong></p>

<p>Iridium 2 has drifted far from its original orbital plane (as
have several of the tumbling satellites). At one time, it was
deliberately allowed to drift to become the spare in another
plane (plane 4?), but it evidently failed on arrival in the new
plane, and continues to drift out of control.</p>

<p>At the Iridium Satellite LLC press conference call on 12
December 2000 <br>
(see <a
href="http://www.ee.surrey.ac.uk/Personal/L.Wood/constellations/iridium/conference-call-Dec-2000.html">http://www.ee.surrey.ac.uk/Personal/L.Wood/constellations/iridium/conference-call-Dec-2000.html</a>),
a figure of 8 operational spares was quoted. This would include
Iridium 82, 84 and 86 which have since become operational.</p>

<p>Also at the Iridium Satellite LLC press conference call on 12
December 2000 <br>
(see <a
href="http://www.ee.surrey.ac.uk/Personal/L.Wood/constellations/iridium/conference-call-Dec-2000.html">http://www.ee.surrey.ac.uk/Personal/L.Wood/constellations/iridium/conference-call-Dec-2000.html</a>),
plans were announced to launch further spare satellites for the
constellation:<br>
<em>&quot;We'll be launching seven more in the next year or so.
We have the first launch scheduled for next June, June of 2001.
That will be a Delta 2 launch; we'll be putting five spare
satellites into orbit. The following spring, roughly March of
2002, we'll be launching two more and in that case we'll be using
the Russian rocket. So we will inject seven more spares into the
system, so we'll have more than two spares in each orbit, and
that will give us the life that we believe is there&quot;<br>
</em>These launches were in fact delayed until 2002.</p>

<h6>[<a href="astronom.htm">Rod Sladen's Astronomy Page</a>] [<a
href="index.htm">Rod Sladen's Home Page</a>]</h6>
</body>
</html>
SLADEN
) {

    SKIP: {

	my ($what, $url, $expect, $file, $data) = @$_;
	my ($skip, $rslt, $got, $dt) = parse_date ($url);

	if ( $skip ) {
	    my $msg = "$url: $skip";
	    diag $msg;
	    skip $msg, 2;
	}

	defined $got or $got = 'undef';
	$dt ||= 0;
        cmp_ok $dt, '<', $expect, "$what last modified before @{[
		strftime( TFMT, gmtime $expect ) ]}"
	    or diag "$what actually modified @{[
		strftime( TFMT, gmtime $dt )]}";

	$test++;

	$data
	    or skip 'No comparison data provided', 1;

	if ($data && $rslt) {
	    $got = $rslt->content();
	    1 while $got =~ s/\015\012/\n/gm;
	    $skip = '';
	} else {
	    $got = $skip ||= 'No known reason';
	}
	print <<eod;
#
# Test $test: Content of $what
#       URL: $url
eod
	is $got, $data, "$what content"
	    or do {
	    if (open (my $fh, '>', "$file.expect")) {
		print $fh $data;
		close $fh;
	    } else {
		diag "Failed to open $file.expect: $!";
	    }
	    if (open (my $fh, '>', "$file.got")) {
		print $fh $got;
		close $fh;
	    } else {
		diag "Failed to open $file.got: $!";
	    }
	    diag <<"EOD";

Expected and gotten information written to $file.expect and
$file.got respectively.

EOD
	};
    }
}

$fail
    and diag <<'EOD';

Failures in this test script simply mean that the Iridium status
information shipped with the package may be out of date.

EOD

done_testing;

sub parse_date {
    my ($url) = @_;

    my $rslt = $ua->get ($url);
    $rslt->is_success
	or return ($rslt->status_line);
    my $got = $rslt->header ('Last-Modified')
	or return ('Last-Modified header not returned', $rslt);
    my ( $day, $mon, $yr, $hr, $min, $sec ) =
	$got =~ m/,\s*(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)/
	or return ('Unable to parse Last-Modified header', $rslt);
    defined( my $mn = $mth{lc $mon} )
	or return ('Invalid month in Last-Modified header', $rslt);
    return ( undef, $rslt, $got, time_gm( $sec, $min, $hr, $day, $mn, $yr ) );
}

1;
