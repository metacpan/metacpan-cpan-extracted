package Business::PayPoint::MCPE;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use LWP::UserAgent;
use Carp 'croak';
use URI::Escape qw/uri_unescape/;

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    $args{InstID} or croak "InstID is required.";

    $args{TestMode} ||= 0;
    $args{ua} ||= LWP::UserAgent->new();

    $args{POST_URL} ||= 'https://secure.metacharge.com/mcpe/corporate';
    $args{APIVersion} ||= '1.3';

    bless \%args, $class;
}

sub payment {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'PAYMENT',
    );
}

sub refund {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'REFUND',
    );
}

sub repeat {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'REPEAT',
    );
}

sub capture {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'CAPTURE',
    );
}

sub void {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'VOID',
    );
}

sub cancel {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'CANCEL',
    );
}

sub confirm {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'CONFIRM',
    );
}

sub nonauth {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $self->request(
        %args,
        TransType  => 'NONAUTH',
    );
}

sub request {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;

    my @intFields = ('TestMode', 'InstID', 'TransID', 'AccountID', 'AuthMode', 'CountryIP', 'AVS', 'Status', 'Time', 'CV2', 'Reference', 'Recurs', 'CancelAfter', 'ScheduleID');
    my @fltFields = ('APIVersion', 'Amount', 'OriginalAmount', 'SchAmount', 'FraudScore');
    my @datFields = ('Fulfillment');

    $params{TestMode}   = $self->{TestMode} unless exists $params{TestMode};
    $params{InstID}     ||= $self->{InstID};
    $params{APIVersion} ||= $self->{APIVersion};

    my %r;
    foreach my $key (keys %params) {
        if ($key =~ /^(int|flt|str|dat)/) {
            $r{$key} = $params{$key};
        } elsif (grep { $_ eq $key } @intFields) {
            $r{'int' . $key} = $params{$key};
        } elsif (grep { $_ eq $key } @fltFields) {
            $r{'flt' . $key} = $params{$key};
        } elsif (grep { $_ eq $key } @fltFields) {
            $r{'dat' . $key} = $params{$key};
        } else {
            $r{'str' . $key} = $params{$key};
        }
    }

    my $resp = $self->{ua}->post($self->{POST_URL}, \%r);
    # use Data::Dumper; print STDERR Dumper(\$resp);
    unless ($resp->is_success) {
        return wantarray ? (error => $resp->status_line) : { error => $resp->status_line };
    }

    my @parts = split('&', $resp->decoded_content);
    my %parts;
    foreach my $p (@parts) {
        my ($a, $b) = split('=', $p, 2);
        $a =~ s/^(int|flt|str|dat)//;
        $parts{$a} = uri_unescape($b);
        $parts{$a} =~ s/\+/ /g;
    }
    return wantarray ? %parts : \%parts;
}

1;
__END__

=encoding utf-8

=head1 NAME

Business::PayPoint::MCPE - PayPoint: Merchant Card Payment Engine

=head1 SYNOPSIS

    use Business::PayPoint::MCPE;

    my $bpm = Business::PayPoint::MCPE->new(
        TestMode => 1,
        InstID => '123456',
    );

    my %data = $bpm->payment(
        CartID => 654321,
        Desc   => 'description of goods',
        Amount => '10.00',
        Currency => 'GBP',
        CardHolder => 'Joe Bloggs',
        Postcode   => 'BA12BU',
        Email      => 'test@paypoint.net',
        CardNumber => '1234123412341234',
        CV2        => '707',
        ExpiryDate => '0616',
        CardType   => 'VISA',
        Country    => 'GB',
    );
    print Dumper(\%data); use Data::Dumper;

=head1 DESCRIPTION

Business::PayPoint::MCPE is for L<https://www.paypoint.net/assets/guides/MCPE_Freedom+IMA_2.3.pdf>

=head1 METHODS

=head2 new

=over 4

=item InstID

required.

=item TestMode

1 or 0. default is 0.

=back

=head2 payment

    my %data = $bpm->payment(
        CartID => 654321,
        Desc   => 'description of goods',
        Amount => '10.00',
        Currency => 'GBP',
        CardHolder => 'Joe Bloggs',
        Postcode   => 'BA12BU',
        Email      => 'test@paypoint.net',
        CardNumber => '1234123412341234',
        CV2        => '707',
        ExpiryDate => '0616',
        CardType   => 'VISA',
        Country    => 'GB',
    );
    print Dumper(\%data);

=head2 refund

    my $TransID = $data{TransID}; # from above payment
    my $SecurityToken = $data{SecurityToken};
    my %data = $bpm->refund(
        TransID => $TransID,
        SecurityToken => $SecurityToken,
        Amount => '5.00',
    );

=head2 repeat

    my $TransID = $data{TransID}; # from above payment
    my $SecurityToken = $data{SecurityToken};
    my %data = $bpm->repeat(
        TransID => $TransID,
        SecurityToken => $SecurityToken,
        Amount => '5.00',
    );

=head2 capture

    my %data = $bpm->capture(
        TransID => $TransID,
        SecurityToken => $SecurityToken,
        Amount => '5.00',
    );
    print Dumper(\%data);

PreAuth Capture

=head2 void

    my %data = $bpm->void(
        TransID => $TransID,
        SecurityToken => $SecurityToken,
        Amount => '5.00',
    );
    print Dumper(\%data);

PreAuth Void

=head2 cancel

    my %data = $bpm->void(
        ScheduleID => $ScheduleID
    );
    print Dumper(\%data);

Subscription Cancellation

=head2 confirm

    my %data = $bpm->confirm(
        CartID => $CartID
    );
    print Dumper(\%data);

Transaction Confirm

=head2 nonauth

    my %data = $bpm->nonauth(
        CartID => $CartID,
        Desc   => 'description of goods',
        Amount => '10.00',
        Currency => 'GBP',
        PaymentType => 'NETELLER',
        PaymentDetail => "450000000001",
        Postcode   => 'BA12BU',
        Email      => 'test@paypoint.net',
        Country    => 'GB',
    );
    print Dumper(\%data);

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
