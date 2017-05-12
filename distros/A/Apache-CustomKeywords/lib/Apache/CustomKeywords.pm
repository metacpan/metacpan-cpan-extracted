package Apache::CustomKeywords;

use strict;
use vars qw($VERSION);
$VERSION = 0.03;

use Apache::Constants qw(:response);
use Apache::ModuleConfig;
use Apache::Util;
use vars qw($MSN_URL $MSN_KEY @ISA);
@ISA = qw(DynaLoader);

$MSN_URL = 'http://auto.search.msn.com/response.asp';
$MSN_KEY = 'MT';

__PACKAGE__->bootstrap($VERSION) if $ENV{MOD_PERL};

sub handler($$) {
    my($class, $r) = @_;
    if ($r->proxyreq) {
	my $uri = $r->uri;
	if ($uri =~ /^$MSN_URL/) {
	    my $location = $class->convert_query($r);
	    if (defined $location) {
		$r->header_out(Location => $location);
		return REDIRECT;
	    }
	}
	$r->filename("proxy:$uri");
	$r->handler('proxy-server');
	return OK;
    } else {
	my $location = $class->convert_query($r);
	if (defined $location) {
	    $r->header_out(Location => $location);
	    return REDIRECT;
	}
	$r->send_http_header('text/html');
	$r->print(__PACKAGE__ . ": Can't parse tokens.");
	return OK;
    }
}

sub convert_query {
    my($class, $r) = @_;
    my $cfg = Apache::ModuleConfig->get($r) || {};
    my $keyword = $cfg->{CustomKeywords} or return;
    my $query = $class->query($r);
    $query =~ s/^(\S+)\s*// or return;
    if (my $engine = $keyword->{$1}) {
	return $class->interpolate($engine, $query);
	return $engine;
    }
    elsif (my $default = $cfg->{CustomKeywordsDefault}) {
	return $class->interpolate($keyword->{$default}, join(' ', $1, $query));
    }
}

sub interpolate {
    my($class, $engine, $query) = @_;
    $engine =~ s/%s/$class->escape_it($query)/eg;
    return $engine;
}

sub escape_it {
    my($class, $query) = @_;
    $query =~ s/ /+/g;
    return Apache::Util::escape_uri($query);
}

sub query {
    my($class, $r) = @_;
    my %args = $r->args;
    return $args{$MSN_KEY};
}

sub CustomKeyword($$$$) {
    my($cfg, $parms, $arg1, $arg2) = @_;
    $cfg->{CustomKeywordsDefault} ||= $arg1;
    $cfg->{CustomKeywords} ||= {};
    $cfg->{CustomKeywords}->{$arg1} = $arg2;
}

1;
__END__

=head1 NAME

Apache::CustomKeywords - Customizable toolbar for MSIE

=head1 SYNOPSIS

  # 1. As an Apache proxy
  Listen 8888
  <VirtualHost *:8888>
  PerlTransHandler +Apache::CustomKeywords
  CustomKeyword cpan http://search.cpan.org/search?mode=module&query=%s
  CustomKeyword perldoc http://perldoc.com/cgi-bin/htsearch?words=%s&restrict=perl5.8.0
  CustomKeyword google http://www.google.com/search?q=%s
  </VirtualHost>

  # 2. As a pseudo-MSN
  <Location /response.asp>
  SetHandler perl-script
  PerlHandler +Apache::CustomKeywords
  CustomKeyword cpan http://search.cpan.org/search?mode=module&query=%s
  # ...
  </Location>

=head1 DESCRIPTION

Apache::CustomKeywords is a customizable proxy/webapp to change your
MSIE's Location box to your favourite toolbar!

See http://www.mozilla.org/docs/end-user/keywords.html for what Custom
Keywords means in Mozilla. This module enables Custom Keywords in MSIE.

With C<CustomKeyword> settings shown in L</"SYNOPSIS">, you type
C<cpan CustomKeywords> or C<google blah blah> in your browser's
Location: box, then you will be redirected to the page you wanna go
to!

If your command is not recognized by this module, the first
C<CustomKeyword> entry is used as default.

Here's the way this handler works:

=over 4

=item *

Type "foo bar" in Location: box

=item *

MSIE sends request to C<auto.search.msn.com>

=item *

Apache::CustomKeywords detects it and redirects browser to your
favourite search engine.

=back

=head1 CONFIGURATION

There're two ways to let your browser use this module:

=over 4

=item As a proxy server

configure C<httpd.conf> with a proxy version and set up your browser's
proxy setting.

=item As a pseudo MSN

configure C<httpd.conf> with psuedo MSN version and set up your Hosts
file (C</etc/hosts> in Un*x, C<Windows/Hosts> or
C<windows/system/drivers/etc/Hosts> in Win32) or local DNS so that
C<auto.search.msn.com> points to the server where this module is
installed.

=back

=head1 NOTE

If you put C<:> or C<@> as a query in Location: box, MSIE recognizes
it as protocol or authentication password stuff, hence this module
might not work.

=head1 TODO

=over 4

=item *

User-definable conversion of query paramers, including encoding
conversions. Currenty only C<%s> interpolates to URI-Escaped string
encoded in UTF8.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<mod_perl>, http://www.mozilla.org/docs/end-user/keywords.html

=cut
