use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
	module_name => 'CGI::Mungo',
	license => 'perl',
	dist_author => 'MacGyveR <dumb@cpan.org>',
	dist_abstract => 'Very simple CGI web framework',
	requires => {
		"CGI::Simple::Cookie" => 0,
		"HTTP::Response" => 0,
		"CGI" => 0,
		"Carp" => 0,
		"File::Basename" => 0,
		"Data::Dumper" => 0,
		"Template" => 0,
		"File::Spec" => 0,
		"Class::Load" => 0,
		"File::Basename" => 0
	},
	build_requires => {
		"Test::More" => 0,
		"HTTP::Daemon" => 0,
		"HTTP::Status" => 0,
		"HTTP::Response" => 0,
	},
	create_makefile_pl => 'traditional'
);
$build->create_build_script;
