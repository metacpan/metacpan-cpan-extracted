use strict;
use warnings;
use utf8;
use Test::More;

use File::ShareDir;
use File::Basename qw(dirname);
our $BASE_DIR = dirname(__FILE__);

{
    package MyApp;
    use parent qw/Amon2/;
    sub base_dir { $::BASE_DIR }

    __PACKAGE__->load_plugins(
        'ShareDir',
    );
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
}

like(MyApp::Web->share_dir(), qr{^t.600_plugins.share$});
like(MyApp->share_dir(), qr{^t.600_plugins.share$});

no warnings 'redefine', 'once';
%Amon2::Plugin::ShareDir::SHARE_DIR_CACHE = ();
local *File::ShareDir::dist_dir = sub { "t/600_plugins/dist/$_[0]" };
local $BASE_DIR = '/notexistent/';

like(MyApp->share_dir(), qr!^t[/\\]600_plugins[/\\]dist[/\\]MyApp!);

done_testing;

