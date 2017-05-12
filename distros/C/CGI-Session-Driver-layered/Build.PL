use warnings;
use strict;
use Module::Build;

Module::Build->new(
    module_name    => 'CGI::Session::Driver::layered',
    license        => 'perl',
    build_requires => {
	'Test::More' => 0,
	'Test::Exception' => 0,
    },
    requires => {
	'CGI::Session' => 4.00,
	'Time::HiRes'  => 0,
    }
)->create_build_script();
