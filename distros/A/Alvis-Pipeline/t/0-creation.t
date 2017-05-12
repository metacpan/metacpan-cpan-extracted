# $Id: 0-creation.t,v 1.6 2005/10/10 14:16:15 mike Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 0-creation.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 8;

BEGIN { use_ok('Alvis::Pipeline') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass
my $pipe;
eval { $pipe = new Alvis::Pipeline() };
ok(!defined $pipe && defined $@ && $@ =~ /Can.t locate object method "new"/,
   "instantiation of abstract pipe subclass is refused");

# Read-pipe creation with missing parameters, and success
eval { $pipe = new Alvis::Pipeline::Read() };
ok(!defined $pipe && defined $@ && $@ =~ /no spooldir/,
   "Read-pipe creation with no spooldir is refused");

eval { $pipe = new Alvis::Pipeline::Read(spooldir => "/tmp/xyzzy") };
ok(!defined $pipe && defined $@ && $@ =~ /no port/,
   "Read-pipe creation with no port is refused");

eval { $pipe = new Alvis::Pipeline::Read(spooldir => "/tmp/xyzzy",
					 port => 31802) };
ok(defined $pipe,
   "Read-pipe creation with spooldir and port is accepted");
$pipe->close();
$pipe = undef;

# Write-pipe creation with missing parameters, and success
eval { $pipe = new Alvis::Pipeline::Write() };
ok(!defined $pipe && defined $@ && $@ =~ /no host/,
   "Write-pipe creation with no host is refused");

eval { $pipe = new Alvis::Pipeline::Write(host => "localhost") };
ok(!defined $pipe && defined $@ && $@ =~ /no port/,
   "Write-pipe creation with no port is refused");

eval { $pipe = new Alvis::Pipeline::Write(host => "localhost",
					  port => 29168) };
ok(!defined $pipe && defined $@ && $@ =~ /Connection refused/,
   "Write-pipe creation with no listener on port is refused");

if (0) {
### This won't pass on machines with no web-server
eval { $pipe = new Alvis::Pipeline::Write(host => "localhost",
					  port => 80) };
ok(defined $pipe,
   "Write-pipe creation with host and port=80 is accepted");
$pipe->close();
$pipe = undef;
}
