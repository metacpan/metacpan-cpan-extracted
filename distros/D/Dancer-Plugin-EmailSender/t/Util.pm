package t::Util;

use Email::Sender::Simple qw{};
use Test::More;
use Sub::Exporter -setup => {exports => [qw{body_is body_like envelope_is envelope_like header_is header_like with_sent}]};

sub body_is ($$) {
    my ($email, $value) = @_;
    my $body = $email->get_body || '';
    is ($body, $value, "Comparing body against $value");
}

sub body_like ($$) {
    my ($email, $regex) = @_;
    my $body = $email->get_body || '';
    like ($body, $regex, "Checking body against $regex");
}

sub envelope_is ($$$) {
    my ($sent, $checking, $value) = @_;
    my $item = $sent->{envelope}->{$checking} || '';
    is_deeply ($item, $value, "Comparing envelope $checking against $value");
}

sub envelope_like ($$$) {
    my ($sent, $checking, $regex) = @_;
    my $item = $sent->{envelope}->{$checking} || '';
    like ($header, $regex, "Checking envelope $checking against $regex");
}

sub header_is ($$$) {
    my ($email, $checking, $value) = @_;
    my $header = $email->get_header ($checking) || '';
    is ($header, $value, "Comparing header $checking against $value");
}

sub header_like ($$$) {
    my ($email, $checking, $regex) = @_;
    my $header = $email->get_header ($checking) || '';
    like ($header, $regex, "Checking header $checking against $regex");
}

sub with_sent ($&) {
    my ($transport, $sub) = @_;
    if (my $email = shift @{$transport->deliveries}) {
        $sub->($email);
    }
}

1;
