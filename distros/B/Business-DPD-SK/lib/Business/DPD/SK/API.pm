package Business::DPD::SK::API;

use 5.010;
use Moose;

our $VERSION = '0.01';

use LWP::UserAgent;
use HTTP::Request;
use JSON::XS;
use Carp qw(croak);
use File::Spec;
use Config::INI::Reader;
use Business::DPD::SK::SPc;

has 'config_file' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {File::Spec->catfile(Business::DPD::SK::SPc->sysconfdir, 'dpd-sk', 'api.ini')},
);
has 'api_config' => (is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_api_config');

foreach my $key (qw(base_url api_email api_key delis_id sender_address_id)) {
    has $key => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my ($self) = @_;
            my $value = $self->api_config->{$key};
            croak "no $key in " . $self->config_file
                unless defined($value) && length($value);
            return $value;
        },
    );
}

has '_ua'   => (is => 'ro', isa => 'Object', required => 1, lazy => 1, builder => '_build__ua');
has '_json' => (is => 'ro', isa => 'Object', required => 1, lazy => 1, builder => '_build__json');

sub _build_api_config {
    my ($self) = @_;
    my $config = Config::INI::Reader->read_file($self->config_file)->{api};
    croak 'no [api] section in ' . $self->config_file
        unless $config;
    return $config;
}

sub _build__json {
    return JSON::XS->new->pretty->canonical->utf8;
}

sub _build__ua {
    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->env_proxy;
    return $ua;
}

