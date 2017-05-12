# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Lazy-ModPerl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN { 
	use_ok('Apache2::Const', 2.0);
	use_ok('Apache2::RequestUtil', 2.0);
	use_ok('CGI::Lazy', 0.01);
};

#########################

ok(mod_perl(), 'basic mod_perl config');

#-----------------------------------------------------------------------------
sub mod_perl {
	my $q = CGI::Lazy->new({
				tmplDir 	=> "/templates",
				jsDir		=>  "/js",
				plugins 	=> {
					mod_perl => {
						PerlHandler 	=> "ModPerl::Registry",
						saveOnCleanup	=> 1,
					},
					ajax	=>  1,
				},
			}) or die;
}

