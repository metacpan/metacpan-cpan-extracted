package Business::RealEx;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Digest::SHA1 'sha1_hex';
use LWP::UserAgent;
use Carp 'croak';
use XML::Simple;

sub new {
    my $class = shift;

    my %args = @_ % 2 ? %{$_[0]} : (@_);

    $args{merchantid} or croak 'merchantid is required.';
    $args{secret} or croak 'secret is required.';
    $args{ua} ||= LWP::UserAgent->new;

    bless \%args, $class;
}

sub edit_payer {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    $args{edit_payer} = 1;
    $self->new_payer(%args);
}

sub new_payer {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    foreach my $r ('payerref', 'firstname', 'surname') {
        $args{$r} or croak "$r is required.";
    }

    $args{payertype} ||= 'Business';
    $args{title} ||= 'Mr';
    $self->{__timestamp} = __timestamp();
    my $sha1hash = $self->__sha1hash($args{orderid} || '', $args{amount} || '', $args{currency} || '', $args{payerref});

    # we omit other fields for now
    my $action = $args{edit_payer} ? 'payer-edit' : 'payer-new';
    my $xml = <<XML;
<request type="$action" timestamp="$self->{__timestamp}">
<merchantid>$self->{merchantid}</merchantid>
<orderid>$args{orderid}</orderid>
<payer type="$args{payertype}" ref="$args{payerref}">
<title>$args{title}</title>
<firstname>$args{firstname}</firstname>
<surname>$args{surname}</surname>
XML

    $xml .= "<company>$args{company}</company>" if $args{company};

    $xml .= <<XML;
</payer>
<sha1hash>$sha1hash</sha1hash>
</request>
XML

    return $self->__request($xml);
}

sub new_card {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    my @r = ('ref', 'payerref', 'expdate', 'chname', 'type');
    push @r, 'number' unless $args{update_card}; # update card may not need number
    foreach my $r (@r) {
        $args{$r} or croak "$r is required.";
    }

    $self->{__timestamp} = __timestamp();
    my $sha1hash;
    if ($args{update_card}) {
        # Timestamp.merchantID.payerref.ref.expirydate.cardnumber
        $sha1hash = $self->__sha1hash($args{payerref}, $args{ref}, $args{expdate}, $args{number} || '');
    } else {
        # timestamp.merchantid.orderid.amount.currency.payerref.chname.(card)number
        $sha1hash = $self->__sha1hash($args{orderid} || '', $args{amount} || '', $args{currency} || '', $args{payerref}, $args{chname}, $args{number});
    }

    # we omit other fields for now
    my $action = $args{update_card} ? 'card-update-card' : 'card-new';
    my $xml = <<XML;
<request type="$action" timestamp="$self->{__timestamp}">
<merchantid>$self->{merchantid}</merchantid>
XML

    $xml .= "<orderid>$args{orderid}</orderid>" if $args{orderid};

    $xml .= <<XML;
<card>
<ref>$args{ref}</ref>
<payerref>$args{payerref}</payerref>
<number>$args{number}</number>
<expdate>$args{expdate}</expdate>
<chname>$args{chname}</chname>
<type>$args{type}</type>
XML

    $xml .= "<issueno>$args{issueno}</issueno>" if $args{issueno};

    $xml .= <<XML;
</card>
<sha1hash>$sha1hash</sha1hash>
</request>
XML

    return $self->__request($xml);
}

sub update_card {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    $args{update_card} = 1;
    $self->new_card(%args);
}

sub delete_card {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    my @r = ('ref', 'payerref');

    $self->{__timestamp} = __timestamp();
    # Timestamp.merchantID.payerref.pmtref
    my $sha1hash = $self->__sha1hash($args{payerref}, $args{ref});

    # we omit other fields for now
    my $xml = <<XML;
<request type="card-cancel-card" timestamp="$self->{__timestamp}">
<merchantid>$self->{merchantid}</merchantid>
<card>
<ref>$args{ref}</ref>
<payerref>$args{payerref}</payerref>
</card>
<sha1hash>$sha1hash</sha1hash>
</request>
XML

    return $self->__request($xml);
}

