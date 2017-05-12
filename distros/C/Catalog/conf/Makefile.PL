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
# $Header: /cvsroot/Catalog/Catalog/conf/Makefile.PL,v 1.12 1999/08/12 09:40:08 loic Exp $
#
# This -*- perl -*- script writes the Makefile for Catalog

require 5.005;
use strict;

require "./lib.pl";

conf_env(
	      'infodir' => 'INFODIR',
	      'cgidir' => 'CGIDIR',
	      'cgipath' => 'CGIPATH',
	      'config_dir' => 'CONFIG_DIR',
	      'use_config' => 'USE_CONFIG',
	      'htmldir' => 'HTMLDIR',
	      'htmlpath' => 'HTMLPATH',
	      'userid' => 'USERID',
	      'db_type' => 'DB_TYPE',
	      );

sub misc_ask {
    my($install_conf) = load_config("install.conf");

    my(%h);
    locate_cmds($install_conf, 'texi2html', 'makeinfo', 'texi2dvi', 'dvips', 'chown');
    if(defined($install_conf->{'texi2html'})) {
	yesno('html', \%h,
		 {
		     'prompt' => "
Do you want HTML formated documentation ? ",
		     'yesno' => 1,
		     'default' => exists($ENV{'DOC_HTML'}) ? $ENV{'DOC_HTML'} : 'yes',
		 });
    }
    if(defined($install_conf->{'makeinfo'})) {
	yesno('info', \%h,
		 {
		     'prompt' => "
Do you want Emacs info formated documentation ? ",
		     'yesno' => 1,
		     'default' => exists($ENV{'DOC_INFO'}) ? $ENV{'DOC_INFO'} : 'no',
		 });
    }
    if(defined($install_conf->{'texi2dvi'}) &&
       defined($install_conf->{'dvips'})) {
	yesno('ps', \%h,
		 {
		     'prompt' => "
Do you want Postscript formated documentation ? ",
		     'yesno' => 1,
		     'default' => exists($ENV{'DOC_PS'}) ? $ENV{'DOC_PS'} : 'no',
		 });
    }

    $install_conf->{'doc_all'} = '';
    $install_conf->{'doc_install'} = '';
    my($format);
    foreach $format ('info', 'html', 'ps') {
	if($h{$format}) {
	    $install_conf->{'doc_all'} .= "all_${format} ";
	    $install_conf->{'doc_install'} .= "install_${format} ";
	    if($format eq 'info') {
		getparam('infodir', $install_conf,
			 {
			     'prompt' => "
The absolute pathname of the directory where the documentation will
be installed (Emacs info format only)",
                             'mandatory' => 1,
                             'directory' => 1,
                             'absolute' => 1,
                });
	    }
	}
    }

    if($install_conf->{'chown'}) {
	my($myself) = $ENV{'LOGNAME'};
	if(!defined($myself) || $myself =~ /^\s*$/) {
	    $myself = $ENV{'USERNAME'};
	}
	if(!defined($myself) || $myself =~ /^\s*$/) {
	    $myself = $ENV{'USER'};
	}
	if(!defined($myself) || $myself =~ /^\s*$/) {
	    die "LOGNAME and USERNAME and USER are not defined";
	}
	system("echo a > /tmp/tt$$");
	system("$install_conf->{'chown'} $myself /tmp/tt$$");
	if($? != 0) {
	    $install_conf->{'chown'} = ':';
	}
	system("rm -f /tmp/tt$$");
    } else {
	$install_conf->{'chown'} = ':';
    }
    
    unload_config($install_conf, "install.conf");
}

sub install_ask {
    my($install_conf) = load_config("install.conf");

    getparam('cgidir', $install_conf,
	    {
		'prompt' => "
The absolute pathname of the directory where the cgi-bin
scripts will be installed",
                'mandatory' => 1,
                'directory' => 1,
                'absolute' => 1,
    });
    getparam('cgipath', $install_conf,
	    {
		'prompt' => "
What is the CGIPATH corresponding to CGIDIR
(CGIDIR = $install_conf->{'cgidir'}) ? 
CGIPATH must be the path used to access the cgi-bin located in CGIDIR
when browsing from the WEB. For instance, if CGIDIR is 
/home/httpd/cgi-bin, the CGIPATH is very likely to be /cgi-bin",
                'mandatory' => 1,
                'absolute' => 1,
    });
    $install_conf->{'config_dir'} = $install_conf->{'cgidir'};
    getparam('config_dir', $install_conf,
	    {
		'prompt' => "
The absolute pathname of the directory where the default
configuration files will be installed. If not specified the 
default configuration files will be installed in the CGIDIR 
directory",
                'undef_comment' => "CONFIG_DIR set to CGIDIR ($install_conf->{'cgidir'})\n",
                'directory' => 1,
                'absolute' => 1,
    });
    getparam('htmldir', $install_conf,
            {
                'prompt' => "
The absolute pathname of the directory where the HTML
material (documentation, images, examples) will be installed. It is
a good idea to put all this in a sub directory specific to Catalog so
that it will not interfere with other applications",
                'mandatory' => 1,
                'directory' => 1,
                'absolute' => 1,
    });
    getparam('htmlpath', $install_conf,
            {
                'prompt' => "
What is the HTMLPATH corresponding to HTMLDIR
($install_conf->{'htmldir'}) ? 
HTMLPATH must be the path used to access the files located in HTMLDIR
when browsing from the WEB. For instance, if HTMLDIR is 
/home/httpd/htdocs/Catalog, the HTMLPATH is very likely to be /Catalog",
                'mandatory' => 1,
                'absolute' => 1,
    });
    getparam('userid', $install_conf,
            {
                'prompt' => "
What is the userid of the HTTP server ? The default configuration
files will be copied in the 
$install_conf->{'config_dir'} directory.
The HTML interface must be able to modify them, therefore their 
owner must be the same as the userid of the HTTP server",
                'mandatory' => 1,
    });

    unload_config($install_conf, "install.conf");
}

sub db_ask {
    my($db_conf) = load_config("db.conf");

    getparam('db_type', $db_conf,
		 {
		     'prompt' => "Specify the database you will be using.",
		     'mandatory' => 1,
		     'postamble' => sub {
			 my($var, $value, $undefp, $silent, $spec) = @_;
			 if(! -r "$value.pl") {
			     print "$value is not among the known databases" if(!$silent);
			     return 0;
			 }
			 return 1;
		     },
		 });
    
    require "./$db_conf->{'db_type'}.pl";

    search_conf("$db_conf->{'db_type'}.conf");
    db_real_ask();

    unload_config($db_conf, "db.conf");
}

search_conf(qw(install.conf db.conf));
install_ask();
misc_ask();
db_ask();
