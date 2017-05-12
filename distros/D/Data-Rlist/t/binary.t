#!/usr/bin/perl
#
# binary.t
#
# Test bas64-encoded binaries.
#
# $Writestamp: 2008-02-10 23:51:10 andreas$
# $Compile: perl -M'constant standalone => 1' binary.t$

use warnings;
use strict;
use constant;
use Test;
BEGIN { plan tests => 25 }
BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use Data::Rlist qw/:strings/;
use MIME::Base64;

our $tempfile = "$0.tmp";
our $temp;

#########################

{
	for my $opts (qw/fast default string squeezed outlined/) {
		my $binary1 = join('', map { chr(int rand 256) } 1..50); # single line
		my $binary = join('', map { chr(int rand 256) } 1..300); # multiple lines
		my $data = { random_strings => [ encode_base64($binary1),
										 encode_base64($binary) ] };
		my $b64 = $data->{random_strings}->[0];

		ok(ord(substr $b64, -1) == 10); # linefeed
		ok(not is_value($b64)); # shall not qualify as value, since it ends
                                # with a linefeed

		ok(WriteData $data, $tempfile, $opts);
		ok($temp = ReadData($tempfile));
		ok(not CompareData $data, $temp);
	}
}

unlink $tempfile;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