sub receipt_in {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    my @r = ('account', 'amount', 'currency', 'payerref', 'paymentmethod');
    foreach my $r (@r) {
        $args{$r} or croak "$r is required.";
    }

    $self->{__timestamp} = __timestamp();
    # timestamp.merchantid.orderid.amount.currency.payerref
    my $sha1hash = $self->__sha1hash($args{orderid} || '', $args{amount} || '', $args{currency} || '', $args{payerref});

    $args{autosettle} = 1 unless exists $args{autosettle};

    # we omit other fields for now
    my $action = 'receipt-in';
    my $xml = <<XML;
<request type="$action" timestamp="$self->{__timestamp}">
<merchantid>$self->{merchantid}</merchantid>
<account>$self->{account}</account>
XML

    $xml .= "<orderid>$args{orderid}</orderid>" if $args{orderid};
    if ($args{cvn}) {
        $xml .= <<XML;
<paymentdata>
  <cvn>
    <number>$args{cvn}</number>
  </cvn>
</paymentdata>
XML
    }

    $xml .= <<XML;
<amount currency="$args{currency}">$args{amount}</amount>
<payerref>$args{payerref}</payerref>
<paymentmethod>$args{paymentmethod}</paymentmethod>
<autosettle flag="$args{autosettle}" />
XML

    $xml .= "<authcode>$args{authcode}</authcode>" if $args{authcode};

    $xml .= <<XML;
<sha1hash>$sha1hash</sha1hash>
</request>
XML

    return $self->__request($xml);
}

sub refund {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : (@_);

    my @r = ('account', 'amount', 'currency', 'payerref', 'paymentmethod');
    foreach my $r (@r) {
        $args{$r} or croak "$r is required.";
    }

    $args{refund_password} or $self->{refund_password} or die 'refund_password is required.';

    $self->{__timestamp} = __timestamp();
    # timestamp.merchantid.orderid.amount.currency.payerref
    my $sha1hash = $self->__sha1hash($args{orderid} || '', $args{amount} || '', $args{currency} || '', $args{payerref});
    my $refundhash = sha1_hex($args{refund_password} || $self->{refund_password});

    $args{autosettle} = 1 unless exists $args{autosettle};

    # we omit other fields for now
    my $action = 'payment-out';
    my $xml = <<XML;
<request type="$action" timestamp="$self->{__timestamp}">
<merchantid>$self->{merchantid}</merchantid>
<account>$self->{account}</account>
XML

    $xml .= "<orderid>$args{orderid}</orderid>" if $args{orderid};

    $xml .= <<XML;
<amount currency="$args{currency}">$args{amount}</amount>
<payerref>$args{payerref}</payerref>
<paymentmethod>$args{paymentmethod}</paymentmethod>
XML

    $xml .= <<XML;
<sha1hash>$sha1hash</sha1hash>
<refundhash>$refundhash</refundhash>
</request>
XML

    return $self->__request($xml);
}

sub __request {
    my ($self, $xml) = @_;

    my $resp = $self->{ua}->post('https://epage.payandshop.com/epage-remote-plugins.cgi', Content => $xml);
    # use Data::Dumper; print Dumper(\$resp);
    return { error => 'Failed to talk with remote server: ' . $resp->status_line } unless $resp->is_success;
    return XMLin($resp->content, ForceArray => 0, SuppressEmpty => '');
}

sub __sha1hash {
    my $self = shift;
    return sha1_hex(join('.', sha1_hex($self->__sha_string(@_)), $self->{secret}));
}

sub __sha_string {
    my $self = shift;
    return join('.', $self->{__timestamp}, $self->{merchantid}, @_);
}

sub __timestamp {
    my @d = localtime();
    return sprintf('%04d%02d%02d%02d%02d%02d', $d[5] + 1900, $d[4] + 1, $d[3], @d[qw/2 1 0/]);
}

1;
__END__

=encoding utf-8

=head1 NAME

Business::RealEx - RealVault, Remote (Integrated) XML Solution

=head1 SYNOPSIS

    use Business::RealEx;

    my $realex = Business::RealEx->new(
        merchantid => 'zzz',
        secret => 'blabla',
    );

    my $data = $realex->new_payer(
        orderid => abs($$) . "-" . time() . "-robin",
        payerref => 'fayland',
        firstname => 'Fayland',
        surname => 'Lam',
        company => '247moneybox'
    );
    print Dumper(\$data);

    my $data = $realex->new_card(
        orderid => abs($$) . "-" . time() . "-robin",
        ref => 'fayland-card',
        payerref => 'fayland',
        number => '4988433008499991',
        expdate => '0115',
        chname => 'Fayland Lam',
        type => 'visa',
    );
    print Dumper(\$data);

    my $data = $realex->update_card(
        orderid => abs($$) . "-" . time() . "-robin",
        ref => 'fayland-card',
        payerref => 'fayland',
        expdate => '0115',
        chname => 'Fayland Lam',
        type => 'visa',
    );
    print Dumper(\$data);

    my $data = $realex->delete_card(
        ref => 'fayland-card',
        payerref => 'fayland',
    );
    print Dumper(\$data);

    my $data = $realex->receipt_in(
        orderid => abs($$) . "-" . time() . "-robin",
        account => 'internet',
        amount => '19999',
        currency => 'EUR',
        payerref => 'fayland',
        paymentmethod => 'visa01', # card-ref?
    );
    print Dumper(\$data);

=head1 DESCRIPTION

Business::RealEx is for L<https://resourcecentre.realexpayments.com/documents/pdf.html?id=152>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
