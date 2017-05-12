package Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object::CaptchaKey;
use Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object();
use base qw(Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object);

__PACKAGE__->meta->setup(
	table=> 'captcha_key',
	columns=> [ 
		qw(
			id 
			hex_id 
			is_valid 
			timestamp_created 
			ip_created 
			timestamp_used 
			ip_used
		)
	],
	primary_key_columns=> ['id'],
	unique_key=> 'hex_id',
);
__PACKAGE__->meta->initialize( replace_existing=> 1 );
1;