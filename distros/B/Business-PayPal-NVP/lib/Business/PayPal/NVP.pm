package Business::PayPal::NVP;

use 5.008001;
use strict;
use warnings;

our $VERSION = '1.10';
our $AUTOLOAD;

our $Debug  = 0;
our $Branch = 'test';
our $Timeout= 0;
our $UserAgent;

use LWP::UserAgent ();
use URI::Escape ();
use Carp 'croak';

sub API_VERSION { 98 }

## NOTE: This is an inside-out object; remove members in
## NOTE: the DESTROY() sub if you add additional members.

my %errors = ();
my %test   = ();
my %live   = ();

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \(my $ref), $class;

    $Branch = $args{branch} || 'test';
    $Timeout = $args{timeout};
    $UserAgent = $args{ua} || LWP::UserAgent->new;

    if (ref $UserAgent ne 'LWP::UserAgent') {
        die "ua must be a LWP::UserAgent object\n";
    }

    $errors {$self} = [ ];
    $test   {$self} = $args{test} || { };
    $live   {$self} = $args{live} || { };

    return $self;
}

sub AUTH_CRED {
    my $self   = shift;
    my $cred   = shift;
    my $branch = shift || $Branch || 'test';

    return { testuser => $test{$self}->{user},
	     testpwd  => $test{$self}->{pwd},
	     testsig  => $test{$self}->{sig},
	     testurl  => $test{$self}->{url} || 'https://api-3t.sandbox.paypal.com/nvp',
             testsubj => $test{$self}->{subject},
	     testver  => $test{$self}->{version},

	     liveuser => $live{$self}->{user},
	     livepwd  => $live{$self}->{pwd},
	     livesig  => $live{$self}->{sig},
	     liveurl  => $live{$self}->{url} || 'https://api-3t.paypal.com/nvp',
             livesubj => $live{$self}->{subject},
	     livever  => $live{$self}->{version},
	 }->{$branch . $cred};
}

sub _do_request {
    my $self = shift;
    my %args = @_;

    my $lwp = $UserAgent;
    $lwp->timeout($Timeout) if $Timeout;
    $lwp->agent("perl-Business-PayPal-NVP/$VERSION");
    my $req = HTTP::Request->new( POST => $self->AUTH_CRED('url') );
    $req->content_type( 'application/x-www-form-urlencoded' );

    my $content = _build_content( USER      => $self->AUTH_CRED('user'),
				  PWD       => $self->AUTH_CRED('pwd'),
				  SIGNATURE => $self->AUTH_CRED('sig'),
				  VERSION   => delete $args{VERSION} || $self->AUTH_CRED('ver') || API_VERSION,
                                  SUBJECT   => $self->AUTH_CRED('subj'),
				  %args );
    $req->content( $content );

    if ($Debug) {
        require Data::Dumper;
        print STDERR "Making request: " . Data::Dumper::Dumper($req);
    }

    my $res = $lwp->request($req);

    unless( $res->code == 200 ) {
        $self->errors("Failure: " . $res->code . ': ' . $res->message);
        return ();
    }

    return map { URI::Escape::uri_unescape($_) }
      map { split /=/, $_, 2 }
        split /&/, $res->content;
}

sub _build_content {
    my %args = @_;

    my @args = ();
    for my $key ( keys %args ) {
	$args{$key} = ( defined $args{$key} ? $args{$key} : '' );
        push @args, URI::Escape::uri_escape($key) . '=' . URI::Escape::uri_escape($args{$key});
    }

    return join('&', @args) || '';
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    return if $method eq 'DESTROY';
    croak "Undefined subroutine $method" unless $method =~ /^[A-Z]/;
    $self->_do_request(METHOD => $method, @_);
}

sub send {
    shift->_do_request(@_);
}

sub errors {
    my $self = shift;

    if( @_ ) {
        push @{ $errors{$self} }, @_;
        return;
    }

    return @{ $errors{$self} };
}

