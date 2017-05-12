use strict;
use lib 'lib';
use Test::More;

use Data::Processor::ValidatorFactory;

my $vf = Data::Processor::ValidatorFactory->new;

like ($vf->file('<','oops')->('/tmp/xkddf'),qr/oops/, 'error message generated');
is ($vf->rx(qr{XX},'oops')->('xxXXx'),undef,'regular expression check');
is ($vf->any(qw(OFF ON))->('OFF'),undef, 'is it one of the list');
is ($vf->dir()->('/'),undef, 'directory exists');


done_testing;
