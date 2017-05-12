use String::Interpolate qw(safe_interpolate interpolate);
sub setClient{
    $pem = interpolate($BITPAYPEM);
    $uri = $BITPAYURL;
    my %options = ("pem" => $pem, "apiUri" => $uri);
    my $client = Business::OnlinePayment::BitPay::Client->new(%options);
    return $client;
};

1;

