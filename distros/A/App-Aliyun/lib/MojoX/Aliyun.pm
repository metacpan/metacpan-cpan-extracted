package MojoX::Aliyun;

use strict;
use warnings;
use v5.10;
use Carp qw/croak/;
use Mojo::Base -base;
use Mojo::UserAgent;

use DateTime;
use Digest::SHA qw(hmac_sha1_base64);
use URI::Escape;
use Data::UUID;

our $VERSION = '0.01';

has 'ua' => sub {
    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name("MojoX-Aliyun $VERSION");
    return $ua;
};

has 'access_key';
has 'access_secret';
has 'region_id';

sub request {
    my ($self, $method, $url, $params) = @_;

    croak 'access_key and access_secret are required' unless $self->access_key and $self->access_secret;

    # alias
    if ($url =~ /^\w+$/) {
        $url = "https://$url.aliyuncs.com/";
    }

    my $uri = Mojo::URL->new($url);
    my $path = $uri->path;

    my $Version = '2014-05-26';
    $Version = '2014-08-15' if $url =~ 'rds\.';

    my $ug   = Data::UUID->new;
    my $uuid = $ug->to_string($ug->create());
    my %auth_params = (
        Timestamp => sprintf("%s", DateTime->now()),
        Format    => 'JSON',
        Version   => $Version,
        SignatureMethod  => 'HMAC-SHA1',
        SignatureVersion => '1.0',
        SignatureNonce   => $uuid,
        AccessKeyId => $self->access_key,
        $self->region_id ? (RegionId => $self->region_id) : (),
        $params ? %$params : (),
    );

    # say Dumper(\%auth_params); use Data::Dumper;

    # Thanks to https://github.com/lemontv/AliyunPerlLib/blob/master/Aliyun/Auth.pm
    my %dumb = %auth_params; $dumb{Timestamp} = uri_escape($dumb{Timestamp});
    my @tmps = map { join('=', $_, $dumb{$_}) } sort keys(%dumb);
    my $StringToSign = join("&",  @tmps);
    $StringToSign = join('&', $method, uri_escape($path), uri_escape($StringToSign));
    my $Signature = hmac_sha1_base64($StringToSign, $self->access_secret . '&');
    $auth_params{Signature} = $Signature . '=';

    my $tx = $self->ua->build_tx($method => $url => form => \%auth_params );
    $tx = $self->ua->start($tx);

    return $tx->res->json if ($tx->res->headers->content_type || '') =~ /json/;

    my $err = $tx->error;
    croak "$err->{code} response: $err->{message}" if $err->{code};
    croak "Connection error: $err->{message}";
}

1;