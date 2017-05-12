package Akado::Account;
{
  $Akado::Account::VERSION = '1.2.0';
}

# ABSTRACT: get internet provider Akado account info

use strict;
use warnings FATAL => 'all';
use utf8;

use Carp;
use Digest::MD5 qw(md5_hex);
use HTTP::Request::Common;
use LWP;
use XML::XPath;


sub new {
    my ($class, $self) = @_;

    croak 'No login specified, stopped' unless $self->{login};
    croak 'No password specified, stopped' unless $self->{password};

    $self->{site} ||= 'https://office.akado.ru/';

    bless($self, $class);
    return $self;
}


sub get_balance {
    my ($self) = @_;

    my $data = $self->_get_cached_parsed_data();
    return $data->{balance};
}


sub get_next_month_payment {
    my ($self) = @_;

    my $data = $self->_get_cached_parsed_data();
    return $data->{next_month_payment};
}


sub _get_cached_parsed_data {
    my ($self) = @_;

    if (not defined $self->{_parsed_data}) {
        my $xml = $self->_get_full_account_info_xml();
        $self->{_parsed_data} = $self->_parse_xml($xml);
    }

    return $self->{_parsed_data};
}


sub _get_full_account_info_xml {
    my ($self) = @_;

    my $browser = LWP::UserAgent->new;
    $browser->agent("Akado::Account/$Akado::Account::VERSION");
    $browser->cookie_jar( {} );

    # At first we need to login to the site.
    # Here we POST login/password and recieve session cookies that are stored
    # in the UserAgent cookie_jar.
    my $auth_response = $self->_get_auth_response($browser);

    # Here we get account data using session cookies that we got at the
    # previous step
    my $data_response = $self->_get_data_response($browser);

    my $xml = $data_response->decoded_content;

    return $xml;
}


sub _parse_xml {
    my ($self, $xml) = @_;

    my $xp = XML::XPath->new( xml => $xml );

    my $balance = $xp->findnodes('//bill[contains(@description, "Остаток на счете на")]/@amount')->[0]->getNodeValue();
    my $next_month_payment = $xp->findnodes('//bill[@description="Стоимость услуг в следующем календарном месяце"]/@amount')->[0]->getNodeValue();

    my $parsed_account_info = {
        balance => $balance,
        next_month_payment => $next_month_payment,
    };

    return $parsed_account_info;
}


sub _get_auth_response {
    my ($self, $browser) = @_;

    my $url = $self->{site} . "/user/login.xml";

    my $request = POST($url,
        Content => [
            login    => $self->{login},
            password => $self->{password},
        ]
    );

    my $response = $browser->request($request);
    $self->_check_response($response);

    return $response;
}


sub _get_data_response {
    my ($self, $browser) = @_;

    # To get from Akado site data in xml format we need to add cookie render
    # with the value 'xml'
    $browser->{cookie_jar}->set_cookie(
        0,        # version
        'render', # key
        'xml',    # value
        '/',      # $path
        $self->_get_domain_from_cookies($browser->{cookie_jar}), # domain
    );

    my $url = $self->{site} . "/finance/display.xml";

    my $request = HTTP::Request->new(
        'GET',
        $url,
    );

    my $response = $browser->request($request);
    $self->_check_response($response);

    return $response;
}


sub _get_domain_from_cookies {
    my ($self, $cookies) = @_;

    my $domain;

    $cookies->scan(
        sub {
            $domain = $_[4];
        }
    );

    return $domain
}


sub _check_response {
    my ($self, $response) = @_;

    my $url = scalar $response->request->uri->canonical;
    if ($response->is_error) {
        croak "Can't get url '$url'. Got error "
            . $response->status_line;
    }

    return '';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Akado::Account - get internet provider Akado account info

=head1 VERSION

version 1.2.0

=head1 SYNOPSIS

Akado is the internet provider that works in Moscow, Russia.
L<http://www.akado.ru/>

Every Akado customer has access to the site L<https://office.akado.ru/> where
he can see his account info. This module creates Perl object that gets account
info from that site.

Unfortunately Akdado account site has no API, so this module acts as a browser
to get needed info.

Every module method dies in case of error.

=head1 DESCRIPTION

Akado::Account version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=head1 METHODS

=head2 new

This a constuctor. It creates object. The constractor will not access the
account site. All network interaction is made in the methods that return data.

    my $aa = Akado::Account->new({
        login => $login,
        password => $password,
    });

=head2 get_balance

It will return number. The number is the sum of money that is left on the
user account. The currencty is RUB (Russian rouble).

    say $aa->get_balance();     # will print '749.82', or something like this

If the object hasn't accessed the Akado account site
L<https://office.akado.ru/> since the object was created, the method will
access site, get data from it and store it in the object. The object will
access Akado site only once, after saving data in the object all methods use
that cached data.

=head2 get_next_month_payment

It will return number. The number is the sum of money that the user will have
to pay for the next month. The currencty is RUB (Russian rouble).

    say $aa->get_next_month_payment();

If the object hasn't accessed the Akado account site
L<https://office.akado.ru/> since the object was created, the method will
access site, get data from it and store it in the object. The object will
access Akado site only once, after saving data in the object all methods use
that cached data.

=begin comment _get_cached_parsed_data

B<Get:> 1) $self

B<Return:> 1) $parsed_data

This is private method that should not be used outside the object.

The method checks if the object has already accessed Akado site, if it hasn't
the method gets the data from site, parses it, stores parsed data in the
object and returnes the stored data.

It the object already had accessed Akado site the method will just return
stored parsed data.

Sample of what it can return:

    {
        balance            => 749.82,
        date               => "2012-09-29",
        next_month_payment => 779,
    }

=end comment

=begin comment _get_full_account_info_xml

B<Get:> 1) $self

B<Return:> 1) $xml

Metod returns xml with user account info. Because the Akado site hasn't got
API this method acts as a browser.

=end comment

=begin comment _parse_xml

B<Get:> 1) $self 2) $xml

B<Return:> 1) $parsed_data

Metod gets xml that was previously downloaded from the Akado account site and
returnes some data from it.

It will return something like:

    {
        balance            => 1558.82,
        next_month_payment => 779,
    }

=end comment

=begin comment _get_auth_response

B<Get:> 1) $self 2) $browser - LWP::UserAgent object

B<Return:> 2) $response - HTTP::Response object

The method gets LWP::UserAgent object that has cookies jar in it and logges to
the Akado site. After the log in the cookies are stored in the $browser
object to make it possible to access other pages.

=end comment

=begin comment _get_data_response

B<Get:> 1) $self 2) $browser - LWP::UserAgent object

B<Return:> 2) $response - HTTP::Response object

The method gets LWP::UserAgent object that has session cookies in it and the
method returns the xml page with user account data.

=end comment

=begin comment _get_data_response

B<Get:> 1) $self 2) $cookies - HTTP::Cookies object

B<Return:> 2) $domain - the string 'office.akado.ru' or something like this.

Method gets domain part from existing cookies. This part is needed to create
new cookie.

=end comment

=begin comment _check_response

B<Get:> 1) $self 2) $cookies - HTTP::Response object

B<Return:> -

The method checks that there was no error in accessing some page. If there was
error, the die is performed.

=end comment

=head1 TODO

For now the object can return only several numbers, but the Akado site has
much more data in it. So it will be great if this module can get more details
about user account.

For now he module does not have tests. It was created interacting with the
production system. This is not good. The test should be added that mocks Akado
site and its data.

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
