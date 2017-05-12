#!/usr/bin/env perl;

use strict;
use warnings;
use feature qw( say );

use lib 'eg/lib';

use Example::TransactionFetcher;
my $fetcher = Example::TransactionFetcher->new_with_options;
$fetcher->find;

