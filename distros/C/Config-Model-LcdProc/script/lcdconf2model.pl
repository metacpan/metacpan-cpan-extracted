#!/usr/bin/perl
#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

# This script uses all the information available in LCDd.conf to create a model
# for LCDd configuration file

# How does this work ?

# The conventions used in LCDd.conf template file are written in a way
# which makes it relatively easy to parse to get all required
# information to build a model.

# All drivers are listed, most parameters have default values and
# legal values written in comments in a uniform way. Hence this file
# (and comments) can be parsed to retrieve the information required to
# create a consistent model for LcdProc configuration. Some useful
# parameters are commented out in LCD.conf. So some processing is
# required to be able to create a model with these commented
# parameters.  See below for this processing.

# This script performs the following tasks:
# 1/ check whether generating the model is necessary (or possible)
# 2/ pre-process LCDd.conf template
# 3/ parse the new LCDd.conf template
# 4/ mine the information there and translate them in a format suitable to create
#    a model. Comments are used to provide default and legal values and also to provide
#    user documentation
# 5/ Write the resulting LCDd model

use Config::Model 2.076;
use Config::Model::Itself 2.005;    # to create the model

use 5.010;
use Path::Tiny;
use Getopt::Long;

my $verbose = 0;
my $show_model = 0;
my $force = 0;
my $source = "lcdproc/LCDd.conf" ;

my $result = GetOptions (
    "verbose"  => \$verbose,
    "model" => \$show_model,
    "force" => \$force,
    "file=s" => \$source,
);

die "Unknown option. Expected -verbose, -force, -file  or -model" unless $result ;

########################
#
# Step 1: Check whether generating lcdproc model is necessary.

my $target = "lib/Config/Model/models/LCDd.pl";
my $script = "script/lcdconf2model.pl";

if (-e $target and -M $target < -M $script and -M $target < -M $source) {
    say "LcdProc model is up to date";
    exit unless $force;
}

say "Building lcdproc model from upstream LCDd.conf file $source" ;

###########################
#
# Step 2: pre-process LCDd.conf (INI file)

# Here's the LCDd.conf pre-processing mentioned above

# read LCDd.conf
my @lines    = path($source)->lines;

# un-comment commented parameters and put value as default value
foreach my $line (@lines) {
    $line =~ s/^#(\w+)=(.*)/# [default: $2]\n$1=$2/;
}

# write pre-processed files
my $path = path('.');
my $tmp = $path->child('tmp');
$tmp->mkpath;
$tmp->child('LCDd.conf')->spew(@lines);

###########################
#
# Step 3: parse LCDd.conf (INI file)

# Problem: comments must also be retrieved and associated with INI
# class and parameters

# Fortunately, Config::Model::Backend::IniFile can already perform this
# task.

# On the other hand, Config::Model::Backend::IniFile must store its
# values in a configuration tree. A model suitable for LCDd.conf that
# accepts any INI class and any INI parameter must be created

# Dump stack trace in case of error
Config::Model::Exception::Any->Trace(1) ;

# one model to rule them all
my $model = Config::Model->new();

# The model for pre-precessed LCDd.conf must be made of 2 classes:
# - the main config class that contains INI class names (named Dummy here)
# - the child class that contains data from a elements of the INI
#   classes (named Dummy::Class)

# For techinical reason, the lower class (Dummy::Class) must be
# created first.

# The class is used to store any parameter found in an INI class
$model->create_config_class(
    name   => 'Dummy::Class',
    accept => [
        'Hello|GoodBye|key' => {
            type => 'list',
            cargo => { qw/type  leaf value_type uniline/}
        },
        '.*' => {
            type => 'leaf',
            value_type => 'uniline'
        }
    ],
);

# This class contains any INI class, and use Dummy::Class to hold parameters.
$model->create_config_class(
    name   => 'Dummy',
    accept => [
        '.*' => {
            type => 'node',
            config_class_name => 'Dummy::Class'
        }
    ],
    read_config => [{
        backend => 'IniFile',
        config_dir => 'tmp', # created above
        file => 'LCDd.conf'
    }]
);

# Now the dummy configuration class is created. Let's create a
# configuration tree to store the data from LCDd.conf

my $dummy = $model->instance(
    instance_name   => 'dummy',
    root_class_name => 'Dummy',
)-> config_root;

##############################################
#
# Step 4: Mine the LCDd.conf information and create a model
#

# Create a meta tree that will contain LCDd model
my $meta_root = $model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'meta_model',
) -> config_root;

# Create LCDd configuration class and store the first comment from LCDd.conf as
# class description
$meta_root->grab("class:LCDd class_description")->store( $dummy->annotation );

# append my own text
my $extra_description = "Model information was extracted from /etc/LCDd.conf";
$meta_root->load(qq!class:LCDd class_description.="\n\n$extra_description"!);

