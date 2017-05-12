package TestApp;
use Moose;
use File::Temp qw/ tempdir /;
use namespace::autoclean;

use Catalyst qw/
    +CatalystX::Resource
    Session
    Session::Store::File
    Session::State::Cookie
/;
extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestApp',
    'Plugin::Session' => {
        storage        => tempdir(CLEANUP => 1),
        flash_to_stash => 1,
    },
    'Model::DB' => {
        connect_info => {
            dsn => 'dbi:SQLite:dbname=:memory:',
            user => '',
            password => '',
        },
    },
    'View::HTML' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to( 'root', 'templates' )
        ],
        TEMPLATE_EXTENSION => '.tt',
        WRAPPER => 'wrapper.tt',
        ENCODING => 'UTF-8',
        render_die => 1,
    },
    'Controller::Resource::Concert' => {
        resultset_key => 'concerts',
        resource_key => 'concert',
        parent_key => 'artist',
        parents_accessor => 'concerts',
        form_class => 'TestApp::Form::Resource::Concert',
        model => 'DB::Resource::Concert',
        traits => ['-Delete'],
        identifier_candidates => [ 'location' ],
        actions => {
            base => {
                PathPart => 'concerts',
                Chained  => '/resource/artist/base_with_id',
            },
        },
    },
    'Controller::Resource::Album' => {
        resultset_key => 'albums',
        resource_key => 'album',
        parent_key => 'artist',
        parents_accessor => 'albums',
        form_class => 'TestApp::Form::Resource::Album',
        model => 'DB::Resource::Album',
        actions => {
            base => {
                PathPart => 'albums',
                Chained  => '/resource/artist/base_with_id',
            },
        },
    },
    'Controller::Resource::Song' => {
        resultset_key => 'songs',
        resource_key => 'song',
        form_class => 'TestApp::Form::Resource::Song',
        model => 'DB::Resource::Song',
        parent_key => 'album',
        parents_accessor => 'songs',
        traits => ['Sortable'],
        actions => {
            base => {
                PathPart => 'songs',
                Chained  => '/resource/album/base_with_id',
            },
        },
    },
    'Controller::Resource::Artwork' => {
        resultset_key => 'artworks',
        resource_key => 'artwork',
        form_class => 'TestApp::Form::Resource::Artwork',
        model => 'DB::Resource::Artwork',
        parent_key => 'album',
        parents_accessor => 'artworks',
        redirect_mode => 'show_parent',
        traits => ['Sortable', '-List'],
        actions => {
            base => {
                PathPart => 'artworks',
                Chained  => '/resource/album/base_with_id',
            },
        },
    },
    'Controller::Resource::Lyric' => {
        resultset_key => 'lyrics',
        resource_key => 'lyric',
        form_class => 'TestApp::Form::Resource::Lyric',
        model => 'DB::Resource::Lyric',
        parent_key => 'album',
        parents_accessor => 'lyrics',
        redirect_mode => 'show',
        traits => ['Sortable'],
        actions => {
            base => {
                PathPart => 'lyrics',
                Chained  => '/resource/album/base_with_id',
            },
        },
    },
    'CatalystX::Resource' => {
        error_path => '/error404',
        controllers => [ qw/
            Resource::Concert
            Resource::Album
            Resource::Song
            Resource::Artwork
            Resource::Lyric
        / ],
     },
);

__PACKAGE__->setup();

1;