sub clear_errors {
    my $self = shift;
    $errors{$self} = [];
}

sub DESTROY {
    my $self = $_[0];

    delete $errors {$self};
    delete $test   {$self};
    delete $live   {$self};

    my $super = $self->can("SUPER::DESTROY");
    goto &$super if $super;
}

1;
__END__

=head1 NAME

Business::PayPal::NVP - PayPal NVP API

=head1 SYNOPSIS

  use Business::PayPal::NVP;

  my $nvp = new Business::PayPal::NVP( test => { user => 'foo.domain.tld',
                                                 pwd  => '123412345',
                                                 sig  => 'A4fksj34.KKkkdjwi.w993sfjwiejfoi-2kj3' },
                                       live => { user => 'foo.domain.tld',
                                                 pwd  => '55553333234',
                                                 sig  => 'Afk4js43K.kKdkwj.i9w39fswjeifji-2oj3k' },
                                       branch  => 'test',
                                       timeout => 60,
                                     );

  ##
  ## direct payment
  ##
  %resp = $nvp->DoDirectPayment( PAYMENTACTION  => 'Sale',
                                 CREDITCARDTYPE => 'VISA',
                                 ACCT           => '4321123412341234',
                                 AMT            => '30.00',
                                 EXPDATE        => '022018',   ## mmyyyy
                                 CVV2           => '100',
                                 IPADDRESS      => '12.34.56.78',
                                 FIRSTNAME      => 'Buyer',
                                 LASTNAME       => 'Person',
                                 STREET         => '1234 Street',
                                 CITY           => 'Omaha',
                                 STATE          => 'NE',
                                 COUNTRY        => 'United States',
                                 ZIP            => '12345',
                                 COUNTRYCODE    => 'US' );

  unless( $resp{ACK} eq 'Success' ) {
      croak "dang it...";
  }


  ##
  ## express checkout
  ##
  $invnum = time;
  %resp = $nvp->SetExpressCheckout( AMT           => '25.44',
                                    CURRENCYCODE  => 'USD',
                                    DESC          => 'one widget',
                                    CUSTOM        => 'thank you for your money!',
                                    INVNUM        => $invnum,
                                    PAYMENTACTION => 'Sale',
                                    RETURNURL     => 'http://www.example.com/thankyou.html',
                                    CANCELURL     => 'http://www.example.com/sorry.html', );

  $token = $resp{TOKEN};

  %resp = $pp->GetExpressCheckoutDetails( TOKEN => $token );

  $payerid = $resp{PAYERID};

  %resp = $pp->DoExpressCheckoutPayment( TOKEN         => $token,
                                         AMT           => '25.44',
                                         PAYERID       => $payerid,
                                         PAYMENTACTION => 'Sale' );

=head1 DESCRIPTION

B<Business::PayPal::NVP> makes calls to PayPal's NVP ("name-value
pair"--a fancy name for HTTP POST queries) API.

Making a call is as simple as creating an NVP object and invoking the
PayPal API method with the appropriate arguments.

Consult the PayPal NVP API for parameter names and valid values. Note
that you do not need to URI escape your values; this module handles
all of the messy HTTP transport issues.

Here is the PayPal NVP API:

L<https://developer.paypal.com/webapps/developer/docs/classic/api/>

=head1 METHODS

=head2 new

Creates a new PayPal connection object. This method is required for
all PayPal transactions, but the object may be reused for subsequent
transactions.

Parameters:

=over 4

=item branch

defaults to 'test'. Set to 'live' if you want to make live transaction
queries.

=item test

sets the test authentication data. Takes a hashref in the following
format:

  { user => 'paypal_user_info',
    pwd  => 'paypal_password',
    sig  => 'paypal_signature',
    version  => '53.0',
    subject  => 'some@where.tld' }

The I<version> and I<subject> parameters are optional. The I<version>
parameter changes the default API version (currently 98) for all
calls made using this object. The I<subject> parameter is passed as
described in the PayPal API documentation (do not use unless you
understand what it is for).

