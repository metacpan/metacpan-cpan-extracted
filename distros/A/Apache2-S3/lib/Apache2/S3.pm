package Apache2::S3;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK DECLINED PROXYREQ_REVERSE);
use Apache2::RequestRec;
use Apache2::Filter;
use Apache2::FilterRec;
use APR::Table;
use APR::String;
use MIME::Base64;
use Digest::SHA1;
use Digest::HMAC;
use URI::Escape;
use HTML::Entities;
use XML::Parser;
use Time::Local;
use POSIX;
use CGI;

our $VERSION = '0.05';

our $ESCAPE = quotemeta " #%<>[\]^`{|}?\\";

use constant TEXT => '0';

sub _signature
{
    my ($id, $key, $data) = @_;
    return "AWS $id:".MIME::Base64::encode_base64(Digest::HMAC::hmac($data, $key, \&Digest::SHA1::sha1), "");
}

sub handler
{
    my $r = shift;

    return Apache2::Const::DECLINED
        if $r->proxyreq;

    return Apache2::Const::DECLINED
        unless $r->method eq 'GET' or $r->dir_config('S3ReadWrite');

    my $h = $r->headers_in;
    my $uri = $r->uri;

    my %map = split /\s*(?:,|=>)\s*/, $r->dir_config("S3Map");

    # most specific (longest) match first
    foreach my $base (sort { length $b <=> length $a } keys %map)
    {
        $uri =~ s|^($base/*)|| or next;
        my $stripped = $1;

        my ($bucket, $keyId, $keySecret) = split m|/|, $map{$base};
        $keyId ||= $r->dir_config("S3Key");
        $keySecret ||= $r->dir_config("S3Secret");

        my $is_dir = $uri =~ m,(^|/)$,;
        my $path = "/$bucket/".($is_dir ? "" : $uri);

        my $args = $r->args || "";
        my $sub = $args =~ s/^(acl|logging|torrent)(?:&|$)// ? $1 : "";
        local $CGI::USE_PARAM_SEMICOLONS = 0;
        $args = CGI->new($r, $args);

        if ($is_dir)
        {
            $args->param('delimiter', $args->param('delimiter') || '/');
            $args->param('prefix', $uri) if $uri;
        }

        my %note = (
            'id'       => $keyId,
            'secret'   => $keySecret,
            'path'     => $path,
            'sub'      => $sub,
            'stripped' => $stripped,
            ($is_dir ? ('prefix' => $uri) : ()),
            (($args->param('raw') or not $is_dir or $sub) ? ('raw' => 1) : ()),
            (($args->param('nocache') or $is_dir or $sub) ? ('nocache' => 1) : ()),
        );

        $r->notes->add(__PACKAGE__."::s3_$_" => $note{$_})
            foreach keys %note;

        $r->proxyreq(Apache2::Const::PROXYREQ_REVERSE);
        $r->uri("http://s3.amazonaws.com$path");
        $r->args(($sub ? "$sub&" : "").$args->query_string);
        $r->filename("proxy:http://s3.amazonaws.com$path");
        $r->handler('proxy-server');

        # we delay adding the authorization header to give
        # mod_auth* a chance to authenticate the users request
        # which would use the same header
        $r->set_handlers('PerlFixupHandler' => \&s3_auth_handler);

        # we set up an output filter to translate XML responses
        # for directory requests into "pretty" HTML
        $r->add_output_filter(\&output_filter);

        return Apache2::Const::OK;
    }

    return Apache2::Const::DECLINED;
}

sub s3_auth_handler
{
    my $r = shift;
    my $h = $r->headers_in;

    my ($keyId, $keySecret, $path, $sub) =
        map $r->notes->get(__PACKAGE__."::s3_$_"), qw(id secret path sub);

    $h->{'Date'} = POSIX::strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime);
    $h->{'Authorization'} = _signature $keyId, $keySecret, join "\n",
        $r->method,
        $h->{'Content-MD5'} || "",
        $h->{'Content-Type'} || "",
        $h->{'Date'},
        uri_escape($path, $ESCAPE).($sub ? "?$sub" : "");

    return Apache2::Const::OK;
}

sub _xml_get_tags
{
    my ($tree, $tag, @tags) = @_;
    my @ret;
    for (my $i = @$tree % 2; $i < @$tree; $i += 2)
    {
        next unless $tree->[$i] eq $tag;
        push @ret, $tree->[$i+1];
        last unless wantarray;
    }
    return unless @ret;
    return _xml_get_tags($ret[0], @tags) if @tags;
    return wantarray ? @ret : $ret[0];
}

sub _reformat_directory
{
    my ($f, $ctx) = @_;

    my $stripped = $f->r->notes->get(__PACKAGE__.'::s3_stripped');
    my $prefix = $f->r->notes->get(__PACKAGE__.'::s3_prefix');

    my $tree = eval {
        XML::Parser->new(Style => 'Tree')->parse($ctx->{text});
    };

    my $list = _xml_get_tags($tree, 'ListBucketResult')
        or die $ctx->{text};

    my $is_truncated = _xml_get_tags($list, 'IsTruncated', TEXT) =~ /^(?:false|)$/i ? 0 : 1;
    my $next_marker = _xml_get_tags($list, 'NextMarker', TEXT);

    my @dirs = map +{
        Name         => _xml_get_tags($_, 'Prefix', TEXT),
    }, _xml_get_tags($list, 'CommonPrefixes');

    my @files = map +{
        Name         => _xml_get_tags($_, 'Key', TEXT),
        Size         => _xml_get_tags($_, 'Size', TEXT),
        LastModified => _xml_get_tags($_, 'LastModified', TEXT) =~
            /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?Z$/
                ? timegm($6, $5, $4, $3, $2-1, $1) : 0,
    }, _xml_get_tags($list, 'Contents');

    my $ret = "";

    $ret .= qq|<html><body><pre>|;

    $ret .= qq|<a href="|.("$stripped$prefix" =~ m|^(.*/)[^/]+/$| ? $1 : "/").qq|">Parent Directory</a>\n|;

    $ret .= qq|<a href="?marker=|.(uri_escape $next_marker).qq|">Next Page</a>\n|
        if $is_truncated and $next_marker;

    $ret .= sprintf(qq|<a href="%s">%s</a>%s %-18s %s\n|,
            $stripped.uri_escape($_->{Name}, $ESCAPE),
            HTML::Entities::encode($_->{DisplayName}),
            " "x(87 - length $_->{DisplayName}),
            $_->{LastModified} ? strftime("%d-%b-%Y %H:%M", localtime($_->{LastModified})) : "-",
            $_->{Size} ? APR::String::format_size($_->{Size}) : "")
        foreach map {
            $_->{DisplayName} = $_->{Name} =~ m|([^/]+)/?$| ? $1 : $_->{Name};
            $_;
        } @dirs, @files;

    $ret .= qq|</pre></body></html>|;

    $ret;
}

