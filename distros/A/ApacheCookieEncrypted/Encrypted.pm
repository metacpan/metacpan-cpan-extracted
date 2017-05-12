package Apache::Cookie::Encrypted;
#use Apache::Cookie;
use base qw(Apache::Cookie);

require Apache;

use strict;
use warnings;
use Crypt::CBC;
use Carp;
use vars qw($VERSION $key);

$VERSION = '0.03';

# get the encryption key

BEGIN {
    my $r = Apache->request;
    $key = $r->dir_config('COOKIE_KEY');
}

# Our own constructor. Effectivly overrides the new constructor.

sub new {
    my ($class) = shift;
    my @args = @_;

    # variable declaration
    my (@new_args, $r, $params);
    $params = {};


    # we go through the argument to pull the Apache::Request out of the array and
    # put the rest into another one to be parsed after this.
    foreach my $arg (@args) {
        if (ref($arg) eq "Apache::Request" || ref($arg) eq "Apache") {
            $r = $arg;
        } else {
            push(@new_args, $arg);
        }
    }

    # load in options supplied to new()
    for (my $x = 0; $x <= $#new_args; $x += 2) {
        defined($args[($x + 1)]) or croak("Apache::Cookie::Encrypted->new() called with odd number of".
                                          " option parameters - should be of the form -option => value");

        $params->{lc($new_args[$x])} = $new_args[($x + 1)];
    }

    # check for the key and place it in the proper variable
    unless ($key) {
	if (exists($params->{-key})) {
	    $key = $params->{-key};
	    delete $params->{-key};
	} else {
	    croak "No key defined - key must be defined for Apache::Cookie::Encrypted to work\n";
	}
    }

    my $self = $class->SUPER::new($r);

    if (exists($params->{-name})) {
        $self->name($params->{-name});
    }

    if (exists($params->{-value})) {
        $params->{-value} = &_encrypt_data( $params->{-value} );
        $self->value($params->{-value});
    }

    if (exists($params->{-expires})) {
        $self->expires($params->{-expires});
    }

    if (exists($params->{-domain})) {
        $self->domain($params->{-domain});
    }

    if (exists($params->{-path})) {
        $self->path($params->{-path});
    }

    if (exists($params->{-secure})) {
        $self->secure($params->{-secure});
    }

    # return the blessed object
    return bless $self, $class;

}

sub Apache::Cookie::Encrypted::value {
    my $self = shift;

    my $data = shift || undef;

    if ($data) {
        $data = &_encrypt_data($data) if $data ne '';
        $self->SUPER::value($data);
    } else {
        my  @cookie_data = $self->SUPER::value();
        my $data_in;
        if (scalar(@cookie_data) > 1) {
            $data_in = \@cookie_data;
        } else {
            $data_in = $cookie_data[0];
        }
        my $data_out = &_decrypt_data( $data_in );
        return wantarray ? @$data_out : $data_out;
    }
}

sub Apache::Cookie::Encrypted::parse {
    my $self = shift;

    my $data = shift || undef;
    my %parsed;

    if ($data) {
	%parsed = SUPER::parse($data);
    } else {
	%parsed = SUPER::parse();
    }
    
    my %new_parsed;

    foreach (keys %parsed) {
	$new_parsed{$_} = bless $parsed{$_}, $self;
    }

    return wantarray ? %new_parsed : \%new_parsed;
}

sub Apache::Cookie::Encrypted::fetch {
    my $self = shift;

    my %fetched = $self->SUPER::fetch();

    my %enc_fetch_translated;

    foreach (keys %fetched) {
        $enc_fetch_translated{$_} = bless $fetched{$_}, $self;
    }

    return wantarray ? %enc_fetch_translated : \%enc_fetch_translated;
}

# data encryption subroutine
{
sub _encrypt_data {
    my $data = shift;

    croak("Can't encrypt anything without a key!") unless $key;

    my $cipher = new Crypt::CBC($key,'Blowfish');

    if (ref($data) eq "ARRAY") {
        for (my $i = 0; $i <= $#$data; $i++) {
            $data->[$i] = $cipher->encrypt_hex($data->[$i]);
        }
        return $data;
    } else {
        $data = $cipher->encrypt_hex( $data );
        return $data;
    }
}
}

