use Test::More qw(no_plan);
use Config::Format::Ini;
use File::Slurp qw(slurp);

my $dir  = $ENV{PWD} =~ m#\/t$#  ? './data' : 't/data';

my $c1 = { 
	chars   => { common=> [ 'apple'          ],
	             pun1  => [ '2!@'            ],
		     math  => [ '+-/*~.(){}='    ],
		     pun2  => [  '$%^&_:[]|`'    ],
                  },
};
my $res ;
my $c2 = { chars => { simple    => [ 'an', 'apple'             ],
                      quote1    => [ q(can't wouln't), 'more'  ], 
		      quote2    => [ q(can''t')                ],
		      comma1    => [ q(Imperials, The), 'more' ],
		      space1    => [ q(Innocents, The )        ],
		      space2    => [ q( Duke ,  The  )         ],
	              comment1  => [ q(Caddilacs; The)         ],
	              comment2  => [ 'Caddilacs'               ],
		      comment3  => [ q(Five Satins # The)      ],
                    }

};
$res =  read_ini "$dir/val2";
is_deeply( $res, $c2)  ;

$res =  read_ini "$dir/val1";
is_deeply( $res, $c1)  ;


