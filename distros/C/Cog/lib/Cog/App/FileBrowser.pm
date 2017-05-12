package Cog::App::FileBrowser;
use Mo;
extends 'Cog::App';

use constant webapp => 'Cog::App::FileBrowser::WebApp';

package Cog::App::FileBrowser::WebApp;
use Mo;
extends 'Cog::WebApp';

use constant index_file => 'index.html';

sub site_navigation {
    [
        ['Home' => '/home/'],
        ['Files' => '/files/'],
        ['Tags' => '/tags/'],
    ]
}

sub url_map {
    [
        ['/' => 'redirect', ('/home/')],
        ['/home/' => 'about_cog'],
        ['/files/' => 'files_list'],
        ['/tags/' => 'tags_list'],
    ];
}

sub js_files {
    [qw(
        jquery-1.4.4.min.js
        jquery.cookie.js
        jemplate.js
        separator.js
        cog.js
        config.js
        url-map.js
        start.js
    )]
}

sub css_files {
    [qw(
        layout.css
        page-list.css
        page-display.css
    )];
}

sub image_files {
    [qw(
        tile.gif
        cog.png
    )];
}

sub template_files {
    [qw(
        config.js
        js-mf.mk
        css-mf.mk

        layout.html
        site-navigation.html
        page-list.html
        page-display.html
        tag-list.html
        404.html
    )];
}

1;
