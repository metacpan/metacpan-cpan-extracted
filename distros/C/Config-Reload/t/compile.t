use v5.10;
use warnings;
use Test::More;

use Config::Reload qw(files_hash);

no strict 'refs';
ok defined &{'files_hash'}, 'export files_hash on request';

done_testing;