# data decryption subroutine
{
sub _decrypt_data {
    my $data = shift;

    croak("Can't decrypt anything without a key!") unless $key;

    my $cipher = new Crypt::CBC($key,'Blowfish');

    if (ref($data) eq "ARRAY") {
        for (my $i = 0; $i <= $#$data; $i++) {
            $data->[$i] = $cipher->decrypt_hex($data->[$i]);
        }
        return $data;
    } else {
        $data = $cipher->decrypt_hex( $data );
        return $data;
    }
}
}

1;

__END__

=head1 NAME

Apache::Cookie::Encrypted - Encrypted HTTP Cookies Class

=head1 SYNOPSIS

  use Apache::Cookie::Encrypted;
  my $cookie = Apache::Cookie::Encrypted->new($r, ...); 

=head1 DESCRIPTION

The Apache::Cookie::Encrypted module is a class derived from Apache::Cookie.
It creates a cookie with its contents encrypted with Crypt::Blowfish.

=head1 METHODS

This interface is identical to the I<Apache::Cookie> interface with a couple of
exceptions. Refer to the I<Apache::Cookie> documentation while these docs
are being refined.

You'll notice that the documentation is pretty much the same as I<Apache::Cookie's>.
It is. I took most of the documentation and put it here for your convienience.

=over 4

=item new 

Just like Apache::Cookie->new(), it also requires an I<Apache> object 
but also can take an I<Apache::Request> object:

    my $cookie = Apache::Cookie::Encrypted->new($r,
						-key     =>  $key,
						-name    =>  'foo',
						-value   =>  'bar',
						-expires =>  '+3M',
						-domain  =>  '.myeboard.com',
						-path    =>  '/',
						-secure  =>  1
						);

The key doesn't have to be defined in the constructor if you set it in
your httpd.conf as a PerlSetVar.

    PerlSetVar  COOKIE_KEY <Blowfish key>

B<Make sure you do define a key or else the module will croak.>

=item bake

This is the same bake method in I<Apache::Cookie>.

    $cookie->bake;

=item parse

This method parses the given string if present, otherwise, the incoming Cookie header:

    my $cookies = $cookie->parse; #hash ref

    my %cookies = $cookie->parse;

    my %cookies = $cookie->parse($cookie_string);

=item fetch

Fetch and parse incoming I<Cookie> header:

    my $cookies = Apache::Cookie::Encrypted->fetch; # hash ref
    my %cookies = Apache::Cookie::Encrypted->fetch; # plain hash

The value will be decrypted upon call to $cookie->value.

=item as_string

Format the cookie object as a string:

    #same as $cookie->bake
    $r->err_headers_out->add("Set-Cookie" => $cookie->as_string);

=item name

Get or set the name of the cookie:

    my $name = $cookie->name;

    $cookie->name("Foo");

=item value

Get or set the values of the cookie:

    my $value = $cookie->value;
    my @value = $cookie->value;

    $cookie->value("string");
    $cookie->value(\@array);

Just like in I<Apache::Cookie> except that the contents are encrypted
and decrypted automaticaly with the key defined in the constructor or
set within httpd.conf as a PerlSetVar.

B<Remember the key must be set in the constructor or in the httpd.conf
file for this module to work. It wil complain if its not set.>

=item domain

Get or set the domain for the cookie:

    my $domain = $cookie->domain;
    $cookie->domain(".cp.net");

=item path

Get or set the path for the cookie:

    my $path = $cookie->path;
    $cookie->path("/");

=item expires

Get or set the expire time for the cookie:

    my $expires = $cookie->expires;
    $cookie->expires("+3h");

=item secure

Get or set the secure flag for the cookie:

    my $secure = $cookie->secure;
    $cookie->secure(1);

=back

=head1 SEE ALSO

I<Apache>(3), I<Apache::Cookie>(3), I<Apache::Request>(3)

=head1 AUTHOR

Jamie Krasnoo<jkrasnoo@socal.rr.com>

=head1 CREDITS

Apache::Cookie - docs and modules - Doug MacEachern
Crypt::CBC - Lincoln Stein, lstein@cshl.org
Crypt::Blowfish - Dave Paris <amused@pobox.com> and those mentioned in the module.

=cut
