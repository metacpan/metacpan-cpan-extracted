package Catalyst::Model::PayPal::IPN;

use Moose;
use Business::PayPal::IPN;
use namespace::clean -except => ['meta'];

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:MSTROUT';

extends 'Catalyst::Model';

has 'req' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "req not provided before use" }
);

has 'business_email' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "business_email not provided before use" }
);

has 'currency_code' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "currency_code not provided before use" }
);

has 'postback_action' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "postback_action not provided before use" }
);

has 'postback_url' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "postback_url not provided before use" }
);

has 'cancellation_action' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "cancellation_action not provided before use" }
);

has 'cancellation_url' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "cancellation_url not provided before use" }
);

has 'completion_action' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "completion_action not provided before use" }
);

has 'completion_url' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { confess "completion_url not provided before use" }
);

has 'debug_mode' => ( is => 'rw', required => 1, default => sub { 0 } );

has 'encrypt_mode' => ( is => 'rw', required => 1, default => sub { 0 },
                        trigger => sub {shift->_check_encrypt_mode} );

has 'cert' => (
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default =>
      sub { confess "cert not provided for encryption" if shift->encrypt_mode }
);

has 'cert_key' => (
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => sub {
        confess "cert_key not provided for encryption" if shift->encrypt_mode;
    }
);

has 'paypal_cert' => (
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => sub {
        confess "paypal_cert not provided for encryption"
          if shift->encrypt_mode;
    }
);

has 'paypal_gateway' => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { shift->build_paypal_gateway },
);

has '_ipn_object' => (
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { shift->_build_ipn_object },
);

sub BUILD {
    shift->_check_encrypt_mode;
}

sub _check_encrypt_mode {
    Catalyst::Utils::ensure_class_loaded('Business::PayPal::EWP')
          if shift->encrypt_mode;
}

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    return $c->stash->{ ref($self) } ||= $self->_build_context_copy($c);
}

sub _build_context_copy {
    my ( $self, $c ) = @_;
    my $copy = bless( {%$self}, ref($self) );
    my $req = $c->req;
    $copy->req($req);
    $copy->_fill_action( $c, $_ ) for qw/postback completion cancellation/;
    return $copy;
}

sub _fill_action {
    my ( $self, $c, $fill ) = @_;
    my $url_meth  = "${fill}_url";
    my $args_meth = "${fill}_action";
    my @args      = @{ $self->$args_meth };
    my ( $controller, $action_name ) = ( shift(@args), shift(@args) );
    my $action = $c->controller($controller)->action_for($action_name);
    my $uri = $c->uri_for( $action => @args );
    $self->$url_meth("${uri}");
}

sub build_paypal_gateway {
    my $self = shift;
    return (
        $self->debug_mode
        ? 'https://www.sandbox.paypal.com/cgi-bin/webscr'
        : 'https://www.paypal.com/cgi-bin/webscr'
    );
}

sub _build_ipn_object {
    my $self = shift;
    local $Business::PayPal::IPN::GTW = $self->paypal_gateway;
    my $ipn = Business::PayPal::IPN->new( query => $self->req );
    unless ($ipn) {
        $ipn =
          Catalyst::Model::PayPal::IPN::ErrorHandle->new(
            error => Business::PayPal::IPN->error );
    }
    return $ipn;
}

sub is_completed {
    my $self = shift;
    return $self->_ipn_object->completed;
}

sub error {
    my $self = shift;
    return
      unless $self->_ipn_object->isa(
        'Catalyst::Model::PayPal::IPN::ErrorHandle');
    return $self->_ipn_object->error;
}

# https://www.paypal.com/IntegrationCenter/ic_ipn-pdt-variable-reference.html

sub buyer_info {
    my $self = shift;
    return unless $self->is_completed;
    return $self->_ipn_object->vars();
}

sub correlation_info {
    my $self = shift;
    return {
        amount => $self->req->params->{mc_gross},
        map { ( $_ => $self->req->params->{$_} ) } qw/invoice custom/
    };
}

sub form_info {
    my ( $self, $args ) = @_;
    foreach my $key (qw/amount item_name/) {
        confess "${key} must be defined" unless defined( $args->{$key} );
    }
    return {
        business      => $self->business_email,
        currency_code => $self->currency_code,
        notify_url    => $self->postback_url,
        return        => $self->completion_url,
        cancel_return => $self->cancellation_url,
        cmd           => '_ext-enter',
        redirect_cmd  => '_xclick',
        %$args
    };
}

sub encrypt_form {
    my ( $self, $args ) = @_;

    confess "encrypt_mode must be enabled" unless $self->encrypt_mode;

    my $form_args = $self->form_info($args);

    # SignAndEncrypt needs CSV key/vals
    my $form;
    for my $form_param ( keys %$form_args ) {
        $form .= $form_param . '=' . $form_args->{$form_param} . "\n";
    }

    return Business::PayPal::EWP::SignAndEncrypt(
        $form, $self->cert_key, $self->cert, $self->paypal_cert
    );
}

