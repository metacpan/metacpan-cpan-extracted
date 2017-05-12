shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall
use Module::Build;

Module::Build->new(
    dist_author         => 'Mark Hedges <hedges@ucsd.edu>',
	module_name         => 'CGI::FormBuilder::Source::YAML',
	license             => 'perl',
	requires => {
        'CGI::FormBuilder'      => 3.02,
        'YAML::Syck'            => 0,
        'Test::More'            => 0,
        'FindBin'               => 0,
	},
)->create_build_script;

