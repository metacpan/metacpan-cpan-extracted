#!/usr/bin/perl

use strict;
use warnings;
use App::CriticDB::DB::Stor;
use Fcntl qw/:flock/;
use File::Temp qw/tempfile/;
use Test::More tests=>3;

subtest 'end to end'=>sub{
	plan tests=>8;
	my ($db,$mtime);
	my ($fh,$fn)=tempfile(UNLINK=>1); close($fh); unlink($fn);
	#
	$db=App::CriticDB::DB::Stor->new(mode=>'file',file=>$fn,type=>'storable');
	ok(-e $fn,"created:  stor ($fn)");
	$mtime=(stat($fn))[9];
	is(ref($db),'App::CriticDB::DB::Stor','class:  Stor');
	is($$db{store}{version},1001,'Store version');
	#
	$db->store(file=>'/fake/path.pm',violations=>[{policy=>'TestPolicy',sev=>3,line=>1,col=>1,desc=>'d',expl=>'e',code=>'c'}]);
	ok((stat($fn))[9]<=$mtime,'store:  not auto-write');
	if(time()<=$mtime) { sleep(1) }
	$db->write();
	ok((stat($fn))[9]>=$mtime,'write:  file updated');
	$db=undef;
	#
	$db=App::CriticDB::DB->new(mode=>'file',file=>$fn,type=>'storable');
	ok(defined($$db{store}{file}{'/fake/path.pm'}),'read:  file entry');
	is(scalar(@{$$db{store}{file}{'/fake/path.pm'}{violations}}),1,'read:  violation count');
	ok(defined($$db{store}{index}{policy}),'read:  policy index');
};

subtest 'mtime guard'=>sub{
	plan tests=>2;
	my ($fh,$fn)=tempfile(UNLINK=>1); close($fh); unlink($fn);
	my $db=App::CriticDB::DB->new(mode=>'file',file=>$fn,type=>'storable');
	$$db{mtime}+=100; $$db{store}{version}='99999';
	$db->read();
	is($$db{store}{version},99999,'old mtime:  no re-read');
	$$db{mtime}=0;
	$db->read();
	is($$db{store}{version},1001,'newer mtime:  re-read');
};

subtest 'update guards'=>sub {
	plan tests=>2;
	my ($fh,$fn)=tempfile(UNLINK=>1); close($fh); unlink($fn);
	my $db=App::CriticDB::DB->new(mode=>'file',file=>$fn,type=>'storable');
	sleep(1); # ensure mtime tick
	open(my $dupfh,'>',$fn);
	print $dupfh "\n";
	close($dupfh);
	eval {$db->write()};
	like($@,qr/changed underneath/,'Refuse write if file changed');
	#
	unlink($fn);
	$db->write();
	chmod(oct('0400'),$fn);
	eval {$db->write()};
	like($@,qr/Failed to open/,'No write permissions');
};
