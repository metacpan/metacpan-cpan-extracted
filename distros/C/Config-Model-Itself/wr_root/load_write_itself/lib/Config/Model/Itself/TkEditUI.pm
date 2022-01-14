#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Itself::TkEditUI ;

use strict;
use warnings ;
use Carp ;
use 5.10.0;

use Config::Model::TkUI 1.370;


use base qw/Config::Model::TkUI/;

Construct Tk::Widget 'ConfigModelEditUI';

sub ClassInit {
    my ($class, $mw) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.


    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;

    my $cm_lib_dir    = (delete $args->{-cm_lib_dir})."/models" ;
    my $model_name   = delete $args->{-model_name} || '';
    my $root_dir     = delete $args->{-root_dir} ; # used to test the edited model

    $args->{'-title'} ||= "cme meta edit $model_name" ;

    $cw->SUPER::Populate($args) ;

    my $model_menu = $cw->{my_menu}->cascade(
        -label => 'Model',
        -menuitems => $cw->build_menu() ,
    ) ;

    $cw->{cm_lib_dir} = $cm_lib_dir ;
    $cw->{model_name} = $model_name ;
    $cw->{root_dir} = $root_dir ;

    $cw->show_message("Add a name in Class to create your model") unless $model_name;
}

sub build_menu {
    my $cw = shift ;

    # search for config_dir override
    my $root = $cw->{instance}->config_root;
    my $items = [];
    my %app;

    my $found_app = 0;
    foreach my $app ($root->fetch_element('application')->fetch_all_indexes) {
        push @$items, [ command => "test $app", '-command' => sub{ $cw->test_model($app) }];
        $app{$app} = $root->grab_value("application:$app config_dir");
    }

    push @$items, [ qw/command test -command/, sub{ $cw->test_model }] unless @$items ;

    return $items;
}

sub test_model {
    my $cw = shift ;
    my $app = shift;

    if ( $cw->{instance}->needs_save ) {
        my $answer = $cw->Dialog(
            -title          => "save model before test",
            -text           => "Save model ?",
            -buttons        => [ qw/yes no cancel/, 'show changes' ],
            -default_button => 'yes',
        )->Show;

        if ( $answer eq 'yes' ) {
            $cw->save( sub {$cw->_launch_test($app);});
        }
        elsif ( $answer eq 'no' ) {
            $cw->_launch_test($app);
        }
        elsif ( $answer =~ /show/ ) {
            $cw->show_changes( sub { $cw->test_model } );
        }
    }
    else {
        $cw->_launch_test($app);
    }
}

sub _launch_test {
    my $cw = shift ;
    my $app = shift;

    my $testw =  $cw -> {test_widget} ;
    $testw->destroy if defined $testw and Tk::Exists($testw);

    # need to read test model from where it was written...
    my $model = Config::Model -> new(model_dir => $cw->{cm_lib_dir}) ;

    # keep a reference on this object, otherwise it will vanish at the end of this block.
    $cw->{test_model} =  $model ;

    my %args = ( root_dir => $cw->{root_dir} );
    my $root = $cw->{instance}->config_root;

    $args{root_class_name} = $app ? $root->grab_value("application:$app model") : $cw->{model_name};
    $args{instance_name} = $app ? "test $app" : $cw->{model_name};

    if ($app) {
        $args{application} = $app;
        $args{config_dir} = $root->grab_value("application:$app config_dir");
    }

    my $instance_to_test = $model->instance ( %args ) ;

    $cw -> {test_widget} = $cw->ConfigModelUI (-instance => $instance_to_test, -quit => 'soft') ;
}

1;
