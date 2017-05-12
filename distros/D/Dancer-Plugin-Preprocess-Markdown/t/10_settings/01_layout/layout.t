use strict;
use warnings;
use Dancer;
use Dancer::Test;
use Test::More import => ['!pass'];

plan tests => 4;

set appdir => path(dirname(__FILE__), 'app');
set views => path(dirname(__FILE__), 'app', 'views');
set layout => 'main';
set plugins => {
    'Preprocess::Markdown' => {
        paths => {
            '/' => undef,
            '/1' => {
                src_dir => 'md/src',
                layout => 'layout1'
            },
            '/2' => {
                src_dir => 'md/src',
                layout => 'layout2'
            },
            '/3' => {
                src_dir => 'md/src',
                layout => undef
            }
        }
    }
};

Dancer::ModuleLoader->load('Dancer::Plugin::Preprocess::Markdown');

my $res = dancer_response(GET => '/foo.html');
like $res->content, qr/^main layout/, 'Default layout is applied';
$res = dancer_response(GET => '/1/foo.html');
like $res->content, qr/^layout 1/, 'Path-specific layout is applied';
$res = dancer_response(GET => '/2/foo.html');
like $res->content, qr/^layout 2/, 'Another path-specific layout is applied';
$res = dancer_response(GET => '/3/foo.html');
unlike $res->content, qr/^main layout/, 'No layout is applied';
