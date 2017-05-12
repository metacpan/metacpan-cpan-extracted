# TODO:
#
# Redo fingerprinting
package Cog::Runner;
use Mo;
extends 'Cog::Base';

use Plack::Builder;
use Plack::Runner;

sub fingerprinted { $_[0]->{PATH_INFO} =~ /[0-9a-f]{32}/ }
use constant MAX_DATE => 'Sun, 17-Jan-2038 19:14:07 GMT';

sub app {
    my $self = shift;
    return builder {
        # Serve cached stuff...
        enable 'Cache' => (
            match_url => $self->config->cache_urls,
            cache_dir => 'cache',
        ) if $self->config->cache_urls;
        # If this is a proxy url, just serve that.
        enable 'ProxyMap' => (
            proxymap => $self->config->proxymap,
        ) if $self->config->proxymap;
        # Fingerprinted files live forever
        enable_if sub { fingerprinted(@_) },
            'Header', set => ['Expires' => MAX_DATE];
        # All other files get ETagged
        enable_if sub { ! fingerprinted(@_) },
            'Header', set => ['Cache-Control' => 'no-cache'];
        enable 'ConditionalGET';
        enable 'ETag', file_etag => [qw/inode mtime size/];
        # Serve static files from disk
        if (my $rewrites = $self->webapp->rewrite) {
            enable 'Rewrite', rules => sub {
                for my $rewrite (@$rewrites) {
                    s!$rewrite->[0]!$rewrite->[1]! and last;
                }
                return;
            };
        }
        enable 'Static',
            path => qr{^/(all-.*\.(css|js)|image/)},
            root => $self->config->app->webapp_root;
        # Everything else is from the web app.
        $self->webapp->web_app;
    }
}

sub run {
    my $self = shift;
    my @args = $self->get_args(@_);
    my $runner = Plack::Runner->new;
    $runner->parse_options(@args);
    $runner->run($self->app);
}

# TODO integrate these into config
sub get_args {
    my $self = shift;
    my %args = @_;
    if ($ENV{COG_HOST}) {
        delete @args{qw(--host -h)};
        $args{'--host'} = $ENV{COG_HOST};
    }
    if ($ENV{COG_PORT}) {
        delete @args{qw(--port -p)};
        $args{'--port'} = $ENV{COG_PORT};
    }
    if ($ENV{COG_SERVER}) {
        delete @args{qw(--server -s)};
        $args{'--server'} = $ENV{COG_SERVER};
    }
    if ($ENV{COG_DAEMONIZE}) {
        delete @args{qw(--daemonize -D)};
        $args{'--daemonize'} = $ENV{COG_DAEMONIZE};
        $args{'--pid'} = 'cog.pid';
    }
    if ($ENV{COG_LOG}) {
        delete @args{qw(--access-log)};
        $args{'--access-log'} = $ENV{COG_LOG};
    }
    return %args;
}

1;
