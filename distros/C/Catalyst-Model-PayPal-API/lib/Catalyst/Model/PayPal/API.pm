#!/bin/false
package Catalyst::Model::PayPal::API;

# ABSTRACT: A Catalyst Model for PayPal via Business::PayPal::API

use strict;
use warnings;

use parent 'Catalyst::Model';

use Business::PayPal::API;

our $VERSION = '0.31';

=head1 NAME

Catalyst::Model::PayPal::API - PayPal Model for Catalyst

=head1 WARNING

Although I have been using this model for over 12 months in production,
and it has processed over $10,000 in sales - please test thoroughly
before risking your livelyhood on it!

This module is really only a layer between Catalyst::Model and
Business::PayPal::API, any problems will PayPall are probably problems
with the underlying module.

=head1 SYNOPSIS

  package YourApp::Model::PayPal;
  use parent 'Catalyst::Model::PayPal::API';
  __PACKAGE->config(%paypal_account_details);
  1

  package YourApp::Controller::Foo;

  sub index : Path('/') {
    my ( $self, $c, @args ) = @_;

    my %resp = $c->model('PayPal')->SetExpressCheckout(%options);

    if ( $resp{Ack} eq 'Success' ) {
      # save the various details in a database or something, then redirect

	$c->response->redirect(
	    $c->model('PayPal')->redirect_url() . $resp{Token} );

    } else {
      # handle the error details, see Business::PayPal::API
    }
  }
  1

=head1 USAGE

=head2 3-token (Signature) authentication

  package 'Your::Model::PayPal';
  use parent 'Catalyst::Model::PayPal::API';

  __PACKAGE__->config(
      Username   => 'your paypal username',
      Password   => 'ABCDEF',  ## supplied by PayPal
      Signature  => 'xyz',     ## ditto
      sandbox    => 0 || 1,    ## Use sandbox or production API
      subclasses => [qw( ExpressCheckout GetTransactionDetails )],
                               ## Which functions to use
  );

=over 4

=item Username

Your paypal API username

=item Password

As supplied by PayPal

=item Signature

As supplied by PayPal

=item sandbox

If true, uses the sandbox apis rather than production APIs

Use this for the thorough testing I mentioned above.

=item subclasses

L<Business::PayPal::API> has a custom import() function which you must
instruct to load which ever API functions you want to use. This sounds
less strange than it is. See B<Business::PayPal::API::*> for which
API options can be loaded.

Check the documentation for L<Business::PayPal::API> for details on which 
options you want to use here.

=back

=head2 PEM certificate authentication

  package 'Your::Model::PayPal';
  use parent 'Catalyst::Model::PayPal::API';

  __PACKAGE__->config(
      Username   => 'your paypal username',
      Password   => 'ABCDEF',  ## supplied by PayPal
      CertFile   => '/path/to/file', ## file, supplied by PayPal
      KeyFile    => '/path/to/file', ## file, supplied by PayPal
      sandbox    => 0 || 1,    ## Use sandbox or production API
      subclasses => [qw( ExpressCheckout GetTransactionDetails )],
                               ## Which functions to use
  );

=cut

=over 4

=item Username, Password, sandbox, subclasses

As described previously

=item CertFile

Location of the CertFile

=item KeyFile

Location of the KeyFile

=back

=head2 Certificate authentication

  package 'Your::Model::PayPal';
  use parent 'Catalyst::Model::PayPal::API';

  __PACKAGE__->config(
      Username    => 'your paypal username',
      Password    => 'ABCDEF',  ## supplied by PayPal
      PKCS12File  => '/path/to/file', ## file, supplied by PayPal
      PKCS12Password => '/path/to/file', ## file, supplied by PayPal
      sandbox     => 0 || 1,    ## Use sandbox or production API
      subclasses  => [qw( ExpressCheckout GetTransactionDetails )],
                                ## Which functions to use
  );

=over 4

=item Username, Password, sandbox, subclasses

As described previously

=item PKCS12File

Location of the PKCS12File

=item PKCS12Password

Location of the PKCS12Password

=back

=head1 DESCRIPTION

This is a Catalyst model for Business::PayPal::API, allowing you to use
PayPal to bill your clients in your Catalyst application.

When naming this model, I have chosen to drop the 'Business::' so as to
shorten the name somewhat.

=head1 FUNCTIONS

=head2 new

You don't need to worry about new(), Catalyst uses this all on its own.

=cut

sub new {

    my ( $class, $c, $config ) = @_;

    my $self = $class->next::method($c);

    die(q|No configured subclasses|)
      unless $self->{subclasses};

    # try to import the subclasses
    # this is somewhat nasty so blame it on Business::PayPal::API ...
    Business::PayPal::API::import(
        '',    # fake $self
        ref $self->{subclasses}
        ? @{ $self->{subclasses} }
        : $self->{subclasses}
    );

    # try to guess whats wanted
    die q|Username required| unless $self->{Username};
    die q|Password required| unless $self->{Password};

    my %options;

    ## try 3-token (Signature) authentication
    $options{Signature} = $self->{Signature}
      if $self->{Signature};

    ## try PEM certificate authentication
    if ( $self->{CertFile} or $self->{KeyFile} ) {

        die q|Multiple auth types attempted| if %options;
        die q|CertFile missing| unless $self->{CertFile};
        die q|KeyFile missing|  unless $self->{KeyFile};

        $options{CertFile} = $self->{CertFile};
        $options{KeyFile}  = $self->{KeyFile};

    }

    ## try certificate authentication
    if ( $self->{PKCS12File} or $self->{PKCS12Password} ) {

        die q|Multiple auth types attempted| if %options;
        die q|PKCS12File missing|     unless $self->{PKCS12File};
        die q|PKCS12Password missing| unless $self->{PKCS12Password};

        $options{PKCS12File}     = $self->{PKCS12File};
        $options{PKCS12Password} = $self->{PKCS12Password};

    }

    die q|No auth values given in config|
      unless %options;

    # drop in username, password, sandbox etc
    %options = (
        Username => $self->{Username},
        Password => $self->{Password},
        sandbox  => $self->{sandbox} || 0,
        %options,
    );

    my $paypal = Business::PayPal::API->new(%options);

    $self->{paypal} = $paypal;

    return $self;
}

# pass stuff on through to PayPal
# we need to strip some crap but thats ok
sub AUTOLOAD {

    my $self = shift;
    my %args = @_;

    our $AUTOLOAD;

    my $program = $AUTOLOAD;
    $program =~ s/.*:://;

    # pass straight through to our paypal object

    return $self->{paypal}->$program(%args);

}

=head2 redirect_url

 $redirect = $c->model('PayPal')->redirect_url() . $token;

This is a convenient function which you can use to redirect your customer
to PayPal to make their purchases. You just concatenate their token
to the end and redirect!

This function knows about the sandbox setting, which is also very convenient
 when testing. But remember that you provide to PayPal the return URL,
so you'll need to match it with your production and testing environments
independant on your own!

=cut

sub redirect_url {

    my $self = shift;

    return 'https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token='
      unless $self->{sandbox};

    return
'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=';

}

=head1 ERROR HANDLING

As per L<Busines::PayPal::API>, errors are in the %resp returned when functions are 
called.

=head1 SEE ALSO

L<Business::PayPal::API>

=head1 AUTHOR

Dean Hamstead, C<< <dean at fragfest.com.au> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-PayPal-API>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Please fork and contribute via L<https://github.com/djzort/Catalyst-Model-PayPal-API>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Dean Hamstead,

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1
