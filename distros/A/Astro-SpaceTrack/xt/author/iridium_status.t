package main;

use strict;
use warnings;

use Astro::SpaceTrack qw{ :ref };
use Test::More 0.96;	# Because of subtest().

use lib qw{ inc };
use My::Module::Test ();

my $space_track_skip = My::Module::Test::__spacetrack_skip(
    envir	=> 1,
    no_prompt	=> My::Module::Test->NO_SPACE_TRACK_ACCOUNT(),
);

# The following hash is used to compute the todo list. The keys are
# the OIDs for the Iridium satellites. The value for each key is a hash
# containing the names of inconsistent data sources and a true value for
# each inconsistent name. If all three sources are mutually inconsistent,
# only two source names need be given.

my %known_inconsistent = (
    24792 => { sladen => 1 },	# Sladen: Failed 02-Nov-2017
				# Kelso: Failed 16-Nov-2017
				# Decayed: 24-Nov-2017
				# Sladen removed 24-Nov-2017
#   24793 => { sladen => 1 },	# Sladen: failed 02-Nov-2017
				# Kelso: failed 30-May-2018
#   24794 => { sladen => 1 },	# Sladen: failed 23-Nov-2017
				# Kelso: failed 19-Dec-2017
#   24795 => { sladen => 1 },	# Kelso: Failed 16-Nov-2017
				# Sladen Failed 17-Nov-2017
    24796 => { sladen => 1 },	# Kelso: failed 20-Oct-2012;
				# Sladen: still operational.
    24837 => { sladen => 1 },	# Kelso: Spare 23-Mar-2018
				# Sladen: Failed 24-Mar-2018
				# Kelso: Backup 30-May-2018
    24840 => { sladen => 1 },	# Sladen: failed 17-Mar-2018
    24869 => { sladen => 1 },	# Sladen: failed 14-May-2017
				# Kelso: Backup 30-May-2018
#   24872 => { sladen => 1 },	# Sladen: failed 19-May-2017
				# Kelso: Backup 30-May-2018
				# Kelso: Tumbling 12-Jun-2018
    24904 => { sladen => 1 },	# Kelso: spare 08-Feb-2018
				# Sladen: failed 14-Feb-2018
#   24905 => { sladen => 1 },	# Kelso: spare 08-Feb-2018
				# Kelso: Tumbling 30-May-2018
    24906 => { sladen => 1 },	# Kelso: spare 08-Feb-2018
				# Sladen: failed 14-May-2018
				# Decayed: 28-Mar-2018
    24907 => { sladen => 1 },	# Kelso: failed 19-Dec-2017
    24950 => { sladen => 1 },	# about 28-Aug-2017: Sladen declares failed
				# Kelso: Backup 30-May-2018
    24966 => { sladen => 1 },	# 14-Apr-2018: Sladen failed
				# Kelso: Backup 30-May-2018
#   24968 => { sladen => 1 },	# Sladen: failed 09-Dec-2017
				# Decayed 26-May-2018
#   24969 => { sladen => 1 },	# Sladen: failed 09-Dec-2017
				# SpaceTrack: Decayed 08-Jan-2018
#   25040 => { sladen => 1 },	# 20-Jun-2018: Kelso partly operational
				# 26-Jun-2018: Sladen failed
				# 28-Jun-2018: Kelso failed
#   25042 => { sladen => 1 },	# 19-Aug-2016: Sladen - Failed on station?
				# Kelso: Failed 30-May-2018
    25106 => { sladen => 1 },	# 06-May 2018: Sladen - Failed
				# Kelso: Backup 30-May-2018
#   25108 => { sladen => 1 },	# 26-Jan-2018: Kelso - Partly operational.
    25263 => { sladen => 1 },	# Sladen: operational; others: spare.
				# Sladen: failed 09-Dec-2017 (Kelso: operational)
				# Kelso: Backup 30-May-2018
    25272 => { sladen => 1 },	# 14-Aug-2017: Sladen tumbling.
				# Kelso: Backup 30-May-2018
    25274 => { sladen => 1 },	# about 28-Aug-2017: Sladen declares failed.
				# Kelso: Backup 30-May-2018
    25285 => { sladen => 1 },	# 18-May-2018: Sladen failed
				# Kelso: Backup 30-May-2018
    25287 => { sladen => 1 },	# 10-May-2018: Kelso partly operational
				# 18-May-2018: Sladen failed
				# Kelso: Backup 30-May-2018
#   25288 => { sladen => 1 },	# 26-Jun-2018: Kelso partly operational
				# 01-Jul-2018: Sladen failed
				# 03-Jul-2018: Kelso failed
    25289 => { sladen => 1 },	# 10-May-2018: Kelso partly operational
				# 18-May-2018: Sladen failed
				# Kelso: Backup 30-May-2018
#   25290 => { sladen => 1 },	# 08-Jun-2018: Kelso partly operational
				# 11-Jun-2018: Sladen failed on station
				# 20-Jun-2018: Kelso failed
#   25291 => { sladen => 1 },	# 10-May-2018: Kelso partly operational
				# 18-May-2018: Sladen failed
				# Kelso: Failed 30-May-2018
				# Space Track: Decayed 06-Jun-2018
    25342 => { sladen => 1 },	# 14-Jun-2018: Sladen failed.
    25343 => { sladen => 1 },	# 27-Apr-2018: Kelso partly operational
#   25346 => { sladen => 1 },	# 14-Jun-2018: Kelso partly operational
				# 15-Jun-2018: Sladen failed on station
				# 22-Jun-2018: Kelso failed
#   25431 => { sladen => 1 },	# 21-Jan-2018: Sladen failed.
    25431 => { sladen => 1 },	# Sladen: failed 09-Feb-2018
    25432 => { sladen => 1 },	# 10-Mar-2018: Sladen failed.
				# Kelso: Backup 30-May-2018
#   25468 => { sladen => 1 },	# Sladen: failed 14-May-2017
				# Kelso: Backup 30-May-2018
				# Kelso: Tumbling 20-Jun-2018
				# SpaceTrack: decaued 17-Jul-2018
    25469 => { sladen => 1 },	# 12-Jul-2018: Kelso partially operational
				# 12-Jul-2018: Sladen failed
    25577 => { sladen => 1 },	# 14-Apr-2018: Sladen failed
				# Kelso: Backup 30-May-2018
    25578 => { sladen => 1 },	# 26-Apr-2018: Sladen failed
				# Kelso: Backup 30-May-2018
#   25778 => { sladen => 1 },	# 04-May-2018: Sladen failed
				# 25-May-2018: Decayed
#   27373 => { sladen => 1 },	# 10-Mar-2018: Sladen failed.
				# Kelso: Failed 30-May-2018
    27374 => { sladen => 1 },	# 02-Mar-2018 Kelso: partly operationsl
#   27376 => { sladen => 1 },	# Sladen: failed 22-Dec-2017
				# Kelso: Failed 30-May-2018
    27450 => { sladen => 1 },	# 10-Mar-2018: Sladen failed.
				# Kelso: Backup 30-May-2018
    27451 => { sladen => 1 },	# 06-Jul-2018: Kelso partly operational
    				# 09-Jul-2018: Sladen failed
);

