package CloudApp::REST;

use Moose;
use MooseX::Types::URI qw(Uri);

use LWP::UserAgent;
use HTTP::Request;
use JSON::XS;
use Module::Load;
use Data::Dumper;

=head1 NAME

CloudApp::REST - Perl Interface to the CloudApp REST API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

has useragent => (
    is       => 'ro',
    required => 0,
    isa      => 'LWP::UserAgent',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $ua   = LWP::UserAgent->new;
        $ua->agent($self->agent_name);
        $ua->proxy('http', $self->proxy) if $self->proxy;
        return $ua;
    },
    clearer => '_reset_useragent',
                 );

has debug => (is => 'rw', required => 0, isa => 'Bool', default => 0);

has agent_name => (is => 'rw', required => 0, isa => 'Str', default => __PACKAGE__ . "/" . $VERSION);
has private_base_url => (is => 'rw', required => 0, isa => Uri, coerce => 1, default => sub { to_Uri('http://my.cl.ly/') });
has public_base_url  => (is => 'rw', required => 0, isa => Uri, coerce => 1, default => sub { to_Uri('http://cl.ly/') });
has fileupload_url   => (is => 'rw', required => 0, isa => Uri, coerce => 1, default => sub { to_Uri('http://f.cl.ly') });

has auth_netloc => (is => 'rw', required => 0, isa => 'Str', default => 'my.cl.ly:80');
has auth_realm  => (is => 'rw', required => 0, isa => 'Str', default => 'Application');

has email => (is => 'rw', required => 0, isa => 'Str');
has username => (is => 'rw', required => 0, isa => 'Str', trigger => sub { shift->email(shift) });
has password => (is => 'rw', required => 0, isa => 'Str');

has proxy => (is => 'rw', required => 0, isa => Uri, coerce => 1);

=head1 SYNOPSIS

This is a Perl Interface to the CloudApp REST API.  You can find more information about
CloudApp at L<http://www.getcloudapp.com/>.

Here's an example on how to retrieve the last 5 items:

  use CloudApp::REST;
  
  my $cl = CloudApp::REST->new;
  
  $cl->email('email@example.com');
  $cl->password('my_supersafe_secret');
  
  my $items = $cl->get_items;

=head1 SUBROUTINES/METHODS

=head2 new

Creates and returns a new instance.

=head2 email

B<Note:> C<username> is now an alias for the C<email> method, provided for legacy!

Parameters:

=over

=item C<$email>

=back

Sets the email address for requests that need authentication.  Unless you only use L</get_item>
an email address is required.

=head2 password

Parameters:

=over

=item C<$password>

=back

Sets the password for requests that need authentication.  Unless you only use L</get_item>
a password is required.

=head2 get_item

Parameters:

=over

=item C<\%params>

=back

Gets a single item from CloudApp and returns the appropriate C<CloudApp::REST::Item::*> module.
Only one of the following parameters should be given.  However, if C<uri> is given, C<slug>
is ignored.

=over 4

=item I<uri =E<gt> $uri>

The URI to the CloudApp item, eg. C<http://cl.ly/abc123>.

Basically this can be an arbitraty URI pointing anywhere, as long as the app behind it
supports the CloudApp API.

=item I<slug =E<gt> $slug>

The so called C<slug> of an CloudApp Item, eg. C<abc123> for the item at C<http://cl.ly/abc123>.

=back

=cut

sub get_item {
    my $self   = shift;
    my $params = shift;

    my $uri = $params->{uri} || ($params->{slug} ? $self->public_base_url . $params->{slug} : die "No 'uri' or 'slug' given");

    my $item_attrs = $self->_get_response({ uri => $uri });

    return $self->_build_item($item_attrs);
}

=head2 get_items

Parameters:

=over

=item C<\%params>

=back

Gets some or all items from CloudApp, depending on the parameters you pass in.  Returns an arrayref
or array (depending on your context) of appropriate C<CloudApp::REST::Item::*> objects.

=over 4

=item I<per_page =E<gt> $n>

=item I<limit =E<gt> $n>

Sets the maximum count of items per page and/or the maximum items you want to retrieve.  If C<per_page>
is given, C<limit> is ignored.

If not present, defaults to C<5>.

=item I<page =E<gt> $n>

Sets the current page you want to retrieve items from.

Example: If C<per_page> or C<limit> is C<5> and C<page> is C<2>, you will retrieve a maximum of C<5> items
starting at number C<6> (1-based).  If there are no such items, an empty arrayref is returned.
I<B<Note:> this behavior fully depends on the behaviour of the API!>

