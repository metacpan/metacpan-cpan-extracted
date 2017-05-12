#
#   Copyright (C) 1998, 1999 Loic Dachary
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
# $Header: /cvsroot/Catalog/Catalog/conf/lib.pl,v 1.3 1999/09/07 14:48:03 loic Exp $
#
#
# Perl module configuration utility functions
#
# Parameters in *all* configurations files must be unique.
# If parameter set by environment variable, don't go to interactive mode
# If parameter set by environment variable but checking says it's wrong
#   go to interactive mode
# If USE_DEFAULTS set to 1 only go to interactive mode if checking says
#   that a parameter is wrong
# Providing a directory containing an existing configuration with USE_CONFIG
# or interactively automatically set USE_DEFAULTS.
#
# Usage: 
# in a Makefile.PL
#
# require "lib.pl" 
# #
# # Mapping between configuration label and environment variables
# #
# conf_env(
#	      'infodir' => 'INFODIR',
#	      'cgidir' => 'CGIDIR',
#	      'cgipath' => 'CGIPATH',
#	      'config_dir' => 'CONFIG_DIR',
#	      'use_config' => 'USE_CONFIG',
#	      'htmldir' => 'HTMLDIR',
#	      'htmlpath' => 'HTMLPATH',
#	      'userid' => 'USERID',
#	      'home' => 'MYSQL_HOME',
#	      'user' => 'MYSQL_USER',
#	      'passwd' => 'MYSQL_PASSWORD',
#	      'host' => 'MYSQL_HOST',
#	      'base' => 'MYSQL_BASE',
#	      'port' => 'MYSQL_PORT',
#	      'unix_port' => 'MYSQL_UNIX_PORT',
#	      );
# #
# # Get configuration parameters
# #
# sub install_ask {
#    my($install_conf) = load_config("install.conf");
#
#    getparam('cgidir', $install_conf,
#	    {
#		'prompt' => "
#The absolute pathname of the directory where the cgi-bin
#scripts will be installed",
#                'mandatory' => 1,
#                'directory' => 1,
#                'absolute' => 1,
#    });
#
#	yesno('html', \%h,
#		 {
#		     'prompt' => "
#Do you you want HTML formated documentation ? ",
#		     'yesno' => 1,
#		     'default' => exists($ENV{'DOC_HTML'}) ? $ENV{'DOC_HTML'} : 'yes',
#		 });
#
#    unload_config($install_conf, "install.conf");
# }
# #
# # Possible re-use of an existing configuration
# #
# search_conf();
# #
# # Effective configuration
# #
# install_ask();
# 
use strict;

%::var2env = (
	      'use_config' => 'USE_CONFIG',
	      );

#
# Add more mapping between configuration variables and environment variables
#
sub conf_env {
    my(%conf) = @_;

    %::var2env = ( %::var2env, %conf );

    %::env2var = map { $::var2env{$_} => $_ } keys(%::var2env);
}

#
# Set $h->{$var} to the value provided by the user
# $spec
#   (see $spec of getparam_valid for more)
#   prompt : prompt shown to user
#
# Uses $::var2env to find the environment variable overriding $var value
# 
# If parameter set by environment variable, don't go to interactive mode
# If parameter set by environment variable but checking says it's wrong
#   go to interactive mode
# If USE_DEFAULTS set to 1 only go to interactive mode if checking says
#   that a parameter is wrong
#
sub getparam {
    my($var, $h, $spec) = @_;
    my($env) = $::var2env{$var};
    my($value) = $h->{$var};
    #
    # ENV overrides existing value
    # nothing specified : value = undef
    # empty string specified : value = ''
    # string specified : value = string
    #
    my($from_env) = 0;
    if(defined($env) && exists($ENV{$env})) {
	if($ENV{$env} !~ /^\s*$/o) {
	    $value = $ENV{$env};
	} else {
	    $value = '';
	}
	$from_env = 1;
    } else {
	if(defined($value)) {
	    if($value =~ /^\s*$/o) {
		$value = '';
	    }
	} 
    }

    #
    # If USE_DEFAULTS, only go to interactive mode if an error is
    # detected with default parameters.
    # Otherwise go to interactive mode if value is not set by 
    # the environment.
    #
    my($interactivep);
    my($undefp);
    if($ENV{'USE_DEFAULTS'}) {
	$undefp = 'undef_ok';
	$interactivep = 0;
    } else {
	$undefp = 'undef_notok';
	$interactivep = !$from_env;
    }

    #
    # Go in interactive loop if the value found in the environment 
    # is not valid or no value was found in the environment.
    #
    if(!getparam_valid($var, $value, $undefp, 'silent', $spec) || $interactivep) {
	print $spec->{'prompt'};
	my($ok) = 0;
	do {
	    print "\n(";
	    if(defined($value)) {
		if($value eq '') {
		    print "default is empty string";
		} else {
		    print "default $value";
		}
	    } else {
		print "no default";
	    }
	    print ", type '' for empty string) $var : ";
	    my($tmp);
	    $tmp = <STDIN>;
	    chop($tmp);
	    $tmp =~ s/^\s*(.*?)\s*$/$1/o;
	    $tmp = undef if($tmp eq "''");
	    if(defined($tmp) && $tmp eq '') {
		$ok = getparam_valid($var, $value, 'undef_ok', undef, $spec);
	    } else {
		if($ok = getparam_valid($var, $tmp, 'undef_ok', undef, $spec)) {
		    $value = $tmp;
		}
	    }
	} while(!$ok);
	print "\n";
    }

    $h->{$var} = $value;
}