my $st = Astro::SpaceTrack->new();

my @sources = qw{ kelso sladen };

$space_track_skip
    or push @sources, 'spacetrack';

my (%skip, %text, %status);
my %name;
foreach my $src (@sources) {
    my ($rslt, $data) = $st->iridium_status( { raw => 1 }, $src);
    if ($rslt->is_success) {
	$text{$src} = $rslt->content;
	my %sts;
	ARRAY_REF eq ref $data
	    and %sts = map {$_->[0] => $_->[4]} @$data;
	$status{$src} = \%sts;
	foreach (@$data) {
	    $name{$_->[0]} ||= $_->[1];
	}
    } else {
	$skip{$src} = ucfirst($src) . ' data unavailable';
    }
}

# We used to compute the following as all permutations of sources, BUT:
# 1) McCants' data is no longer maintained
# 2) We added 'spacetrack' which, when raw, is not really comparable.
# TRW 2017-10-03
my @pairs = ( [ qw{ kelso sladen } ] );

my @keys;
{	#	Begin local symbol block
    my %ky;
    foreach my $src (keys %status) {
	foreach my $oid (keys %{$status{$src}}) {
	    $ky{$oid}++;
	}
    }
    @keys = sort {$a <=> $b} keys %ky;
}

foreach (
	["T. S. Kelso's Iridium list",
	kelso => <<'KELSO'],
 24793   Iridium 7      [-]      Tumbling
 24795   Iridium 5      [-]      Tumbling
 24796   Iridium 4      [-]      Tumbling
 24836   Iridium 914    [-]      Tumbling
 24837   Iridium 12     [B]      
 24839   Iridium 10     [+]      
 24841   Iridium 16     [-]      Tumbling
 24842   Iridium 911    [-]      Tumbling
 24869   Iridium 15     [B]      
 24870   Iridium 17     [-]      Tumbling
 24871   Iridium 920    [-]      Tumbling
 24872   Iridium 18     [-]      Tumbling
 24873   Iridium 921    [-]      Tumbling
 24903   Iridium 26     [-]      Tumbling
 24905   Iridium 46     [-]      Tumbling
 24907   Iridium 22     [-]      Tumbling
 24925   Dummy mass 1   [-]      Tumbling
 24926   Dummy mass 2   [-]      Tumbling
 24944   Iridium 29     [-]      Tumbling
 24945   Iridium 32     [+]      
 24946   Iridium 33     [-]      Tumbling
 24948   Iridium 28     [-]      Tumbling
 24950   Iridium 31     [B]      
 24966   Iridium 35     [B]      
 24967   Iridium 36     [-]      Tumbling
 25040   Iridium 41     [-]      Tumbling
 25041   Iridium 40     [-]      Tumbling
 25042   Iridium 39     [-]      Tumbling
 25043   Iridium 38     [-]      Tumbling
 25077   Iridium 42     [-]      Tumbling
 25078   Iridium 44     [-]      Tumbling
 25104   Iridium 45     [+]      
 25105   Iridium 24     [-]      Tumbling
 25106   Iridium 47     [B]      
 25169   Iridium 52     [+]      
 25170   Iridium 56     [+]      
 25171   Iridium 54     [+]      
 25172   Iridium 50     [+]      
 25173   Iridium 53     [+]      
 25262   Iridium 51     [-]      Tumbling
 25263   Iridium 61     [B]      
 25272   Iridium 55     [B]      
 25273   Iridium 57     [-]      Tumbling
 25274   Iridium 58     [B]      
 25275   Iridium 59     [+]      
 25276   Iridium 60     [+]      
 25285   Iridium 62     [B]      
 25286   Iridium 63     [-]      Tumbling
 25287   Iridium 64     [B]      
 25289   Iridium 66     [B]      
 25319   Iridium 69     [-]      Tumbling
 25320   Iridium 71     [-]      Tumbling
 25342   Iridium 70     [+]      
 25344   Iridium 73     [-]      Tumbling
 25432   Iridium 76     [B]      
 25467   Iridium 82     [-]      Tumbling
 25469   Iridium 80     [-]      Tumbling
 25527   Iridium 2      [-]      Tumbling
 25528   Iridium 86     [+]      
 25530   Iridium 84     [+]      
 25531   Iridium 83     [+]      
 25577   Iridium 20     [B]      
 25578   Iridium 11     [B]      
 25777   Iridium 14     [+]      
 27372   Iridium 91     [+]      
 27373   Iridium 90     [-]      Tumbling
 27375   Iridium 95     [+]      
 27376   Iridium 96     [-]      Tumbling
 27450   Iridium 97     [B]      
 27451   Iridium 98     [P]      
KELSO
	["Rod Sladen's Iridium Constellation Status",
	sladen => <<'SLADEN'],
 24793   Iridium 7      [-]      Plane 4 - Failed on station?
 24795   Iridium 5      [-]      Plane 4 - Failed on station?
 24796   Iridium 4      [-]      Plane 4 - Failed on station?
 24836   Iridium 914    [-]      Plane 5
 24837   Iridium 12     [-]      Plane 5
 24839   Iridium 10     [+]      Plane 5
 24841   Iridium 16     [-]      Plane 5
 24842   Iridium 911    [-]      Plane 5
 24869   Iridium 15     [-]      Plane 6
 24870   Iridium 17     [-]      Plane 6
 24871   Iridium 920    [-]      Plane 6
 24872   Iridium 18     [-]      Plane 6 - Failed on station?
 24873   Iridium 921    [-]      Plane 6
 24903   Iridium 26     [-]      Plane 2 - Failed on station?
 24905   Iridium 46     [-]      Plane 2 - Failed on station?
 24907   Iridium 22     [-]      Plane 2 - Failed on station?
 24925   Dummy mass 1   [-]      Dummy
 24926   Dummy mass 2   [-]      Dummy
 24944   Iridium 29     [-]      Plane 3 - Failed on station?
 24945   Iridium 32     [+]      Plane 3
 24946   Iridium 33     [-]      Plane 3
 24948   Iridium 28     [-]      Plane 3 - Failed on station?
 24950   Iridium 31     [-]      Plane 3
 24966   Iridium 35     [-]      Plane 4
 24967   Iridium 36     [-]      Plane 4
 25040   Iridium 41     [-]      Plane 6 - Failed on station?
 25041   Iridium 40     [-]      Plane 6 - Failed on station?
 25042   Iridium 39     [-]      Plane 6 - Failed on station?
 25043   Iridium 38     [-]      Plane 6
 25077   Iridium 42     [-]      Plane 6
 25078   Iridium 44     [-]      Plane 6
 25104   Iridium 45     [+]      Plane 3
 25105   Iridium 24     [-]      Plane 2
 25106   Iridium 47     [-]      Plane 2
 25169   Iridium 52     [+]      Plane 5
 25170   Iridium 56     [+]      Plane 5
 25171   Iridium 54     [+]      Plane 5
 25172   Iridium 50     [+]      Plane 5
 25173   Iridium 53     [+]      Plane 5
 25262   Iridium 51     [-]      Plane 4 - Failed on station?
 25263   Iridium 61     [-]      Plane 4
 25272   Iridium 55     [-]      Plane 3
 25273   Iridium 57     [-]      Plane 3 - Failed on station?
 25274   Iridium 58     [-]      Plane 3
 25275   Iridium 59     [+]      Plane 3
 25276   Iridium 60     [+]      Plane 3
 25285   Iridium 62     [-]      Plane 1
 25286   Iridium 63     [-]      Plane 1 - Failed on station?
 25287   Iridium 64     [-]      Plane 1
 25289   Iridium 66     [-]      Plane 1
 25319   Iridium 69     [-]      Plane 2
 25320   Iridium 71     [-]      Plane 2
 25342   Iridium 70     [-]      Plane 1
 25344   Iridium 73     [-]      Plane 1
 25432   Iridium 76     [-]      Plane 2
 25467   Iridium 82     [-]      Plane 6 - Failed on station?
 25469   Iridium 80     [-]      Plane 6 - Failed on station?
 25527   Iridium 2      [-]      Plane 5
 25528   Iridium 86     [+]      Plane 5
 25530   Iridium 84     [+]      Plane 5
 25531   Iridium 83     [+]      Plane 5
 25577   Iridium 20     [-]      Plane 2
 25578   Iridium 11     [-]      Plane 2
 25777   Iridium 14     [+]      Plane 1
 27372   Iridium 91     [+]      Plane 3
 27373   Iridium 90     [-]      Plane 5 - Failed on station?
 27375   Iridium 95     [+]      Plane 3
 27376   Iridium 96     [-]      Plane 4 - Failed on station?
 27450   Iridium 97     [-]      Plane 4
 27451   Iridium 98     [-]      Plane 6 - Failed on station?
SLADEN
        $space_track_skip ? () :
	[ "Space Track Iridium status",
	spacetrack => <<'SPACETRACK'],
 24792   Iridium 8      [D]      Decayed 2017-11-24
 24793   Iridium 7      [?]      SpaceTrack
 24794   Iridium 6      [D]      Decayed 2017-12-23
 24795   Iridium 5      [?]      SpaceTrack
 24796   Iridium 4      [?]      SpaceTrack
 24836   Iridium 914    [?]      SpaceTrack
 24837   Iridium 12     [?]      SpaceTrack
 24838   Iridium 09     [D]      Decayed 2003-03-11
 24839   Iridium 10     [?]      SpaceTrack
 24840   Iridium 13     [D]      Decayed 2018-04-29
 24841   Iridium 16     [?]      SpaceTrack
 24842   Iridium 911    [?]      SpaceTrack
 24869   Iridium 15     [?]      SpaceTrack
 24870   Iridium 17     [?]      SpaceTrack
 24871   Iridium 920    [?]      SpaceTrack
 24872   Iridium 18     [?]      SpaceTrack
 24873   Iridium 921    [?]      SpaceTrack
 24903   Iridium 26     [?]      SpaceTrack
 24904   Iridium 25     [D]      Decayed 2018-05-14
 24905   Iridium 46     [?]      SpaceTrack
 24906   Iridium 23     [D]      Decayed 2018-03-28
 24907   Iridium 22     [?]      SpaceTrack
 24944   Iridium 29     [?]      SpaceTrack
 24945   Iridium 32     [?]      SpaceTrack
 24946   Iridium 33     [?]      SpaceTrack
 24947   Iridium 27     [D]      Decayed 2002-02-01
 24948   Iridium 28     [?]      SpaceTrack
 24949   Iridium 30     [D]      Decayed 2017-09-28
 24950   Iridium 31     [?]      SpaceTrack
 24965   Iridium 19     [D]      Decayed 2018-04-07
 24966   Iridium 35     [?]      SpaceTrack
 24967   Iridium 36     [?]      SpaceTrack
 24968   Iridium 37     [D]      Decayed 2018-05-26
 24969   Iridium 34     [D]      Decayed 2018-01-08
 25039   Iridium 43     [D]      Decayed 2018-02-11
 25040   Iridium 41     [?]      SpaceTrack
 25041   Iridium 40     [?]      SpaceTrack
 25042   Iridium 39     [?]      SpaceTrack
 25043   Iridium 38     [?]      SpaceTrack
 25077   Iridium 42     [?]      SpaceTrack
 25078   Iridium 44     [?]      SpaceTrack
 25104   Iridium 45     [?]      SpaceTrack
 25105   Iridium 24     [?]      SpaceTrack
 25106   Iridium 47     [?]      SpaceTrack
 25107   Iridium 48     [D]      Decayed 2001-05-05
 25108   Iridium 49     [D]      Decayed 2018-02-13
 25169   Iridium 52     [?]      SpaceTrack
 25170   Iridium 56     [?]      SpaceTrack
 25171   Iridium 54     [?]      SpaceTrack
 25172   Iridium 50     [?]      SpaceTrack
 25173   Iridium 53     [?]      SpaceTrack
 25262   Iridium 51     [?]      SpaceTrack
 25263   Iridium 61     [?]      SpaceTrack
 25272   Iridium 55     [?]      SpaceTrack
 25273   Iridium 57     [?]      SpaceTrack
 25274   Iridium 58     [?]      SpaceTrack
 25275   Iridium 59     [?]      SpaceTrack
 25276   Iridium 60     [?]      SpaceTrack
 25285   Iridium 62     [?]      SpaceTrack
 25286   Iridium 63     [?]      SpaceTrack
 25287   Iridium 64     [?]      SpaceTrack
 25288   Iridium 65     [D]      Decayed 2018-07-19
 25289   Iridium 66     [?]      SpaceTrack
 25290   Iridium 67     [D]      Decayed 2018-07-02
 25291   Iridium 68     [D]      Decayed 2018-06-06
 25319   Iridium 69     [?]      SpaceTrack
 25320   Iridium 71     [?]      SpaceTrack
 25342   Iridium 70     [?]      SpaceTrack
 25343   Iridium 72     [D]      Decayed 2018-05-14
 25344   Iridium 73     [?]      SpaceTrack
 25345   Iridium 74     [D]      Decayed 2017-06-11
 25346   Iridium 75     [D]      Decayed 2018-07-10
 25431   Iridium 03     [D]      Decayed 2018-02-08
 25432   Iridium 76     [?]      SpaceTrack
 25467   Iridium 82     [?]      SpaceTrack
 25468   Iridium 81     [D]      Decayed 2018-07-17
 25469   Iridium 80     [?]      SpaceTrack
 25470   Iridium 79     [D]      Decayed 2000-11-29
 25471   Iridium 77     [D]      Decayed 2017-09-22
 25527   Iridium 2      [?]      SpaceTrack
 25528   Iridium 86     [?]      SpaceTrack
 25529   Iridium 85     [D]      Decayed 2000-12-30
 25530   Iridium 84     [?]      SpaceTrack
 25531   Iridium 83     [?]      SpaceTrack
 25577   Iridium 20     [?]      SpaceTrack
 25578   Iridium 11     [?]      SpaceTrack
 25777   Iridium 14     [?]      SpaceTrack
 25778   Iridium 21     [D]      Decayed 2018-05-24
 27372   Iridium 91     [?]      SpaceTrack
 27373   Iridium 90     [?]      SpaceTrack
 27374   Iridium 94     [D]      Decayed 2018-04-18
 27375   Iridium 95     [?]      SpaceTrack
 27376   Iridium 96     [?]      SpaceTrack
 27450   Iridium 97     [?]      SpaceTrack
 27451   Iridium 98     [?]      SpaceTrack
SPACETRACK
	) {
    my ( $what, $file, $data ) = @$_;
    $data ||= '';
    my $got = $skip{$file} ? 'skip' : $text{$file};
    1 while $got =~ s/\015\012/\n/gm;

    SKIP: {
	$skip{$file}
	    and skip $skip{$file}, 1;

	if ( not is $got, $data, "Content of $what" ) {
	    my $fn = "$file.expect";
	    open (my $fh, '>', $fn) or die "Unable to open $fn: $!";
	    print $fh $data;
	    close $fh;
	    $fn = "$file.got";
	    open ($fh, '>', $fn) or die "Unable to open $fn: $!";
	    print $fh $got;
	    close $fh;
	    diag <<"EOD";
Expected and gotten information written to $file.expect and
$file.got respectively.
EOD
	}
    }
}

