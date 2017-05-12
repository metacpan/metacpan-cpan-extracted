#!/usr/bin/perl
# $Id: tests.t,v 1.6 2005/12/01 18:12:37 dk Exp $

use strict;
use Test::More tests => 18;
$SIG{__DIE__} = sub { # need no Test::Builder hacks
	return if $^S;
	Carp::cluck(@_);
	die @_;
};

BEGIN { use_ok('DBIx::Roles'); }
require_ok('DBIx::Roles');

package DummyDBI;

sub connect { bless {}, shift }
sub disconnect {}
sub ping {0} # for AutoReconnect test

package Phase1;
use DBIx::Roles;
use strict;
import Test::More;

my $d = DBIx::Roles-> new;
ok( $d, "create object");

$d = DBIx::Roles-> new(qw(Hook));
ok( $d, "create object with roles"); 

$DBIx::Roles::DBI_connect = sub { bless {}, 'DummyDBI' };

# check if hooks work
my $had_disconnect = 0;
$d->{Hooks}->{disconnect} = sub {
	$had_disconnect++;
};
ok( $d-> connect(), "connect"); 
undef $d;

ok( $had_disconnect, "disconnect");

package Phase2;
use strict;
import Test::More;
use DBIx::Roles qw(
	AutoReconnect Buffered InlineArray Shared 
	StoredProcedures Transaction Hook SQLAbstract 
);
my $do = 0;
my $do_params;

$d = DBI-> connect('','','', { Hooks => {
selectrow_array => sub {
	return 42;
},
do => sub {
	$do++;
	$do_params = [ @_[2..$#_]];
	return @_;
},
},
Buffered => 0,
});
ok( $d, "DBI->connect() overload");

# plain request
my $g = $d-> selectrow_array( 'select dummy from yummy where 1=?', {}, 1);
ok( $g && $g == 42, "'dbi_methods'");

$d-> {Buffered} = 1;
$do = 0;
$d-> do("select ?,?", {}, 'param1', 'param2');
ok( $do == 0, "DBI methods");
$d-> {Buffered} = 0;
ok(( $do == 1 and @$do_params == 4 and $do_params->[-1] eq 'param2'), "DBI methods");

# like a stored proc?
$g = $d-> unbelievable_procedure( 'select 1');
ok( $g && $g == 42, "'any'/StoredProcedures");

# flattened array
my @g = $d-> do( 'select ?', {}, [1,2,3]);
ok(( 5 == @g) and not( ref($g[4])), "'rewrite'/InlineArray");

# transaction
my $begin_works = 0;
$d->{Hooks}->{begin_work} = sub {$begin_works++; 1};
$d->{Hooks}->{rollback} = sub {};
$d->begin_work;
$d->begin_work;
$d->rollback;
$g = $d->commit || 0;
ok(( 0 == $g and 1 == $begin_works), "Transaction");

# SQL::Abstract
@g = $d-> insert( 'moo', [1..4]);
ok( $g[2] && $g[2] =~ /insert\s+into\s+moo/i, "SQL::Abstract");

# can restart?
my $do_retries = 2;

$DBIx::Roles::DBI_connect = sub {
	die "Won't connect\n" if $do_retries-- > 0 ;
	return bless {}, 'DummyDBI';
};

$d->{Hooks}->{do} = sub { 
	# emulate connection break
	die "aaa!!" if $do_retries > 0;
	return 42;
};
$d-> {ReconnectMaxTries} = $do_retries + 2;
$d-> {ReconnectTimeout} = 0;
$d-> {AutoCommit} = 1; # it doesn't like transactions 
$d-> {PrintError} = 0; # it warns when reconnects
$d-> do('select 0');
ok(( -1 == $do_retries and $d-> dbh and 1), "AutoReconnect");
undef $d;

# Shared
my $conn = 0;
$DBIx::Roles::DBI_connect = sub {
	$conn++;
	return bless {}, 'DummyDBI';
};
my $k1 = DBI->connect('oh','my','god');
my $k2 = DBI->connect('oh','my','god');
ok(( 1 == $conn && $k1->instance->dbh == $k2->instance->dbh), 'Shared');

# Shared can live together with AutoConnect
$do_retries = 2;
$DBIx::Roles::DBI_connect = sub {
	die "Won't connect\n" if $do_retries-- > 0 ;
	return bless {}, 'DummyDBI';
};
$k1-> {Buffered} = 0;
$k1-> {ReconnectMaxTries} = $do_retries + 2;
$k1-> {ReconnectTimeout} = 0;
$k1-> {AutoCommit} = 1; # it doesn't like transactions 
$k1-> {PrintError} = 0; # it warns when reconnects
$k1->{Hooks}->{do} = sub { 
	# emulate connection break
	die "aaa!!" if $do_retries > 0;
	return 42;
};
my $k1d1 = $k1-> instance-> dbh;
$k1-> do('select 0');
my $k1d2 = $k1-> instance-> dbh;
my $k2d1 = $k2-> instance-> dbh;
ok(
	( defined($k1d1) and defined($k1d2) and ($k1d1 != $k1d2) and defined($k2d1) and ( $k2d1 == $k1d2)), 
	'Shared+AutoReconnect'
);
undef $k1;
undef $k2;

package Phase3;
use strict;
import Test::More;
use DBIx::Roles;

$DBIx::Roles::DBI_connect = sub { bless {}, 'DummyDBI' };
$d = DBI-> connect;
# tests that after DBI->connect() was overridden, it works as before in the other packages
ok( $d and ( $d =~ /Dummy/)+0, "package-selective DBI::connect");
