package Dancer::Plugin::Legacy::Routing;

use strict;
use warnings;

use Dancer qw(:syntax);
use Dancer::Plugin;

our $VERSION = '0.0.4'; # VERSION
# ABSTRACT: Dancer Plugin for Deprecating Existing Routes

=pod

=encoding utf8

=head1 NAME

Dancer::Plugin::Legacy::Routing - Dancer Plugin for Deprecating Existing Routes

=head1 SYNOPSIS

    package MyDancerApp;

    use strict;
    use warnings;

    use Dancer;
    use Dancer::Plugin::Legacy::Routing;

    get        "/my/fancy/new/route"  => \&still_good_controller;
    legacy_get "/my/stinky/old/route" => \&still_good_controller;

    sub still_good_controller {
      status 200;
      return "Plugins Rocks!";
    }

=head1 DESCRIPTION

Often times in refactoring and general software development of web applications a developer will
find themselves with the need to support all existing routes while at the same time building out
a better set of routes.  The major problem here is to find all applications, templates, bookmarks,
and all other references to these old routes, that is not always possible.

Enter Dancer::Plugin::Legacy::Routing, this plugin for Dancer allows you to clean up and improve
all of your routes while still maintaining all of your old ones in a clean and easy to see and
understand way.  You can even optionally get log entries that will tell you how people are getting
to your old routes and how often they are being called.

=head2 Configuration

Dancer::Plugin::Legacy::Routing makes use of the standard Dancer environment based routing.  Since
this is a plugin, be sure to include this is the correct place under plugins.

=head3 Options

=head4 log

Currently "log" is the only option (this will likely be built out in future versions).  Having this
set to a truthy value will result in messages being written (with the level of I<info>) to your dancer
log file.

    [30494]  info @0.000631> [hit #2]Legacy Route GET '/legacy/get' referred from '(none)' in repos/Dancer-Plugin-Legacy-Routing/lib/Dancer/Plugin/Legacy/Routing.pm l. 32


=head3 YAML Example Configuration File

    logger: file
    log: info
    warnings: 1
    show_errors: 1
    auto_reload: 0

    plugins:
      Legacy::Routing:
        log: 1

B<NOTE> The name of this plugin is Legacy::Routing, that is what you want to specify in your
environment's configuration file.

=head1 METHODS

The standard HTTP methods are available for you to legacy-ify, including any.

=head2 legacy_get

    get "/good/get"          => \&test_get;
    legacy_get "/legacy/get" => \&test_get;

    get "/good/get/:var"          => \&test_get_with_var;
    legacy_get "/legacy/get/:var" => \&test_get_with_var;

    get "/good/get/:var/params"          => \&test_get_with_params;
    legacy_get "/legacy/get/:var/params" => \&test_get_with_params;

=cut

register legacy_get => sub {
    my $pattern = shift;
    my $code    = shift;

    my $conf = plugin_setting();

    my $hooked_code = sub {
        $conf->{log} and _log_request();
        &$code();
    };

    get $pattern, $hooked_code;
};

=head2 legacy_post

    post "/good/post"          => \&test_post;
    legacy_post "/legacy/post" => \&test_post;

    post "/good/post/:var"          => \&test_post_with_var;
    legacy_post "/legacy/post/:var" => \&test_post_with_var;

    post "/good/post/:var/params"          => \&test_post_with_params;
    legacy_post "/legacy/post/:var/params" => \&test_post_with_params;

=cut

register legacy_post => sub {
    my $pattern = shift;
    my $code    = shift;

    my $conf = plugin_setting();

    my $hooked_code = sub {
        $conf->{log} and _log_request();
        &$code();
    };

    post $pattern, $hooked_code;
};

=head2 legacy_put

    put "/good/put"          => \&test_put;
    legacy_put "/legacy/put" => \&test_put;

    put "/good/put/:var"          => \&test_put_with_var;
    legacy_put "/legacy/put/:var" => \&test_put_with_var;

    put "/good/put/:var/params"          => \&test_put_with_params;
    legacy_put "/legacy/put/:var/params" => \&test_put_with_params;

=cut

register legacy_put => sub {
    my $pattern = shift;
    my $code    = shift;

    my $conf = plugin_setting();

    my $hooked_code = sub {
        $conf->{log} and _log_request();
        &$code();
    };

    put $pattern, $hooked_code;
};

=head2 legacy_del

    del "/good/delete"          => \&test_del;
    legacy_del "/legacy/delete" => \&test_del;

    del "/good/delete/:var"          => \&test_del_with_var;
    legacy_del "/legacy/delete/:var" => \&test_del_with_var;

    del "/good/delete/:var/params"          => \&test_del_with_params;
    legacy_del "/legacy/delete/:var/params" => \&test_del_with_params;

=cut

register legacy_del => sub {
    my $pattern = shift;
    my $code    = shift;

    my $conf = plugin_setting();

    my $hooked_code = sub {
        $conf->{log} and _log_request();
        &$code();
    };

    del $pattern, $hooked_code;
};

=head2 legacy_any

    any "/good/any"          => \&test_any;
    legacy_any "/legacy/any" => \&test_any;

=cut

register legacy_any => sub {
    my $pattern = shift;
    my $code    = shift;

    my $conf = plugin_setting();

    my $hooked_code = sub {
        $conf->{log} and _log_request();
        &$code();
    };

    any $pattern, $hooked_code;
};

sub _log_request {
    info "Legacy Route "
      . request->method . " '"
      . request->path
      . "' referred from '"
      . ( defined request->referer ? request->referer : "(none)" ) . "'";

    return;
}

register_plugin;
1;

__END__

=pod

=head1 AUTHORS

Robert Stone C<< <drzigman AT cpan DOT org > >>

=head1 COPYRIGHT & LICENSE

Copyright 2014 Robert Stone

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU Lesser General Public License as published by the Free Software Foundation; or any compatible license.

See http://dev.perl.org/licenses/ for more information.

=cut
