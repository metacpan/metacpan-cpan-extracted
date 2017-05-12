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
# $Header: /cvsroot/Catalog/Catalog/t/mysql.pl,v 1.2 1999/06/09 07:18:39 loic Exp $
#
#
# Copy and modify configuration files for test
#
sub conftest_db {
    my($mysql_conf) = load_config("conf/mysql.conf");
    $mysql_conf->{'base'} = 'test';
    $mysql_conf->{'host'} = 'localhost';
    $mysql_conf->{'port'} = '7777';
    my($cwd) = getcwd();
    $mysql_conf->{'unix_port'} = "$cwd/t/tmp/db.sock";
    $mysql_conf->{'user'} = undef;
    $mysql_conf->{'passwd'} = undef;
    unload_config($mysql_conf, "conf/mysql.conf", "t/conf/mysql.conf");
}

sub sys {
    my ($cmd) = @_;
    print "$cmd\n";
    my $status = system($cmd);
    warn "Command ``$cmd'' failed\n" if $status != 0;
    return $status;
}

sub rundb {
    conftest_db();
    my($mysql_conf) = load_config("t/conf/mysql.conf");
    my(@paths) = map { "$mysql_conf->{home}/$_/mysqld" } qw(libexec sbin bin);
    my($mysqld) = grep { -x $_ } @paths;
    error("mysqld not found in @paths") unless(-f $mysqld && -x $mysqld);
    sys("kill -15 `cat t/tmp/db.pid`") if -f "t/tmp/db.pid";
    sys("rm -fr t/tmp/db");
    mkdir("t/tmp/db", 0777) or die "mkdir t/tmp/db: $!";
    my($mysql_opt) = "--port $mysql_conf->{'port'} --socket $mysql_conf->{'unix_port'}";
    my($cwd) = getcwd();
    my($cmd) = "$mysqld --skip-grant-table --datadir=$cwd/t/tmp/db --pid-file $cwd/t/tmp/db.pid";
	$cmd .= " $mysql_opt > /dev/null 2>&1 &";
    sys($cmd);
    #
    # Wait a bit for the server to start
    #
    sleep 3;
    sleep 3 unless -f "t/tmp/db.pid";
    sys("$mysql_conf->{'home'}/bin/mysql $mysql_opt -e 'create database test'");
}

sub stopdb {
#
# Cleanup
#
    sys("kill -15 `cat t/tmp/db.pid`") if -f "t/tmp/db.pid";
	unlink "t/conf/mysql.conf";
    sleep 3;
}

END {
	stopdb();
}

1;
