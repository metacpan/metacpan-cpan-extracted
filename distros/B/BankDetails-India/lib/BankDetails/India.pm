package BankDetails::India;
use strict;
use warnings;
use CHI;
use Carp qw (croak);
use LWP::UserAgent;
use Moose;
use Sereal qw(encode_sereal decode_sereal);
use Digest::MD5 qw(md5_hex);
use JSON;
use XML::Simple;
use Cwd;

our $VERSION = '1.0';

has user_agent => (
    is => 'ro',
    lazy => 1,
    builder => '_build_user_agent',
);
 
sub _build_user_agent {
    my $self = shift;
    return LWP::UserAgent->new;
}

has api_url => (
    isa => 'Str',
    is => 'ro',
    default => 'https://ifsc.razorpay.com/',
);

sub ping_api {
    my ($self) = @_;
    my $response = $self->user_agent->get($self->api_url);
    return ($response->code == 200) ? 1 : 0;
}

has 'cache_data' => (
    is      => 'rw',
    isa     => 'CHI::Driver',
    builder => '_build_cache_data',
);

my $cwd = getcwd();
sub _build_cache_data {
    my $cache = CHI->new(driver => 'File', 
                    namespace => 'BankDetailsIndiaIFSC',
                    root_dir => $cwd . '/cache/');
    return $cache;
}

sub get_all_data_by_ifsc {
    my ($self, $ifsc_code) = @_;

    return $self->get_response($self->api_url, $ifsc_code);
}

sub get_bank_name_by_ifsc {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'BANK'};
}

sub get_address_by_ifsc {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'ADDRESS'};
}

sub get_contact_by_ifsc {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'CONTACT'};
}

sub get_state_by_ifsc {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'STATE'};
}

sub get_district_by_ifsc {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'DISTRICT'};
}

sub get_city_by_ifsc {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'CITY'};
}

sub get_micr_code_by_ifsc {
    my ($self, $ifsc_code) = @_;
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'MICR'};
}

sub get_imps_value {
    my ($self, $ifsc_code) = @_;

    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'IMPS'};
}

sub get_neft_value {
    my ($self, $ifsc_code) = @_;
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'NEFT'};
}

sub get_rtgs_value {
    my ($self, $ifsc_code) = @_;
 
    my $data = $self->get_response($self->api_url, $ifsc_code);
    return $data->{'RTGS'};
}

sub download_json {
    my ($self, $ifsc_code, $file_name) = @_;
    return if ( !$self->ping_api );
    my $request_url = $self->api_url.$ifsc_code;
    my $response = $self->user_agent->get($request_url);
    $file_name ||= "bankdetails_$ifsc_code.json";
    open(my $fh, '>', $file_name) or die $!;
    print $fh $response->decoded_content;
    close($fh);
}

sub download_xml {
    my ($self, $ifsc_code, $file_name) = @_;
    return if ( !$self->ping_api );
    my $request_url = $self->api_url.$ifsc_code;
    my $response = $self->user_agent->get($request_url);
    my $response_data = decode_json($response->decoded_content);
    $self->_convert_json_boolean($response_data);
    my $xml = XMLout($response_data, RootName => 'data', NoAttr => 1);
    $file_name ||= "bankdetails_$ifsc_code.xml";
    open(my $fh, '>', $file_name) or die $!;
    print $fh $xml;
    close($fh);
}

sub get_response {
    my ($self, $endpoint, $ifsc) = @_;
    return if ( !$self->ping_api || !defined $endpoint || length $endpoint <= 0);

    $ifsc = uc($ifsc);
    my $request_url = $endpoint.$ifsc;
    my $cache_key = md5_hex(encode_sereal($ifsc));
    my $response_data;
    my $cache_response_data = $self->cache_data->get($cache_key);
    if (defined $cache_response_data) {
        $response_data = decode_sereal($cache_response_data);
    } else {
        my $response = $self->user_agent->get($request_url);
        my $response_content;

        if ($response->is_success) {
            $response_content = $response->decoded_content;
        } else {
            croak "Failed to fetch data: " . $response->status_line;
        }
        $response_data = decode_json($response_content);
        $self->_convert_json_boolean($response_data);
        $self->cache_data->set($cache_key, encode_sereal($response_data));
    }
    return $response_data;
}

sub _convert_json_boolean {
    my ( $self, $data ) = @_;

    if (ref($data) eq 'HASH') {
        foreach my $key (keys %$data) {
            if (ref($data->{$key}) eq 'JSON::PP::Boolean') {
                $data->{$key} = $data->{$key} ? 1 : 0;
            } elsif (ref($data->{$key}) eq 'HASH' || ref($data->{$key}) eq 'ARRAY') {
                $self->_convert_json_boolean($data->{$key});
            }
        }
    } elsif (ref($data) eq 'ARRAY') {
        for (my $i = 0; $i < scalar(@$data); $i++) {
            if (ref($data->[$i]) eq 'JSON::PP::Boolean') {
                $data->[$i] = $data->[$i] ? 1 : 0;
            } elsif (ref($data->[$i]) eq 'HASH' || ref($data->[$i]) eq 'ARRAY') {
                $self->_convert_json_boolean($data->[$i]);
            }
        }
    }
}

1;

__END__

=head1 NAME

