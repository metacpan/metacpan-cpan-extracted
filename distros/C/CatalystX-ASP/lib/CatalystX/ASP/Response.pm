package CatalystX::ASP::Response;

use namespace::autoclean;
use Moose;
use CatalystX::ASP::Exception::End;
use Tie::Handle;
use List::Util qw(all);
use Data::Dumper;

has 'asp' => (
    is       => 'ro',
    isa      => 'CatalystX::ASP',
    required => 1,
    weak_ref => 1,
);

has '_flushed_offset' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

=head1 NAME

CatalystX::ASP::Response - $Response Object

=head1 SYNOPSIS

  use CatalystX::ASP::Response;

  my $resp = CatalystX::ASP::Response->new(asp => $asp);
  $resp->Write('<h1>Hello World!</h1>');
  my $body = $resp->Body;

=head1 DESCRIPTION

This object manages the output from the ASP Application and the client web
browser. It does not store state information like the $Session object but does
have a wide array of methods to call.

=cut

=head1 ATTRIBUTES

=over

=item $Response->{BinaryRef}

API extension. This is a perl reference to the buffered output of the
C<$Response> object, and can be used in the C<Script_OnFlush> F<global.asa>
event to modify the buffered output at runtime to apply global changes to
scripts output without having to modify all the scripts. These changes take
place before content is flushed to the client web browser.

  sub Script_OnFlush {
    my $ref = $Response->{BinaryRef};
    $$ref =~ s/\s+/ /sg; # to strip extra white space
  }

=cut

has 'BinaryRef' => (
    is      => 'rw',
    isa     => 'ScalarRef',
    default => sub { \( shift->Body ) }
);

has 'Body' => (
    is      => 'rw',
    isa     => 'Str',
    traits  => ['String'],
    handles => {
        Write      => 'append',
        BodyLength => 'length',
        BodySubstr => 'substr',
    },
);

# This attribute has no effect
has 'Buffer' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=item $Response->{CacheControl}

Default C<"private">, when set to public allows proxy servers to cache the
content. This setting controls the value set in the HTTP header C<Cache-Control>

=cut

has 'CacheControl' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'private',
);

=item $Response->{Charset}

This member when set appends itself to the value of the Content-Type HTTP
header.  If C<< $Response->{Charset} = 'ISO-LATIN-1' >> is set, the
corresponding header would look like:

  Content-Type: text/html; charset=ISO-LATIN-1

=cut

has 'Charset' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

# This attribute has no effect
has 'Clean' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

=item $Response->{ContentType}

Default C<"text/html">. Sets the MIME type for the current response being sent
to the client. Sent as an HTTP header.

=cut

has 'ContentType' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'text/html',
);

# For some reason, for attributes that start with a capital letter, Moose seems
# to load the default value before the object is fully initialized. lazy => 1 is
# a workaround to build the defaults later
has 'Cookies' => (
    is      => 'rw',
    isa     => 'HashRef',
    reader  => '_get_Cookies',
    writer  => '_set_Cookies',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        my $c = $self->asp->c;
        my %cookies;
        for my $name ( keys %{ $c->response->cookies } ) {
            my $cookie = $c->response->cookies->{$name};
            for my $attr ( keys %$cookie ) {
                $cookies{$name}{ ucfirst( $attr ) } = ref $cookie eq 'HASH'
                    ? $cookie->{$attr}
                    : $cookie->$attr;
            }
            if ( ref $cookies{$name}{Value} eq 'ARRAY'
                && all {/.=./} @{ $cookies{$name}{Value} } ) {
                for ( @{ delete $cookies{$name}{Value} } ) {
                    my ( $key, $val ) = split '=';
                    $cookies{$name}{Value}{$key} = $val;
                }
            }
        }
        return \%cookies;
    },
    traits  => ['Hash'],
    handles => {
        _get_Cookie => 'get',
        _set_Cookie => 'set',
    },
);

# This attribute currently has no effect
has 'Debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    reader  => '_Debug',
);

=item $Response->{Expires}

Sends a response header to the client indicating the $time in SECONDS in which
the document should expire.  A time of C<0> means immediate expiration. The
header generated is a standard HTTP date like: "Wed, 09 Feb 1994 22:23:32 GMT".

=cut

has 'Expires' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

# This attribute has no effect
has 'ExpiresAbsolute' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

# This attribute has no effect
has 'FormFill' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=item $Response->{IsClientConnected}

1 if web client is connected, C<0> if not. This value starts set to 1, and will
be updated whenever a C<< $Response->Flush() >> is called.

As of Apache::ASP version 2.23 this value is updated correctly before
F<global.asa> C<Script_OnStart> is called, so global script termination may be
correctly handled during that event, which one might want to do with excessive
user STOP/RELOADS when the web server is very busy.

