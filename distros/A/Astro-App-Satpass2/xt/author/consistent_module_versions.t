package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use Astro::App::Satpass2::Utils;

use lib qw{ inc };
use My::Module::Test::App;
use My::Module::Recommend;

note 'Test whether required module versions are defined consistently';

foreach my $module ( qw{ DateTime::Calendar::Christian } ) {
    my $prod_ver = Astro::App::Satpass2::Utils->__module_version( $module );
    foreach my $support_mod ( qw{ My::Module::Test::App
	My::Module::Recommend
	} ) {
	my $support_ver = $support_mod->__module_version( $module );
	is $support_ver, $prod_ver, "$module version requirement is consistent between Astro::App::Satpass2::Utils and $support_mod";
    }
}

done_testing;

1;

# ex: set textwidth=72 :
