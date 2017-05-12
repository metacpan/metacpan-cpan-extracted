$Apache::SWIT::Security::Session::Sec_Man->add_uri_access_control(
		'/test/basic_handler', { perms => [ 12 ] });
$Apache::SWIT::Security::Session::Sec_Man->add_uri_access_control(
		'/test/foo', { perms => [ 12 ] });
