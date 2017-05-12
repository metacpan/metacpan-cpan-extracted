# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2;

use strict;
use warnings;
no warnings 'deprecated';
use Danga::Socket;
use AxKit2::Client;
use AxKit2::Server;
use AxKit2::Config;
use AxKit2::Console;
use AxKit2::Constants qw(LOGINFO);

use constant AIO_AVAILABLE => eval { require IO::AIO };

our $VERSION = '1.1';

sub run {
    my $class       = shift;
    my $configfile  = shift;
    
    my $config = AxKit2::Config->new($configfile);
    
    local $SIG{'PIPE'} = "IGNORE";  # handled manually
    
    # config server
    AxKit2::Console->create(AxKit2::Config->global);
    
    # setup server
    for my $server ($config->servers) {
        AxKit2::Server->create($server);
    }
    
    if (AIO_AVAILABLE) {
        AxKit2::Client->log(LOGINFO, "Adding AIO support");
        Danga::Socket->AddOtherFds (IO::AIO::poll_fileno() =>
                                    \&IO::AIO::poll_cb);
    }

    # print $_, "\n" for sort keys %INC;
    
    Danga::Socket->EventLoop();
}

1;

=head1 NAME

AxKit2 - XML Application Server

=head1 SYNOPSIS

Just start the server:

  $ cp etc/axkit.conf.sample etc/axkit.conf
  $ ./axkit

To do anything more than run the demo files you'll need to read the
documentation and start writing plugins.

=head1 DESCRIPTION

AxKit2 is the second generation XML Application Server following in the
footsteps of AxKit-1 (ONE). AxKit makes content generation easy by providing
powerful tools to push XML through stylesheets. This helps ensure your web
applications don't suffer from XSS bugs, and provides standardised templating
tools so that your template authors don't need to learn new Perl templating
tools.

In doing all this AxKit harnesses the power of XML. Feel the power.

=head1 PLUGINS

Everything AxKit2 does is controlled by a plugin, and thus a lot of the
documentation for things that AxKit2 does is held within the provided plugins.

To get started writing plugins see L<AxKit2::Docs::WritingPlugins>.

=head2 CORE PLUGINS

The following are the core plugins which ship with AxKit2:

=over 4

=item * B<cachecache> - A cache plugin that gives every plugin access to a
cache.

See L<plugins::cachecache>.

=item * B<dir_to_xml> - Provides XML for a directory request.

See L<plugins::dir_to_xml>.

=item * B<error_xml> - When an exception/error occurs this plugin generates
XML (with an optional stacktrace) for what happened, and allows you to apply
XSLT to that XML to display it in the browser.

See L<plugins::error_xml>.

=item * B<fast_mime_map> - Maps files to a MIME type for output in the
F<Content-Type> header using the file extension only.

See L<plugins::fast_mime_map>.

=item * B<magic_mime_map> - Maps files to a MIME type using F<File::MMagic>.

See L<plugins::magic_mime_map>.

=item * B<request_log> - Logs requests in the Apache combined log format.

See L<plugins::request_log>.

=item * B<serve_cgi> - Runs CGI scripts.

See L<plugins::serve_cgi>.

=item * B<serve_file> - Serves plain files.

See L<plugins::serve_file>.

=item * B<stats> - Provides access statistics for the console.

See L<plugins::stats>.

=item * B<uri_to_file> - Maps URLs to filenames.

See L<plugins::uri_to_file>.

=item * B<logging/warn> - Logging output to STDERR via warn().

See L<plugins::logging::warn>.

=back

=head1 CONSOLE

AxKit2 has a console which you can log into to view current and trend activity
on your server. To setup the console add the following config:

  ConsolePort 18000
  Plugin stats

This creates the console on C<localhost:18000>, and loads the stats plugin to
provide trend statistics on your server. To use the console just telnet to
port 18000. There is online help there and it should be obvious what each
function does.

To provide additional stats, modify the stats plugin or write your own. Whatever
C<get_stats> returns will be output in the console when asked for statistics.

=head1 API DOCUMENTATION

TODO - fill in as I write more docs for each module.

=head1 Why 2.0?

In creating AxKit2 the following goals were aimed for:

=over 4

=item * Make it easier to setup and get started with than before.

=item * Make it faster.

=item * Make building complex web applications easier.

=item * Make easy to extend and hack on.

=item * Make complex pipelines and caching schemes easier.

=back

Many people wanted a straight port to Apache2/mod_perl2, so that they could
get their AxKit code migrated off the Apache1.x platform. This would have been
one route to go down, a route which we looked at very seriously. However already
taking up the mantle of an Apache2 version of AxKit is Tom Schindl's
Apache2::TomKit distribution. Please check that out if you absolutely need
mod_perl2 integration.

=head1 LICENSE

AxKit2 is licensed under the Apache License, Version 2.0.

=cut