foreach my $id ( @keys ) {
    foreach my $pr ( @pairs ) {
	SKIP: {
	    my $skip;
	    $skip = _skip_reason( $id, $pr )
		and skip $skip, 1;

	    defined $status{$pr->[0]}{$id}
		or diag "$id $pr->[0] undef";
	    defined $status{$pr->[1]}{$id}
		or diag "$id $pr->[1] undef";
	    cmp_ok $status{$pr->[0]}{$id}, '==', $status{$pr->[1]}{$id},
	    "$id status consistent between $pr->[0] and $pr->[1]"
		or diag xlate( $pr->[0], $pr->[1], $id );
	}
    }
}

{
    my @xlation;
    BEGIN {
	foreach my $st ( qw{
	    BODY_STATUS_IS_OPERATIONAL
	    BODY_STATUS_IS_SPARE
	    BODY_STATUS_IS_TUMBLING
	    }
	) {
	    my $inx = Astro::SpaceTrack->$st();
	    ( my $name = $st ) =~ s/ .* _ //smx;
	    $name = lc $name;
	    $xlation[$inx] = "$inx ($name)";
	}
    }

    sub xlate {
	my ( $left, $right, $id ) = @_;
	my @args;
	foreach my $src ( $left, $right ) {
	    my $st = $status{$src}{$id};
	    push @args, $src, $xlation[$st];
	    defined $args[-1]
		or $args[-1] = $st;
	}
	return sprintf '    %s: %s; %s: %s', @args;
    }
}

done_testing;

sub _skip_reason {
    my ( $id, $pr ) = @_;

    foreach my $src ( @{ $pr } ) {
	$skip{$src}
	    and return $skip{$src};
    }

    foreach my $src ( @{ $pr } ) {
	exists $status{$src}{$id}
	    or return "$id missing from $src";
    }

    foreach my $inx ( 0 .. $#$pr ) {
	my $src = $pr->[$inx];
	my $pard = $pr->[$#$pr - $inx];
	$known_inconsistent{$id}{$src}
	    and return "$id status known inconsistent between $src and $pard";
    }

    return;
}

1;
