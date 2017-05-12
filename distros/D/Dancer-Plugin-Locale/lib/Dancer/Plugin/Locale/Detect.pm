package Dancer::Plugin::Locale::Detect;

our $VERSION = '0.0103';

use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Locale::Util;

{
    my $setting = plugin_setting;

    hook before => sub {
        my $param = exists $setting->{param} ? $setting->{param} : 'locale';
        my $parse_http_accept = exists $setting->{parse_http_accept} ? $setting->{parse_http_accept} : 1;

        if (my $loc = params->{$param}) {
            return if Locale::Util::web_set_locale($loc);
        }
        if ($parse_http_accept) {
            return if Locale::Util::web_set_locale(request->header('Accept-Language'));
        }
        if (my $loc = $setting->{default_locale}) {
            return if Locale::Util::web_set_locale($loc);
        }
        Locale::Util::web_set_locale('');
    };
}

register_plugin;

1;
