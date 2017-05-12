package Apache::No404Proxy::Google;

use strict;
use vars qw($VERSION);
$VERSION = 0.05;

require Apache::No404Proxy;
use base qw(Apache::No404Proxy);

use SOAP::Lite;

sub fetch {
    my($class, $r) = @_;
    my $key = $r->dir_config('GoogleLicenseKey') or die "You need GoogleLicenseKey to use this module";
    return SOAP::Lite
	->uri('urn:GoogleSearch')
	    ->proxy('http://api.google.com/search/beta2')
		->doGetCachedPage($key, $r->uri)
		    ->result;
}

1;
__END__

=head1 NAME

Apache::No404Proxy::Google - Implementation of Apache::No404Proxy

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::No404Proxy::Google
  PerlSetVar GoogleLicenseKey **************

=head1 DESCRIPTION

Apache::No404Proxy::Google is one of the implementations of
Apache::No404Proxy. This module uses SOAP::Lite to fetch Google cache.

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::No404Proxy>, L<SOAP::Lite>, L<WWW::Cache::Google>

=cut