An API extension C<< $Response->IsClientConnected >> may be called for refreshed
connection status without calling first a C<< $Response->Flush >>

=cut

# This attribute has no effect
has 'IsClientConnected' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

# This attribute has no effect
has 'PICS' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=item $Response->{Status}

Sets the status code returned by the server. Can be used to set messages like
500, internal server error

=cut

has 'Status' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub BUILD {
    my ( $self ) = @_;

    no warnings 'redefine';
    *TIEHANDLE = sub {$self};
    $self->{out} = $self->{BinaryRef} = \( $self->{Body} );

    # Don't initiate below attributes unless past setup phase
    return unless $self->asp->_setup_finished;

    # Due to problem mentioned above in the builder methods, we are calling
    # these attributes to populate the values for the hash key to be available
    $self->Cookies;
}

=back

=head1 METHODS

=over

=item $Response->AddHeader($name, $value)

Adds a custom header to a web page. Headers are sent only before any text from
the main page is sent.

=cut

sub AddHeader {
    my ( $self, $name, $value ) = @_;
    $self->asp->c->response->header( $name => $value );
}

sub PRINT { my $self = shift; $self->Write( $_ ) for @_ }

sub PRINTF {
    my ( $self, $format, @list ) = @_;
    $self->Write( sprintf( $format, @list ) );
}

=item $Response->AppendToLog($message)

Adds $message to the server log. Useful for debugging.

=cut

sub AppendToLog {
    my ( $self, $message ) = @_;
    $self->asp->c->log->debug( $message );
}

=item $Response->BinaryWrite($data)

Writes binary data to the client. The only difference from
C<< $Response->Write() >> is that C<< $Response->Flush() >> is called internally
first, so the data cannot be parsed as an html header. Flushing flushes the
header if has not already been written.

If you have set the C<< $Response->{ContentType} >> to something other than
C<text/html>, cgi header parsing (see CGI notes), will be automatically be
turned off, so you will not necessarily need to use C<BinaryWrite> for writing
binary data.

=cut

*BinaryWrite = *Write;

sub WriteRef {
    my ( $self, $dataref ) = @_;
    $self->Write( $$dataref );
}

=item $Response->Clear()

Erases buffered ASP output.

=cut

sub Clear {
    my ( $self ) = @_;
    $self->Body && $self->Body( $self->BodySubstr( 0, $self->_flushed_offset ) );
    $self->{out} = $self->{BinaryRef} = \( $self->{Body} );
    return;
}

=item $Response->Cookies($name, [$key,] $value)

Sets the key or attribute of cookie with name C<$name> to the value C<$value>.
If C<$key> is not defined, the Value of the cookie is set. ASP CookiePath is
assumed to be / in these examples.

  $Response->Cookies('name', 'value');
  # Set-Cookie: name=value; path=/

  $Response->Cookies("Test", "data1", "test value");
  $Response->Cookies("Test", "data2", "more test");
  $Response->Cookies(
    "Test", "Expires",
    HTTP::Date::time2str(time+86400)
  );
  $Response->Cookies("Test", "Secure", 1);
  $Response->Cookies("Test", "Path", "/");
  $Response->Cookies("Test", "Domain", "host.com");
  # Set-Cookie:Test=data1=test%20value&data2=more%20test; \
  #   expires=Fri, 23 Apr 1999 07:19:52 GMT;              \
  #   path=/; domain=host.com; secure

The latter use of C<$key> in the cookies not only sets cookie attributes such as
Expires, but also treats the cookie as a hash of key value pairs which can later
be accesses by

  $Request->Cookies('Test', 'data1');
  $Request->Cookies('Test', 'data2');