__PACKAGE__->meta->make_immutable;

package Catalyst::Model::PayPal::IPN::ErrorHandle;

use Moose;
use namespace::clean -except => ['meta'];

has 'error' => ( is => 'ro', required => 1 );

sub completed { 0 }

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf8

=head1 NAME

Catalyst::Model::PayPal::IPN - Handle Instant Payment Notifications and PayPal Button Generation

=head1 VERSION

This document describes Catalyst::Model::PayPal::IPN version 0.04

=head1 SYNOPSIS

    lib/MyApp/Model/Paypal/IPN.pm

    package MyApp::Model::Paypal::IPN;

    use strict;
    use warnings;
    use parent 'Catalyst::Model::PayPal::IPN';

    1;

    myapp.yml

    paypal:
        cert_id: 3TFC4UDJER95J
        page_style: MyApp
        no_note: 1
        no_shipping: 1
        lc: GB
        bn: PP-BuyNowBF

    Model::Paypal::IPN:
        debug_mode: 1
        encrypt_mode: 0
        business_email: ghenry_1188297224_biz@suretecsystems.com
        currency_code: GBP
        cert: /home/ghenry/MyApp/root/auth/paypal_certs/www.myapp.net.crt
        cert_key: /home/ghenry/MyApp/root/auth/paypal_certs/www.myapp.net.key
        paypal_cert: /home/ghenry/MyApp/root/auth/paypal_certs/paypal_sandbox_cert.pem
        completion_action:
            - Subscribe
            - subscribe
            - payment
            - received
        postback_action:
            - Subscribe
            - subscribe
            - payment
            - ipn
        cancellation_action:
            - Subscribe
            - subscribe
            - payment
            - cancelled

    MyApp::Controller::Subscribe

    =head2 ipn

    Handle PayPal IPN stuff

    =cut

    sub ipn : Path('payment/ipn') {
        my ( $self, $c ) = @_;

        my $ipn = $c->model('Paypal::IPN');

        if ( $ipn->is_completed ) {
            my %ipn_vars = $ipn->buyer_info();
            $c->stash->{ipn_vars} = \%ipn_vars;

            Do stuff here

            # Just so we reply with something, which in turn sends a HTTP Status 200
            # OK, which we need to stop PayPal.
            # We don't get as we don't use a template and RenderView looks for a
            # template, a body or status equal to 3XX
            $c->res->body('ok');
        }
        else {

        # Just so we reply with something, which in turn sends a HTTP Status 200
        # OK, which we need to stop PayPal.
        # We don't get as we don't use a template and RenderView looks for a
        # template, a body or status equal to 3XX
            $c->res->body('not_ok');
            $c->log->debug( $record_payment_result->transmsgtext ) if $c->debug;
            $c->log->debug( $ipn->error ) if $ipn->error && $c->debug;
        }
    }

    =head2 cancelled

    Cancelled Payment

    =cut

    sub cancelled : Path('payment/cancelled') {
        my ( $self, $c ) = @_;

        Do stuff on cancel

        $c->stash->{template} = 'user/subscribe/cancelled.tt';
    }

    =head2 generate_paypal_buttons

    =cut

    sub generate_paypal_buttons : Private {
        my ( $self, $c ) = @_;

        if ( $c->stash->{all_buttons} ) {
            $c->stash->{subtypes} = [
                $c->model('FTMAdminDB::FTMTariffs')->search(
                    {
                        objectname => 'FTM_SUB_TARIFFS',
                        objectitem => 'TARIFFTYPENO',
                        lovlangid  => $langid,
                    },
                )
            ];

            for my $tariff ( @{ $c->stash->{subtypes} } ) {
                next if $tariff->tariffid == 1;
                my %data = (
                    #cert_id     => $c->config->{paypal}->{cert_id},
                    cmd         => '_xclick',
                    item_name   => $tariff->itemdesc,
                    item_number => $tariff->tariffid,
                    amount      => $tariff->peruser,
                    page_style  => $c->config->{paypal}->{page_style},
                    no_shipping => $c->config->{paypal}->{no_shipping},
                    no_note     => $c->config->{paypal}->{no_note},
                    'lc'        => $c->config->{paypal}->{lc},
                    bn          => $c->config->{paypal}->{bn},
                    custom      => $c->req->param('subid'),
                );

                if ( $c->debug ) {
                    for my $param ( keys %data ) {
                        $c->log->debug( $param . '=' . $data{$param} );
                    }
                }
                $c->stash->{unencrypted_form_data} =
                  $c->model('Paypal::IPN')->form_info( \%data );

                my @button_info = (
                    $tariff->itemdesc, $tariff->peruser,
                    $c->stash->{unencrypted_form_data}
                );
                push @{ $c->stash->{unencrypted_buttons} }, \@button_info;

                #$c->stash->{encrypted_form_data} =
                #  $c->model('Paypal::IPN')->encrypt_form( \%data );

                #my @button_info = (
                #    $tariff->itemdesc, $tariff->peruser,
                #    $c->stash->{encrypted_form_data}
                #);
                #push @{ $c->stash->{encrypted_buttons} }, \@button_info;
            }
        }
    }

    buttons.tt

    <table>
        [% FOREACH button IN unencrypted_buttons %]
            <tr>
                <td><b>[% button.0 %]</b></td>
                <td><b>Price:</b> £[% button.1 %]</td>
                <td class="content">
                    <form method="post" action="[% c.model('Paypal::IPN').paypal_gateway %]">
                    <input type="hidden" name="cmd" value="_xclick">
                    <input type="image" src="https://www.paypal.com/en_US/i/btn/x-click-but23.gif" border="0"
                    name="submit" alt="Make payments with PayPal - it's fast, free and secure!">
                    <img alt="" border="0" src="https://www.paypal.com/en_GB/i/scr/pixel.gif" width="1" height="1">
            [% FOREACH key IN button.2.keys %]
                    <input type="hidden" name="[% key %]" value="[% button.2.$key %]" />
            [% END %]
                    </form>
                </td>
            </tr>
        [% END %]
            <tr>
                <td class="content">
                    <input type="button" onclick="dojo.widget.byId('profdiag').hide();" value="Close" name="close"/>
                </td>
                <td class="content" colspan="2">
                    <a href="#" onclick="javascript:window.open('https://www.paypal.com/uk/cgi-bin/webscr?cmd=xpt/cps/popup/OLCWhatIsPayPal-outside','olcwhatispaypal','toolbar=no,location=no, directories=no, status=no, menubar=no, scrollbars=yes,resizable=yes, width=400, height=350');"><img src="https://www.paypal.com/en_GB/i/bnr/horizontal_solution_PP.gif" border="0"
