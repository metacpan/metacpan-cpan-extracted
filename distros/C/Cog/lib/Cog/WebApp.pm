package Cog::WebApp;
use Mo;
extends 'Cog::Base';

has env => ();

use constant index_file => '';
use constant plugins => [];
use constant site_navigation => [];
use constant url_map => [];
use constant post_map => [];
use constant coffee_files => [];
use constant js_files => [qw(
    jquery.js
    jquery-ui.js
    jquery-json.js
    jquery.cookie.js
    jquery.jemplate.js
    jemplate.js
    cog.js
    config.js
    url-map.js
    fixups.js
)];
use constant css_files => [qw(
    reset.css
    layout.css
    layout-table.css
)];
use constant image_files => [];
use constant template_files => [];
use constant runner_class => 'Cog::Runner';
use constant rewrite => undef;

sub web_app {
    my $self = shift;
    my $webapp = $self->app->webapp_root;
    my $index_file = "$webapp/index.html";
    open INDEX, $index_file or die "Can't open '$index_file'";
    my $html = do {local $/; <INDEX>};
    close INDEX or die;

    my $time = scalar(gmtime);
    $time .= ' GMT' unless $time =~ /GMT/;
    return sub {
        my $env = shift;
        return $env->{REQUEST_METHOD} eq 'POST'
            ? $self->handle_post($env)
            : [
                200, [
                    'Content-Type' => 'text/html',
                    'Last-Modified' => $time,
                ], [$html]
            ];
    };
}

sub handle_post {
    # Call handler based on url
    # Return results or OK
    my $self = shift;
    $self->env(shift);
    $self->read_json;
    my $path = $self->env->{PATH_INFO};
    my $post_map = $self->config->post_map;
    my ($regexp, $action, @args, @captures);
    for my $entry (@$post_map) {
        ($regexp, $action, @args) = @$entry;
        if ($path =~ /^$regexp$/) {
            @captures = ('', $1, $2, $3, $4, $5);
            last;
        }
        undef $action;
    }
    return [501, [], ["Invalid POST request: '$path'"]] unless $action;
    @args = map {s/\$(\d+)/$captures[$1]/ge; ($_)} @args;
    my $method = "handle_$action";
    my $result = eval { $self->$method(@args) };
    if ($@) {
        warn $@;
        return [500, [], [ $@ ]];
    }
    $result = 'OK' unless defined $result;
    if (ref($result) eq 'ARRAY') {
        return $result;
    }
    elsif (ref($result) eq 'HASH') {
        return [
            200,
            [ 'Content-Type' => 'application/json' ],
            [ $self->json->encode($result) ]
        ];
    }
    else {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $result ] ];
    }
}

sub response_json {
    my ($self, $data) = @_;
    die "response_json() requires a hash or array" unless ref $data;
    my $json = $self->json->encode($data);
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ $json ],
    ];
}

sub read_json {
    my $self = shift;
    my $env = $self->env;
    return unless
#         $env->{CONTENT_TYPE} =~ m!application/json! and
        $env->{CONTENT_LENGTH};
    my $json = do { my $io = $env->{'psgi.input'}; local $/; <$io> };
    $env->{post_data} = $self->json->decode($json);
}

1;
