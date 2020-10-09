#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
 
BEGIN { plan skip_all => 'TEST_AUTHOR not enabled' if not $ENV{TEST_AUTHOR}; }
use Test::CPAN::Changes;
use Caller::Hide;

changes_file_ok('CHANGES', { version => Caller::Hide->VERSION });
done_testing();
