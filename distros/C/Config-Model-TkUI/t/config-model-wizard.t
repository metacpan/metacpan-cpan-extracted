# -*- cperl -*-


use ExtUtils::testlib;
use Test::More ;
use Tk;
use Config::Model::TkUI;
use Config::Model ;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Config::Model::Value ;
use Test::Memory::Cycle;

use strict;
use warnings;
use lib 't/lib';

my ($model, $trace, $args) = init_test('show');

note("You can play with the widget if you run the test with 's' argument");

my $wr_root = setup_test_dir;

my $inst = $model->instance (
    root_class_name => 'Master',
    instance_name => 'test1',
    root_dir   => $wr_root,
);

ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

$Config::Model::Value::nowarning=1;

my $step = qq!
warn_unless=qwerty
std_id:ab X=Bv -
std_id:ab2 -
std_id:bc X=Av -
std_id:"a b" X=Av -
std_id:"a b.c" X=Av -
tree_macro=mXY
a_string="toto tata"
a_long_string="a very long string with\nembedded return"
hash_a:toto=toto_value
hash_a:titi=titi_value
hash_a:"ti ti"="ti ti value"
ordered_hash:z=1
ordered_hash:y=2
ordered_hash:x=3
ordered_hash_of_nodes:N1 X=Av -
ordered_hash_of_nodes:N2 X=Bv -
lista=a,b,c,d
olist:0 X=Av -
olist:1 X=Bv -
my_ref_check_list=toto 
my_reference="titi"
my_plain_check_list=AA,AC
warp warp2 aa2="foo bar"
!;

ok( $root->load( step => $step ), "set up data in tree");

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($root) ;

my $toto ;


# TBD eval this and skip test in case of failure.
SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 if $@;

    $mw->withdraw ;

    my $cmw = $mw->ConfigModelWizard (-root => $root, 
                                      -store_cb => sub{},
                                  ) ;

    my $delay = 1000 ;

    sub inc_d { $delay += 500 } ;

    my @test ;
    foreach (1 .. 4 ) {
        push @test, sub {$cmw->{keep_wiz_editor} = 0 ; $cmw->{wizard}->go_forward; } ;
    }
    foreach (1 .. 2 ) {
        push @test, sub {$cmw->{keep_wiz_editor} = 0 ; $cmw->{wizard}->go_backward;} ;
    }
    # no problem if too many subs are defined: programs will exit
    foreach (1 .. 100 ) {
        push @test, sub {$cmw->{keep_wiz_editor} = 0 ; $cmw->{wizard}->go_forward; } ;
    }


    unless ($args->{show}) {
        foreach my $t (@test) {
            $mw->after($delay, $t);
            inc_d ;
        }
    }

    $cmw->start_wizard() ;

    ok(1,"wizard done") ;

    memory_cycle_ok($cmw, "memory cycle");
}

done_testing;
