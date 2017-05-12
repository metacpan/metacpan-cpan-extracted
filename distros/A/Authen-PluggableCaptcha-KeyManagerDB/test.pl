package test;

use warnings;
use strict;

use lib qw( 
				lib 
				../Authen-PluggableCaptcha/lib
		);

use Authen::PluggableCaptcha;
use Authen::PluggableCaptcha::KeyManagerDB;
use Authen::PluggableCaptcha::KeyManagerDB::RoseDB;

# non transaction safe

my 	$captcha= Authen::PluggableCaptcha->new( 
	type=>'new' , 
	seed=> 'a' , 
	site_secret=> 'z' ,
	keymanager_class=> 'Authen::PluggableCaptcha::KeyManagerDB',
	keymanager_args=> {
		remote_ip=> '127.0.0.1',
	},
);
my 	$captcha_publickey= $captcha->get_publickey();
	printf "\nnew->'%s'\n" , $captcha_publickey;

my 	$captcha2= Authen::PluggableCaptcha->new( 
	type=>'existing' , 
	seed=> 'a' , 
	site_secret=> 'z' ,
	keymanager_class=> 'Authen::PluggableCaptcha::KeyManagerDB',
	keymanager_args=> {
		remote_ip=> '127.0.0.1',
	},
	publickey=> $captcha_publickey ,
);

$captcha2->expire_publickey();


# transaction safe

my 	$roseDB_dbObj= Authen::PluggableCaptcha::KeyManagerDB::RoseDB->new();
	$roseDB_dbObj->begin_work;

my 	$captcha_trans= Authen::PluggableCaptcha->new( 
	type=>'new' , 
	seed=> 'a' , 
	site_secret=> 'z' ,
	keymanager_class=> 'Authen::PluggableCaptcha::KeyManagerDB',
	keymanager_args=> {
		db=> $roseDB_dbObj,
		remote_ip=> '127.0.0.1',
	},
);
my 	$captcha_trans_key= $captcha->get_publickey();
	printf "\nnew->'%s'\n" , $captcha_trans_key;

my 	$captcha_trans2= Authen::PluggableCaptcha->new( 
	type=>'existing' , 
	seed=> 'a' , 
	site_secret=> 'z' ,
	keymanager_class=> 'Authen::PluggableCaptcha::KeyManagerDB',
	publickey=> $captcha_trans_key ,
	keymanager_args=> {
		db=> $roseDB_dbObj,
		remote_ip=> '127.0.0.1',
	},
);

if ( $captcha_trans2->IS_VALID )
{
	print STDERR "\n valid ! going to expire..." . 
	$captcha_trans2->expire_publickey();
};

$roseDB_dbObj->commit;