If C<page> and C<offset> are not present, C<page> defaults to C<1>.

=item I<offset =E<gt> $n>

As an alternative to C<page> you can define an offset.  If C<page> is not given but C<offset> is, C<offset>
is divided by C<per_page> and then converted to an integer.  The result is then used as C<page>.

=item I<type =E<gt> $type>

If you want to get only a specific type of items, set C<type> to an appropriate value.  The value should
be the last part of the module name of the appropriate C<CloudApp::REST::Item::*> class in lower case, eg.
C<archive> for C<CloudApp::REST::Item::Archive>.  If you set C<type> to a value that is not an item type,
an empty list will be returned by this method.

=item I<deleted =E<gt> $bool>

Set to a true value if you want only items from the trash.  Defaults to C<false>.  You may want
to use the shortcut L</get_trash> instead.

=back

=cut

sub get_items {
    my $self   = shift;
    my $params = shift;

    my $per_page = $params->{per_page} || $params->{limit} || 5;
    my $page = $params->{page} || ($params->{offset} ? int($params->{offset} / $per_page) : 1);
    my $type = $params->{type} ? "&type=" . $params->{type} : '';
    my $deleted = $params->{deleted} ? 'true' : 'false';

    $self->authenticate;
    my $hashed_items = $self->_get_response({ uri => $self->private_base_url . "items?page=$page&per_page=$per_page&deleted=$deleted" . $type });

    return $self->_build_items($hashed_items);
}

=head2 get_trash

Parameters:

=over

=item C<\%params>

=back

Accepts the same parameters as L</get_items>, except for C<deleted>.  L</get_trash> is
 nly a small wrapper around L</get_items>.

=cut

sub get_trash {
    my $self   = shift;
    my $params = shift;

    $params->{deleted} = 1;
    return $self->get_items($params);
}

=head2 create_bookmark

Parameters:

=over

=item C<\%params>

=back

Creates a bookmark at CloudApp and returns the newly created bookmark as a L<CloudApp::REST::Item::Bookmark> object.

=over 4

=item I<name =E<gt> $name>

I<Required.>

The name of the bookmark, eg. C<12. Deutscher Perl Workshop>.

=item I<uri =E<gt> $uri>

I<Required.>

The URI of the bookmark, eg. C<http://conferences.yapceurope.org/gpw2010/>.

=back

=cut

sub create_bookmark {
    my $self   = shift;
    my $params = shift;

    die "Provide 'name' and 'uri'" unless $params->{name} && $params->{uri};

    $self->authenticate;
    my $bookmark = $self->_get_response(
                                        {
                                          uri    => $self->private_base_url . "items",
                                          params => {
                                                      item => {
                                                                name         => $params->{name},
                                                                redirect_url => $params->{uri},
                                                              }
                                                    }
                                        }
                                       );

    return $self->_build_item($bookmark);
}

=head2 create_file

Parameters:

=over

=item C<\%params>

=back

Uploads a local file to CloudApp and returns the corresponding C<CloudApp::REST::Item::*> object.

=over 4

=item I<file =E<gt> $path_to_file>

I<Required.>

The path to the file that will be uploaded.  If the file is not accessible or does not exist,
L</create_file> dies before trying to upload.

=back

=cut

sub create_file {
    my $self   = shift;
    my $params = shift;

    die "Provide 'file'" unless $params->{file};
    die "File " . $params->{file} . " does not exist" unless -f $params->{file};

    $self->authenticate;
    my $req_params = $self->_get_response({ uri => $self->private_base_url . "items/new" });
    $req_params->{params}->{file} = $params->{file};

    my $res = $self->_get_response({ uri => $req_params->{url}, params => $req_params->{params} });

    return ref $res eq 'ARRAY' ? $self->_build_items($res) : $self->_build_item($res);
}

=head2 delete_item

Parameters:

=over

=item C<$item>

=back

Deletes an item at CloudApp.  C<$item> has to be an C<CloudApp::REST::Item::*> object.

Usually this method is called via L<CloudApp::REST::Item/delete>
of a C<CloudApp::REST::Item::*> module object.

=cut

sub delete_item {
    my $self = shift;
    my $item = shift;

    $self->authenticate;
    $self->_get_response({ method => 'DELETE', uri => $item->href->path });

    return 1;
}

=head2 authenticate

Parameters:

=over

=item C<\%params>

=back

