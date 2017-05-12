package TestApReqI18N::dump;

use strict;
use warnings FATAL => 'all';

use Apache::Constants 'OK';
use Apache::Request::I18N;
use Data::Dumper;

sub handler {
	my $r = shift;

	$r = Apache::Request::I18N->instance($r);

	$r->send_http_header('text/plain');

	my %vars = map +($_, [ $r->param($_) ]), $r->param;
	my @uploads = map [$_->name, $_->filename, $_->size], $r->upload;

	print Data::Dumper->Dump([\%vars, \@uploads], [qw(*vars *uploads)]);

	OK;
}

1;

__DATA__

<Location /TestApReqI18N__dump>
PerlSetVar DecodeParms ascii
</Location>

<Location /TestApReqI18N__dump/latin1>
PerlSetVar DecodeParms ISO-8859-1
</Location>

<Location /TestApReqI18N__dump/utf7>
PerlSetVar DecodeParms UTF-7
</Location>

<Location /TestApReqI18N__dump/utf8>
PerlSetVar DecodeParms UTF-8
</Location>

<LocationMatch /TestApReqI18N__dump/[^/]+/latin1>
PerlSetVar EncodeParms ISO-8859-1
</LocationMatch>

<LocationMatch /TestApReqI18N__dump/[^/]+/utf7>
PerlSetVar EncodeParms UTF-7
</LocationMatch>

<LocationMatch /TestApReqI18N__dump/[^/]+/utf8>
PerlSetVar EncodeParms UTF-8
</LocationMatch>

