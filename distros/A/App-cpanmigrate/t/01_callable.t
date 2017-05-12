use strict;
use warnings;
use Test::More;

require App::cpanmigrate::bash;
my $bash = App::cpanmigrate::bash->script('perl-5.14.1');
like $bash, qr/@@@@@ /, 'fetch bash script';

require App::cpanmigrate::csh;
my $csh = App::cpanmigrate::csh->script('perl-5.14.1');
like $csh, qr/@@@@@ /, 'fetch csh script';

done_testing;
