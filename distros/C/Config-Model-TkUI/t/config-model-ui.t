# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Log::Log4perl;
use Tk;
use Config::Model::TkUI;
use Config::Model 2.137;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use strict;
use warnings;

use lib 't/lib';

$::_use_log4perl_to_warn = 1;

sub test_all {
    my ($mw, $delay,$test_ref) = @_ ;
    my $test = shift @$test_ref ;
    $test->() ;
    $mw->after($delay, sub { test_all($mw, $delay,$test_ref) } ) if @$test_ref;
}

my ($model, $trace, $args) = init_test('show');

note("You can play with the widget if you run this test with '--show' option");

my $wr_root = setup_test_dir;
my $cmu ;

my $inst = $model->instance (
    root_class_name => 'Master',
    instance_name => 'test1',
    root_dir   => $wr_root,
    on_message_cb => sub { $cmu->show_message(@_) ;}
);

ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = qq!
#"class comment\nbig\nreally big"
std_id#"std_id comment"
std_id:ab X=Bv -
std_id:ab2 -
std_id:bc X=Av -
std_id:"a b" X=Av -
std_id:"a b.c" X=Av -
tree_macro=mXY#"big lever here"
a_string="utf8 smiley \x{263A}"
a_long_string="a very long string with\nembedded return"
hash_a:toto=toto_value
hash_a:toto#"index comment"
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

$step .= '! a_very_long_string=~"s/\s*general\s*/ /ig"';

ok( $root->load( step => $step ),
  "set up data in tree");

my $load_fix = "a_mandatory_string=foo1 another_mandatory_string=foo2 
                ordered_hash_of_mandatory:foo=hashfoo 
                warp a_string=warpfoo a_long_string=longfoo another_string=anotherfoo -
                slave_y a_string=slave_y_foo a_long_string=sylongfoo another_string=sy_anotherfoo" ;

#$root->load(step => "tree_macro=XZ") ;

$root->fetch_element('ordered_hash_of_mandatory')->fetch_with_id('foo') ;

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($root) ;

