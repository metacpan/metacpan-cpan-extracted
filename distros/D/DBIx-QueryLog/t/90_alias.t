use strict;
use warnings;
use Test::More;
require DBIx::QueryLog;

is \&DBIx::QueryLog::begin, \&DBIx::QueryLog::import, 'begin';
is \&DBIx::QueryLog::end, \&DBIx::QueryLog::unimport, 'end';
is \&DBIx::QueryLog::enable, \&DBIx::QueryLog::import, 'enable';
is \&DBIx::QueryLog::disable, \&DBIx::QueryLog::unimport, 'disable';

done_testing;
