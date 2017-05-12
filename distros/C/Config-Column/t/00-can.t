use utf8;
use strict;
use warnings;
use Test::More tests => 2;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

can_ok('Config::Column', qw/new add_data_last add_data write_data read_data read_data_num _write_order _write_order_has_delimiter _write_order_no_delimiter/);
