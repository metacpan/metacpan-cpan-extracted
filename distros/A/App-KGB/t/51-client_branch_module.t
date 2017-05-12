use strict;
use warnings;

use autodie qw(:all);
use Test::More;

BEGIN {
    eval { require SVN::Core; 1 }
        or plan skip_all => "SVN::Core required for testing the Subversion client";
    eval { require SVN::Fs; 1 }
        or plan skip_all => "SVN::Fs required for testing the Subversion client";
    eval { require SVN::Repos; 1 }
        or plan skip_all => "SVN::Repos required for testing the Subversion client";
};

use App::KGB::Change;
use App::KGB::Client::Subversion;
use App::KGB::Client::ServerRef;

my $port = 7645;
my $password = 'v,sjflir';

my $c = new_ok(
    'App::KGB::Client::Subversion' => [
        {   repo_id => 'test',
            servers => [
                App::KGB::Client::ServerRef->new(
                    {   uri      => "http://127.0.0.1:$port/",
                        password => $password,
                    }
                ),
            ],

            #br_mod_re      => \@br_mod_re,
            #br_mod_re_swap => $br_mod_re_swap,
            #ignore_branch  => $ignore_branch,
            repo_path => '/',
            revision  => 1,
        }
    ]
);

sub test_matching {
    my ( $test_name, $files, $res, $swap, $wanted_branch, $wanted_module,
        $rest )
        = @_;

    $files = [$files] unless ref($files);
    $res   = [$res]   unless ref($res);

    my $changes
        = [ map { App::KGB::Change->new( { action => 'M', path => $_, } ) }
            @$files ];

    if ($swap) {
        $c->mod_br_re($res);
        $c->br_mod_re( [] );
    }
    else {
        $c->br_mod_re($res);
        $c->mod_br_re( [] );
    }

    my ( $branch, $module ) = $c->detect_branch_and_module( $changes );

    is( $branch, $wanted_branch,
        "branch detection in [$test_name] (@$files) =~ (@$res)" );
    is( $module, $wanted_module,
        "module detection in [$test_name] (@$files) =~ (@$res)" );
    is( "@$changes", $rest, "file list for [$test_name]" );
}

test_matching(
    'module and branch',
    '/kgb/trunk/some/file',
    '^/([^/]+)/([^/]+)/', 1,
    'trunk', 'kgb', 'some/file',
);

test_matching(
    'branch and module',
    '/trunk/kgb/some/file',
    '^/([^/]+)/([^/]+)/', 0,
    'trunk', 'kgb', 'some/file',
);

test_matching(
    'branch only',
    '/trunk/some/file',
    '^/([^/]+)/()', 0,
    'trunk', '', 'some/file',
);

test_matching(
    'module only',
    '/website/some/file',
    '^/(website)/()', 1,
    '', 'website', 'some/file',
);

test_matching(
    'real example',
    'kgb/trunk/script/kgb-bot',
    [   "^([^/]+)/(trunk|tags)/",
        "^([^/]+)/branches/([^/]+)/",
        "^(website)/()",
    ], 1,
    'trunk', 'kgb', 'script/kgb-bot',
);

test_matching(
    'multi-file in one dir',
    [ 'kgb/trunk/script/kgb-bot', 'kgb/trunk/script/kgb-client' ],
    [   "^([^/]+)/(trunk|tags)/",
        "^([^/]+)/branches/([^/]+)/",
        "^(website)/()",
    ], 1,
    'trunk', 'kgb', 'script/kgb-bot script/kgb-client',
);

test_matching(
    'multi-module',
    [ 'trunk/foo/debian/moo', 'trunk/bar/debian/goo' ],
    [   "^(trunk|tags)/([^/]+)/",
        "^branches/([^/]+)/([^/]+)/",
        "^(website)/()",
    ], 0,
    undef, undef, 'trunk/foo/debian/moo trunk/bar/debian/goo',
);

test_matching(
    'multi-module with separated modules',
    [ 'foo/trunk/debian/moo', 'bar/trunk/debian/goo' ],
    [   "^([^/]+)/(trunk|tags)/",
        "^([^/]+)/branches/([^/]+)/",
        "^(website)/()",
    ], 1,
    undef, undef, 'foo/trunk/debian/moo bar/trunk/debian/goo',
);

done_testing();
