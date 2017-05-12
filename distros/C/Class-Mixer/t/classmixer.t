#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests=>59;
my $verbose = $ENV{TEST_VERBOSE} || $ENV{VERBOSE};

BEGIN { use_ok('Class::Mixer') };

{
package test1x; sub x{}
package test1y; sub x{}
package test1z; sub x{}
package test1q; sub x{}
package TEST1;
use Class::Mixer before => 'test1x', 
		after => 'test1y',
		isa => 'test1z',
		requires => 'test1q';
};

is_deeply(\@TEST1::MIXERS, [ before => 'test1x',
                after => 'test1y',
                isa => 'test1z',
                requires => 'test1q' ], 	'Class::Mixer::import');

$Class::Mixer::DEBUG = $ENV{DEBUG};

{package BX; sub x{} }
{package X2; use Class::Mixer before=>'BX'; sub x {} };
{package X1; use Class::Mixer before=>'X2';}

my $x = X1->new;
my @mro = Class::C3::calculateMRO('X1');
is_deeply(\@mro, [qw(X1 X2 BX Class::Mixer)], 'simple before mix');

{package XY; use Class::Mixer before=>'X1'; }
{package X3; use Class::Mixer requires=>'X1','XY'; }
eval { my $x = X3->new; 
@mro = Class::C3::calculateMRO('X3');
};
diag $@ if $@;
is_deeply(\@mro, [qw(X3 XY X1 X2 BX Class::Mixer)], 'tricky mixin');



# using swank as model

{package TBase; use Class::Mixer; sub x{} sub init { $_[0]->{base} = 1; } }

{package TCompiler; use Class::Mixer requires=>'TBase'; }

{package TDate; use Class::Mixer before=>'TBase'; }

{package TStorage; use Class::Mixer requires=>'TDate', before=>'TBase'; 
sub init { $_[0]->{storage} = 1; $_[0]->next::method; } 
}

{package TIO; use Class::Mixer before=>'TBase'; }

{package Test1; use base qw(TStorage TBase TIO); }

# test1: before and requires, and also 'use base'
my $test1 = Test1->new;
@mro = Class::C3::calculateMRO('Test1');
like("@mro", qr/TStorage.*TBase/,	'Test1: storage before base');
like("@mro", qr/TIO.*TBase/,		'Test1: io before base');
like("@mro", qr/TBase.*Class::Mixer/,	'Test1: base before classmixer');
like("@mro", qr/TDate.*TBase/,		'Test1: date before base');

is($test1->{storage}, 1,		'test init storage');
is($test1->{base}, 1,		'test init base');


{package TSession; use Class::Mixer after=>'TIO', before=>'TBase'; }

{package Test2; use base qw(TStorage TBase TSession TIO); }

# test2: after
my $test2 = Test2->new;
@mro = Class::C3::calculateMRO('Test2');
like("@mro", qr/TStorage.*TBase/,	'Test2: storage before base');
like("@mro", qr/TIO.*TBase/,		'Test2: io before base');
like("@mro", qr/TBase.*Class::Mixer/,	'Test2: base before classmixer');
like("@mro", qr/TDate.*TBase/,		'Test2: date before base');
like("@mro", qr/TIO.*TSession/,		'Test2: session after io');


{package TIO2; use Class::Mixer isa=>'TIO'; }

{package TTIO; use Class::Mixer isa=>'TIO2'; }

{package Test3; use base qw(TTIO TStorage TSession); }

# test3: isa
my $test3 = Test3->new;
@mro = Class::C3::calculateMRO('Test3');
like("@mro", qr/TStorage.*TBase/,	'Test3: storage before base');
like("@mro", qr/TIO.*TBase/,		'Test3: io before base');
like("@mro", qr/TBase.*Class::Mixer/,	'Test3: base before classmixer');
like("@mro", qr/TDate.*TBase/,		'Test3: date before base');
like("@mro", qr/TIO.*TSession/,		'Test3: session after io');
like("@mro", qr/TTIO TIO2 TIO/,		'Test3: io isa together');


{package TLucene; use Class::Mixer before=>'TStorage'; }
{package Test4; use base qw(Test3 TLucene); }
# test4: mixin one more
my $test4 = Test4->new;
@mro = Class::C3::calculateMRO('Test4');
like("@mro", qr/TStorage.*TBase/,	'Test4: storage before base');
like("@mro", qr/TIO.*TBase/,		'Test4: io before base');
like("@mro", qr/TBase.*Class::Mixer/,	'Test4: base before classmixer');
like("@mro", qr/TDate.*TBase/,		'Test4: date before base');
like("@mro", qr/TIO.*TSession/,		'Test4: session after io');
like("@mro", qr/TTIO TIO2 TIO/,		'Test4: io isa together');
like("@mro", qr/TLucene.*TStorage/,	'Test4: lucene before storage');