Because this is perl, you can (though it's not portable!) reference the cookies
directly through hash notation. The same 5 commands above could be compressed
to:

  $Response->{Cookies}{Test} = {
    Secure  => 1,
    Value   => {
      data1 => 'test value',
      data2 => 'more test'
    },
    Expires => 86400, # not portable, see above
    Domain  => 'host.com',
    Path    => '/'
  };

and the first command would be:

  # you don't need to use hash notation when you are only setting
  # a simple value
  $Response->{Cookies}{'Test Name'} = 'Test Value';

I prefer the hash notation for cookies, as this looks nice, and is quite
perl-ish. It is here to stay. The C<Cookie()> routine is very complex and does
its best to allow access to the underlying hash structure of the data. This is
the best emulation I could write trying to match the Collections functionality
of cookies in IIS ASP.

For more information on Cookies, please go to the source at
http://home.netscape.com/newsref/std/cookie_spec.html

=cut

sub Cookies {
    my ( $self, $name, @cookie ) = @_;

    if ( @cookie == 0 ) {
        return $self->_get_Cookies;
    } elsif ( @cookie == 1 ) {
        my $value = $cookie[0];
        $self->_set_Cookie( $name => { Value => $value } );
        return $value;
    } else {
        my ( $key, $value ) = @cookie;
        if ( $key =~ m/secure|value|expires|domain|path|httponly/i ) {
            if ( my $existing = $self->_get_Cookie( $name ) ) {
                return $existing->{$key} = $value;
            } else {
                $self->_set_Cookie( $name => { $key => $value } );
                return $value;
            }
        } else {
            if ( my $existing = $self->_get_Cookie( $name ) ) {
                return $existing->{Value}{$key} = $value;
            } else {
                $self->_set_Cookie( $name => { Value => { $key => $value } } );
                return $value;
            }
        }
    }
}

=item $Response->Debug(@args)

API Extension. If the Debug config option is set greater than C<0>, this routine
will write C<@args> out to server error log. Refs in C<@args> will be expanded
one level deep, so data in simple data structures like one-level hash refs and
array refs will be displayed. CODE refs like

  $Response->Debug(sub { "some value" });

will be executed and their output added to the debug output. This extension
allows the user to tie directly into the debugging capabilities of this module.

While developing an app on a production server, it is often useful to have a
separate error log for the application to catch debugging output separately.

If you want further debugging support, like stack traces in your code, consider
doing things like:

  $Response->Debug( sub { Carp::longmess('debug trace') };
  $SIG{__WARN__} = \&Carp::cluck; # then warn() will stack trace

The only way at present to see exactly where in your script an error occurred is
to set the Debug config directive to 2, and match the error line number to perl
script generated from your ASP script.

However, as of version C<0.10>, the perl script generated from the asp script
should match almost exactly line by line, except in cases of inlined includes,
which add to the text of the original script, pod comments which are entirely
yanked out, and C<< <% # comment %> >> style comments which have a C<\n> added
to them so they still work.

=cut

sub Debug {
    my ( $self, @args ) = @_;
    local $Data::Dumper::Maxdepth = 1;
    $self->AppendToLog( Dumper( \@args ) );
}

=item $Response->End()

Sends result to client, and immediately exits script. Automatically called at
end of script, if not already called.

=cut

sub End {
    shift->Clear;
    CatalystX::ASP::Exception::End->throw;
}

# TODO to implement or not to implement?
sub ErrorDocument {
    my ( $self, $code, $uri ) = @_;
    $self->asp->c->log->warn( "\$Reponse->ErrorDocument has not been implemented!" );
    return;
}

=item $Response->Flush()

Sends buffered output to client and clears buffer.

=cut

sub Flush {
    my ( $self ) = @_;
    $self->asp->GlobalASA->Script_OnFlush;
    $self->_flushed_offset( $self->BodyLength );
}

=item $Response->Include($filename, @args)

This API extension calls the routine compiled from asp script in C<$filename>
with the args @args.  This is a direct translation of the SSI tag

  <!--#include file=$filename args=@args-->

Please see the SSI section for more on SSI in general.

This API extension was created to allow greater modularization of code by
allowing includes to be called with runtime arguments.  Files included are
compiled once, and the anonymous code ref from that compilation is cached, thus
including a file in this manner is just like calling a perl subroutine. The
C<@args> can be found in C<@_> in the includes like:

  # include.inc
  <% my @args = @_; %>

As of C<2.23>, multiple return values can be returned from an include like:

  my @rv = $Response->Include($filename, @args);

=item $Response->Include(\$script_text, @args)

Added in Apache::ASP C<2.11>, this method allows for executing ASP scripts that
are generated dynamically by passing in a reference to the script data instead
of the file name. This works just like the normal C<< $Response->Include() >>
API, except a string reference is passed in instead of a filename. For example:

  <%
    my $script = "<\% print 'TEST'; %\>";
    $Response->Include(\$script);
  %>

This include would output C<TEST>. Note that tokens like C<< <% >> and C<< %> >>
must be escaped so Apache::ASP does not try to compile those code blocks
directly when compiling the original script. If the C<$script> data were fetched
directly from some external resource like a database, then these tokens would
not need to be escaped at all as in:

  <%
    my $script = $dbh->selectrow_array(
       "select script_text from scripts where script_id = ?",
       undef, $script_id
       );
    $Response->Include(\$script);
  %>

This method could also be used to render other types of dynamic scripts, like
XML docs using XMLSubs for example, though for complex runtime XML rendering,
one should use something better suited like XSLT.

=cut

sub Include {
    my ( $self, $include, @args ) = @_;
    my $asp = $self->asp;
    my $c   = $asp->c;

    my $compiled;
    if ( ref( $include ) && ref( $include ) eq 'SCALAR' ) {
        my $scriptref = $include;
        my $parsed_object = $asp->parse( $c, $scriptref );
        $compiled = {
            mtime => time(),
            perl  => $parsed_object->{data},
        };
        my $caller = [ caller( 1 ) ]->[3] || 'main';
        my $id = join( '', '__ASP_', $caller, 'x', $asp->_compile_checksum );
        my $subid = join( '', $asp->GlobalASA->package, '::', $id, 'xREF' );
        if ( $parsed_object->{is_perl}
            && ( my $code = $asp->compile( $c, $parsed_object->{data}, $subid ) ) ) {
            $compiled->{is_perl} = 1;
            $compiled->{code}    = $code;
        } else {
            $compiled->{is_raw} = 1;
            $compiled->{code}   = $parsed_object->{data};
        }
    } else {
        $compiled = $asp->compile_include( $c, $include );
        return unless $compiled;
    }

    my $code = $compiled->{code};

    # exit early for cached static file
    if ( $compiled->{is_raw} ) {
        $self->WriteRef( $code );
        return;
    }

    $asp->execute( $c, $code, @args );
}

=item $Response->IsClientConnected()

API Extension. C<1> for web client still connected, C<0> if disconnected which
might happen if the user hits the stop button. The original API for this
C<< $Response->{IsClientConnected} >> is only updated after a
C<< $Response->Flush >> is called, so this method may be called for a refreshed
status.

Note C<< $Response->Flush >> calls C<< $Response->IsClientConnected >> to
update C<< $Response->{IsClientConnected} >> so to use this you are going
straight to the source! But if you are doing a loop like:

  while(@data) {
    $Response->End if ! $Response->{IsClientConnected};
    my $row = shift @data;
    %> <%= $row %> <%
    $Response->Flush;
  }

Then its more efficient to use the member instead of the method since
C<< $Response->Flush() >> has already updated that value for you.

=item $Response->Redirect($url)

Sends the client a command to go to a different url C<$url>. Script immediately
ends.

=cut

sub Redirect {
    my ( $self, $url ) = @_;
    my $c = $self->asp->c;

    $self->_flush_Cookies( $c );
    $self->Status( 302 );
    $c->response->redirect( $url );
    $c->detach;
}

=item $Response->TrapInclude($file, @args)

Calls $Response->Include() with same arguments as passed to it, but instead
traps the include output buffer and returns it as as a perl string reference.
This allows one to postprocess the output buffer before sending to the client.

  my $string_ref = $Response->TrapInclude('file.inc');
  $$string_ref =~ s/\s+/ /sg; # squash whitespace like Clean 1
  print $$string_ref;

The data is returned as a referenece to save on what might be a large string
copy. You may dereference the data with the $$string_ref notation.

=cut

sub TrapInclude {
    my ( $self, $include, @args ) = @_;

    my $saved = $self->Body;
    $self->Clear;

    no warnings 'redefine';
    local *CatalystX::ASP::Response::Flush = sub { };
    local $self->{out} = local $self->{BinaryRef} = \( $self->{Body} );

    $self->Include( $include, @args );
    my $trapped = $self->Body;

    $self->Body( $saved );

    return \$trapped;
}

=item $Response->Write($data)

Write output to the HTML page. C<< <%=$data%> >> syntax is shorthand for a
C<< $Response->Write($data) >>. All final output to the client must at some
point go through this method.

=cut

sub _flush_Cookies {
    my ( $self, $c ) = @_;
    my $cookies = $self->_get_Cookies;
    for my $name ( keys %$cookies ) {
        my $cookie = $cookies->{$name};
        if ( ref $cookie eq 'HASH' ) {
            for my $key ( keys %$cookie ) {

                # This is really to support Apache::ASP's support hashes in cookies
                if ( $key =~ m/value/i && ref( $cookie->{$key} ) eq 'HASH' ) {
                    $c->response->cookies->{$name}{value} =
                        [ map { "$_=" . $cookie->{$key}{$_} } keys %{ $cookie->{$key} } ];
                } else {

                    # Thankfully, don't need to make 'value' an arrayref for CGI::Simple::Cookie
                    $c->response->cookies->{$name}{ lc( $key ) } = $cookie->{$key};
                }
            }
        } else {
            $c->response->cookies->{$name}{value} = $cookie;
        }
    }
}

__PACKAGE__->meta->make_immutable;

=back

=head1 SEE ALSO

=over

=item * L<CatalystX::ASP::Session>

=item * L<CatalystX::ASP::Request>

=item * L<CatalystX::ASP::Application>

=item * L<CatalystX::ASP::Server>

=back
