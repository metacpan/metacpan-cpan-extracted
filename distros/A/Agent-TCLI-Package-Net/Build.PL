use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Agent::TCLI::Package::Net',
    license             => 'perl',
    dist_author         => 'Eric Hacker <hacker@cpan.org>',
    dist_abstract		=> 'Network tools for TCLI agents',
    dist_version_from   => 'lib/Agent/TCLI/Package/Net.pm',
    requires => {
		'Agent::TCLI'				 			=> '0.03',
		'POE::Component::Client::Ping' 			=> '0',
		'POE::Component::Client::Traceroute' 	=> '0',
		'POE::Component::Client::HTTP'		 	=> '0',
		'POE::Component::Client::SMTP'		 	=> '0',
		'POE::Component::Client::Keepalive'		=> '0',
		'POE::Component::Server::SimpleHTTP' 	=> '0',
		'Email::MIME::Creator'					=> '0',
		'File::Slurp'							=> '0',

		'FormValidator::Simple::Plugin::NetAddr::IP'	=> '0.01',
    	},
    create_makefile_pl => 'passthrough',
);

# This will cause it to pick up XML files
$builder->add_build_element('xml');

$builder->create_build_script();


