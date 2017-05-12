#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/tools/main.pm,v 1.10 1999/10/24 13:48:51 loic Exp $
#
# 
#
# The Main classes provide a simple method to handle program options 
# from the command line (@ARGV). It uses class hierarchy to provide:
#   . Options inheritance: all the programs want to have options
#     like -verbose, -fake etc. In addition all the packages used by
#     more than one program can be/want to be controled by command line options
#     (-heuristics is used by the FURL.pm package). The problem faced
#     with traditional `getopt' method is that the main program must be
#     aware of all the options of all the packages. The ideal situation
#     is that each package handle the options that concern it and leave
#     the other untouched. That is exactly what option inheritance allow.
#   . Option propagation: When a program calls another one it wants to give
#     it part of his options. The most common case is -verbose flag that
#     need to be forwarded to all the commands run from the main command.
#     Option propagation is a function that rebuild the command line
#     arguments so that they can be given in argument to another command.
#   
#
package Catalog::tools::main;
use strict;

use Catalog::tools::tools;
use Getopt::Long;
use File::Basename;

#
# Build a Main object.
#  
# options - hash table that is a list of the options recognized by
#           Main and in the syntax used by the GetOptions function
#           see the mygetopt::Long package for more information.
# short_usage - hash table mapping option name to a short description,
#               something like '-noheuristics -heuristics'. Not really
#               a description.
# long_usage - hash table mapping option name to a human readable
#              explanation of the option.
# default - hash table mapping option name to the default value for the 
#           option. 
# order - a list of the options in order. The usage command use this
#         list to show the options in order.
# 
sub new {
    my($type) = shift;
    my($self) = {};

    bless($self, $type);

    $self->{'options'} = {};
    $self->{'short_usage'} = {};
    $self->{'long_usage'} = {};
    $self->{'default'} = {};
    $self->{'order'} = [];
    #
    # Set default options
    #
    $self->initoptions();
    #
    # Override with caller choice
    #
    $self->initialize(@_);
    #
    # Parse the collected options
    #
    $self->getopt();

    dbg("running $0\n", "normal");
    return $self;
}

#
# Set the options available to everyone
#
sub initoptions {
    my($self) = shift;

    $self->initialize(
      ['help', '-help', 'get usage message'],
      ['fake', '-fake', 'do not actually perform any actions'],
      ['error_stack', '-error_stack', 'whenever an error occur shows the full stack'],
      ['verbose=s', '-verbose {normal|high|...}', 
       '-verbose  verbosity level (default normal),
		.*       everything,
		normal   print messages reporting the progression,
		high     huge output for debugging'],
      ['info', '-info', 'all informations about options'],
    );
}

#
# Build a usage string, display it and die.
#
sub usage {
    my($self, $message) = @_;
    my($command) = basename($0);

    my($short_usage);
    my($long_usage);
    my($order) = $self->{'order'};
    my($option);
    foreach $option (reverse(@$order)) {
	$short_usage .= "$self->{'short_usage'}->{$option}";
	$long_usage .= "$self->{'long_usage'}->{$option}";
    }

    die "$message\nusage: $command $short_usage\n$long_usage";
}

#
# Build a synopsis line for manual entries
#
sub synopsis {
    my($self, $message) = @_;
    my($command) = basename($0);

    my($synopsis);
    my($order) = $self->{'order'};
    my($option);
    foreach $option (reverse(@$order)) {
	$synopsis .= "$self->{'short_usage'}->{$option}";
    }

    return "$command $synopsis";
}

#
# Build a option table, display it and die.
#
sub info {
    my($self) = @_;
    my($command) = basename($0);

    my($info);
    my($order) = $self->{'order'};
    $info .= "[ ";
    my($option);
    foreach $option (reverse(@$order)) {
	next if($option eq "info");
	my($flag) = $option;
	$flag =~ s/^(\w+).*/$1/;
	my($value);
	eval "\$value = \$::opt_$flag";
	$info .= "[ '$option', '$self->{'short_usage'}->{$option}', '$self->{'explain'}->{$option}',  '$value' ],";
    }
    $info .= " [ 'ARGV', '@ARGV' ] ]";

    print "$info\n";
    exit(0);
}

#
# Analyse the options in @ARGV according to the specifications in
# 'options' variable.
#
sub getopt {
    my($self) = shift;

    return if($self->{'getopt_done'});

    my($options) = $self->{'options'};

    #
    # Default is to lock files (oread, owrite, readfile, writefile...)
    #
    #   $self->{default}->{'lock'} = 1;

    #
    # Default is to get normal verbosity
    #
    $self->{default}->{'verbose'} = 'normal';
    $::opt_verbose = 'normal';

    if (!GetOptions($self->{'linkage'}, keys(%$options)) || $::opt_help) {
	$self->usage();
    }

    $self->info() if($::opt_info);

    $self->{'getopt_done'} = 'yes';
}

#
# Analyze the options specs given in argument.
# The specs are a table with entries containing three fields:
#   . option description for GetOptions (see mygetopt::Long)
#   . short description
#   . long description
#
sub initialize {
    my($self) = shift;

    my($spec);
    my($order) = $self->{'order'};
    foreach $spec (@_) {
	my($option, $flags, $explain) = @$spec;
	my($name) = $option;
	$name =~ s/[=!].*//;
	my($var);
	eval "\$var = \\\$::opt_$name";
	$self->{'linkage'}->{$name} = $var;
	$self->{'options'}->{$option} = 1;
	$self->{'short_usage'}->{$option} = "[$flags] ";
	$self->{'long_usage'}->{$option} = "\t$flags\t$explain\n";
	$self->{'explain'}->{$option} = "$explain";
	push(@$order, $option) if(!grep($_ eq $option, @$order));
    }
}

#
# Build an arg string suitable for running a new command.
# Only the options of the package given in argument are analyzed.
# Only the options in @valid are returned.
#
sub options {
    my($self, $package, @valid) = @_;

    my($my_options) = "${package}::my_options";
    my(@options);
    my($options);
    foreach $options ($self->${my_options}(@valid)) {
#	print "options = $options\n";
	if(!grep($_ eq $options, @options)) {
	    push(@options, $options);
	}
    }
    return "@options";
}

#
# Each package should define this function to call extract_options
# in a given order.
#
sub my_options {
    my($self, @valid) = @_;

    return $self->extract_options('help', 'fake', 'base', 'error_stack', 'verbose', 'info', 'time', @valid);
}

#
# Backbone of options. Make the string rebuilding the options given
# in @ARGV initialy.
#
sub extract_options {
    my($self, @valid) = @_;
    
    my($options) = $self->{'options'};
    my($option);
    my($tmp);
    foreach $option (keys(%$options)) {
	my($flag) = $option =~ /^(.+?)\b.*/;
	next if(!grep($_ eq $flag, @valid));
	my($var) = "::opt_$flag";
	
	if(defined($$var)) {
	    if($option =~ /!$/) {
		if($$var) {
		    $tmp .= "-$flag ";
		} else {
		    $tmp .= "-no$flag ";
		}
	    } elsif($option =~ /=[is]$/) {
		if($$var ne $self->{'default'}->{$flag}) {
		    $tmp .= "-$flag '$$var' ";
		}
	    } else {
		$tmp .= "-$flag ";
	    }
	}
    }
    return $tmp;
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
