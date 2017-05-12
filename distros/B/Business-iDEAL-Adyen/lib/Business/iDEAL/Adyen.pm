package Business::iDEAL::Adyen;

use strict;
use Carp;

use DateTime;
use Digest::HMAC_SHA1;
use LWP::UserAgent;
use URI;
use XML::Simple;

our $VERSION = '0.02';

=pod

=head1 NAME

Business::iDEAL::Adyen - Backend for iDEAL payments through adyen.com

=head1 SYNOPSIS

  use Business::iDEAL::Adyen;
    
  # first setup the object
  my $ideal = Business::iDEAL::Adyen->new({
                  shared_secret   => 'your very secure secret',
                  skinCode        => 's0m3C0d3',
                  merchantAccount => 'your merchant account',
                  test            => 1,
              });
    
  # then fetch a list of bank ids and bank codes
  my $banks = $ideal->banklist();
  
  # after the user has chosen the bank he/she wants to use
  # it's time to fetch the redirect URL
  my $redir = $ideal->fetch({
                  # mandatory fields
                  bank_id         => 1000,
                  paymentAmount   => 1250,
  
                  # optional fields
                  merchantReference => 'your order ID',
                  currencyCode      => 'EUR',
                  shopperLocale     => 'nl',
                  shipBeforeDate    => '2010-01-01',
                  sessionValidity   => '2009-01-01T01:01:01Z',
              });
  
  # redirect your user to his/her bank, like
  print redirect( $redir );

After the user has finalized the payment, he/she'll be returned to
your website (as defined in the Adyen skin)

  use Business::iDEAL::Adyen;
  use CGI qw/:standard/;
  
  # first setup the objects
  my $cgi   = new CGI;
  my $ideal = Business::iDEAL::Adyen->new({
                  shared_secret => 'your very secure secret',
                  skinCode      => 
                  test          => 1,
              });
  
  # check user input
  if( $ideal->check( \%{$cgi->Vars} ) ) {
  
     # payment succeeded, so you probably want to update your
     # database with $cgi->param('merchantReference')
  
  } else {

     # payment was not successful
     # $ideal->error() contains what went wrong (most likely the
     # request has been tampered with and the signature is incorrect)
  
  }


=head1 DESCRIPTION

Business::iDEAL::Adyen provides a backend to process iDEAL payments
through adyen.com (the non-HPP (Hosted Payment Pages) way). 