sub output_filter
{
    my $f = shift;

    my $ctx;

    unless ($ctx = $f->ctx)
    {
        # disable caching layer if requested
        if ($f->r->notes->get(__PACKAGE__.'::s3_nocache'))
        {
            my $next = $f;

            while ($next)
            {
                $next->remove if $next->frec->name =~ /^cache_\w+$/i;
                $next = $next->next;
            }
        }
        else
        {
            # mark as public to allow mod_cache to save it even though it includes an Authorization header
            $f->r->headers_out->{'Cache-Control'} = join(",", grep defined && length,
                split(/\s*,\s*/, $f->r->headers_out->{'Cache-Control'} || ""), "public");
        }

        # don't process this output if requested
        if ($f->r->notes->get(__PACKAGE__.'::s3_raw') or lc $f->r->content_type ne 'application/xml')
        {
            $f->remove;

	    unless ($f->r->content_type eq 'application/xml')
	    {
		# S3 supports byte-range requests, but doesn't advertise it.
		$f->r->headers_out->{'Accept-Ranges'} = 'bytes';
	    }

            return Apache2::Const::DECLINED
        }

        $f->r->content_type('text/html');
        $f->r->headers_out->unset('Content-Length');
        $f->ctx($ctx = { text => "" })
    }

    $ctx->{text} .= $_
        while $f->read($_);

    return Apache2::Const::OK
        unless $f->seen_eos;

    my $ret = _reformat_directory($f, $ctx);

    $f->r->headers_out->{'Content-Length'} = length $ret;
    $f->print($ret);
    $f->ctx(undef);

    return Apache2::Const::OK;
}

1;
__END__
=head1 NAME

Apache2::S3 - mod_perl library for proxying requests to amazon S3

=head1 SYNOPSIS

  PerlModule Apache2::S3;
  PerlTransHandler Apache2::S3

  PerlSetVar S3Key foo
  PerlSetVar S3Secret bar
  PerlSetVar S3Map '/path/ => amazon.s3.bucket.name'

  # If you want to support non-GET requests
  PerlSetVar S3ReadWrite 1

=head1 DESCRIPTION

This module will map requests for URLs on your server into proxy
requests to the Amazon S3 service, adding authentication headers
along the way to permit access to non-public resources.

It doesn't actually do any proxying itself, rather it just adds
the required authentication fields to the request and sets up mod_proxy
to handle it.  Therefore you will need to enable mod_proxy like so:

  ProxyRequests on

If you permit modification requests (PUT/DELETE) using the
S3ReadWrite feature then it is quite important that you protect
the url from untrusted requests using something like the following
on Apache 2.2:

  <Proxy *>
    <LimitExcept GET>
      Order deny,allow
      Deny from all
      Allow from localhost
    </LimitExcept>
  </Proxy>

=head1 SEE ALSO

  Apache::PassThru from Chapter 7 of "Writing Apache Modules with Perl and C"
  http://www.modperl.com

  Amazon S3 API
  http://developer.amazonwebservices.com/connect/entry.jspa?entryID=123

=head1 AUTHOR

Iain Wade, E<lt>iwade@optusnet.com.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Iain Wade

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
