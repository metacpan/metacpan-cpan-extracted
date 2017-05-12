
use strict;
use warnings;

use Test::More;

{

    package MY::Supersite::EnvVarNotSet;
    use Bread::Board::LazyLoader::Supersite
        env_var => 'MY_SITE',
        site    => 't::BaseSite';
}

{

    package MY::Supersite::EnvVarSet;

    BEGIN {
        $ENV{MY_SITE} = 't::ExtSite';
    }
    use Bread::Board::LazyLoader::Supersite
        env_var => 'MY_SITE',
        site    => 't::BaseSite';
}

{

    package MY::Supersite::MoreEntriesInEnv;

    BEGIN {
        $ENV{MY_SITE} = 't/files/sandbox.ioc;t::ExtSite';
    }

    use Bread::Board::LazyLoader::Supersite
        env_var => 'MY_SITE',
        site    => 't::BaseSite';
}

my $base_root = MY::Supersite::EnvVarNotSet->root;
is( $base_root->fetch('First/Second/tag')->get,
    'created by BaseSite',
    "The env not set thus site is used"
);

my $ext_root = MY::Supersite::EnvVarSet->root;
is_deeply(
    $ext_root->fetch('First/Second/tag')->get,
    'created by BaseSite, modified by ExtSite',
    "The env var has priority"
);

my $sandboxed_root = MY::Supersite::MoreEntriesInEnv->root;
is( $sandboxed_root->fetch('First/Second/tag')->get,
    'created by BaseSite, modified by ExtSite sandboxed',
	"There site may be further, modified by file"
);

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:
