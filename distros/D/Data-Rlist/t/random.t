#!/usr/bin/perl
#
# random.t
#
# Test example code from the Rlist.pm POD.
#
# $Writestamp: 2008-07-24 17:16:21 eh2sper$
# $Compile: perl -M'constant standalone => 1' random.t$

BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use warnings;
use strict;

use Data::Rlist;
use MIME::Base64;

use Test::More tests => 6;

our $standalone = $constant::declared{'main::standalone'};
our $mydir = $standalone ? '.' : 't';
our $myrlsfile = "$mydir/test4.rls"; # nanoscripts
die `pwd` unless -e $myrlsfile;

# Shall be the currently edited ../lib/Data/Rlist.pm and not the installed
# version.

if ($standalone) {
	$Data::Rlist::EchoStderr = 1;
	print "using Data::Rlist $Data::Rlist::VERSION\n";
} else {
	$Data::Rlist::EchoStderr = 1;
}

###############################################################################
# Binary Data

our $binary_data = join('', map { chr(int rand 256) } 1..300);
our $sample = { random_string => encode_base64($binary_data) };

ok(WriteData $sample, "$mydir/random.rls");

unlink('random.rls') unless $standalone;

###############################################################################
# Nanoscripts

our $nanoscripts = ReadData $myrlsfile;

ok(!(Data::Rlist::errors() || Data::Rlist::warnings()));
ok(!($Data::Rlist::Errors || $Data::Rlist::Warnings));
ok(!@{Data::Rlist::messages()});
ok($nanoscripts);

our $data = join('', <DATA>);
    $data = EvaluateData \$data;

ok($data->[0]->{foo} eq 'bar');

__END__
( <<perl )
ReadData(\\'{ foo = bar; }');
perl