# eval this and skip test in case of failure.
SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 unless $mw;

    $mw->withdraw ;

    $cmu = $mw->ConfigModelUI (-instance => $inst ) ;

    my $delay = 200 ;

    my $tktree= $cmu->Subwidget('tree') ;
    my $mgr   = $cmu->Subwidget('multi_mgr') ;
    my $widget ; # ugly global variable. Use with care
    my $idx = 1 ;

    my @test = (
	 sub { $cmu->reload ; ok(1,"forced test: reload") } ,
	) ;

    if (not $args->{show}) {
        my $log_tester = Test::Log::Log4perl->get_logger("User");

        push @test,
            sub { $cmu->{elt_filter_value} = 'aa2'; $cmu->reload ;},
            sub { $cmu->{elt_filter_value} = 'bb2'; $cmu->reload ;},
            sub { $cmu->{elt_filter_value} = '[ab]+2'; $cmu->reload ;},
            sub { $cmu->{elt_filter_value} = ''; $cmu->reload ;},
            sub { $cmu->create_element_widget('edit','test1'); ok(1,"test ".$idx++)},
            sub { $inst->show_message("Hello World")},
            sub { $cmu->force_element_display($root->grab('std_id:dd DX')) ; ok(1,"test ".$idx++)},
            sub { $cmu->edit_copy('test1.std_id'); ok(1,"test ".$idx++)},
            sub { $cmu->force_element_display($root->grab('hash_a:titi')) ; ok(1,"test grab 'hash_a:titi' ".$idx++)},
            sub { $cmu->edit_copy('test1.hash_a.titi'); ok(1,"test edit_copy test1.hash_a.titi".$idx++)},
            sub { $cmu->create_element_widget('view','test1'); ok(1,"test view test1 ".$idx++)},
            sub { $tktree->open('test1.lista') ; ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.std_id');; ok(1,"test ".$idx++)},
            sub { $cmu->{editor}->add_entry('e'); ok(1,"test ".$idx++)},
            sub { $tktree->open('test1.std_id') ; ok(1,"test ".$idx++)},
            sub { $cmu->reload; ok(1,"test reload ".$idx++)} ,
            sub { $cmu->create_element_widget('view','test1.std_id'); ok(1,"test ".$idx++)},
            sub { $inst->show_message("Hello again World")},
            sub { $cmu->create_element_widget('edit','test1.std_id'); ok(1,"test ".$idx++)},
            sub { $tktree->open('test1.std_id.ab') ; ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.std_id.ab.Z'); ok(1,"test ".$idx++)},
            sub { $root->load(step => "std_id:ab Z=Cv") ; $cmu->reload ;; ok(1,"test load ".$idx++)},
            sub { $tktree->open('test1.std_id.ab') ; ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.std_id.ab.DX'); ok(1,"test ".$idx++)},
            sub { $root->load(step => "std_id:ab3") ; $cmu->reload ;; ok(1,"test load ".$idx++)} ,
            sub { $cmu->create_element_widget('view','test1.a_very_long_string'); ok(1,"test diff view ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.string_with_def'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.string_with_def'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.a_long_string'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.a_long_string'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.int_v'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.int_v'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.my_plain_check_list'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.my_plain_check_list'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.my_ref_check_list'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.my_ref_check_list'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('view','test1.my_reference'); ok(1,"test ".$idx++)},
            sub { $cmu->create_element_widget('edit','test1.my_reference'); ok(1,"test ".$idx++)};

        push @test, sub {
            my $name = "check_list_with_upstream_default";
            my $clwud = $root->grab(step => $name) ;
            $cmu->force_element_display($clwud);
            ok(1,"show check list with upstream value ".$idx++)
        };
        push @test, sub {
            my $name = "check_list_with_upstream_default";
            my $clwud = $root->grab(step => $name) ;
            my @set = $clwud->get_choice; $clwud->check(@set);
            $cmu->force_element_display($clwud);
            ok(1,"test check list with upstream data ".$idx++)
        };

        push @test,
            sub { $root->load(step => "ordered_checklist=A,Z,G") ; $cmu->reload ;; ok(1,"test load ".$idx++)} ,
            sub { $widget = $cmu->create_element_widget('edit','test1.ordered_checklist'); ok(1,"test ".$idx++)},
            sub { $widget->Subwidget('notebook')->raise('order') ;; ok(1,"test notebook raise 1 ".$idx++)},
            sub { $widget->Subwidget('notebook')->raise('order') ;; ok(1,"test notebook raise 2 ".$idx++)},
            sub { $widget->{order_list}->selectionSet(1,1) ;; ok(1,"test selectionSet ".$idx++)}, # Z
            sub { $widget->move_selected_down ; ok(1,"test move_selected_down ".$idx++)},
            # cannot save with pending errors sub { $cmu->save(); ok(1,"test save 1 ".$idx++)},
            sub {
                #for ($cmu->children) { $_->destroy if $_->name =~ /dialog/i; } ;
                $root->load($load_fix);; ok(1,"test load_fix ".$idx++)
            },
            sub { $cmu->save(); ok(1,"test save 2 ".$idx++)},
            sub {
                $cmu->create_element_widget('edit','test1.always_warn');
                $cmu -> force_element_display($root->grab('always_warn')) ;
                ok(1,"test always_warn ".$idx++);
            };

        # warn test, 3 warnings: load, fetch for hlist, fetch for editor
        push @test, sub {
            Test::Log::Log4perl->start(ignore_priority => "info");
            $log_tester->warn(qr/always/);
            $root->load("always_warn=foo") ;
            $cmu->reload ;
            Test::Log::Log4perl->end("always_warn logged a warning".$idx++) ;
        };

        push @test, sub {
            $root->load('always_warn~') ;
            $cmu->reload ;
            ok(1,"test remove always_warn ".$idx++)
        };

        push @test, sub {
            $cmu->create_element_widget('edit','test1.warn_unless');
            $cmu -> force_element_display($root->grab('warn_unless')) ;
            ok(1,"test warn_unless ".$idx++);
        };

        push @test, sub {
            Test::Log::Log4perl->start(ignore_priority => "info");
            $log_tester->warn(qr/warn_unless/);
            $root->load("warn_unless=bar") ;
            $cmu->reload ;
            Test::Log::Log4perl->end("warn_unless logged a warning".$idx++) ;
        };

        push @test,
            sub { $root->load('warn_unless=foo2') ; $cmu->reload ;; ok(1,"test fix warn_unless ".$idx++)},
            sub { $cmu ->show_changes ; ok(1,"test show_changes ".$idx++)} ;

        push @test,
            # test behavior when pasting data in tktree
            # the 3 first items show an error message in TkUI message widget (bottom of widget)
            map {               ## no critic (ProhibitComplexMappings)
                my $elt = $_;
                sub {
                    $cmu->on_cut_buffer_dump("test1.$elt", "test cut buffer dump string");
                    ok(1,"test cut_buffer_dump on element $elt ".$idx++)
                };
            } qw/a_uniline olist ordered_checklist a_uniline lista/ ;

        push @test,
            sub { $cmu->{hide_empty_values} = 1 ; ok(1,"test hide empty value ".$idx++); },
            sub { $cmu->{show_only_custom}  = 1 ; ok(1,"test show only custom and hide empty value ".$idx++); },
            sub { $cmu->{hide_empty_values} = 0 ; ok(1,"show empty value ".$idx++); },
            sub { $cmu->{show_only_custom}  = 0 ; ok(1,"disable show only custom values ".$idx++); },

            sub { $mw->destroy; };
    }

    test_all($mw , $delay, \@test) ; 

    ok(1,"window launched") ;

    # $mw->WidgetDump ;
    MainLoop ; # Tk's

}

ok(1,"All tests are done");

done_testing;