A word of warning to start with (copied verbatim out of Adyen's iDEAL PDF):

  iDeal API Payments are not enabled by default. If you would like to 
  process iDeal using this method, you can request this through the support 
  channel at L<https://support.adyen.com>.

=head2 METHODS

=head3 new

C<new> creates a new C<Business::iDEAL::Adyen> object.

=head4 options

=over 5 

=item B<shared_secret> I<[mandatory]>

This option should be the same as the secret entered
in the Adyen skin.

=item B<skinCode> I<[mandatory]>

The code of the skin we're using.

=item B<merchantAccount> I<[mandatory]>

The merchant account name

=item B<test>

A boolean value that switches on the use of the test environment.

=back

=cut

sub new {
    my ($class, $args) = @_;
    $args ||= {};
    $class->_croak("Options must be a hash reference")
        if ref($args) ne 'HASH';

    my $self = {};
    bless $self, $class;

    # initialize the object
    $self->_init($args);

    return $self;
}

sub _croak {
    my $self = shift;
    Carp::croak(@_);
}

sub _carp {
    my $self = shift;
    Carp::carp(@_);
}

sub _init {
    my ($self, $args) = @_;

    # test for mandatory fields
    for(qw/shared_secret skinCode merchantAccount/) {
       $self->_croak("$_ not set") unless $args->{$_};
    }

    # set some defaults and let user override if needed
    my %options = (
        ua            => LWP::UserAgent->new(
                             agent => __PACKAGE__." v. ".$VERSION,
			     requests_redirectable => '',
                         ),
        xso           => XML::Simple->new(),
	hmac          => Digest::HMAC_SHA1->new(delete $args->{shared_secret}),
        prod_base_url => 'https://live.adyen.com',
        test_base_url => 'https://test.adyen.com',
        banklist_path => '/hpp/idealbanklist.shtml',
        redirect_path => '/hpp/redirectIdeal.shtml',
        %{ $args }
    );

    # map all keys to $self->{_$key} for easy access
    $self->{"_$_"} = $options{$_} for (keys %options);
}

sub _url {
    my ($self, $type) = @_;

    # determine what path we need and whether that exists or not
    my $path = $self->{"_".$type."_path"} or 
        $self->_croak("Unknown type '$type'");

    # return the test or production url based on $type input
    return ($self->{_test} ? $self->{_test_base_url} 
                           : $self->{_prod_base_url}).
            $path;
}

sub _parse_xml {
    my ($self, $input) = @_;
    return unless($input);

    return $self->{_xso}->XMLin($input);    
}

sub _sign_req {
    my ($self, $args) = @_;

    my $plaintext = '';
    if($args->{paymentAmount}) {
        # Initial signature (the one we _send_)
        for(qw/paymentAmount currencyCode shipBeforeDate merchantReference 
               skinCode merchantAccount sessionValidity shopperEmail 
               shopperReference allowedMethods blockedMethods/) {
            $plaintext .= ( defined $self->{"_$_"} ) 
                       ? $self->{"_$_"} : ( $args->{$_} || "" );
        }
    } else {
        # Second signature (the one we _receive_)
        for(qw/authResult pspReference merchantReference skinCode/) {
            $plaintext .= ( defined $self->{"_$_"} ) 
                       ? $self->{"_$_"} : ( $args->{$_} || "" );
        }
    }

    $self->{_hmac}->add($plaintext);
    my $b64_digest = $self->{_hmac}->b64digest;
       $b64_digest .= '=' while (length($b64_digest) % 4);

    return $b64_digest; 
}

=pod

=head3 banklist

In order to offer all iDEAL banks, you will have to fetch a list
with their names and codes. This list is subject to change, so check
this often (Adyen recommends "regularly (e.g. once a day)").
I'd suggest to always check this before a payment.

This method will return an arrayref with the bank_ids and bank_names,
or undef in case an error occured (see L<"error">)

=cut

sub banklist {
    my $self = shift;

    my $res = $self->{_ua}->get($self->_url('banklist'));
    if ($res->is_success) {
        return $self->_parse_xml($res->decoded_content)->{'bank'};
    } else {
        $self->{_error} = $res->status_line;
        return undef;
    }
}

=pod

=head3 fetch

After you've retrieved the L<"banklist">, your users may choose the preferred
bank. Now you can feed that 'bank_id', together with the other mandatory
options to this method.

C<fetch> will return an URL to the bank's iDEAL page that the user should
be directed to.

Some fields are mandatory, while others have somewhat sane defaults and
may be skipped.

=head4 options

=over 5

=item B<bank_id> I<[mandatory]>

This is the bank ID chose by the user and provided by the L<"banklist">
method.

=item B<paymentAmount> I<[mandatory]>

How much would you like to charge your user? Note that this is in
cents, so 12,50 EUR should be inserted as 1250. If a dot or comma
is found in this value, it will be stripped. Don't count on this being
perfect, so sanitize your own input.

=item B<merchantReference>

This will normally be set to your order number, or anything that's useful
to identify the order with. If not set, a semi-random number is generated.

=item B<currencyCode>

Defaults to 'EUR', since iDEAL is a Dutch system and we Dutchmen "embraced"
the euro.

=item B<shopperLocale>

Defaults to 'nl'. Again, iDEAL is a Dutch system.

=item B<shipBeforeDate>

To make matters easy, we set a I<shipBeforeDate> of today + 1 month.

=item B<sessionValidity>

By default, we set this value to now + 1 hour, UTC. A user should
be able to finish his/her transaction within an hour.

=back

Other options, as described in the Adyen integration manual, like
I<shopperEmail>, could be passed in as well, but are completely
optional.

=cut

sub fetch {
    my ($self, $parms) = @_;
    $parms ||= {};
    $self->_croak("Parameters must be a hash reference")
        unless ref($parms) eq 'HASH';

    # check for mandatory fields that we can't generate
    for(qw/bank_id paymentAmount/) {
        $self->_croak("$_ not set") unless($parms->{$_});
    }

    # make sure we have the paymentAmount in cents
    $parms->{paymentAmount} =~ s![,\.]!!;

    # check for mandatory fields that we could generate where needed
    $parms->{merchantReference} ||= int(rand(1000000)).time();
    $parms->{currencyCode}      ||= 'EUR';
    $parms->{shopperLocale}     ||= 'nl';
    $parms->{shipBeforeDate}    ||= DateTime->now()
                                            ->add(months => 1)
                                            ->strftime("%F");
    $parms->{sessionValidity}   ||= DateTime->now(time_zone => 'UTC')
                                            ->add(hours => 1)
                                            ->strftime("%FT%TZ");

    # set iDEAL settings
    $parms->{skipSelection}   = 'true';
    $parms->{brandCode}       = 'ideal';
    $parms->{idealIssuerId}   = delete $parms->{bank_id};

    # set globals
    $parms->{skinCode}        = $self->{_skinCode};
    $parms->{merchantAccount} = $self->{_merchantAccount};

    # calculate and set the signature
    $parms->{merchantSig}   = $self->_sign_req($parms);

    # create URL
    my $uri = URI->new( $self->_url('redirect') );
       $uri->query_form( $parms );

    return $uri->as_string;
}

=pod

=head3 check

When a user has proceeded the payment throught the bank's website, he/she'll
be returned to your website (as specified on the Adyen's skin pages).

This method can be called to check whether the payment succeeded or not.
I<check> returns true when the payment was authorized and undef in
all other cases (see L<"error"> in that case).

=cut

sub check {
    my ($self, $args) = @_;

    if($args->{merchantSig} && $args->{merchantSig} eq $self->_sign_req($args)){
        # Signature is ok
        if($args->{authResult} eq 'AUTHORISED') {
            # Payment is OK
            return 1;
        } else {
            # Payment failed
            $self->{_error} = "Payment status: ".$args->{authResult};
        }
    } else {
        # Signature failed
        $self->{_error} = "Merchant Signature was incorrect";
    }
    return undef;
}

=pod

=head3 error

If errors occur (most likely signature related), this method will return
the latest error that occured.

=cut

sub error {
    my $self = shift;
    return $self->{_error};
}


=pod

=head1 SEE ALSO

=over 5

=item * L<http://www.ideal.nl>

=item * L<https://support.adyen.com/index.php>

=item * L<http://menno.b10m.net/perl/>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Business-iDEAL-Adyen>.

=head1 AUTHOR

Menno Blom,
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Menno Blom

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
