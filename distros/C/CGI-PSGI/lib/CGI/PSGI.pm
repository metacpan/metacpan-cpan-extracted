package CGI::PSGI;

use strict;
use 5.008_001;
our $VERSION = '0.16';

use base qw(CGI);

sub new {
    my($class, $env) = @_;
    CGI::initialize_globals();

    my $self = bless {
        psgi_env     => $env,
        use_tempfile => 1,
    }, $class;

    local *ENV = $env;
    local $CGI::MOD_PERL = 0;
    # never fall back to CGI.pm's offline debugging mode, which reads the
    # params from the process' own @ARGV: older CGI.pm does that for any
    # unrecognised REQUEST_METHOD, e.g. OPTIONS (CVE-2026-120637), and all
    # versions do it for an env without one
    local $CGI::DEBUG = 0;
    $self->SUPER::init;

    $self;
}

sub env {
    $_[0]->{psgi_env};
}

sub read_from_client {
    my($self, $buff, $len, $offset) = @_;
    $self->{psgi_env}{'psgi.input'}->read($$buff, $len, $offset);
}

# copied from CGI.pm. Deprecated: no CGI.pm since (at least) 4.04 calls it,
# and it will be removed in a future release.
sub read_from_stdin {
    my($self, $buff) = @_;

    my($eoffound) = 0;
    my($localbuf) = '';
    my($tempbuf) = '';
    my($bufsiz) = 1024;
    my($res);

    while ($eoffound == 0) {
        $res = $self->{psgi_env}{'psgi.input'}->read($tempbuf, $bufsiz, 0);

        if ( !defined($res) ) {
            # TODO: how to do error reporting ?
            $eoffound = 1;
            last;
        }
        if ( $res == 0 ) {
            $eoffound = 1;
            last;
        }
        $localbuf .= $tempbuf;
    }

    $$buff = $localbuf;

    return $res;
}

# Like CGI::Util::_rearrange_params (private to CGI.pm, so not used
# directly): maps -named or positional arguments onto the slots in $order
# and returns the slots, plus a hash ref of the leftover named arguments.
sub _rearrange_params {
    my($order, @param) = @_;
    return [] unless @param;

    if (ref($param[0]) eq 'HASH') {
        @param = %{$param[0]};
    } else {
        return \@param
            unless defined($param[0]) && substr($param[0],0,1) eq '-';
    }

    my(%pos, $i);
    $i = 0;
    for my $slot (@$order) {
        $pos{lc $_} = $i for ref($slot) eq 'ARRAY' ? @$slot : $slot;
        $i++;
    }

    my %params = @param;
    my(@result, %leftover);
    $#result = $#$order;

    # favour CONTENT-TYPE over TYPE etc. when both are given, as CGI.pm does
    # (same comparator as CGI.pm, for compatibility)
    for my $k (sort { $a =~ /content/i ? 1 : $b =~ /content/i ? -1 : $a cmp $b } keys %params) {
        (my $key = lc $k) =~ s/^-//;
        if (exists $pos{$key}) {
            $result[$pos{$key}] = $params{$k};
        } else {
            $leftover{$key} = $params{$k};
        }
    }

    return \@result, \%leftover;
}

# Unfold CRLF + whitespace (RFC 822) in place, and die on any other newline.
sub _check_header_values {
    for my $header (@_) {
        next unless defined $header;
        $header =~ s/$CGI::CRLF(\s)/$1/g;
        if ($header =~ m/$CGI::CRLF|\015|\012/) {
            # shorten very long values in the diagnostic
            $header = substr($header,0,72).'...' if length $header > 72;
            die "Invalid header value contains a newline not followed by whitespace: $header";
        }
    }
}

