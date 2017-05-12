# $Id: test.t,v 1.0 2010/01/02
use Test;
use strict;

BEGIN { plan tests => 7 }

#test1
use Chromosome::Map;
ok(1);

#test2
my $map = Chromosome::Map->new (-length  => '140',
				 -name    => 'CHR_NAME',
				 -height  => '500',
				 -units   => 'cM',
				 );
ok ($map);

#test3
my $mark_track = Chromosome::Map::Track->new (-name => 'Marker Track',
						  -type => 'marker',
						  );
ok($mark_track);

#test4
my $r2 = $map->add_track($mark_track);
ok($r2);

#test5
my $marker = Chromosome::Map::Element->new(-name => 'test_name',
						  -loc	=> 20,
						  -type	=> 'marker',
						  -color => 'red',
						 );
ok($marker);

#test6
my $r5 = $mark_track->add_element($marker);
ok($r5);

#test7
my $png = $map->png;
ok($png);