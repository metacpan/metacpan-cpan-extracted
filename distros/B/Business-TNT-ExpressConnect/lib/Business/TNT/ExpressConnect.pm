package Business::TNT::ExpressConnect;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

use Path::Class qw(dir file);
use Config::INI::Reader;
use LWP::UserAgent;
use Moose;
use XML::Compile::Schema;
use XML::Compile::Util qw/pack_type/;
use DateTime;

use Business::TNT::ExpressConnect::SPc;

has 'user_agent' => (is => 'ro', lazy_build => 1);
has 'config'     => (is => 'ro', lazy_build => 1);
has 'username'   => (is => 'ro', lazy_build => 1);
has 'password'   => (is => 'ro', lazy_build => 1);
has 'xml_schema' => (is => 'ro', lazy_build => 1);
has 'error'      => (is => 'rw', isa        => 'Bool', default => 0);
has 'errors'     => (is => 'rw', isa        => 'ArrayRef[Str]');
has 'warnings'   => (is => 'rw', isa        => 'ArrayRef[Str]');

sub _build_user_agent {
    my ($self) = @_;

    my $user_agent = LWP::UserAgent->new;
    $user_agent->timeout(30);
    $user_agent->env_proxy;

    return $user_agent;
}

sub _build_config {
    my ($self) = @_;

    my $config_filename =
        file(Business::TNT::ExpressConnect::SPc->sysconfdir, 'tnt-expressconnect.ini');

    unless (-r $config_filename) {
        $self->warnings(['could not read config file '.$config_filename]);
        return {};
    }

    return Config::INI::Reader->read_file($config_filename);
}

sub _build_username {
    my ($self) = @_;

    return $self->config->{_}->{username};
}

sub _build_password {
    my ($self) = @_;

    return $self->config->{_}->{password};
}

sub _build_xml_schema {
    my ($self) = @_;

    my $xsd_file   = $self->_price_request_common_xsd;
    my $xml_schema = XML::Compile::Schema->new($xsd_file);

    return $xml_schema;
}

sub _xsd_basedir {
    dir(Business::TNT::ExpressConnect::SPc->datadir, 'tnt-expressconnect', 'xsd', 'pricing', 'v3');
}

sub _price_request_in_xsd {
    my $file = _xsd_basedir->file('PriceRequestIN.xsd');

    die "cannot read request IN xsd file " . $file unless (-r $file);

    return $file;
}

sub _price_request_out_xsd {
    my ($self) = @_;
    my $file = _xsd_basedir->file('PriceResponseOUT.xsd');

    die "cannot read request OUT xsd file " . $file unless (-r $file);

    return $file;
}

sub _price_request_common_xsd {
    my ($self) = @_;

    my $file = _xsd_basedir->file('commonDefinitions.xsd');

    die "cannot read common definitions xsd file " . $file unless (-r $file);

    return $file;
}

sub tnt_get_price_url {
    return 'https://express.tnt.com/expressconnect/pricing/getprice';
}