# Ported from CGI::header. Values are used as given: like CGI.pm 5.02 they are
# no longer HTML unescaped, which decoded entities such as &#13;&#10; after
# the newline check (CVE-2026-120639).
sub psgi_header {
    my($self, @p) = @_;

    my(@header);

    my $order = [['TYPE','CONTENT_TYPE','CONTENT-TYPE'],
                 'STATUS',['COOKIE','COOKIES','SET-COOKIE'],'TARGET',
                 'EXPIRES','NPH','CHARSET',
                 'ATTACHMENT','P3P'];
    my($result, $leftover) = _rearrange_params($order, @p);
    my($type,$status,$cookie,$target,$expires,$nph,$charset,$attachment,$p3p) =
        @{$result}[0 .. $#$order];

    # extra headers: positional ones given as name=value, and leftover named
    # ones, where -x_foo => 'bar' becomes X-foo: bar
    my @other_headers;
    for my $line (@{$result}[@$order .. $#$result]) {
        next unless defined $line;
        # Don't use \s because of perl bug 21951
        next unless my($name, $value) = $line =~ /([^ \r\n\t=]+)=\"?(.+?)\"?$/s;
        push @other_headers, ucfirst(lc $name), $value;
    }
    for my $name (sort keys %{ $leftover || {} }) {
        next unless defined $leftover->{$name};
        (my $header = lc $name) =~ tr/_/-/;
        push @other_headers, ucfirst($header), "$leftover->{$name}";
    }

    # Since $cookie and $p3p may be array references, stringify them
    # before the newline checks.
    my @cookie;
    for (ref($cookie) eq 'ARRAY' ? @$cookie : $cookie) {
        my $cs = UNIVERSAL::isa($_,'CGI::Cookie') ? $_->as_string : $_;
        push @cookie, $cs if defined $cs and $cs ne '';
    }
    $p3p = join(" ", @$p3p) if ref($p3p) eq "ARRAY";

    # header names and values, per RFC 822
    _check_header_values($type,$status,@cookie,$target,$expires,$nph,$charset,$attachment,$p3p,@other_headers);

    $type ||= 'text/html' unless defined($type);
    if (defined $charset) {
        $self->charset($charset);
    } else {
        $charset = $self->charset if $type =~ /^text\//;
    }
    $charset ||= '';

    $type .= "; charset=$charset"
        if     $type ne ''
           and $type !~ /\bcharset\b/
           and defined $charset
           and $charset ne '';

    push(@header, "Window-Target", $target) if $target;
    push(@header, "P3P", qq(policyref="/w3c/p3p.xml", CP="$p3p")) if $p3p;

    # push all the cookies -- there may be several
    push(@header, map { ("Set-Cookie", $_) } @cookie);

    # if the user indicates an expiration time, then we need
    # both an Expires and a Date header (so that the browser is
    # uses OUR clock)
    push(@header,"Expires", CGI::expires($expires,'http'))
        if $expires;
    push(@header,"Date", CGI::expires(0,'http')) if $expires || $cookie || $nph;
    push(@header,"Pragma", "no-cache") if $self->cache();
    if ($attachment) {
        # the filename is a quoted-string (RFC 9110 5.6.4), so a " or \ in
        # it must be escaped, or it could inject other parameters
        # (CVE-2026-120647)
        (my $filename = $attachment) =~ s/(["\\])/\\$1/g;
        push(@header,"Content-Disposition", "attachment; filename=\"$filename\"");
    }
    push(@header, @other_headers);

    push(@header,"Content-Type", $type) if $type ne '';

    $status ||= "200";
    $status =~ s/\D*$//;

    return $status, \@header;
}

# Ported from CGI.pm's redirect() method. Like CGI.pm 5.02, values are passed
# on as given: HTML unescaping them decoded entities in a (possibly app
# validated) Location, e.g. "/&#47evil.example/" became "//evil.example/"
# (CVE-2026-120638).
sub psgi_redirect {
    my ($self,@p) = @_;
    my $order = [['LOCATION','URI','URL'],'TARGET','STATUS',['COOKIE','COOKIES','SET-COOKIE'],'NPH'];
    my($result, $leftover) = _rearrange_params($order, @p);
    my($url,$target,$status,$cookie,$nph,@other) = @$result;
    $status = '302 Found' unless defined $status;
    $url ||= $self->self_url;
    my(@o);
    # extra positional parameters, given as name=value
    for (@other) { next unless defined; tr/\"//d; push(@o,split("=",$_,2)); }
    # extra named parameters
    push(@o, map { ("-$_" => $leftover->{$_}) } sort keys %{ $leftover || {} });
    unshift(@o,
	 '-Status'  => $status,
	 '-Location'=> $url,
	 '-nph'     => $nph);
    unshift(@o,'-Target'=>$target) if $target;
    unshift(@o,'-Type'=>'');
    unshift(@o,'-Cookie'=>$cookie) if $cookie;
    return $self->psgi_header(@o);
}

# The list is auto generated and modified with:
# perl -nle '/^sub (\w+)/ and $sub=$1; \
#   /^}\s*$/ and do { print $sub if $code{$sub} =~ /([\%\$]ENV|http\()/; undef $sub };\
#   $code{$sub} .= "$_\n" if $sub; \
#   /^\s*package [^C]/ and exit' \
# `perldoc -l CGI`
for my $method (qw(
    url_param
    url
    cookie
    raw_cookie
    _name_and_path_from_env
    request_method
    content_type
    path_translated
    request_uri
    Accept
    user_agent
    virtual_host
    remote_host
    remote_addr
    referer
    server_name
    server_software
    virtual_port
    server_port
    server_protocol
    http
    https
    remote_ident
    auth_type
    remote_user
    user_name
    read_multipart
    read_multipart_related
    env_query_string
)) {
    # skip methods the installed CGI.pm doesn't have (env_query_string
    # is new in CGI.pm 4.x)
    next unless CGI->can($method);
    no strict 'refs';
    *$method = sub {
        my $self  = shift;
        my $super = "SUPER::$method";
        local *ENV = $self->{psgi_env};
        $self->$super(@_);
    };
}

sub DESTROY {
    my $self = shift;
    CGI::initialize_globals();
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

CGI::PSGI - Adapt CGI.pm to the PSGI protocol

=head1 SYNOPSIS

=for test_synopsis my $body;

  use CGI::PSGI;

  my $app = sub {
      my $env = shift;
      my $q = CGI::PSGI->new($env);
      return [ $q->psgi_header, [ $body ] ];
  };

=head1 DESCRIPTION

This module is for web application framework developers who currently uses
L<CGI> to handle query parameters, and would like for the frameworks to comply
with the L<PSGI> protocol.

Only slight modifications should be required if the framework is already
collecting the body content to print to STDOUT at one place (rather using
the print-as-you-go approach).

On the other hand, if you are an "end user" of CGI.pm and have a CGI script
that you want to run under PSGI web servers, this module might not be what you
want.  Take a look at L<CGI::Emulate::PSGI> instead.

Your application, typically the web application framework adapter
should update the code to do C<< CGI::PSGI->new($env) >> instead of
C<< CGI->new >> to create a new CGI object. (This is similar to how
L<CGI::Fast> object is initialized in a FastCGI environment.)

=head1 INTERFACES SUPPORTED

Only the object-oriented interface of CGI.pm is supported through CGI::PSGI.
This means you should always create an object with C<< CGI::PSGI->new($env) >>
and should call methods on the object.

The function-based interface like C<< use CGI ':standard' >> does not work with this module.

=head1 METHODS

CGI::PSGI adds the following extra methods to CGI.pm:

=head2 env

  $env = $cgi->env;

Returns the PSGI environment in a hash reference. This allows CGI.pm-based
application frameworks such as L<CGI::Application> to access PSGI extensions,
typically set by Plack Middleware components.

So if you enable L<Plack::Middleware::Session>, your application and
plugin developers can access the session via:

  $cgi->env->{'plack.session'}->get("foo");

Of course this should be coded carefully by checking the existence of
C<env> method as well as the hash key C<plack.session>.

=head2 psgi_header

 my ($status_code, $headers_aref) = $cgi->psgi_header(%args);

Works like CGI.pm's L<header()>, but the return format is modified. It returns
an array with the status code and arrayref of header pairs that PSGI
requires.

If your application doesn't use C<< $cgi->header >>, you can ignore this
method and generate the status code and headers arrayref another way.

=head2 psgi_redirect

 my ($status_code, $headers_aref) = $cgi->psgi_redirect(%args); 

Works like CGI.pm's L<redirect()>, but the return format is modified. It
returns an array with the status code and arrayref of header pairs that PSGI
requires.

If your application doesn't use C<< $cgi->redirect >>, you can ignore this
method and generate the status code and headers arrayref another way.

=head2 Header and redirect values

As in CGI.pm 5.02, C<psgi_header> and C<psgi_redirect> use header values and
the redirect URL exactly as given: they are no longer HTML unescaped. Pass
e.g. C</x?a=1&b=2>, not C</x?a=1&amp;b=2>. A newline in a header name or
value (including each cookie and P3P value in an array reference) makes them
die (a CRLF followed by whitespace is unfolded instead, as in CGI.pm), and
quotes and backslashes in the C<-attachment> filename are escaped.

=head2 Request limits and CGI.pm 5.02

CGI::PSGI reads the request body from C<psgi.input> through CGI.pm, so CGI.pm's
request handling applies to PSGI apps too. With CGI.pm 5.02 or later that
includes:

=over 4

=item *

C<$CGI::POST_MAX> defaults to 128MB, and there are new C<$CGI::MAX_PARAMS>
(10,000) and C<$CGI::MAX_UPLOADS> (1,000) limits. A request over a limit gets
a C<413 Request entity too large> C<cgi_error>, so check
C<< $q->cgi_error >> and set the response status yourself. Set a limit to
-1 for no limit.

=item *

C<X-Forwarded-Host> is ignored by C<url>, C<self_url> and the default
C<psgi_redirect> location, unless C<$CGI::TRUST_X_FORWARDED_HOST> is set.
Behind a reverse proxy, consider L<Plack::Middleware::ReverseProxy>.

=item *

Upload filenames have any directory part and control characters removed,
unless C<$CGI::SANITIZE_UPLOAD_FILENAMES> is 0.

=item *

Client sent parameters named C<POSTDATA>, C<PUTDATA>, C<PATCHDATA> or
C<XForms:Model> are ignored.

=back

These are process-wide globals. In a persistent PSGI server, set them once
at startup, or with C<local> around C<< CGI::PSGI->new >> for one request.

=head1 LIMITATIONS

Do not use L<CGI::Pretty> or something similar in your controller. The
module messes up L<CGI>'s DIY autoloader and breaks CGI::PSGI (and
potentially other) inheritance.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Mark Stosberg E<lt>mark@summersault.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI>, L<CGI::Emulate::PSGI>

=cut
