#!/usr/bin/perl

=pod

pexit.pl

Author: Chen Gang
Blog: http://blog.yikuyiku.com
Corp: SINA
At 2014-04-22 Beijing

=cut


use strict;
use warnings;
pexit(0, 'exitmsg');

sub pexit
{
    my $exitcode = int(shift @_);
    my $w = join " ", @_;
    print "$w";
    exit $exitcode;
}

