# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 35;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

use Data::Dumper;

sub D (\@) {
	Data::Dumper->Dump([@{$_[0]}], [map { "\$_[$_]" } 0 .. $#{$_[0]}]);
}

if (1) {
	my $e = "error";
	$@ = $e;
	is(cvErrorStr(-2), "Unspecified error");
	is($@, $e);
	is(Cv->ErrorStr(-2), "Unspecified error");
	is($@, $e);
	is(Cv->errorStr(-2), "Unspecified error");
	is($@, $e);
}

if (2) {
	my ($status, $funcName, $errMsg) = (-1, "funcName", "errMsg");
	my $err = join(' ', "OpenCV Error:", Cv->errorStr($status),
				   "($errMsg)", "in $funcName");
	$err =~ s/[\(\)\.]/\\$&/g;
	throws_ok { cvError($status, $funcName, $errMsg ) } qr/$err/;
}

if (3) {
	cvSetErrMode(0);
	is(cvGetErrMode(), 0, "errMode");
	my ($status, $funcName, $errMsg, $file, $line) =
		(-1, "funcName", "errMsg0", rand, rand);
	my $err;
	sub myError {
		$err = \@_;
		# print STDERR "myerror:\n", D(@_);
	}
	my $prevError = cvRedirectError(
		\&myError, my $myData = "mydata",
		my $prevData,
		);
	throws_ok {
		cvError($status, $funcName, $errMsg, $file, $line);
	} qr/OpenCV Error: Backtrace \($errMsg\) in $funcName/;
	is(cvGetErrStatus(), $status, "errStatus");
	is($err->[0], $status);
	is($err->[1], $funcName);
	is($err->[2], $errMsg);
	is($err->[3], $file);
	is($err->[4], $line);
	is($err->[5], $myData);
	my $prevError2 = cvRedirectError($prevError, $prevData, my $prevData2);
	is($prevError2, \&myError);
	is($prevData2, $myData);
}

if (4) {
	Cv->setErrMode(1);
	is(Cv->getErrMode(), 1, "errMode1");
	my ($status, $funcName, $errMsg, $file, $line) =
		(-2, "funcName2", "errMsg2", rand, rand);
	my $err;
	my $prevError = Cv->redirectError(
		my $myError = sub {
			$err = \@_;
			# print STDERR "myerror1:\n", D(@_);
		},
		my $myData = "mydata1",
		my $prevData,
		);
	lives_ok { Cv->error($status, $funcName, $errMsg, $file, $line) };
	is(Cv->getErrStatus(), $status, "errStatus");
	is($err->[0], $status);
	is($err->[1], $funcName);
	is($err->[2], $errMsg);
	is($err->[3], $file);
	is($err->[4], $line);
	is($err->[5], $myData);
	my $prevError2 = Cv->redirectError($prevError, $prevData, my $prevData2);
	is($prevError2, $myError);
	is($prevData2, $myData);
}

if (5) {
	Cv->setErrMode(2);
	is(Cv->getErrMode(), 2, "errMode2");
	my ($status, $funcName, $errMsg, $file, $line) =
		(-3, "funcName3", "errMsg3", rand, rand);
	my $err;
	my $prevError = Cv->redirectError(
		sub {
			$err = \@_;
			# print STDERR "myerror1:\n", D(@_);
		},
		my $myData = "mydata2",
		my $prevData,
		);
	lives_ok { Cv->error($status, $funcName, $errMsg, $file, $line) };
	is(Cv->getErrStatus(), $status, "errStatus");
	is($err, undef);
	Cv->redirectError($prevError, $prevData);
}

if (6) {
	Cv->setErrMode(0);
	Cv->redirectError(sub { });
	throws_ok { Cv::cvCreateImage([-1, -1], 8, 3); } qr/OpenCV Error:/;
}
