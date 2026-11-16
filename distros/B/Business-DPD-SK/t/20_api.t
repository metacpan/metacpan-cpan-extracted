use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP ();

# Deliberately no `use JSON::XS` or `use HTTP::Request` here: the module must
# load its own dependencies.
use Business::DPD::SK::API;

# Records requests and replays canned HTTP::Response objects.
{
    package FakeUA;
    require HTTP::Response;
    sub new { my ($class, @responses) = @_; return bless {responses => [@responses], requests => []}, $class }
    sub request {
        my ($self, $req, $filename) = @_;
        push @{$self->{requests}}, {request => $req, filename => $filename};
        my $res = shift @{$self->{responses}} or die 'unexpected request';
        if ($filename && $res->is_success) {
            open(my $fh, '>:raw', $filename) or die $!;
            print {$fh} $res->content;
            close($fh);
        }
        return $res;
    }
}

sub json_response {
    my ($code, $data) = @_;
    return HTTP::Response->new($code, 'x', ['Content-Type' => 'application/json'],
        JSON::PP->new->utf8->encode($data));
}

my %api_args = (
    api_email         => 'shipper@example.test',
    api_key           => 'test-key',
    delis_id          => 'DELIS1',
    sender_address_id => '42',
    base_url          => 'https://api.example.test/shipment/json',
);

my %create_args = (
    recipient_address => {name => 'Jane Doe', zip => '83101', country => 703},
    parcels           => [{weight => 2.5}],
    reference         => 'PO-1',
);

subtest 'create sends createV3 and stores the label' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $labels = File::Spec->catfile($dir, 'labels.pdf');
    my $ua = FakeUA->new(
        json_response(200, {
            result => {result => [{
                success => JSON::PP::true,
                parcels => [{parcelno => '0123'}],
                mpsId   => 'MPS1',
                label   => 'https://api.example.test/label/1',
            }]}
        }),
        HTTP::Response->new(200, 'OK', [], '%PDF-label'),
    );
    my $api = Business::DPD::SK::API->new(%api_args, _ua => $ua);

    my $res = $api->create(%create_args, labels_filename => $labels);
    is_deeply($res, {parcels => [{parcelno => '0123'}], msid => 'MPS1'}, 'parcels and mpsId returned');

    my $post = $ua->{requests}[0]{request};
    is($post->method . ' ' . $post->uri, "POST $api_args{base_url}", 'POST to the base URL');
    is_deeply(
        JSON::PP->new->utf8->decode($post->content),
        {   jsonrpc => '2.0',
            method  => 'createV3',
            id      => undef,
            params  => {
                DPDSecurity => {SecurityToken => {Email => 'shipper@example.test', ClientKey => 'test-key'}},
                shipment    => [{
                    addressRecipient => $create_args{recipient_address},
                    addressSender    => {id => '42'},
                    delisId          => 'DELIS1',
                    parcels          => {parcel => [{weight => 2.5}]},
                    product          => 1,
                    reference        => 'PO-1',
                    services         => {},
                }],
            },
        },
        'createV3 request body'
    );

    is($ua->{requests}[1]{request}->uri, 'https://api.example.test/label/1', 'label fetched');
    is($ua->{requests}[1]{filename}, $labels, 'into labels_filename');
    open(my $fh, '<:raw', $labels) or die $!;
    is(do {local $/; <$fh>}, '%PDF-label', 'label content written');
};

subtest 'errors' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my %args = (%create_args, labels_filename => File::Spec->catfile($dir, 'l.pdf'));

    my $api = Business::DPD::SK::API->new(%api_args, _ua => FakeUA->new(HTTP::Response->new(500, 'Boom')));
    throws_ok {$api->create(%args)} qr/request to DPD failed: 500/, 'HTTP error';

    $api = Business::DPD::SK::API->new(%api_args,
        _ua => FakeUA->new(json_response(200, {result => {result => [{success => JSON::PP::false}]}})));
    throws_ok {$api->create(%args)} qr/not successful/, 'unsuccessful response';

    $api = Business::DPD::SK::API->new(%api_args,
        _ua => FakeUA->new(HTTP::Response->new(200, 'OK', [], 'not json')));
    throws_ok {$api->create(%args)} qr/unknown response from DPD/, 'invalid JSON';

    throws_ok {$api->create(%create_args)} qr/need labels_filename/, 'missing argument';
};

sub write_ini {
    my ($content) = @_;
    my $ini = File::Spec->catfile(tempdir(CLEANUP => 1), 'api.ini');
    open(my $fh, '>', $ini) or die $!;
    print {$fh} $content;
    close($fh);
    return $ini;
}

my %ini_values = (
    base_url          => 'https://ini.example.test/shipment/json',
    api_email         => 'ini@example.test',
    api_key           => 'ini-key',
    delis_id          => 'INIDELIS',
    sender_address_id => '7',
);

subtest 'defaults are read from the config file' => sub {
    my $ini = write_ini(join('', "[api]\n", map {"$_=$ini_values{$_}\n"} sort keys %ini_values));
    my $api = Business::DPD::SK::API->new(config_file => $ini);
    is($api->$_, $ini_values{$_}, $_) for sort keys %ini_values;
};

subtest 'constructor arguments override and skip the config file' => sub {
    my $api = Business::DPD::SK::API->new(%api_args, config_file => '/nonexistent/api.ini');
    is($api->$_, $api_args{$_}, $_) for sort keys %api_args;
};

subtest 'missing configuration croaks' => sub {
    my $ini = write_ini("[api]\napi_email=ini\@example.test\napi_key=\n");
    my $api = Business::DPD::SK::API->new(config_file => $ini);
    throws_ok {$api->api_key} qr/no api_key in \Q$ini\E/, 'empty key';
    throws_ok {$api->delis_id} qr/no delis_id in \Q$ini\E/, 'missing key';

    $ini = write_ini("[other]\nx=1\n");
    $api = Business::DPD::SK::API->new(config_file => $ini);
    throws_ok {$api->base_url} qr/no \[api\] section in \Q$ini\E/, 'missing section';
};

done_testing();
