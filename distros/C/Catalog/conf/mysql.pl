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
# $Header: /cvsroot/Catalog/Catalog/conf/mysql.pl,v 1.2 1999/06/09 07:11:31 loic Exp $

require 5.005;
use strict;

require "./lib.pl";

conf_env(
	      'home' => 'MYSQL_HOME',
	      'user' => 'MYSQL_USER',
	      'passwd' => 'MYSQL_PASSWORD',
	      'host' => 'MYSQL_HOST',
	      'base' => 'MYSQL_BASE',
	      'port' => 'MYSQL_PORT',
	      'unix_port' => 'MYSQL_UNIX_PORT',
	      );

sub db_real_ask {
    my($mysql_conf) = load_config("mysql.conf");

    if(!$ENV{'USE_DEFAULTS'}) {
	print "
You will now be prompted for the parameters that allow a connection
to the MySQL database to be established.

";
    }

    my($ok);
    do {
	getparam('home', $mysql_conf,
		 {
		     'prompt' => "Directory in which MySQL is installed. For instance
if you have /usr/local/bin/mysqldump then the directory is /usr/local.
If you have /opt/mysql-3.21/bin/mysqldump then use /opt/mysql-3.21 as the directory.",
		     'mandatory' => 1,
		     'directory' => 1,
		     'absolute' => 1,
		     'postamble' => sub {
			 my($var, $value, $undefp, $silent, $spec) = @_;
			 if(! -x "$value/bin/mysqldump") {
			     print "$value/bin/mysqldump not found " if(!$silent);
			     return 0;
			 }
			 return 1;
		     },
		 });
	getparam('base', $mysql_conf,
		 {
		     'prompt' => "MySQL database where the catalog tables will be created.
The mysql database is created when you installed MySQL. You can
use it if you don't want to create your own.",
		     'mandatory' => 1,
		 });
	getparam('user', $mysql_conf,
		 {
		     'prompt' => "MySQL user only if not running with --skip-grant-tables",
		 });
	getparam('passwd', $mysql_conf,
		 {
		     'prompt' => "MySQL password  only if not running with --skip-grant-tables",
		 });
	getparam('host', $mysql_conf,
		 {
		     'prompt' => "MySQL host if not localhost",
		 });
	getparam('port', $mysql_conf,
		 {
		     'prompt' => "MySQL port if not default port",
		 });
	getparam('unix_port', $mysql_conf,
		 {
		     'prompt' => "MySQL socket if not default socket. 
This is only needed if running more than one MySQL server on the same host.
If you don't know what this is about, leave it empty.",
                 });
	conf2opt($mysql_conf);
	$ok = dbconnect($mysql_conf);
	if(!$ok) {
	    print "
Please fix the mysql parameters so that a connection can be established.
";
	    delete($ENV{'USE_DEFAULTS'});
	    my($key);
	    foreach $key (qw(MYSQL_BASE MYSQL_USER MYSQL_PASSWORD MYSQL_HOST MYSQL_BASE MYSQL_PORT)) {
		delete($ENV{$key});
	    }
	}
    } while(!$ok);

    unload_config($mysql_conf, "mysql.conf");
}

my($ok) = 0;
my($user, $passwd);

sub dbconnect {
    my($mysql_conf) = @_;

    my($opt) = $mysql_conf->{'cmd_opt'};
    
    my($cmd) = "$mysql_conf->{'home'}/bin/mysql $opt -e \"show tables\" $mysql_conf->{'base'}";
    system("echo 'Trying to connect with: $cmd'");
    system("echo '------- Test output begin -----------'");
    my($unset) = "unset MYSQL_BASE ; unset MYSQL_USER ; unset MYSQL_PASSWORD ; unset MYSQL_HOST ; unset MYSQL_BASE ; unset MYSQL_PORT ; unset MYSQL_UNIX_PORT";
    system("$unset ; $cmd");
    my($status) = !$?;
    system("echo '------- Test output end   -----------'");
    return $status;
}

sub conf2opt {
    my($mysql_conf) = @_;
    
    my(%map) = (
		'user' => 'user',
		'passwd' => 'password',
		'port' => 'port',
		'host' => 'host',
		'unix_port' => 'socket',
		);
    my($opt) = '';
    my($key);
    foreach $key ('user', 'passwd', 'port', 'host', 'unix_port') {
	$opt .= " --$map{$key}='$mysql_conf->{$key}'" if(defined($mysql_conf->{$key}) && $mysql_conf->{$key} !~ /^\s*$/o);
    }

    $mysql_conf->{'cmd_opt'} = $opt;
}

version_check('DBD::mysql', '2.0210', 'require DBI; require DBD::mysql;');

1;
