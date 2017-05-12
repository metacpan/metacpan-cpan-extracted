package MyApp::Model::TextLinkAds;

use base qw/ Catalyst::Model::TextLinkAds /;

__PACKAGE__->config(
    cache  => 0,      # optional: default uses Cache::FileCache
    tmpdir => '/tmp', # optional: default File::Spec->tmpdir
);


1;
