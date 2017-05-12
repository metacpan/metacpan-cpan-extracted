use strict;
use warnings;
use inc::Module::Install 1.16;
use Module::Install::Share;
use Module::Install::AutoInstall;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Helper/View/Bootstrap.pm > README' );
}

perl_version '5.012001';
version_from 'lib/Catalyst/Helper/View/Bootstrap.pm';

name 'Catalyst-Helper-View-Bootstrap';
all_from 'lib/Catalyst/Helper/View/Bootstrap.pm';
requires 'File::ShareDir';

requires 'Catalyst'        => '5.7';
requires 'Template'        => 0;
requires 'Catalyst::View::TT' => 0;
requires 'Path::Class' => 0;

test_requires 'Test::More';
test_requires 'Test::Pod';

install_share 'share';

auto_install;

resources
    repository => 'https://github.com/ferz/Catalyst--Helper--View--Bootstrap';

abstract 'Helper for Twitter Bootstrap and TT view which builds a skeleton web site';

makemaker_args(
    META_MERGE        => {
	"meta-spec" => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url => 'git@github.com:ferz/Catalyst--Helper--View--Bootstrap.git',
		web => 'https://github.com/ferz/Catalyst--Helper--View--Bootstrap',
	    },
	},
    },
    META_ADD => {
	resources => {
	    repository => 'https://github.com/ferz/Catalyst--Helper--View--Bootstrap',
	},
    }
    );

WriteAll;
