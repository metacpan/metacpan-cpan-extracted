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
# $Header: /cvsroot/Catalog/Catalog/t/lib.pl,v 1.6 1999/09/07 14:48:04 loic Exp $
#
use Cwd;
use Catalog;

require "conf/lib.pl";

#$::opt_verbose = 'RDF';
#$::opt_error_stack = 'yes';

#
# Run a private daemon to prevent accidental polution
#
mkdir("t/tmp", 0777) if(! -d "t/tmp");

my($db_conf) = load_config("conf/db.conf");

require "t/$db_conf->{'db_type'}.pl";

sub conftest_generic {
    my($install_conf) = load_config("conf/install.conf");
    unload_config($install_conf, "conf/install.conf", "t/conf/install.conf");

    my($db_conf) = load_config("conf/db.conf");
    unload_config($db_conf, "conf/db.conf", "t/conf/db.conf");

    rundb();
}

sub conftest_generic_clean {
    system("rm t/conf/install.conf t/conf/db.conf");
    stopdb();
}

#
# cgi output directory
#
mkdir("t/tmp/html", 0777) if(!-d "t/tmp/html");
#
# Template files
#
$ENV{'TEMPLATESDIR'} = "t/templates";
#
# Configuration files
#
$ENV{'CONFIG_DIR'} = "t/conf";
#
# Simulate cgi environment
#
$ENV{'REQUEST_METHOD'} = "GET";
#
# Synchronize stdout with stderr
#
$| = 1;

#
# Extract current process size in bytes (ONLY WORKS on RedHat-5.2)
#
sub size {
    open(FILE, "</proc/$$/stat");
    my($a) = <FILE>;
    close(FILE);
    my(@a) = split(' ', $a);
#    print "pid = $a[0]\n"; 
    return $a[22];
}

my($mem_size);

#sub mem_size { $mem_size = size(); print STDERR "$mem_size -> " }
#sub show_size { $mem_size = size(); print STDERR "$mem_size\n" }
sub mem_size {}
sub show_size {}

#
# Assuming that the external var $html contains an HTML page
# with hidden params, push them in $cgi. Sort of emulate a POST...
# If $re is set, only params matching $re will be sniffed
#
sub param_snif {
    my($cgi, $html, $re) = @_;

    while($html =~ /type=hidden.*name=(.*?)\s*value="(.*)"/go) {
	my($var, $value) = ( $1, $2 );
	next if(defined($re) && $var !~ /$re/);
	$value =~ s/&amp;/&/g;
	$value =~ s/%2C/,/g;
#    print STDERR "$var => $value\n";
	$cgi->param($var => $value) if($value);
    }
}

sub create_catalogs {
    my($catalog) = Catalog->new();
    $catalog->csetup_api();
    $catalog->close();
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