alt="Solution Graphics"></a>
                </td>
            </tr>
    </table>


=head1 DESCRIPTION

This model handles all the latest PayPal IPN vars, and provides an
easy method for checking that the transaction was successful.

There are also convenience methods for generating encrypted and non-encrypted
PayPal forms and buttons.

See L<Business::PayPal::IPN> for more info.

B<WARNING:> this module does not have real tests yet, if you encounter problems
please report them via L<http://rt.cpan.org/> .

=head1 INTERFACE

=head2 build_paypal_gateway

If debug_mode is on, returns sandbox url, otherwise normal PayPal gateway

=head2 is_completed

Calls is_completed from L<Business::PayPal::IPN>

=head2 error

Calls error from L<Business::PayPal::IPN>

=head2 buyer_info

Returns IPN vars via L<Business::PayPal::IPN>

See L<https://www.paypal.com/IntegrationCenter/ic_ipn-pdt-variable-reference.html>

=head2 correlation_info

Returns a hashref of amount, invoice and custom.

=head2 form_info

Takes a hashref and returns form data for looping through to create your form.

See L<SYNOPSIS>

=head2 encrypt_form

Encrypts form data.

    $c->model('Paypal::IPN')->encrypt_form( \%data );

=head1 CONFIGURATION AND ENVIRONMENT

The usual techniques for suppling model configuration data in Catalyst apply,
but the follow should be present:

    Model::Paypal::IPN:
        debug_mode: 1
        encrypt_mode: 0
        business_email: ghenry_1188297224_biz@suretecsystems.com
        currency_code: GBP
        completion_action:
            - Subscribe
            - subscribe
            - payment
            - received
        postback_action:
            - Subscribe
            - subscribe
            - payment
            - ipn
        cancellation_action:
            - Subscribe
            - subscribe
            - payment
            - cancelled

debug_mode switches form url to the PayPal sandbox url. If using encrypted
buttons, i.e.

    encrypt_mode: 1

then the following will be needed:

    cert: /home/ghenry/MyApp/root/auth/paypal_certs/www.myapp.net.crt
    cert_key: /home/ghenry/MyApp/root/auth/paypal_certs/www.myapp.net.key
    paypal_cert: /home/ghenry/MyApp/root/auth/paypal_certs/paypal_sandbox_cert.pem

Catalyst::Model::PayPal::IPN requires:

=head1 DEPENDENCIES

L<Moose>

L<namespace::clean>

L<Business::PayPal::IPN>

L<Business::PayPal::EWP>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-model-paypal-ipn@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Matt S Trout C<mst@shadowcatsystems.co.uk>

Gavin Henry  C<ghenry@suretecsystems.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Matt S Trout, C<mst@shadowcatsystems.co.uk>. All rights reserved.

Copyright (c) 2007, Gavin Henry C<ghenry@suretecsystems.com>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
