package App::PAUSE::Comaint::PackageScanner;
use strict;

use LWP::UserAgent;
use YAML;

sub new {
    my($class, $base_url) = @_;
    my $self = {
        ua          => LWP::UserAgent->new(agent => __PACKAGE__),
        api_version => 'v1.0',
        base_url    => $base_url,
    };
    bless $self, $class;
}

sub ua          { $_[0]->{ua}          }
sub base_url    { $_[0]->{base_url}    }
sub api_version { $_[0]->{api_version} }

sub find {
    my($self, $want) = @_;

    my $url = sprintf '%s/%s/package/%s', $self->base_url, $self->api_version, $want;
    my $res = $self->ua->get($url);
    return unless $res->is_success;

    my $package = YAML::Load($res->content);
    return sort keys %{ $package->{provides} };
}

1;
