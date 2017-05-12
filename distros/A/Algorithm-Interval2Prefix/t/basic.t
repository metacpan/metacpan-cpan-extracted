# -*- perl -*-
use Test::More tests => 9;

BEGIN {
  use_ok('Algorithm::Interval2Prefix')
};

ok eq_array([interval2prefix('2340','2349')],
	    ['234']),
  'simple interval';

ok eq_array([interval2prefix('42','42')],
	    ['42']),
  '1-element interval';

ok eq_array([interval2prefix('42','41')],
	    []),
  '0-element interval';

ok eq_array([interval2prefix('27120000', '27124999')],
            [qw(27120 27121 27122 27123 27124)]),
  'normal interval';

ok eq_array([interval2prefix('27120010','27129989')],
            [qw(2712001 2712002 2712003 2712004 2712005 2712006 2712007 2712008 2712009
                271201  271202  271203  271204  271205  271206  271207  271208  271209
                27121   27122   27123   27124   27125   27126   27127   27128
                271290  271291  271292  271293  271294  271295  271296  271297  271298
                2712990 2712991 2712992 2712993 2712994 2712995 2712996 2712997 2712998)]),
  'complex interval';

ok eq_array([interval2prefix(0b11111000, 0b11111111, 2)],
	    [0b11111]),
  'simple base-2 interval';

ok eq_array([interval2prefix(0b1001, 0b1111, 2)],
	    [0b1001, 0b101, 0b11]),
  'normal base-2 interval';

ok eq_array([interval2prefix('39967000', '39980999')],
            [qw(39967 39968 39969 3997 39980)]),
  'doc example';