Instead of using L</email> and L</password> directly you can
pass along both parameters to L</authenticate> to set the user data.

If one of the following parameters are not given, L</authenticate> tries to find them in
L</email> or L</password>.  If either parameter cannot be found,
L</authenticate> dies.

=over 4

=item I<email =E<gt> $email>
=item I<username =E<gt> $email> (B<Legacy>)
=item I<user =E<gt> $email> (B<Legacy>)

Email to authenticate with.  Use one of them to access L</email>.

=item I<password =E<gt> $password>
=item I<pass =E<gt> $password>

Password to authenticate with.  Use one of them to access L</password>.

=back

B<Note:> the credentails passed through L</authenticate> are B<not> saved within the instance
data of L<CloudApp::REST>. As result only one request is handled with authentication, all
following will be processed without it.  Note that some API calles require authentication
and if this data is not present when calling such a method, that method will die.

=cut

sub authenticate {
    my $self   = shift;
    my $params = shift;

    my $email = $params->{email} || $params->{username} || $params->{user} || $self->email || die "You have to provide an email address";
    my $pass  = $params->{password} || $params->{pass} || $self->password || die "You have to provide a password";

    $self->useragent->credentials($self->auth_netloc, $self->auth_realm, $email, $pass);

    return 1;
}

=head2 account_register

Parameters:

=over

=item C<\%params>

=back

Registers an CloudApp account using the given email and password and returns the data returned by the API call as hash ref.

=over 4

=item I<email =E<gt> $email>

Email address (username) to register.

=item I<password =E<gt> $password>
=item I<pass =E<gt> $password>

Password for the user.

=back

=cut

sub account_register {
    my $self   = shift;
    my $params = shift;

    my $email = $params->{email} || $self->email || die "You have to provide an email address";
    my $pass  = $params->{password} || $params->{pass} || $self->password || die "You have to provide a password";

    return $self->_get_response({ uri => $self->private_base_url . 'register', params => { user => { email => $email, password => $pass } } });
}

=head1 FLAGS, ATTRIBUTES AND SETTINGS

You can control some behaviour by setting different flags or change some attributes
or settings.  Use them as methods.

=over 4

=item debug

Parameters:

=over

=item C<$bool>

=back

Activates the debug mode by passing a true value.  Defaults to C<0>.  Debug messages are
printed with C<warn>.

=item agent_name

Parameters:

=over

=item C<$new_name>

=back

Redefines the name of the user agent, defaults to module name and version.

=item private_base_url

Parameters:

=over

=item C<$url>

=back

The hostname and the scheme of the private area (when auth is needed).  Defaults
to C<http://my.cl.ly/>.  I<Usually there is no need to change this!>

=item public_base_url

Parameters:

=over

=item C<$url>

=back

The hostname and the scheme of the public area (when auth is not needed).  Defaults
to C<http://cl.ly/>.  I<Usually there is no need to change this!>

=item auth_netloc

Parameters:

=over

=item C<$netloc>

=back

The so called C<netloc> for authentication, as L<LWP::UserAgent> requires.  Defaults
to C<my.cl.ly:80>.  I<Usually there is no need to change this!>

=item auth_realm

Parameters:

=over

=item C<$real>

=back

The so-called C<realm> for authentication, as required by L<LWP::UserAgent> and the
CloudApp API.  Defaults to C<Application>.  I<Usually there is no need to change this!>

=item proxy

Parameters:

=over

=item C<$proxy_url>

=back

If you need to set a proxy, use this method.  Pass in a proxy URL and port for
an C<http> proxy.  If not set, no proxy is used.

=back

=head1 INTERNAL METHODS

=head2 _build_item

Parameters:

=over

=item C<\%item>

=back

Expects an hashref of an item and returns the
appropriate C<CloudApp::REST::Item::*> module.

=cut

sub _build_item {
    my $self       = shift;
    my $item_attrs = shift;

    my $type = $item_attrs->{item_type};

    $item_attrs->{_REST} = $self;
    foreach (keys %$item_attrs) {
        delete $item_attrs->{$_} unless defined $item_attrs->{$_};
    }

    my $module = __PACKAGE__ . '::Item::' . ucfirst($type);
    load $module;

    my $item_instance = $module->new($item_attrs);

    return $item_instance;
}

=head2 _build_items

Parameters:

=over

=item C<\@items>

=back

Expects an arrayref of items and returns a list
of appropriate C<CloudApp::REST::Item::*> objects as arrayref or array,
depending on your context.

=cut