#
# Sub function of getparam
#
# Perform sanity checks on the value
#                return 1 if value acceptable
#                return 0 if value not acceptable
#
# $var the configuration variable name
# $value the configuration variable value
# $undefp if set to 'undef_ok' $value can be undefined, otherwise
#  if $value is not defined it's wrong
# $silent if set do not print comments
# $spec
#      mandatory if not set : if $value is defined can be null string
#                if set : if $value is defined cannot be null string
#      absolute if set : $value must start with a /
#      directory if set : $value must be a directory
#      directory_comment if set : print if $value not a directory 
#      postamble if set : call with
#                postamble($var, $value, $undefp, $silent, $spec)
#                return 1 if value acceptable
#                return 0 if value not acceptable
#      
#
sub getparam_valid {
    my($var, $value, $undefp, $silent, $spec) = @_;

    if(!defined($value)) {
	if($undefp eq 'undef_ok') {
	    print $spec->{'undef_comment'} if(!$silent);
	    return 1;
	} else {
	    return 0;
	}
    }
    
    if($value eq '') {
	if($spec->{'mandatory'}) {
	    print "this value is mandatory " if(!$silent);
	    print $spec->{'mandatory_comment'} if(!$silent && exists($spec->{'mandatory_comment'}));
	    return 0;
	} else {
	    return 1;
	}
    }

    if($spec->{'absolute'}) {
	if($value !~ m|^/|o) {
	    print "$value must be an absolute path name ";
	    return 0;
	}
    }

    if($spec->{'directory'}) {
	if(! -d $value) {
	    print "$value is not an existing directory " if(!$silent);
	    print $spec->{'directory_comment'} if(!$silent && exists($spec->{'directory_comment'}));
	    return 0;
	}
    }

    if($spec->{'postamble'}) {
	my($func) = $spec->{'postamble'};
	return 0 unless(&$func($var, $value, $undefp, $silent, $spec));
    }

    return 1;
}

#
# Set $h->{$var} to the value provided by the user
# $spec
#   default : if 'yes' default is 1, if 'no' default is 0
#   prompt : prompt shown to user
#   value_yes : set $h->{$var} to this if user says 'yes' (default 1)
#   value_no : set $h->{$var} to this  if user says 'no' (default 0)
#
sub yesno {
    my($var, $h, $spec) = @_;

    my($tmp);
    if($ENV{'USE_DEFAULTS'}) {
	$tmp = $spec->{'default'} eq 'yes' ? 1 : 0;
    } else {
	print $spec->{'prompt'};
	do {
	    print " [$spec->{'default'}] : ";
	    $tmp = <STDIN>;
	    chop($tmp);
	    if($tmp =~ /^yes$/i || $tmp =~ /^y$/i) {
		$tmp = 1;
	    } elsif($tmp =~ /^no$/i || $tmp =~ /^n$/i) {
		$tmp = 0;
	    } elsif($tmp =~ /^\s*$/) {
		$tmp = $spec->{'default'} eq 'yes' ? 1 : 0;
	    } else {
		print "answer yes or no or type return to accept default ";
		$tmp = undef;
	    }
	} while(!defined($tmp));
    }

    my($yes) = defined($spec->{'value_yes'}) ? $spec->{'value_yes'} : 1;
    my($no) = defined($spec->{'value_no'}) ? $spec->{'value_no'} : 0;
    $h->{$var} = $tmp ? $yes : $no;
}