sub create {
    my ($self, %create_args) = @_;

    my $sender_address_id = $self->sender_address_id;
    my $recipient_address = $create_args{recipient_address} // croak 'need recipient_address';
    my $parcels           = $create_args{parcels}           // croak 'need parcels';
    my $reference         = $create_args{reference}         // croak 'need reference';
    my $product_code      = $create_args{product_code}      // 1;
    my $labels_filename   = $create_args{labels_filename}   // croak 'need labels_filename';

    my %create_data = (
        'jsonrpc' => '2.0',
        'method'  => 'createV3',
        'id'      => undef,
        'params'  => {
            'DPDSecurity' => {
                'SecurityToken' => {
                    'Email'     => $self->api_email,
                    'ClientKey' => $self->api_key,
                }
            },
            'shipment' => [
                {   'addressRecipient' => $recipient_address,
                    "addressSender"    => {"id" => $self->sender_address_id},
                    "delisId"          => $self->delis_id,
                    "parcels"          => {"parcel" => $parcels,},
                    "product"          => $product_code,
                    "reference"        => $reference,
                    "services"         => {},
                }
            ],
        },
    );

    my $req = HTTP::Request->new(
        'POST', $self->base_url,
        ['Content-Type' => 'application/json'],
        $self->_json->encode(\%create_data)
    );
    my $res = $self->_ua->request($req);
    die 'request to DPD failed: ' . $res->status_line
        unless ($res->is_success);

    my $res_data = eval {$self->_json->decode($res->decoded_content)->{result}->{result}->[0]};
    die 'unknown response from DPD: ' . $@
        if $@;
    die 'request to DPD was not successful'
        unless $res_data->{success};
    my @res_parcels = @{$res_data->{parcels} // []};

    my $download_url = $res_data->{label};
    my $res2 = $self->_ua->request(HTTP::Request->new('GET', $download_url), $labels_filename);
    die 'request to DPD label fetch failed: ' . $res2->status_line
        unless ($res2->is_success);

    return {
        parcels => \@res_parcels,
        msid    => $res_data->{mpsId},
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Business::DPD::SK::API - create DPD Slovakia shipments and fetch labels

=head1 SYNOPSIS

    use Business::DPD::SK::API;

    # account settings and endpoint from dpd-sk/api.ini
    my $api = Business::DPD::SK::API->new();
    my $res = $api->create(
        recipient_address => {...},
        parcels           => [{weight => 2.5}],
        reference         => 'PO-1',
        labels_filename   => '/tmp/labels.pdf',
    );
    say $res->{msid};

    # constructor arguments override the config file
    my $other = Business::DPD::SK::API->new(
        config_file => '/etc/dpd-sk/api-other.ini',
        base_url    => 'https://api.dpd.sk/shipment/json',
    );

=head1 DESCRIPTION

Thin client for the C<createV3> method of the DPD Slovakia shipment JSON-RPC
API. One call to L</create> registers one shipment with one or more parcels
and saves the label PDF that DPD returns.

=head2 Configuration file

The endpoint and the account settings come from the INI file in
L</config_file>, by default F<dpd-sk/api.ini> below
L<Business::DPD::SK::SPc/sysconfdir> (for example
F</etc/dpd-sk/api.ini> after C<./Build install>). Its C<[api]> section has one
key per attribute:

    [api]
    ; test endpoint
    base_url=https://capi.dpd.sk/shipment/json
    ; production endpoint
    ;base_url=https://api.dpd.sk/shipment/json
    api_email=user@example.com
    api_key=secret
    delis_id=DELIS_ID
    sender_address_id=0

The shipped file selects the test endpoint
C<https://capi.dpd.sk/shipment/json> and holds placeholder account values.
B<To create real shipments, switch the C<base_url> lines to the production
endpoint and fill in the real account values.> DPD may issue separate
credentials for the test and production endpoints; keep them matching the
active C<base_url>.

Each of the five attributes takes its value from the constructor if given,
otherwise from the file. The file is read once, the first time a value is
needed that the constructor did not supply. An object built with all five
values never reads the file.

The file holds the API key. C<./Build install> installs it with mode C<0640>;
give the group of the user that runs the client read access.

=head1 ATTRIBUTES

All attributes are read-only and can only be set through the constructor.
The five API attributes croak with C<no KEY in FILE> on first use when neither
the constructor nor the config file supplies them. An empty value in the
file, such as C<api_key=>, counts as missing.

=head2 config_file

Path of the INI file described in L</Configuration file>. Defaults to
F<dpd-sk/api.ini> below L<Business::DPD::SK::SPc/sysconfdir>.

=head2 api_config

Hash reference with the C<[api]> section of L</config_file>, read on first
use. Croaks with C<no [api] section in FILE> if the section is missing, and
with L<Config::INI::Reader>'s error if the file cannot be read.

=head2 base_url

URL the JSON-RPC requests are POSTed to. Config key C<base_url>.

=head2 api_email

=head2 api_key

Credentials sent as C<DPDSecurity/SecurityToken> (C<Email> and C<ClientKey>)
in every request. Config keys C<api_email> and C<api_key>.

=head2 delis_id

DPD customer (DELIS) identifier, sent as C<delisId> in the shipment. Config
key C<delis_id>.

=head2 sender_address_id

ID of the sender address registered with DPD, sent as
C<< addressSender => {id => ...} >>. Config key C<sender_address_id>.

=head1 METHODS

=head2 create

    my $res = $api->create(%args);

Creates one shipment and downloads its labels.

Arguments:

=over

=item recipient_address

Required. Hash reference in DPD's C<addressRecipient> format. It is passed to
DPD unchanged and not validated.

=item parcels

Required. Array reference of DPD parcel hashes, for example
C<< [{weight => 2.5}] >>. Sent as C<< parcels => {parcel => [...]} >>.

=item reference

Required. Your own reference for the shipment, such as an order number.

=item labels_filename

Required. Path of the file the label PDF is written to. An existing file is
overwritten.

=item product_code

Optional, defaults to C<1>. DPD product, sent as C<product>.

=back

C<create> croaks with C<need ARGUMENT> if a required argument is missing.
The shipment is sent without services (C<services> is an empty hash).

The method makes two HTTP requests: the JSON-RPC POST to L</base_url>, then a
plain GET of the label URL from the response, saved straight into
C<labels_filename>. The label GET carries no credentials. Both use a
10 second timeout and honour the proxy variables read by
L<LWP::UserAgent/env_proxy> (C<http_proxy>, C<https_proxy>, C<no_proxy>).

Returns a hash reference:

    {
        parcels => [...],   # parcel records from DPD's response, as-is
        msid    => '...',   # DPD's mpsId (multi-parcel shipment ID)
    }

C<parcels> is an empty array if DPD returns none.

Dies with one of these messages:

=over

=item C<request to DPD failed: STATUS_LINE>

The shipment POST returned a non-2xx status or failed at transport level.

=item C<unknown response from DPD: ...>

The response body was not JSON or did not have the expected
C<result.result[0]> structure.

=item C<request to DPD was not successful>

DPD answered, but C<success> was false. The message does not include DPD's
error details.

=item C<request to DPD label fetch failed: STATUS_LINE>

The shipment exists at DPD, but downloading the label failed. B<Do not retry
C<create> blindly>: that registers a second shipment. The failure happens after
the shipment is registered and the parcels and C<msid> are lost to the caller.

=back

=head1 SEE ALSO

L<Business::DPD::SK>, L<Business::DPD::SK::SPc>

=cut
