
use Module::Build;
Module::Build->new(
	module_name    => 'Apache::GopherHandler', 
	dist_author    => 'Timm Murray <tmurray@cpan.org>', 
	dist_abstract  => 'Gopher ProtocolHandler for Apache2', 
	license        => 'gpl', 
	requires       => {
		perl              => '5.6.0', 
		'Gopher::Server'  => '0.1.1', 
	}, 
	create_makefile_pl  => 'passthrough', 
)->create_build_script;