=item live

sets the live authentication data. See 'test' parameter for an example
format.

Example:

  my $pp = new Business::PayPal::NVP( branch => 'live',
                                      live   => { user => 'my.live.paypal.api.username',
                                                  pwd  => '234089usdfjo283r4jaksdfu934',
                                                  sig  => SlkaElRakSw34-asdflkj34.sdf', } );

=item ua

sets the user agent used for HTTP requests. Must be an LWP::UserAgent
(for now). Useful if you need to set up a proxies, add handlers, or
make use of other LWP client features.

Example:

    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);

    my $pp = new Business::PayPal::NVP( branch => 'live',
                                        live   => { ... },
                                        ua     => $ua );

=back

=head2 errors

Returns a list of the errors encountered during the last transaction,
if any.

Example:

  $pp->DoDirectPayment(%data)
    or do {
      warn "Error! " . join("\n", $pp->errors);
    };

=head2 clear_errors

Clears the error list.

=head2 All other methods

All other methods are PayPal API calls, I<exactly> as they appear in
the manual, with the exception of the I<METHOD> parameter which is
inferred from the object's method name (e.g., "DoCapture"). If these
methods are not working, check the return value via B<errors()>.

B<Business::PayPal::NVP> treats all method calls it does not recognize
as PayPal API calls and builds a request for you and sends it using
the authentication data you provided in the B<new()> method (either
I<live> or I<test>).

You do not need to add the I<METHOD> parameter to any method calls.

If you encounter a method call that requires a higher version number
than the default (currently 51.0), you may specify that as part of
your call:

  %resp = $pp->SomeNewMethod( VERSION => '54.0', %args );

This works on a method-by-method basis. To change the default for all
method calls, pass in a I<version> parameter when the object is
created (see B<new()>).

Examples:

  %resp = $pp->DoDirectPayment( PAYMENTACTION  => 'Sale',
                                CREDITCARDTYPE => 'VISA',
                                etc. );

  %resp = $pp->DoCapture( AUTHORIZATIONID => $authid,
                          AMT             => '25.00',
                          etc. );

  %resp = $pp->DoAuthorization( %data );

  %resp = $pp->DoReauthorization( %data );

  %resp = $pp->DoVoid( %data );

  %resp = $pp->SetExpressCheckout( %data );

  %resp = $pp->GetExpressCheckout( TOKEN => $token );

  %resp = $pp->DoExpressCheckoutPayment( %data );

  %resp = %pp->GetTransactionDetails( %data );

and so forth. See
L<https://developer.paypal.com/webapps/developer/docs/classic/api/>
for complete API details.

=head2 send

This method is supplied to make method calls that don't seem to work
using the "automatic" method.

Example:

  %resp = $pp->send(METHOD => 'DoDirectPayment', %arguments);

=head1 EXAMPLES

Examples for each method are scattered throughout the documentation
above, as well as in the F<t> directory of this distribution.

=head1 TESTING

To run the built-in tests for this module, you'll need to obtain a
PayPal developer sandbox account. Once you've done that, create a file
in this module's root directory (after you unpack the module, the same
place where the README file is found) named F<auth.txt> in the
following format:

  user = your.TEST.api.username.for.paypal.tld
  pwd  = your.TEST.api.password
  sig  = your.TEST.api.signature

The test harness will read this file and try to connect to PayPal's
test server to make test API calls.

=head1 TROUBLESHOOTING

You may enable the global variable I<$Debug> to turn on some extra
debugging. It's not much, but it may help in some cases. For deep
debugging, you'll want to uncomment the line at the top of the module:

  LWP::Debug qw(+ -conns);

Use the B<errors()> method liberally.

Send any additional suggestions to the author.

=head1 SEE ALSO

L<Business::PayPal::API>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 CONTRIBUTORS

Sachin Sebastian, E<lt>sachinjsk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2016 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
