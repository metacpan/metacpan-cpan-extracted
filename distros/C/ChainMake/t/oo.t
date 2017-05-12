#!/usr/bin/perl

# this tests the oo interface

use strict;
use Test::More tests => 47;
use Config;
use Time::HiRes qw/usleep/;

BEGIN {
    use_ok('ChainMake');
};

my $made;
sub have_made { $made.=shift }
sub made_ok {
    my ($result,$comment)=@_;
    ok( ($made eq $result), "$comment (should '$result', did '$made')" );
    $made='';
}

my $cm1;
ok($cm1=new ChainMake(),'create ChainMake object without arguments');
ok($cm1->configure(
    verbose => 1,
    timestamps_file => 'test-oo-1.stamps',
),'configure it');
ok($cm1->unlink_timestamps(),'clean timestamps');

ok($cm1->{verbose} == '1','verbose set correctly');
ok($cm1->{timestamps_file} eq 'test-oo-1.stamps','timestamps_file set correctly');
ok('$t_name' =~ $cm1->{symbols}->[0],'$t_name set correctly');
ok('$t_base' =~ $cm1->{symbols}->[1],'$t_base set correctly');
ok('$t_ext' =~ $cm1->{symbols}->[2],'$t_ext set correctly');

ok($cm1->configure(
    verbose => 0,
),'configure again');
ok($cm1->{verbose} == '0','verbose set correctly');
ok($cm1->{timestamps_file} eq 'test-oo-1.stamps','timestamps_file setting not modified');

my $cm2;
ok($cm2=new ChainMake(
    verbose => 1,
    timestamps_file => 'test-oo-2.stamps',
    symbols     => [ qr/\$0/, qr/\$1/, qr/\$2/ ],
),'create ChainMake object with arguments');
ok($cm2->unlink_timestamps(),'clean timestamps');

ok($cm2->{verbose} == '1','verbose set correctly');
ok($cm2->{timestamps_file} eq 'test-oo-2.stamps','timestamps_file set correctly');
ok('$0' =~ $cm2->{symbols}->[0],'$t_name set correctly');
ok('$1' =~ $cm2->{symbols}->[1],'$t_base set correctly');
ok('$2' =~ $cm2->{symbols}->[2],'$t_ext set correctly');

my ($t_name,$t_base,$t_ext,$youngest_req,$oldest);

ok(
    $cm1->targets('A1',
        timestamps   => 'once',
        handler => sub {
            ($t_name,$t_base,$t_ext,$youngest_req,$oldest)=@_;
            have_made('A1');
            sleep 1;
            1;
        },
    ),
"declare target A1 scalar style");

ok(
    $cm1->targets(['A2'],
        timestamps   => 'once',
        requirements => ['A1'],
        handler => sub {
            ($t_name,$t_base,$t_ext,$youngest_req,$oldest)=@_;
            have_made('A2');
            sleep 1;
            1;
        },
    ),
"declare target A2 list style");

ok(
    $cm1->targets(['A3'],
        timestamps   => 'once',
        requirements => ['A1','A2'],
        handler => sub {
            ($t_name,$t_base,$t_ext,$youngest_req,$oldest)=@_;
            have_made('A3');
            sleep 1;
            1;
        },
    ),
"declare target A3 list style");

ok(my $A1age=$cm1->chainmake('A1'),'chainmake A1 with cm1');
made_ok('A1','made A1');
ok($t_name eq 'A1','$t_name was A1');
ok(!$oldest,'oldest was undef');
ok(!$youngest_req,'youngest_req was undef');

ok(my $A2age=$cm1->chainmake('A2'),'chainmake A2 with cm1');
made_ok('A2','made A2');
ok($t_name eq 'A2','$t_name was A2');
ok(!$oldest,'oldest was undef');
ok($youngest_req == $A1age,'youngest_req was A1\'s age');

ok(my $A2age2=$cm1->chainmake('A2'),'chainmake A2 with cm1');
made_ok('','made nothing');
ok($A2age == $A2age2,'same age as before');

ok($cm1->delete_timestamp('A1'),'delete timestamp A1');

ok($A2age2=$cm1->chainmake('A2'),'chainmake A2 with cm1');
made_ok('A1A2','made A1A2');
ok($t_name eq 'A2','$t_name was A2');
ok($oldest == $A2age,'oldest was A2\'s age');
ok($youngest_req > $A2age,'youngest_req was bigger than A2\'s old age');





ok(my $A3age=$cm1->chainmake('A3'),'chainmake A3 with cm1');
made_ok('A3','made A3');
ok($t_name eq 'A3','$t_name was A3');
ok(!$oldest,'oldest was undef');
ok($youngest_req == $A2age2,'youngest_req was A2\'s last age');


ok($cm1->unlink_timestamps(),'clean timestamps');