# add legal stuff
$meta_root->load( qq!
    class:LCDd
        copyright:0="2011-2017, Dominique Dumont"
        copyright:1="1999-2017, William Ferrell and others"
        license="GPL-2"
!
);

# add INI backend (So LCDd model will be able to read INI files)
$meta_root->load( qq!
    class:LCDd
        read_config:0
            backend=ini_file
            config_dir="/etc"
            file="LCDd.conf"
!
);

# Note: all the load calls above could be done in one call. They are
# split in several class to clarify what's going on.

# Now, let's use the information retrieved by /etc/LCDd.conf
# and stored in Dummy tree.
# @ini_classes array contains all INI classes found in LCDd.conf,
# make sure to put server in first, and sort the rest
my @ini_classes = sort grep { $_ ne 'server'} $dummy->get_element_name;
unshift @ini_classes, 'server' ;

# Now before actually mining LCDd.conf information, we must prepare
# subs to handle them. This is done using a dispatch table.
my %dispatch;

# first create the default case which will be used for most parameters
# This subs is passed: the INI class name, the INI parameter name
# the comment attached to the parameter, the INI value, and an optional
# value type
$dispatch{_default_} = sub {
    my ( $ini_class, $ini_param, $info_r, $ini_v, $value_type ) = @_;

    # prepare a string to create the ini_class model
    my $load = qq!class:"$ini_class" element:$ini_param type=leaf !;
    $value_type ||= 'uniline';

    # get semantic information from comment (written between square brackets)
    my $square_model = '';

    my $square_rexp = '\[(\s*\w+\s*:[^\]]*)\]';
    if ($$info_r =~ /$square_rexp/s) {
        my $info = $1 ;
        say "class $ini_class element $ini_param info: '$info'" if $verbose;
        $$info_r =~ s/$square_rexp//gs; # remove all remaining square_rexp
        $square_model .= ' '. info_to_model($info,$value_type, $info_r) ;
    }

    unless ($square_model) {
        # or use the value found in INI file as default
        $ini_v =~ s/^"//g;
        $ini_v =~ s/"$//g;
        $square_model .= qq! value_type=$value_type!;
        $square_model .= qq! default="$ini_v"! if length($ini_v);
    }

    # get model information from comment (written between curly brackets)
    my $curly_model = '';
    my $curly_rexp = '{%(\s*\w+.*?)%}' ;
    while ($$info_r =~ /$curly_rexp/s) {
        $curly_model = $1 ;
        say "class $ini_class element $ini_param model snippet: '$curly_model'"
            if $verbose;
        $$info_r =~ s/$curly_rexp//s;
    }

    # return a string containing model specifications
    # spec in curly model may override spec in square model
    return $load . $square_model . $curly_model ;
};

# Now let's take care of the special cases. This one deals with "Driver"
# parameter found in INI [server] class
$dispatch{"LCDd::server"}{Driver} = sub {
    my ( $class, $elt, $info_r, $ini_v ) = @_;
    my $load = qq!class:"$class" element:$elt type=check_list !;
    my @drivers = split /\W+/, $$info_r;
    while ( @drivers and ( shift @drivers ) !~ /supported/ ) { }
    $load .= 'choice=' . join( ',', @drivers ) . ' ';

    #say $load; exit;
    return $load;
};

# Ensure that DriverPath ends with a slash by adding a match clause
$dispatch{"LCDd::server"}{DriverPath} = sub {
    return $dispatch{_default_}->( @_ ) . q! match="/$"! ;
};

# like default but ensure that the parameter is integer
$dispatch{"LCDd::server"}{WaitTime}
    = $dispatch{"LCDd::server"}{ReportLevel}
    = $dispatch{"LCDd::picolcd"}{LircFlushThreshold}
    = $dispatch{"LCDd::server"}{Port}
    = sub {
        my ( $class, $elt, $info_r, $ini_v ) = @_;
        return $dispatch{_default_}->( @_, 'integer' );
    };

# special dispatch case
my %override ;

# Handle display content
$override{"LCDd::server"}{GoodBye}
    = $override{"LCDd::server"}{Hello}
    = $override{"LCDd::linux_input"}{key}
    = sub {
        my ( $class, $elt ) = @_;
        my $ret = qq( class:"$class" element:$elt type=list ) ;
        $ret .= 'cargo type=leaf value_type=uniline';
        return $ret ;
    };

# Now really mine LCDd.conf information using Dummy tree