sub _build_items {
    my $self         = shift;
    my $hashed_items = shift;

    my @items;
    foreach my $item_attrs (@$hashed_items) {
        push @items, $self->_build_item($item_attrs);
    }

    return wantarray ? @items : \@items;
}

=head2 _get_response

Parameters:

=over

=item C<\%params>

=back

Executes each request and communicates with the CloudApp API.

=over 4

=item I<uri =E<gt> $uri>

The URI that is requested, eg. C<http://my.cl.ly/items?page=1&per_page=5>.

=item I<method =E<gt> $method>

The HTTP method of the request type.  If the parameter C<params> to L</_get_response>
is set, C<method> is ignored and set to C<POST>, otherwise to the value of C<method>.  Defaults
to C<GET> in all other cases.

=item I<params =E<gt> \%params>

If C<params> is set, the keys and values are used as C<POST> parameters with their values,
the HTTP method is set to C<POST>.

If C<params> has a key C<file>, this method tries to upload that file.  However, it is not
checked if the file exists (you need to do this by yourself if you use this method directly).

=item I<noredirect =E<gt> $bool>

If C<noredirect> is set to a true value, this method won't follow any redirects.

=back

I<Some notes:>

=over 4

=item

After each call, the current user agent instance is destroyed.  This is done to
reset the redirect status so that the next request won't contain auth data
unless required.

=item

This method handles all HTTP status codes that are considered as C<successful>
(all C<2xx> codes) and the codes C<302> and C<303>.  If other status codes are returned,
the request is considered an error and the method dies.

=back

=cut

sub _get_response {
    my $self   = shift;
    my $params = shift;

    my $uri    = $params->{uri} || die "No URI given!";
    my $method = $params->{method};
    my %body   = $params->{params} ? %{ $params->{params} } : ();

    $self->useragent->requests_redirectable([]) if $params->{noredirect};

    my $res;
    unless (exists $body{file}) {
        $self->_debug("New request, URI is $uri");
        my $req = HTTP::Request->new;
        $req->header(Accept => 'application/json');
        $req->content_type('application/json');
        $req->uri($uri);

        $req->method('GET');
        if (%body) {
            $self->_debug("Have content, method will be POST");

            my $body_json = encode_json \%body;
            $req->content($body_json);
            $req->method('POST');
        }
        if (defined $method && $method) {
            $self->_debug("Explicit method $method");
            $req->method($method);
        }

        $res = $self->useragent->request($req);
    } else {
        my $file = delete $body{file};
        $res = $self->useragent->post($uri, [%body, file => [$file]], Content_Type => 'form-data');
    }

    $self->_reset_useragent;

    if ($res->is_success) {
        $self->_debug("Request successful: " . $res->code);
        $self->_debug("Content: '" . $res->content . "'");
        if ($res->content !~ /^\s*$/) {
            return decode_json($res->content);
        } else {
            return undef;
        }
    } elsif ($res->code == 303 || $res->code == 302) {
        $self->authenticate;
        my $location = to_Uri($res->header('Location'));
        my %params = map { $_ => $location->query_param($_) } $location->query_param;
        return $self->_get_response({ uri => $res->header('Location'), noredirect => 1 });
    } else {
        die "Request error: " . $res->status_line . Dumper($res);
    }
}

=head2 _debug

Parameters:

=over

=item C<@msgs>

=back

Small debug message handler that C<warn>s C<@msgs> joined with a line break.  Only prints if C<debug> set to C<true>.

=cut

sub _debug {
    my $self = shift;
    warn join("\n", @_) . "\n" if $self->debug;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-cloudapp-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CloudApp-REST>.  I will be notified, and then you'll
automatically be updated on the progress of your report as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to linebreak L<http://www.bylinebreak.com/> for making such a cool application,
CloudApp.  Go get yourself an account at L<http://www.getcloudapp.com/>!

=head1 SEE ALSO

L<CloudApp::REST::Item>

L<CloudApp::REST::Item::Archive>

L<CloudApp::REST::Item::Audio>

L<CloudApp::REST::Item::Bookmark>

L<CloudApp::REST::Item::Image>

L<CloudApp::REST::Item::Pdf>

L<CloudApp::REST::Item::Text>

L<CloudApp::REST::Item::Unknown>

L<CloudApp::REST::Item::Video>

=head1 AUTHOR

Matthias Dietrich, C<< <perl@rainboxx.de> >>

L<http://www.rainboxx.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Matthias Dietrich.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of CloudApp::REST
