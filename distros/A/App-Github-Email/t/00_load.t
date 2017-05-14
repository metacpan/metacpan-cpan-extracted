use Test::More tests => 4;

use_ok('LWP::UserAgent');
use_ok('Email::Address');
use_ok('Getopt::Long', qw(GetOptions));
use_ok('List::MoreUtils', qw(uniq));

done_testing();
