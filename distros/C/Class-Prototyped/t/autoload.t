use strict;
$^W++;
use Class::Prototyped qw(:NEW_MAIN);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 35;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $p1 = new( a => 2, [qw(b FIELD autoload)] => sub { time });

ok( Data::Dumper->Dump([[ $p1->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {autoload => 1}, type => 'FIELD', value => sub {} } ]])
);

my $p2 = $p1->clone();

ok( Data::Dumper->Dump([[ $p2->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {autoload => 1}, type => 'FIELD', value => sub {} } ]])
);

my $timea = time;
my $time1 = $p1->b;
my $timez = time;

ok( $time1 >= $timea);
ok( $time1 <= $timez);

ok( Data::Dumper->Dump([[ $p1->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {}, type => 'FIELD', value => $time1 } ]])
);

while ($time1 == time) {
	sleep(1);
}

ok( time != $p1->b );

ok( Data::Dumper->Dump([[ $p2->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {autoload => 1}, type => 'FIELD', value => sub {} } ]])
);

$timea = time;
my $time2 = $p2->b;
$timez = time;

ok( $time2 >= $timea);
ok( $time2 <= $timez);

ok( Data::Dumper->Dump([[ $p2->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {}, type => 'FIELD', value => $time2 } ]])
);

while ($time2 == time) {
	sleep(1);
}

ok( time != $p2->b );

my $p3 = $p1->clone();

ok( Data::Dumper->Dump([[ $p3->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {}, type => 'FIELD', value => $time1 } ]])
);

$p3->b(7);

ok( $p3->b, 7 );


my $p4 = new( a => 2, [qw(b FIELD autoload)] => sub { $_[0]->a });

$p4->a(5);
ok( $p4->a, 5 );
ok( $p4->b, 5 );

$p4->a(2);
ok( $p4->a, 2 );
ok( $p4->b, 5 );

my $p5 = new( a => 4, [qw(b FIELD autoload)] => sub { [ map {rand()} 1..$_[0]->a ] });
my $p6 = $p5->clone;

$p6->a(6);

ok( scalar(@{$p5->b}), 4);
ok( scalar(@{$p6->b}), 6);
ok( scalar($p5->b), "".$p5->b);


my $p7 = new( a => 2, [qw(b FIELD autoload)] => sub { defined $_[1] ? $_[1] : time });

ok( Data::Dumper->Dump([[ $p7->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {autoload => 1}, type => 'FIELD', value => sub {} } ]])
);

my $time7 = $p7->b(5);

ok( $time7, 5);

ok( Data::Dumper->Dump([[ $p7->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {}, type => 'FIELD', value => $time7 } ]])
);


my $p8 = new( a => 2, [qw(b FIELD autoload)] => sub { defined $_[1] ? $_[1] : time });

ok( Data::Dumper->Dump([[ $p8->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {autoload => 1}, type => 'FIELD', value => sub {} } ]])
);

$timea = time;
my $time8 = $p8->b;
$timez = time;

ok( $time8 >= $timea);
ok( $time8 <= $timez);

ok( Data::Dumper->Dump([[ $p8->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {}, type => 'FIELD', value => $time8 } ]])
);


my $p9 = new( a => 2, [qw(b FIELD autoload 1 constant 1)] => sub { time });

$timea = time;
my $time9 = $p9->b;
$timez = time;

ok( $time9 >= $timea);
ok( $time9 <= $timez);

ok( Data::Dumper->Dump([[ $p9->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 2 },
													b => { attribs => {constant => 1}, type => 'FIELD', value => $time9 } ]])
);

$p9->b(5);
ok( $p9->b, $time9 );


my $p10 = new( a => 4, [qw(b FIELD autoload 1 wantarray 1)] => sub { [ map {rand()} 1..$_[0]->a ] });

ok( Data::Dumper->Dump([[ $p10->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 4 },
													b => { attribs => {autoload => 1, wantarray => 1}, type => 'FIELD', value => sub {} } ]])
);

ok( scalar(@{$p10->b}), 4);
ok( scalar($p10->b), "".$p10->b);

ok( Data::Dumper->Dump([[ $p10->reflect->getSlots(undef, 'rotated') ]]),
		Data::Dumper->Dump([[ a => { attribs => {}, type => 'FIELD', value => 4 },
													b => { attribs => {wantarray => 1}, type => 'FIELD', value => scalar($p10->b) } ]])
);
