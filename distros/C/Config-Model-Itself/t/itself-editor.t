# -*- cperl -*-

use Test::More ;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Config::Model::Itself ;

use Tk ;
use Path::Tiny;
use Config::Model::Itself::TkEditUI;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use Test::Memory::Cycle;

use warnings;
use strict;
$File::Copy::Recursive::DirPerms = 0755;


my ($meta_model, $trace, $args) = init_test('show','interactive');

note("You can play with the widget if you run the test with '--show' parameter");

my $wr_test = setup_test_dir ;
my $wr_conf1 = $wr_test->child("wr_conf1");
my $wr_lib = $wr_test->child("lib");
my $wr_model1 = $wr_lib->child("wr_model1");

use lib "wr_root/itself-editor/lib";

{
    no warnings "redefine" ;
    sub Tk::Error {
        my ($widget,$error,@locations) = @_;
        die $error ;
    }
}

$wr_conf1->mkpath;
$wr_model1->mkpath;
$wr_conf1->child("etc/ssh")->mkpath;


dircopy('data',$wr_model1->stringify) || die "cannot copy model data:$!" ;

# cannot use $meta_model as the model dir are different
my $model = Config::Model->new(
    model_dir => $wr_model1->child("models")->relative($wr_lib)->stringify
) ;
ok(1,"loaded Master model") ;

# check that Master Model can be loaded by Config::Model
my $inst1 = $model->instance (
    root_class_name   => 'MasterModel',
    instance_name     => 'test_orig',
    root_dir          => $wr_conf1->stringify,
);
ok($inst1,"created master_model instance") ;

my $root1 = $inst1->config_root ;
my @elt1 = $root1->get_element_name ;

$root1->load("a_string=toto lot_of_checklist macro=AD - "
             ."! warped_values macro=C where_is_element=get_element "
             ."                get_element=m_value_element m_value=Cv") ;
ok($inst1,"loaded some data in master_model instance") ;

# do search for the models created in this test
my $meta_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'itself_instance',
);
ok( $meta_inst, "Read Itself::Model and created instance" );

$meta_inst->initial_load_start ;

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(
    model_object => $meta_root,
    cm_lib_dir => $wr_model1->stringify,
) ;

my $map = $rw_obj->read_all(
    root_model => 'MasterModel',
    legacy     => 'ignore',
);
$meta_inst->initial_load_stop ;

ok(1,"Read all models in data dir") ;


SKIP: {

    my $mw = eval { MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",8 if $@;

    $mw->withdraw ;

    my $write_sub = sub {
        $rw_obj->write_all();
    } ;

    my $cmu = $mw->ConfigModelEditUI (
        -instance => $meta_inst,
        -root_dir => $wr_conf1->stringify,
        -cm_lib_dir => $wr_model1->relative($wr_lib)->stringify ,
        -store_sub => $write_sub,
        -model_name => 'MasterModel',
    ) ;
    my $delay = 500 ;

    my $tktree= $cmu->Subwidget('tree') ;
    my $mgr   = $cmu->Subwidget('multi_mgr') ;

    my @test = (
        view                 => sub { $cmu->create_element_widget('view','itself_instance.class');},
        open_class           => sub { $tktree->open('itself_instance.class');1;},
        open_instance        => sub{$tktree->open('itself_instance.class.MasterModel');1;},
        # save step is mandatory to avoid interaction
        save                 => sub { $cmu -> save ; 1;},
        'open test window'   => sub { $cmu -> test_model ; },
        'reopen test window' => sub { $cmu -> test_model ; },
        exit                 => sub { $cmu->quit ; 1;}
    );

    unless ($args->{show} || $args->{interactive}) {
        my $step = 0;

        # build a FILO queue of test subs
        my $oldsub ;
        while (@test) {
            # iterate through test list in reverse order
            my $t = pop @test ;
            my $k = pop @test ;
            my $next_sub = $oldsub ;
            my $s = sub {
                my $res = &$t;
                ok($res,"Tk UI step ".$step++." $k done");
                $mw->after($delay, $next_sub) if defined $next_sub;
            };
            $oldsub = $s ;
        }

        $mw->after($delay, $oldsub) ; # will launch first test
    }

    ok(1,"window launched") ;

    MainLoop ;                  # Tk's
}

note("testing memory cycles. Please wait...");
memory_cycle_ok($meta_model,"memory cycles");

done_testing;


