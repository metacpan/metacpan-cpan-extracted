# $File: //member/autrijus/Apache-Filter-HanConvert/HanConvert.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 2690 $ $DateTime: 2002/12/12 06:47:15 $

package Apache::Filter::HanConvert;
$Apache::Filter::HanConvert::VERSION = '0.02';

use strict;
use warnings;

=head1 NAME

Apache::Filter::HanConvert - Filter between Chinese variant and encodings

=head1 VERSION

This document describes version 0.02 of Apache::Filter::HanConvert, released
December 12, 2002.

=head1 SYNOPSIS

In F<httpd.conf>:

    PerlModule Apache::Filter::HanConvert
    PerlOutputFilterHandler Apache::Filter::HanConvert
    PerlSetVar HanConvertFromVariant "traditional"

=head1 DESCRIPTION

This module utilizes the B<Encode::HanConvert> module with B<Apache2>'s
output filtering mechanism, to provide a flexible and customizable
solution for serving multiple encoding/variants from the same source
documents.

From the settings in L</SYNOPSIS>, the server would negotiate with the
client's browser about their C<Accept-Language> preference (C<zh-cn> and
C<zh> means Simplified, other C<zh-*> means Traditional), as well as the
preferred C<Accept-Charset> setting (defaults to C<utf8> if nothing
was explicitly specified).

The C<Content-Type> header will be rewritten to reflect the final
encoding used.

If you want to use other encodings, try adding these lines:

    PerlSetVar HanConvertFromEncoding "UTF-8"
    PerlSetVar HanConvertToEncodingTraditional "big5"
    PerlSetVar HanConvertToEncodingSimplified "gbk"

Finally, if you'd like to dictate it to always convert to a specific
variant/encoding, use this:

    PerlSetVar HanConvertToVariant "simplified"
    PerlSetVar HanConvertToEncoding "gbk"

=head1 CAVEATS

The C<HanConvertFromEncoding> config probably could take multiple
encodings and apply L<Encode::Guess> to find out the correct source
encoding.

Currently this module does not work with C<mod_dir>, so the server's
C<DirectoryIndex> setting won't be honored.  Patches welcome!

=cut

use Encode ();
use Encode::HanConvert 0.10 ();

use Apache2 ();
use Apache::Filter ();
use Apache::RequestRec ();

use APR::Brigade ();
use APR::Bucket ();

use Apache::Const -compile => qw(OK DECLINED);
use APR::Const -compile => ':common';

my %variants = (
    'TS'    => 'trad-simp',
    'ST'    => 'simp-trad',
    'XS'    => 'trad-simp',
    'XT'    => 'simp-trad',
);

my %encodings = (
    'T'	    => 'HanConvertToEncodingTraditional',
    'S'	    => 'HanConvertToEncodingSimplified',
);

my %charsets = (
    'T'	    => qr{
	big-?5				    |
	big5-?et(:en)?			    |
	(?:tca|tw)[-_]?big5		    |
	big5-?hk(?:scs)?		    |
	hk(?:scs)?[-_]?big5		    |
	MacChineseTrad			    |
	cp950				    |
	(?:x-)winddows-950		    |
	(?:cmex[-_]|tw[-_])?big5-?e(?:xt)?  |
	(?:cmex[-_]|tw[-_])?big5-?p(?:lus)? |
	(?:cmex[-_]|tw[-_])?big5\+	    |
	(?:ccag[-_])?cccii		    |
	euc[-_]tw			    |
	tw[-_]euc			    |
	utf-?8				    |
	ucs-?2[bl]e			    |
	utf-?(?:16|32)(?:[bl]e)?
    }x,
    'S'	    => qr{
	euc[-_]cn			    |
	cn[-_]euc			    |
	iso-ir-165			    |
	MacChineseSimp			    |
	cp936				    |
	(?:x-)winddows-936		    |
	hz				    |
	gb[-_ ]?2312(?:\D+)?		    |
	gb[-_ ]?18030			    |
	utf-?8				    |
	ucs-?2[bl]e			    |
	utf-?(?:16|32)(?:[bl]e)?
    }x
);

sub Apache::Filter::HanConvert::handler {
    my($filter, $bb) = @_;

    my $r = $filter->r;
    my $content_type = $r->content_type;

    return Apache::DECLINED
	if defined( $content_type ) and $content_type !~ m|^text/|io;

    my $from_variant  = uc(substr($r->dir_config("HanConvertFromVariant"), 0, 1)) || 'X';
    my $from_encoding = $r->dir_config("HanConvertFromEncoding");
    my $to_variant    = uc(substr($r->dir_config("HanConvertToVariant"), 0, 1));
    my $to_encoding   = $r->dir_config("HanConvertToEncoding");

    if (!$to_variant) {
	my $langs = $r->headers_in->get('Accept-Language');

	$to_variant = (($1 and $1 ne 'cn') ? 'T' : 'S')
	    if $langs =~ /\bzh(?:-(tw|cn|hk|sg))?\b/;
    }

    return Apache::DECLINED unless $to_variant;

    $to_encoding ||= $r->dir_config($encodings{$to_variant});
    
    if (!$to_encoding) {
	my $chars = $r->headers_in->get('Accept-Charset');

	$to_encoding = $1
	    if $chars =~ /\b($charsets{$to_variant})\b/i;
    }

    my $var_enc	   = $variants{"$from_variant$to_variant"} || 'utf8';
    $from_encoding = Encode::resolve_alias($from_encoding) || 'utf8';
    $to_encoding   = Encode::resolve_alias($to_encoding)   || 'utf8';

    return Apache::DECLINED if $from_encoding eq $to_encoding
			    and $from_variant eq $to_variant;

    my $charset = ($to_encoding eq 'utf8' ? 'utf-8' : $to_encoding);
    $content_type =~ s/(?:;charset=[^;]+(.*))?$/;charset=$charset$1/;
    $r->content_type($content_type);

    my $c = $filter->c;
    my $bb_ctx = APR::Brigade->new($c->pool, $c->bucket_alloc);
    my $data = '';

    while (!$bb->empty) {
	my $bucket = $bb->first;

	$bucket->remove;

	if ($bucket->is_eos) {
	    $bb_ctx->insert_tail($bucket);
	    last;
	}

	my $buffer;
	my $status = $bucket->read($buffer);
	return $status unless $status == APR::SUCCESS;

	Encode::from_to($buffer, $from_encoding => 'utf8', Encode::FB_HTMLCREF)
	    if $from_encoding ne 'utf8';

	if ($var_enc eq $to_encoding) {
	    $bucket = APR::Bucket->new( $buffer );
	}
	elsif ($data .= $buffer) {
	    $bucket = APR::Bucket->new( Encode::encode(
		$to_encoding, Encode::decode($var_enc, $data, Encode::FB_QUIET)
	    ) );
	}

	$bb_ctx->insert_tail($bucket);
    }

    my $rv = $filter->next->pass_brigade($bb_ctx);
    return $rv unless $rv == APR::SUCCESS;

    Apache::OK;
}

1;

__END__

=head1 SEE ALSO

L<Apache2>, L<Encode::HanConvert>, L<Encode>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
