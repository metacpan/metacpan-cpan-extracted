use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Config::MorePerl;
use FindBin qw($Bin);

my $cfg; 

like( 
	exception {$cfg = Config::MorePerl->process($Bin.'/configs/no_such_file.conf');}, 
	qr/No such file/, 
);
is (ref($cfg),'');

like( 
	exception {$cfg = Config::MorePerl->process($Bin.'/configs/config_with_errors.conf');}, 
	qr/Config::MorePerl: error while processing config/, 
	'\'Config::MorePerl: error while processing config\' appears in the exception'
);
is (ref($cfg),'');

like( 
	exception {$cfg = Config::MorePerl->process($Bin.'/configs/config_with_errors2.conf');}, 
	qr/Config::MorePerl: conflict between variable /, 
	'\'Config::MorePerl: conflict between variable\' appears in the exception'
);
is (ref($cfg),'');


done_testing();