#
# Set $conf->{$cmd} for each @cmds
# with the full path name of the program (uses which)
#
sub locate_cmds {
    my($conf, @cmds) = @_;

    my($cmd);
    foreach $cmd (@cmds) {
	$conf->{$cmd} = undef;
	my($dir);
	foreach $dir (split(/:/, $ENV{'PATH'})) {
	    if(-x "$dir/$cmd" && ! -d "$dir/$cmd") {
		$conf->{$cmd} = "$dir/$cmd";
		last;
	    }
	}
    }
}

#
# Load configuration variables from $config file,
# return a hash pointer $h->{$var} = $value.
# 
# Empty lines and lines beginning with a dash ignored.
#
# A parameter is read if it starts at the beginning of the line
#
sub load_config {
    my($config) = @_;

    my(%record);
    open(FILE, "<$config") || die "cannot open $config for reading : $!";
    while(<FILE>) {
        my($var, $value) = /^([a-z0-9_]+)\s*=\s*(.*?)\s*$/io;
	if(defined($var)) {
	    $record{$var} = $value;
	}
    }
    close(FILE);

    return \%record;
}

#
# Backup file $config_to to $config_to.orig if $config_from eq $config_to
# and $config_to.orig does not exist
#
# Read $config_from, substitute values of parameters with values found
# in $record hash table. Write $config_to with the result, preserving
# comments.
#
# If parameter is not defined (different from empty string)
# it will be written as #parameter =
# otherwise it will be written as parameter = value and 
# value can be the empty string.
# 
sub unload_config {
    my($record, $config_from, $config_to) = @_;

    $config_to = $config_from if(!defined($config_to));

    my($buffer);
    open(FILE, "<$config_from") || die "cannot open $config_from for reading : $!";
    while(<FILE>) {
        my($var) = /^([a-z0-9_]+?)\s*=/io;
	($var) = /^\s*#([a-z0-9_]+?)\s*=/io if(!defined($var));

	if(defined($var) && exists($record->{$var})) {
	    if(defined($record->{$var})) {
		$buffer .= "$var = $record->{$var}\n";
	    } else {
		$buffer .= "#$var = \n";
	    }
	} else {
	    $buffer .= $_;
	}
    }
    close(FILE);

    system("cp $config_to $config_to.orig") if(! -f "$config_to.orig" && $config_from eq $config_to);
    open(FILE, ">$config_to") || die "cannot open $config_to for writing : $!";
    print FILE $buffer;
    close(FILE);
}

#
# Reuse an existing configuration
#
sub search_conf {
    my(@config_files) = @_;

    my(%conf);

    getparam('use_config', \%conf,
	     {
		 'prompt' => "
Shall I take default configuration values from an existing configuration ? 
If yes specify the directory. If no just type return and we will proceed 
with questions.
",
                 'directory' => 1,
                 'absolute' => 1,
		 'postamble' => sub {
		     my($var, $value, $undefp, $silent, $spec) = @_;

		     my(@missing) = map { -f "$value/$_" ? () : $_ } @config_files;

		     if(@missing) {
			 print "@missing file(s) missing in directory $value" if(!$silent);
			 return 0;
		     }
		     return 1;
		 },
    });

    if(-d "$conf{'use_config'}") {
	my($file);
	foreach $file (@config_files) {
	    system("cp $file $file.orig") if(! -f "$file.orig");
	    system("cp $conf{'use_config'}/$file $file");
	}
	$ENV{'USE_DEFAULTS'} = 1;
    } else {
	$ENV{'USE_CONFIG'} = '';
    }
}

#
# Check that package $what is installed and that
# it's version is at least $min_version.
# Use $test to check that package exists : usually something like
# $test = 'require MIME::Base64;';
# Dies if package not present or wrong version.
#
sub version_check {
    my($what, $min_version, $test) = @_;

    print "Checking for $what... ";
    $test .= "; die '' if(\$${what}::VERSION < \$min_version); \$${what}::VERSION";
    my $got_version = eval $test;
	$got_version = "undef" unless defined $got_version;
    if ($@) {
	print " failed\n";
	print <<EOT;
$@
Catalog needs $what module, version >= $min_version
EOT
        exit;
    } else {
        eval "print \" \$${what}::VERSION ok\n\"";
    }
}

1;