sub hash_to_price_request_xml {
    my ($self, $params) = @_;

    my $xml_schema = $self->xml_schema;
    $xml_schema->importDefinitions($self->_price_request_in_xsd);

    # create and use a writer
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $write = $xml_schema->compile(WRITER => '{}priceRequest');

    my %priceCheck = (
        rateId   => 1,                     #unique within priceRequest
        sender   => $params->{sender},
        delivery => $params->{delivery},
        collectionDateTime => ($params->{collection_datetime} // DateTime->now()),
        currency => ($params->{currency} // 'EUR'),
        product => {type => ($params->{product_type} // 'N')}
        ,    #“D” Document(paper/manuals/reports) or “N” Non-document (packages)
    );

    $priceCheck{consignmentDetails} = $params->{consignmentDetails}
        if ($params->{consignmentDetails});
    $priceCheck{seq_pieceLine} = $params->{pieceLines} if ($params->{pieceLines});
    $priceCheck{account}       = $params->{account}    if ($params->{account});

    my %hash = (appId => 'PC', appVersion => '3.0', priceCheck => [\%priceCheck]);

    my $xml = $write->($doc, \%hash);
    $doc->setDocumentElement($xml);

    return $doc;
}

sub get_prices {
    my ($self, $args) = @_;

    my $user_agent = $self->user_agent;
    my $req = HTTP::Request->new(POST => $self->tnt_get_price_url);
    $req->authorization_basic($self->username, $self->password);
    $req->header('Content-Type' => 'text/xml; charset=utf-8');

    if (my $file = $args->{file}) {
        $req->content('' . file($file)->slurp);
    }
    elsif (my $params = $args->{params}) {
        my $xml = $self->hash_to_price_request_xml($params);
        $req->content($xml->toString(1));
    }
    else {
        $self->error(1);
        $self->errors(['missing price request data']);
        return undef;
    }

    my $response = $user_agent->request($req);

    if ($response->is_error) {
        $self->error(1);
        $self->errors(['Request failed: ' . $response->status_line]);
        return undef;
    }

    my $response_xml = $response->content;

    #parse schema
    my $xml_schema = $self->xml_schema;
    $xml_schema->importDefinitions($self->_price_request_out_xsd);

    #read xml file
    my $elem = XML::Compile::Util::pack_type '', 'document';
    my $read = $xml_schema->compile(READER => $elem);

    my $data = $read->($response_xml);

    my @errors;
    my @warnings;
    foreach my $error (@{$data->{errors}->{brokenRule}}) {
        if ($error->{messageType} eq "W") {
            push @warnings, $error->{description};
        } else {
            push @errors, $error->{description};
        }
    }

    if (@warnings) {
        $self->warnings(\@warnings);
    }
    if (@errors) {
        $self->error(1);
        $self->errors(\@errors);
        return undef;
    }

    my $ratedServices = $data->{priceResponse}->[0]->{ratedServices};
    my $currency      = $ratedServices->{currency};
    my $ratedService  = $ratedServices->{ratedService};

    my %prices;
    my $i = 0;
    foreach my $option (@$ratedService) {
        $prices{$option->{product}->{id}} = {
            price_desc           => $option->{product}->{productDesc},
            currency             => $currency,
            total_price          => $option->{totalPrice},
            total_price_excl_vat => $option->{totalPriceExclVat},
            vat_amount           => $option->{vatAmount},
            charge_elements      => $option->{chargeElements},
            sort_index           => $i++,
        };
    }

    return \%prices;
}

sub http_ping {
    my ($self) = @_;
    my $response = $self->user_agent->get($self->tnt_get_price_url);

    return 1 if $response->code == 401;
    return 0;
}

1;

__END__

=head1 NAME

Business::TNT::ExpressConnect - TNT ExpressConnect interface

=head1 SYNOPSIS

    # read config from config file
    my $tnt = Business::TNT::ExpressConnect->new();

    # provide username and password
    my $tnt = Business::TNT::ExpressConnect->new({username => 'john', password => 'secret'});

    # use xml file to define the request
    my $tnt_prices = $tnt->get_prices({file => $xml_filename});

    #use a hash to define the request (only one of consignmentDetails or pieceLines has to be present)
    my %params = (
        sender             => {country => 'AT', town => 'Vienna',    postcode => 1020},
        delivery           => {country => 'AT', town => 'Schwechat', postcode => '2320'},
        account            => {accountNumber => 33505, accountCountry => 'SK'},
        consignmentDetails => {
            totalWeight         => 1.25,
            totalVolume         => 0.1,
            totalNumberOfPieces => 1
        }
        pieceLines => [
            {   pieceLine => {
                    numberOfPieces    => 2,
                    pieceMeasurements => {weight => 11, length => 0.44, width => 0.37, height => 1},
                    pallet            => 0,
                }
            },
        ],
    );

    $tnt_prices = $tnt->get_prices({params => \%params});

    warn join("\n",@{$tnt->errors}) unless ($tnt_prices);

    # tnt prices structure
    $tnt_prices = {
          '10' => {
                  'charge_elements' => 'HASH(0x40a5f40)',
                  'total_price_excl_vat' => '96.14',
                  'vat_amount' => '19.23',
                  'price_desc' => '10:00 Express',
                  'total_price' => '115.37',
                  'sort_index' => 1,
                  'currency' => 'EUR'
                },
          '09' => {
                  'currency' => 'EUR',
                  'sort_index' => 0,
                  'charge_elements' => 'HASH(0x40b0130)',
                  'total_price_excl_vat' => '101.79',
                  'vat_amount' => '20.36',
                  'total_price' => '122.15',
                  'price_desc' => '9:00 Express'
                },
        };


=head1 DESCRIPTION

Calculate prices for TNT delivery.

Schema definitions and user guides: https://express.tnt.com/expresswebservices-website/app/pricingrequest.html

=head1 CONFIGURATION

=head2 etc/tnt-expressconnect.ini

    username = john
    password = secret

=head1 METHODS

=head2 get_prices(\%hash)

get_prices({file => $filename}) or get_prices({params => \%params})

Returns a hash of tnt products for that request or undef in case of error.
$tnt->errors returns an array ref with error messages.

=head2 hash_to_price_request_xml(\%hash)

Takes a hash and turns it into a XML::LibXML::Document for a price request.

=head2 http_ping

Check if tnt server is reachable.

=head2 tnt_get_price_url

Returns the URL of the TNT price check interface.

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>;
Andrea Pavlovic, C<< <spinne at cpan.org> >>

=head1 CONTRIBUTORS

The following people have contributed to the meon::Web by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advice, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    you?

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
