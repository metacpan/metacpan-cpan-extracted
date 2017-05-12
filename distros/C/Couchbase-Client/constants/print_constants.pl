#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Couchbase::Client::Errors;
use Couchbase::Client::IDXConst;

foreach my $const (@Couchbase::Client::Errors::EXPORT,
    @Couchbase::Client::IDXConst::EXPORT) {
    
    no strict 'refs';
    printf("NAME: %-25s VALUE: %d\n", $const, &{$const}());
}
