package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Test qw{ spacetrack_skip_no_prompt };

spacetrack_skip_no_prompt();

my $st = Astro::SpaceTrack->new(
    pretty	=> 1,
    space_track_version	=> 2,
);

my $base_url = $st->_make_space_track_base_url();

note <<'EOD';
The purpose of this test is to demonstrate that ranges work in the Space
Track REST interface.
EOD

{
    # Iridiums, per T. S. Kelso
    my @oids = qw{
	24792-24796 24836 24837 24839-24842 24869-24873 24903-24907
	24925 24926 24944-24946 24948-24950 24965-24969 25039-25043
	25077 25078 25104-25106 25108 25169-25173 25262 25263
	25272-25276 25285-25291 25319 25320 25342-25346 25431 25432
	25467-25469 25471 25527 25528 25530 25531 25577 25578 25777
	25778 27372-27376 27450 27451
    };
    local $ENV{SPACETRACK_REST_RANGE_OPERATOR} = 1;

    $st->set( dump_headers => 6 );

    my $rslt = $st->retrieve( @oids );

    # Method _get_json_object() is unsupported and undocumented.
    my $json = $st->_get_json_object();

    {
	my $data = $json->decode( $rslt->content() );

	is_deeply $data, [
	   {
	      "args" => [
		 "basicspacedata",
		 "query",
		 "class",
		 "tle_latest",
		 "format",
		 "tle",
		 "orderby",
		 "OBJECT_NUMBER asc",
		 "OBJECT_NUMBER",
		 "24792--24796,24836,24837,24839--24842,24869--24873,24903--24907,24925,24926,24944--24946,24948--24950,24965--24969,25039--25043,25077,25078,25104--25106,25108,25169--25173,25262,25263,25272--25276,25285--25291,25319,25320,25342--25346,25431,25432,25467--25469,25471,25527,25528,25530,25531,25577,25578,25777,25778,27372--27376,27450,27451",
		 "ORDINAL",
		 1
	      ],
	      "method" => "GET",
	      "url" => "$base_url/basicspacedata/query/class/tle_latest/format/tle/orderby/OBJECT_NUMBER%20asc/OBJECT_NUMBER/24792--24796,24836,24837,24839--24842,24869--24873,24903--24907,24925,24926,24944--24946,24948--24950,24965--24969,25039--25043,25077,25078,25104--25106,25108,25169--25173,25262,25263,25272--25276,25285--25291,25319,25320,25342--25346,25431,25432,25467--25469,25471,25527,25528,25530,25531,25577,25578,25777,25778,27372--27376,27450,27451/ORDINAL/1",
	      "version" => 2,
	   },
	], 'Generated correct query';
    }

    $st->set( dump_headers => 0 );

    $rslt = $st->retrieve( { json => 1 }, @oids );

    ok $rslt->is_success(), "Retrieve OIDs"
	or diag $rslt->status_line();

    if ( $rslt->is_success() ) {
	my $data = $json->decode( $rslt->content() );
	# Method _expand_oid_list() is unsupported and undocumented.
	my @expect = $st->_expand_oid_list( @oids );

	cmp_ok scalar @{ $data }, '==', scalar @expect,
	'Got expected number of OIDs';

	my %got;
	foreach ( map { $_->{OBJECT_NUMBER} } @{ $data } ) {
	    $got{$_}++;
	}

	foreach my $oid ( @expect ) {
	    cmp_ok $got{$oid}, '==', 1, "Got exactly one of OID $oid";
	    delete $got{$oid};
	}

	my $extra = join ', ', sort { $a <=> $b } keys %got;

	ok !%got, 'No OIDs other than the ones expected'
	    or diag "Extra OIDs: $extra";

    }
}

done_testing;

1;

# ex: set textwidth=72 :
