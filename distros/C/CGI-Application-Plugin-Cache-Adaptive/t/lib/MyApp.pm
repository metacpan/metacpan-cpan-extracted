package MyApp;

use strict;
use warnings;

use base qw(CGI::Application);

use CGI::Application::Plugin::Cache::Adaptive;
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Session;

use Cache::FileCache;

sub setup {
    my ($self, @args) = @_;

    my $cgiapp = $self;

    $self->cache_adaptive({
        backend => Cache::FileCache->new({
            namespace => 'html_cache',
            max_size  => 10 * 1024 * 1024,
        }),
        expires_min => 3,
        expires_max => 60,
        check_load  => sub {
            my $entry = shift;
            int($entry->{process_time} * 2) - 1;
        },
        log => sub {
            my $logs = shift;

            if (ref $logs eq 'HASH' && exists $logs->{type}) {
                $cgiapp->{"Cache::Adaptive::type"} = $logs->{type};
            }
        }
    });

    $self->session;
    # $self->session->param('foo' => 1);
}

sub do_test1 : StartRunmode Cacheable(qw/path path_info query/) {
    sleep 3;
    return "test1";
}

sub do_test2 : Runmode Cacheable(qw/path path_info query/) {
    sleep 3;
    return "test2";
}

sub do_test3 : Runmode Cacheable(qw/path path_info query session/) {
    my $self = shift;
    sleep 3;
    return $self->session->id;
}

1;
