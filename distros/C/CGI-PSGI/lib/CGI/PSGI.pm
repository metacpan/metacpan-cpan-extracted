package CGI::PSGI;

use strict;
use 5.008_001;
our $VERSION = '0.15';

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

# copied from CGI.pm
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

# copied and rearanged from CGI::header
sub psgi_header {
    my($self, @p) = @_;

    my(@header);

    my($type,$status,$cookie,$target,$expires,$nph,$charset,$attachment,$p3p,@other) =
        CGI::rearrange([['TYPE','CONTENT_TYPE','CONTENT-TYPE'],
                        'STATUS',['COOKIE','COOKIES'],'TARGET',
                        'EXPIRES','NPH','CHARSET',
                        'ATTACHMENT','P3P'],@p);

    # CR escaping for values, per RFC 822
    for my $header ($type,$status,$cookie,$target,$expires,$nph,$charset,$attachment,$p3p,@other) {
        if (defined $header) {
            # From RFC 822:
            # Unfolding  is  accomplished  by regarding   CRLF   immediately
            # followed  by  a  LWSP-char  as equivalent to the LWSP-char.
            $header =~ s/$CGI::CRLF(\s)/$1/g;

            # All other uses of newlines are invalid input. 
            if ($header =~ m/$CGI::CRLF|\015|\012/) {
                # shorten very long values in the diagnostic
                $header = substr($header,0,72).'...' if (length $header > 72);
                die "Invalid header value contains a newline not followed by whitespace: $header";
            }
        }
   }

    $type ||= 'text/html' unless defined($type);
    if (defined $charset) {
        $self->charset($charset);
    } else {
        $charset = $self->charset if $type =~ /^text\//;
    }
    $charset ||= '';

    # rearrange() was designed for the HTML portion, so we
    # need to fix it up a little.
    my @other_headers;
    for (@other) {
        # Don't use \s because of perl bug 21951
        next unless my($header,$value) = /([^ \r\n\t=]+)=\"?(.+?)\"?$/;
        $header =~ s/^(\w)(.*)/"\u$1\L$2"/e;
        push @other_headers, $header, $self->unescapeHTML($value);
    }

    $type .= "; charset=$charset"
        if     $type ne ''
           and $type !~ /\bcharset\b/
           and defined $charset
           and $charset ne '';

    # Maybe future compatibility.  Maybe not.
    my $protocol = $self->{psgi_env}{SERVER_PROTOCOL} || 'HTTP/1.0';

    push(@header, "Window-Target", $target) if $target;
    if ($p3p) {
        $p3p = join ' ',@$p3p if ref($p3p) eq 'ARRAY';
        push(@header,"P3P", qq(policyref="/w3c/p3p.xml", CP="$p3p"));
    }

    # push all the cookies -- there may be several
    if ($cookie) {
        my(@cookie) = ref($cookie) && ref($cookie) eq 'ARRAY' ? @{$cookie} : $cookie;
        for (@cookie) {
            my $cs = UNIVERSAL::isa($_,'CGI::Cookie') ? $_->as_string : $_;
            push(@header,"Set-Cookie", $cs) if $cs ne '';
        }
    }
    # if the user indicates an expiration time, then we need
    # both an Expires and a Date header (so that the browser is
    # uses OUR clock)
    push(@header,"Expires", CGI::expires($expires,'http'))
        if $expires;
    push(@header,"Date", CGI::expires(0,'http')) if $expires || $cookie || $nph;
    push(@header,"Pragma", "no-cache") if $self->cache();
    push(@header,"Content-Disposition", "attachment; filename=\"$attachment\"") if $attachment;
    push(@header, @other_headers);

    push(@header,"Content-Type", $type) if $type ne '';

    $status ||= "200";
    $status =~ s/\D*$//;

    return $status, \@header;
}

# Ported from CGI.pm's redirect() method. 
sub psgi_redirect {
    my ($self,@p) = @_;
    my($url,$target,$status,$cookie,$nph,@other) = 
         CGI::rearrange([['LOCATION','URI','URL'],'TARGET','STATUS',['COOKIE','COOKIES'],'NPH'],@p);
    $status = '302 Found' unless defined $status;
    $url ||= $self->self_url;
    my(@o);
    for (@other) { tr/\"//d; push(@o,split("=",$_,2)); }
    unshift(@o,
	 '-Status'  => $status,
	 '-Location'=> $url,
	 '-nph'     => $nph);
    unshift(@o,'-Target'=>$target) if $target;
    unshift(@o,'-Type'=>'');
    my @unescaped;
    unshift(@unescaped,'-Cookie'=>$cookie) if $cookie;
    return $self->psgi_header((map {$self->unescapeHTML($_)} @o),@unescaped);
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
    referrer
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
)) {
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
