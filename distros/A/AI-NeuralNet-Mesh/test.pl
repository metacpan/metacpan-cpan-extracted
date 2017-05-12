# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

sub t { my $f=shift;$t++;my $str=($f)?"ok $t":"not ok $t";print $str,"\n";}

use AI::NeuralNet::Mesh;
$loaded = 1;
t 1;

my $net = new AI::NeuralNet::Mesh(2,2,1);
t $net;
t ($net->intr(0.51) eq 1);
t ($net->intr(0.00001) eq 0);
t ($net->intr(0.50001) eq 1);
t $net->learn_set([	
	[ 1,   1   ], [ 2    ] ,
	[ 1,   2   ], [ 3    ],
	[ 2,   2   ], [ 4    ],
	[ 20,  20  ], [ 40   ],
	[ 100, 100 ], [ 200  ],
	[ 150, 150 ], [ 300  ],
	[ 500, 500 ], [ 1000 ],
],degrade=>1);
t ($net->run([60,40])->[0] eq 100);
t $net->save("add.mesh");
t (my $net2 = AI::NeuralNet::Mesh->new("add.mesh"));
t ($net2->run([60,40])->[0] eq 100);
t $net2->save("add.mesh");
t (-f "add.mesh");
t unlink("add.mesh");



