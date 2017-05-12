#!/usr/bin/perl5
#
# format_snapshot - Read snapshot data.  This operates on the binary
#                   data returned by the GetSnapshot method.
#
# $Id: format_snapshot.pl,v 145.1 2007/10/17 14:44:58 biersma Exp $
#

use strict;
use Carp;
use DB2::Admin::DataStream;

#
# Command line: filenames of archived snapshot data
#
foreach my $fname (@ARGV) {
    open (DATA, $fname) ||
      die "Cannot open input file '$fname': $!";
    local $/;
    my $data = <DATA>;
    close DATA;

    my $stream = DB2::Admin::DataStream::->new($data);
    print $stream->Format(), "\n", ("-" x 72), "\n\n";
}
