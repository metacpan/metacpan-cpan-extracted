package App::Ordo::API;
use Moo;
use feature qw(say);
use Mojo::UserAgent;
use JSON qw(decode_json encode_json);
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::ShareDir qw(dist_file);

has 'ua' => (is => 'lazy');
has 'config_file' => (
    is      => 'ro',
    default => sub { "$ENV{HOME}/.config/App-ordo/ordo_config.json" },
);

has 'config' => (is => 'lazy');

has 'tz' => (is => 'lazy');
sub _build_tz { DateTime::TimeZone::Local->TimeZone->name }

sub _build_ua { Mojo::UserAgent->new->inactivity_timeout(10) }

sub _build_config {
    my $self = shift;

    unless (-f $self->config_file) {
        make_path("$ENV{HOME}/.config/App-ordo");
        my $default = dist_file('App-ordo', 'ordo_config.json');
        copy($default, $self->config_file) or die "Cannot copy config: $!";
        say "Created default config at " . $self->config_file;
    }

    open my $fh, '<', $self->config_file or die "Cannot read config";
    my $json = decode_json(do { local $/; <$fh> });
    close $fh;

    return $json;
}

sub call {
    my ($self, $command, $params) = @_;
    $params->{command} = $command;
    $params->{token} //= $self->config->{token};

    my $tx = $self->ua->post($self->config->{api} => json => $params);
    my $res = $tx->res->json // { success => 0, message => $tx->res->message || 'Unknown' };
    return $res;
}

1;