{package TRCS; use Class::Mixer before=>'TStorage'; }
{package TSecurity; use Class::Mixer before=>'TRCS','TStorage',optional=>'TRCS'; }
{package TUEB; use Class::Mixer before=>'TSecurity','TBase'; }
sub shuffle
{
	srand;
	my @new = ();
	my @old = @_;
	while (@old) {
		push(@new, splice(@old,rand @old,1));
	}
	return @new;
}
{package Test5; use base main::shuffle(qw(TBase TStorage TUEB TLucene TIO2 TRCS TSecurity TSession)); }
# test5: shuffled and more
my $test5 = Test5->new;
@mro = Class::C3::calculateMRO('Test5');
like("@mro", qr/TStorage.*TBase/,	'Test5: storage before base');
like("@mro", qr/TIO.*TBase/,		'Test5: io before base');
like("@mro", qr/TBase.*Class::Mixer/,	'Test5: base before classmixer');
like("@mro", qr/TDate.*TBase/,		'Test5: date before base');
like("@mro", qr/TIO.*TSession/,		'Test5: session after io');
like("@mro", qr/TIO2 TIO/,		'Test5: io isa together');
unlike("@mro", qr/TTIO/,		'Test5: no ttio');
like("@mro", qr/TLucene.*TStorage/,	'Test5: lucene before storage');
like("@mro", qr/TRCS.*TStorage/,	'Test5: rcs before storage');
like("@mro", qr/TSecurity.*TRCS/,	'Test5: security before rcs');
like("@mro", qr/TSecurity.*TStorage/,	'Test5: security before storage');
like("@mro", qr/TUEB.*TSecurity/,	'Test5: ueb before security');


{package TSVN; use Class::Mixer isa=>'TRCS'; }
{package Test6; use base qw(TBase TStorage TUEB TLucene TIO2 TSVN TSecurity TSession); }
# test6: replace RCS with SVN
my $test6 = Test6->new;
@mro = Class::C3::calculateMRO('Test6');
like("@mro", qr/TStorage.*TBase/,	'Test6: storage before base');
like("@mro", qr/TIO.*TBase/,		'Test6: io before base');
like("@mro", qr/TBase.*Class::Mixer/,	'Test6: base before classmixer');
like("@mro", qr/TDate.*TBase/,		'Test6: date before base');
like("@mro", qr/TIO.*TSession/,		'Test6: session after io');
like("@mro", qr/TIO2 TIO/,		'Test6: io isa together');
unlike("@mro", qr/TTIO/,		'Test6: no ttio');
like("@mro", qr/TLucene.*TStorage/,	'Test6: lucene before storage');
like("@mro", qr/TSVN TRCS/,		'Test6: rcs isa together');
like("@mro", qr/TSVN.*TStorage/,	'Test6: svn before storage');
like("@mro", qr/TSecurity.*TSVN/,	'Test6: security before rcs');
like("@mro", qr/TSecurity.*TStorage/,	'Test6: security before storage');
like("@mro", qr/TUEB.*TSecurity/,	'Test6: ueb before security');


{package XXX; 
sub x{}
eval "use Class::Mixer requires=>'YYY';"; }
{package Test7; use base 'XXX'; }
# test7: die with non-class
eval {
my $test7 = Test7->new;
};
ok($@,					'Test7: die with class not exists');


# loops don't matter with requires (should work either way)
{package TR2; sub x{} }
{package TR1; use Class::Mixer requires=>'TR2'; }
{package TR2; use Class::Mixer requires=>'TR1'; }
{package Test8; use Class::Mixer before=>'TR1'; }
eval {
@mro = ();
my $test8 = Test8->new;
@mro = Class::C3::calculateMRO('Test8');
};
diag($@) if $@;
ok(!$@, 				'Test8: no err on req <--> req');
like("@mro", qr/Test8.*TR1/,		'Test8: test before tr1');
like("@mro", qr/Test8.*TR2/,		'Test8: test before tr2');


# test bad trees, such as loops in inheritance
{package TB2; sub x{} }
{package TB1; use Class::Mixer before=>'TB2'; }
{package TB2; use Class::Mixer before=>'TB1'; }
{package Test9; use Class::Mixer before=>'TB1'; }
eval {
@mro = ();
my $test9 = Test9->new;
@mro = Class::C3::calculateMRO('Test9');
};
#diag($@) if $@;
ok($@,	 				'Test9: die on bef <--> bef');


# test unrelated class in different tree branch
{package TPage; use Class::Mixer before=>'TBase'; }
{package Test10; use base qw(Test6); }
my $test10 = Test10->new;
@mro = Class::C3::calculateMRO('Test10');
unlike("@mro", qr/TPage/,		'Test10: no TPage');




# todo

# test optional with missing optional class


