#! /usr/bin/perl

use lib '../lib';
use Data::Pipeline qw( Pipeline Count RSS Filter CSV );

my $url = "http://feeds.feedburner.com/FreeiTunesDownloads";

Pipeline(
    RSS,
    Filter( filters => { title => qr/^\[mus/ } ),
    CSV( column_names => [qw(title)] )
) -> from( url => $url )
  -> to( \*STDOUT );