# loop over all INI classes
foreach my $ini_class (@ini_classes) {
    say "Handling INI class $ini_class" if $verbose;
    my $ini_obj = $dummy->grab($ini_class);
    my $config_class   = "LCDd::$ini_class";

    # create config class in case there's no parameter in INI file
    $meta_root->load(qq!class:"LCDd::$ini_class" class_description="generated from LCDd.conf"!);

    # loop over all INI parameters and create LCDd::$ini_class elements
    foreach my $ini_param ( $ini_obj->get_element_name ) {
        my ($model_spec) ;

        # test for override
        if (my $sub = $override{$config_class}{$ini_param}) {
            # runs the override sub to get the model string
            $model_spec = $sub->($config_class, $ini_param) ;
        }
        else {
            # retrieve the correct sub from the orveride or dispatch table
            my $sub = $dispatch{$config_class}{$ini_param} || $dispatch{_default_};

            # retrieve INI value
            my $ini_v    = $ini_obj->grab_value($ini_param);

            # retrieve INI comment attached to $ini_param
            my $ini_comment = $ini_obj->grab($ini_param)->annotation;

            # runs the sub to get the model string
            $model_spec = $sub->($config_class, $ini_param, \$ini_comment, $ini_v) ;

            # escape embedded quotes
            $ini_comment =~ s/"/\\"/g;
            $ini_comment =~ s/\n*$//;
            $model_spec .= qq! description="$ini_comment"! if length($ini_comment);
        }

        # show the model without the doc (too verbose)
        say "load -> $model_spec" if $show_model ;

        # load class specification in model
        $meta_root->load($model_spec);
    }

    # Now create a an $ini_class element in LCDd class (to link LCDd
    # class and LCDd::$ini_class)
    my $driver_class_spec = qq!
        class:LCDd
            element:$ini_class
    ! ;

    if ( $ini_class eq 'server' or $ini_class eq 'menu' ) {
        $driver_class_spec .= qq!
            type=node
            config_class_name="LCDd::$ini_class"
        ! ;
    }
    else {
        # Arrange a driver class is shown only if the driver was selected
        # in the [server] class
        $driver_class_spec .= qq!
            type=warped_node
            config_class_name="LCDd::$ini_class"
            level=hidden
            warp
              follow:selected="- server Driver"
              rules:"\$selected.is_set('$ini_class')"
                level=normal
        !;
    }
    $meta_root->load($driver_class_spec);
}

######################
#
# Step 5: write the model


# Itself constructor returns an object to read or write the data
# structure containing the model to be edited. force_write is required
# because writer object, being created *after* loading the model in the
# instance, is not aware of these changes.
my $rw_obj = Config::Model::Itself->new(
    model_object => $meta_root,
    cm_lib_dir => 'lib/Config/Model/',
    force_write => 1,
);

say "Writing all models in file (please wait)";
$rw_obj->write_all;

# mop up
$tmp->remove_tree;

say "Done";

# this function extracts info specified between square brackets and returns a model snippet
sub info_to_model {
    my ($info,$value_type, $info_r) = @_ ;

    $info =~ s/\s+//g;
    my @model ;

    # legal needs to be parsed first to setup value_type first
    my %info = map { split /[:=]/,$_ ,2 ; } split /;/,$info ;

    # use this semantic information to better specify the parameter
    if (my $legal = delete $info{legal} || '') {
        if ( $legal =~ /^([\d.]*)-([\d.]*)$/ or $legal =~ /^>([\d.]+)$/ ) {
            my $bounds = '';
            $bounds.= "min=$1 " if defined $1 and length($1);
            $bounds.= "max=$2 " if defined $2 and length($2);
            my $vt = "value_type=";
            $vt .= $bounds =~ m/\./ ? 'number ' : 'integer ';
            push @model, $vt.$bounds;
        }
        elsif ($legal =~ /^(on,off|off,on)$/ ) {
            push @model, "value_type=boolean write_as=off,on"
        }
        elsif ($legal =~ /^(yes,no|no,yes)$/ ) {
            push @model, "value_type=boolean write_as=no,yes"
        }
        elsif ($legal =~ /^([\w\,]+)$/       ) {
            push @model, "value_type=enum choice=$1"
        }
        else{
            # push back $legal info if no model snippet could be extracted
            say "note: unhandled legal  spec: '$legal'. Sending it back to doc";
            push @model, "value_type=$value_type ";
            $$info_r .= "legal: $legal "
        }
    }
    else {
        push @model, "value_type=$value_type ";
    } ;

    foreach my $k (keys %info) {
        my $v = $info{$k} ;
        die "Undefined value. Something is wrong in info '$info'" unless defined $v ;
        $v = '"'.$v.'"' unless $v=~/^"/ ;

        if ($k =~ /default/ ) {
            # specify upstream default value if it was found in the comment
            push @model ,qq!upstream_default=$v! if length($v);
        }
        elsif ($k =~ /assert/ ) {
            push @model ,qq!warn_unless:0 code=$v -!;
        }
        else {
            push @model, "$k=$v" ;
        }
    }

    return join(' ',@model) ;
}

