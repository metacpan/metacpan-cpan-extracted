package CGI::Lite::Request;

our $VERSION = '0.06';

BEGIN {
    our $MODE = 'Base';
    if (exists $ENV{MOD_PERL} or "$ENV{GATEWAY_INTERFACE}" =~ /^CGI-Perl\//) {
        $MODE = 'Apache';
    }
    eval "require CGI\::Lite\::Request\::$MODE";
    unshift @{__PACKAGE__.'::ISA'}, "CGI\::Lite\::Request\::$MODE";
}

1;

__END__

=head1 NAME

CGI::Lite::Request - Request object based on CGI::Lite

=head1 SYNOPSIS

  use CGI::Lite::Request;
   
  my $req = CGI::Lite::Request->new;
  my $req = CGI::Lite::Request->instance;
   
  # parse the incoming request
  $req->parse();
   
  $foo  = $req->param('foo');
  @foos = $req->param('foo');                   # multiple values
  @params = $req->params();                     # params in parse order
  $foo  = $req->args->{foo};                    # hash ref
  %args = $req->args;                           # hash
  $uri = $req->uri;                             # URI
  $req->print(@out);                            # print to STDOUT
  $req->headers;                                # HTTP::Headers instance
  $req->send_http_header;                       # print the header
  $req->content_type('text/html');              # set
  $req->content_type;                           # get
  $path = $req->path_info;                      # $ENV{PATH_INFO}
  $cookie = $req->cookie('my_cookie');          # fetch or create a cookie
  $req->cookie('SID')->value($sessid);          # set a cookie
  $upload = $req->upload('my_field');           # CGI::Lite::Upload instance
  $uploads = $req->uploads;                     # hash ref of CGI::Lite::Upload objects

=head1 DESCRIPTION

This module extends L<CGI::Lite> to provide an interface which is compatible with the most commonly used
methods of L<Apache::Request> as a fat free alternative to L<CGI>.

All methods of L<CGI::Lite> are inherited as is, and the following are defined herein:

=head1 METHODS

=over

=item instance

Allows L<CGI::Lite::Request> to behave as a singleton.

=item new

Constructor

=item parse

This method must be called explicitly to fetch the incoming request before

=item headers

accessor to an internally kept L<HTTP::Headers> object.

=item parse

parses the incoming request - this is called automatically from the
constructor, so you shouldn't need to call this expicitly.

=cut

=item args

return the request parameters as a hash or hash reference depending on
the context. All form data, query string and cookie parameters are available
in the returned hash(ref)

=item param( $key )

get a named parameter. If called in a scalar context, and if more than one
value exists for a field name in the incoming form data, then an array reference
is returned, otherwise for multiple values, if called in a list context, then
an array is returned. If the value is a simple scalar, then in a scalar context
just that value is returned.

=item params

returns all the parameters in the order in which they were parsed. Also includes
cookies and query string parameters.

=item uri

returns the url minus the query string

=item secure

returns true if the request came over https

=item path_info

accessor to the part of the url after the script name

=item print

print to respond to the request. This is normally done after
C<send_http_header> to print the body of data which should be
sent back the the user agent

=item send_http_header

combines the response headers and sends these to the user agent

=item cookie

returnes a named L<CGI::Lite::Cookie> object. If one doesn't
exist by the passed name, then creates a new one and returns
it. Typical semantics would be:

    $sessid = $req->cookie('SID')->value;
    $req->cookie('SID')->value($sessid);

both of these methods will create a new L<CGI::Lite::Request::Cookie>
object if one named 'SID' doesn't already exist. If you don't
want this behaviour, see C<cookies> method

=item cookies

returns a hash reference of L<CGI::Lite::Request::Cookie> objects keyed on their names.
This can be used for accessing cookies where you don't want them
to be created automatically if they don't exists, or for simply
checking for their existence:

    if (exists $req->cookies->{'SID'}) {
        $sessid = $req->cookies->{'SID'}->value;
    }

see L<CGI::Lite::Request::Cookie> for more details

=item upload

returns a named L<CGI::Lite::Upload> object keyed on the field name
with which it was associated when uploaded.

=item uploads

returns a hash reference of all the L<CGI::Lite::Request::Upload> objects
keyed on their names.

see L<CGI::Lite::Request::Upload> for details

=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 ACKNOWLEDGEMENTS

Thanks to Sebastian Riedel for the code shamelessly stolen
from L<Catalyst::Request> and L<Catalyst::Request::Upload>

=head1 SEE ALSO

L<CGI::Lite>, L<CGI::Lite::Cookie>, L<CGI::Lite::Upload>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself

=cut
