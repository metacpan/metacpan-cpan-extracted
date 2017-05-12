#!/usr/bin/perl -w
use Module::Build;
my $build_pkg = eval { require Apache::TestMB }
      ? 'Apache::TestMB' : 'Module::Build';

# find out if they want to install for mod_perl 2
my $MP2 = 0;
if( eval "require Apache2::URI; 1" ) {
    # assume they want mod_perl 2 if it's installed
    $MP2 = 1;
} else {
    foreach my $arg (@ARGV) {
        if( $arg =~ /^MP2=([\S]*)/ ) {
            $MP2 = $1;
        }
    }
}

my $build = $build_pkg->new(
	module_name         => 'CGI::Application::Plugin::Apache',
	license             => 'perl',
	requires            => {
            'CGI::Application'                              => 3.22,
            'Exporter'                                      => 0,
            'Test::More'                                    => 0,
            $MP2 ? 'Apache2::Request' : 'Apache::Request'   => 0,
            $MP2 ? 'Apache2::Cookie'  : 'Apache::Cookie'    => 0,
            $MP2 ? 'Apache2::URI'     : 'Apache::URI'       => 0,
            'HTML::GenerateUtil'=> 0,
	},
    build_requires      => {
        'Apache::Test' => 1,
    },
    create_makefile_pl  => 'passthrough',
    create_readme       => 1,
);
$build->create_build_script();
