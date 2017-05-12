#!perl

use Test::More;
use Test::Fatal;

use Data::Record::Serialize;

use lib 't/lib';

like(
    exception { Data::Record::Serialize->new },
    qr/must specify 'encode'/,
    'empty args'
);

like(
     exception {
	 Data::Record::Serialize->new( encode => 'both',
				       sink => 'stream' );
     },
     qr/don't specify a sink/,
     q[encode includes sink ; don't specify sink]
);


is (
    exception {
	 Data::Record::Serialize->new( encode => 'ddump',
				       sink => 'stream' );
     },
    undef,
    'encode + sink'
   );

is (
    exception {
	 Data::Record::Serialize->new( encode => 'ddump');
     },
    undef,
    'encode + default sink'
   );

done_testing;