BankDetails::India - Perl interface to access the ifsc.razorpay.com webservice.

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

  use BankDetails::India;

  my $api = BankDetails::India->new();
  $api->get_all_data_by_ifsc('KKBK0005652');

=head1 DESCRIPTION

BankDetails::India is a module that provides methods to fetch details of Indian banks
using their IFSC codes. It uses the Razorpay API to retrieve the bank details.

=head1 METHODS

=head2 new([%$args])

Construct a new BankDetails::India instance. Optionally takes a hash or hash reference.

    # Instantiate the class.
    my $api = BankDetails::India->new();

=head3 api_url

The URL of the API resource is read only attribute.

    # get the API endpoint.
    $api->api_url;

=head3 cache_data

The cache engine used to cache the web service API calls. By default, it uses
file-based caching.

    # Instantiate the class by setting the cache engine.
    my $api = BankDetails::India->new(
        CHI->new(
            driver => 'File',
            namespace => 'bankdetails',
            root_dir => '/tmp/cache/'
        )
    );

    # Set through method.
    $api->cache_data(CHI->new(
        driver => 'File',
        namespace => 'bankdetails',
        root_dir => '/tmp/cache/'
    ));

    # get cache engine.
    $api->cache_data

=head2 ping_api()

Checks whether the API endpoint is currently up.

    # Returns 1 if up or 0 if not.
    $api->ping_api();

=head2 get_all_data_by_ifsc

Fetches all the available bank details for the given IFSC code.

    my $data = $bank_details->get_all_data_by_ifsc($ifsc_code);

=head3 Arguments

=over 4

=item * C<$ifsc_code> (String, required) - The Indian Financial System Code (IFSC) of the bank branch.

=back

=head3 Returns

Returns a hashref containing various details related to the bank branch.

=head3 Data Structure

The returned hashref has the following structure:

    {
        IFSC => "SBIN0000123",
        BANK => "State Bank of India",
        ADDRESS => "Main Branch, Mumbai",
        CONTACT => "022-12345678",
        STATE => "Maharashtra",
        DISTRICT => "Mumbai",
        CITY => "Mumbai",
        MICR => "400002007",
        IMPS => 1,
        NEFT => 1,
        RTGS => 1,
    }

=head2 get_bank_name_by_ifsc($ifsc_code)

Get the name of the bank based on the provided IFSC code.

    $api->get_bank_name_by_ifsc('KKBK0005652');

=head2 get_address_by_ifsc($ifsc_code)

Get the address of the bank based on the provided IFSC code.

    $api->get_address_by_ifsc('KKBK0005652');

=head2 get_contact_by_ifsc($ifsc_code)

Get the contact number of the bank based on the provided IFSC code.

    $api->get_contact_by_ifsc('KKBK0005652');

=head2 get_state_by_ifsc($ifsc_code)

Get the state of the bank based on the provided IFSC code.

    $api->get_state_by_ifsc('KKBK0005652');

=head2 get_district_by_ifsc($ifsc_code)

Get the district of the bank based on the provided IFSC code.

    $api->get_district_by_ifsc('KKBK0005652');

=head2 get_city_by_ifsc($ifsc_code)

Get the city of the bank based on the provided IFSC code.

    $api->get_city_by_ifsc('KKBK0005652');

=head2 get_rtgs_value($ifsc_code)

Checks whether the RTGS service is enabled or not for the input IFSC.

    # Returns 1 if RTGS service is enabled or 0 if not.
    $api->get_rtgs_value('KKBK0005652');

=head2 get_imps_value($ifsc_code)

Checks whether the IMPS service is enabled or not for the input IFSC.

    # Returns 1 if IMPS service is enabled or 0 if not.
    $api->get_imps_value('KKBK0005652');

=head2 get_neft_value($ifsc_code)

Checks whether the NEFT service is enabled or not for the input IFSC.

    # Returns 1 if NEFT service is enabled or 0 if not.
    $api->get_neft_value('KKBK0005652');

=head2 get_micr_code_by_ifsc($ifsc_code)

Gets the MICR code (9-digit code) of the bank based on the provided IFSC code.

    # Returns micr code.
    $api->get_micr_code_by_ifsc('KKBK0005652');

=head2 download_json($ifsc_code, $filename)

Download the complete BankDetails data for IFSC code as JSON file. Optional path and file name.

    $ifsc_code = 'KKBK0005652';

    # Using default path and file name.
    $api->download_json($ifsc_code);

    # Using specific path and file name.
    $filename = "/tmp/bankdetails_$ifsc_code.json";
    $api->download_json($ifsc_code, $filename);

=head2 download_xml($ifsc_code, $filename)

Download the complete BankDetails data for IFSC code as XML file. Optional path and file name.

    $ifsc_code = 'KKBK0005652';

    # Using default path and file name.
    $api->download_xml($ifsc_code);

    # Using specific path and file name.
    $filename = "/tmp/bankdetails_$ifsc_code.xml";
    $api->download_xml($ifsc_code, $filename);

=head1 AUTHOR

Rohit R Manjrekar, C<< <manjrekarrohit76@gmail.com> >>

=head1 REPOSITORY

L<https://github.com/rmanjrekar/Webservice>

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2023 Rohit R Manjrekar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
