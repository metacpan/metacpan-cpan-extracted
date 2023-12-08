package Business::PagOnline {
    #use SOAP::Lite +trace => [qw/all -objects/];
    use SOAP::Lite;
    use Digest::SHA qw/hmac_sha256 hmac_sha256_hex hmac_sha256_base64/;
    use Moo;
    use Carp qw/confess/;
    use namespace::clean;
    use version;
    use v5.36;

    our $VERSION = qv("v0.2.0");

    has soapclient => (
        is => 'ro',
        default => sub { SOAP::Lite->new() },
    );

    has tid => ( is => 'ro' );
    has kSig => ( is => 'ro' );

    sub BUILD {
        my ($self, $args) = @_;
        #$self->soapclient->serializer->readable(1);
        #$self->soapclient->envprefix('soapenv');  # As per example
        $self->soapclient->proxy($args->{url});
        $self->soapclient->ns('http://services.api.web.cg.igfs.apps.netsw.it/', 'ser');
    }

    sub payment_init {
        my ($self, $args) = @_;

        $args->{amount} = int ($args->{amount} * 100);
        die 'Invalid-amount' if $args->{amount} !~ m/^\d+$/xs;
        die 'Invalid-shopID' if $args->{shopID} !~ m/^\w+$/xs;
        die 'Invalid-shopUserRef' if !$args->{shopUserRef};

        my %reqargs = (
            langID          => $args->{lang},
            tid             => $self->tid,
            kSig            => $self->kSig,
            trType          => 'PURCHASE',
            shopID          => $args->{shopID},
            shopUserRef     => $args->{shopUserRef},
            amount          => $args->{amount},
            currencyCode    => 'EUR',
            errorURL        => $args->{errorURL}.'',
            notifyURL       => $args->{notifyURL}.'',
        );

        my $signature_str = join('', map { ''.$reqargs{$_} } qw/
            tid shopID shopUserRef shopUserName shopUserAccount
            trType amount currencyCode langID notifyURL
            errorURL addInfo1 addInfo2 addInfo3 addInfo4
            addInfo5 description recurrent paymentReason freeText
            validityExpire
        /);
        $reqargs{signature} = hmac_sha256_base64($signature_str, $self->kSig) . '=';
        #die "$reqargs{kSig} - " . $reqargs{signature};
        #die  Data::Dump::dump(\%reqargs);

        my @soapdata;
        for my $sk(keys %reqargs) {
            next if $sk eq 'kSig';  # This is used to calculate signature but MUST NOT BE SENT or we'll get 500 Error
            my $sd = SOAP::Data->new(name => $sk, value => $reqargs{$sk});
            # $sd->type('');  # As per example
            push @soapdata, $sd;
        }

        # die Data::Dump::dump(\@soapdata);
        my $sd_req = SOAP::Data->new(name => 'request', value => \@soapdata);
        # $sd_req->type('');
        my $res = $self->soapclient->call('ser:Init',
            $sd_req
        )->result;
        # die  Data::Dump::dump($res);
        confess Data::Dump::dump($res) if $res->{error} ne 'false';

        return $res;
    }

    sub payment_verify {
        my ($self, $args) = @_;

        die 'Invalid-shopID' if $args->{shopID} !~ m/^\w+$/xs;
        my %reqargs = (
            tid             => $self->tid,
            kSig            => $self->kSig,
            shopID          => $args->{shopID},
            paymentID       => $args->{paymentID},
        );

        my $signature_str = join('', map { ''.$reqargs{$_} } qw/
            tid shopID paymentID
        /);
        $reqargs{signature} = hmac_sha256_base64($signature_str, $self->kSig) . '=';

        my @soapdata;
        for my $sk(keys %reqargs) {
            next if $sk eq 'kSig';  # This is used to calculate signature but MUST NOT BE SENT or we'll get 500 Error
            my $sd = SOAP::Data->new(name => $sk, value => $reqargs{$sk});
            push @soapdata, $sd;
        }

        my $res = $self->soapclient->call('ser:Verify',
            SOAP::Data->new(name => 'request', value => \@soapdata)
        )->result;

        return $res;
    }
}

1;

=head1 NAME

Business::PagOnline - Perl library for Unicredit's PagOnline payment system

=head1 SYNOPSIS

    use Business::PagOnline;

    # TODO

=head1 DESCRIPTION

This is HIGHLY EXPERIMENTAL and in the works, do not use for now.

=head1 AUTHOR

Michele Beltrame, C<mb@blendgroup.it>

=head1 LICENSE

This library is free software under the Artistic License 2.0.

=cut
