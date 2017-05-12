#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan skip_all => 'This test not designed for Win32' if $^O =~ m/Win32$/;

plan qw/no_plan/;

use t::Test;

my $fastcgi_socket = '127.0.0.1:45450';

stdout_same_as { run_for_example_eg qw# catalyst/fastcgi apache2 dynamic # } 't/assets/apache2/fastcgi-dynamic';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi apache2 standalone --bare # } 't/assets/apache2/fastcgi-standalone';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi apache2 standalone --bare --fastcgi-socket #, $fastcgi_socket } 't/assets/apache2/fastcgi-standalone-host-port';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi apache2 static # } 't/assets/apache2/fastcgi-static';
stdout_same_as { run_for_example_eg qw# catalyst/mod_perl # } 't/assets/apache2/mod_perl';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi nginx --bare # } 't/assets/nginx/standalone';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi nginx --bare --fastcgi-socket #, $fastcgi_socket } 't/assets/nginx/standalone-host-port';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi lighttpd standalone --bare # } 't/assets/lighttpd/standalone';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi lighttpd standalone --bare --fastcgi-socket #, $fastcgi_socket } 't/assets/lighttpd/standalone-host-port';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi lighttpd static --bare --fastcgi-socket /tmp/lighttpd-eg.socket # } 't/assets/lighttpd/static';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi start-stop --fastcgi-pid-file eg-fastcgi.pid # } 't/assets/fastcgi-start-stop';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi start-stop --fastcgi-pid-file eg-fastcgi-host-port.pid --fastcgi-socket #, $fastcgi_socket } 't/assets/fastcgi-start-stop-host-port';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi monit --fastcgi-pid-file eg-fastcgi.pid # } 't/assets/fastcgi-monit';
stdout_same_as { run_for_example_eg qw# catalyst/fastcgi monit --fastcgi-pid-file eg-fastcgi-host-port.pid # } 't/assets/fastcgi-monit-host-port';
stdout_same_as { run_for_example qw# monit --home /home/rob/monit # } 't/assets/monit';
