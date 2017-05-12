package Apache2::Layout;
use 5.008;

use Apache2::Filter      ();  # $f
use Apache2::RequestRec  ();  # $r
use Apache2::RequestUtil ();  # $r->dir_config()
use Apache2::RequestIO   ();
use Apache2::Connection  ();
use Apache2::SubRequest  ();  # $r->lookup_uri()
use Apache2::Log         ();  # $log->info()
use APR::Table           ();  # dir_config->get() and headers_out->get()
use APR::Bucket          ();
use APR::Brigade         ();
use APR::Const -compile => qw(SUCCESS);

use Apache2::Const -compile => qw(OK DECLINED);

use strict;
use warnings;

our $VERSION = '0.6';

use XSLoader;
XSLoader::load __PACKAGE__, $VERSION;

sub handler {
    my ($f, $bb) = @_;

    my $r = $f->r;

    my $log = $r->server->log;

    # we only process HTML documents
    unless ($r->content_type =~ m!text/html!i) {
        $log->debug('skipping request to ',
                    $r->uri, ' (not an HTML document)');
        return Apache2::Const::DECLINED;
    }

    unless ($r->is_initial_req) {
        $log->debug('skipping subrequest ', $r->uri);
        return Apache2::Const::DECLINED;
    }

    my $context = $f->ctx;

    unless ($context) {

        # these are things we only want to do once no matter how
        # many times our filter is invoked per request

        # prep the configuration
        #$context = {};
        if (my $debug = $r->dir_config->get('LayoutDebug')) {
            $context->{debug} = $debug if $debug;
        }

        if (my $comments = $r->dir_config->get('LayoutComments')) {
            $context->{comments} = $comments if $comments;
        }

        # Ordering is important here, we only match in the order
        # we are building up here. Insert in the right order is
        # paramount!
        my @tags;
        if (my $css = $r->dir_config->get('LayoutCSS')) {
            push @tags,
              {
                name    => 'end_head',
                url     => $css,
                pattern => '</\s*head[^>]*>',
                insert  => 'before',
              };
        }
        if (my $header = $r->dir_config->get('LayoutHeader')) {
            push @tags,
              {
                name    => 'start_body',
                url     => $header,
                pattern => '<\s*body[^>]*>',
                insert  => 'after',
              };
        }
        if (my $footer = $r->dir_config->get('LayoutFooter')) {
            push @tags,
              {
                name    => 'end_body',
                url     => $footer,
                pattern => '</\s*body[^>]*>',
                insert  => 'before',
              };
        }

        unless (@tags) {
            $log->debug('skipping request to ',
                        $r->uri, ' (HTML but no Layout configuration)');
            return Apache2::Const::DECLINED;
        }

        $context->{current_tag} = shift @tags;
        $context->{tags}        = \@tags;

        # output filters that alter content are responsible for removing
        # the Content-Length header, but we only need to do this once.
        $r->headers_out->unset('Content-Length');

        #XXX: At this point, we are seriously altering content, so we
        #XXX: might want to fiddle with outbound headers a bit more.
        #XXX: I am thinking about ETag, Last-Modified, Expires, Cache-Control
        #XXX: Similar problem than mod_includes, might be able to steal from
        #XXX: there.
    }

    my $tags = $context->{tags};

    my $bb_ctx = APR::Brigade->new($f->c->pool, $f->c->bucket_alloc);

    $context->{pass}++;
    while (!$bb->is_empty) {
        my $bucket = $bb->first;

        if ($bucket->is_eos) {
            if ($context->{debug} && $context->{matched}) {
		my $ver = __PACKAGE__ . " v$VERSION";
                my $msg =
                  "$ver matched $context->{matched} times out of $context->{tests} over $context->{reads} reads and $context->{pass} passes";
                if ($context->{comments}) {
                    $bb_ctx->insert_tail(
                                APR::Bucket->new(
                                    $bb_ctx->bucket_alloc, "<!-- $msg -->\n"
                                )
                    );
                }
                else {
                    my $uri = $r->uri;
                    $log->debug("[$uri] $msg");
                }
            }
            $bucket->remove;
            $bb_ctx->insert_tail($bucket);
            last;
        }

        if ($bucket->read(my $data)) {
            $context->{reads}++ if $context->{debug};

            # The extra juggling here is because we don't want to match again a tag we've seen already, so we pop
            # them out as we find them.
            while (my $tag = $context->{current_tag}) {
                my $name = $tag->{name};
                my $pat  = $tag->{pattern};

                $context->{tests}++ if $context->{debug};
                if ($data =~ m{(.*)($pat)(.*)}si) {

                    #We match each tag only once, and in order, so roll over to the next match
                    $context->{current_tag} = shift @{$context->{tags}};

                    $context->{matched}++ if $context->{debug};
                    my ($before, $html_tag, $after) = ($1, $2, $3);

                    my $where = $tag->{insert};
                    my $url   = $tag->{url};

                    $bb_ctx->insert_tail(
                          APR::Bucket->new($bb_ctx->bucket_alloc, $before));
                    if ($where eq 'before') {
                        my $rv = _inject($r, $f, $bb, $bb_ctx, $url,
                                         $context->{comments});
                        return $rv unless $rv == APR::Const::SUCCESS;
                    }

                    $bb_ctx->insert_tail(
                        APR::Bucket->new($bb_ctx->bucket_alloc, $html_tag));

                    if ($where eq 'after') {
                        my $rv = _inject($r, $f, $bb, $bb_ctx, $url,
                                         $context->{comments});
                        return $rv unless $rv == APR::Const::SUCCESS;
                    }

                    $data = $after;
                }

                # Optimization here, if the first pattern didn't match,
                # don't bother looking at the others, this assumes the
                # tags are ordered, which the main loop already does
                else {
                    last;
                }
            }

            # Pass thru unmatched data unmodified
            $bb_ctx->insert_tail(
                            APR::Bucket->new($bb_ctx->bucket_alloc, $data));
        }
    $bucket->remove;
    }

    my $rv = $f->next->pass_brigade($bb_ctx);
    return $rv unless $rv == APR::Const::SUCCESS;

    $bb_ctx->destroy();

    # Stash our context for next time around
    $f->ctx($context);

    return Apache2::Const::OK;
}

sub _inject {
    my ($r, $f, $bb, $bb_ctx, $url, $comments) = @_;
    $bb_ctx->insert_tail(
           APR::Bucket->new($bb_ctx->bucket_alloc, "<!-- $url START -->\n"))
      if $comments;

    my $rv = $f->next->pass_brigade($bb_ctx);
    return $rv unless $rv == APR::Const::SUCCESS;
    $rv = _call($url, $r, $f);    #XXX: move back to perl land
    return $rv unless $rv == APR::Const::SUCCESS;
    $bb_ctx->insert_tail(
             APR::Bucket->new($bb_ctx->bucket_alloc, "<!-- $url END -->\n"))
      if $comments;
    return $rv;
}

use Apache2::SubRequest ();

my $call = \&_call_xs;
sub _call {
   return $call->(@_); 
}

sub _call_pp {
    my ($url, $r, $f) = @_;
    # This Pure-perl code would work, if not for a bug in mod_perl
    # mod_perl 2.0.4 will be fixed (r607687)
    my $subr = $r->lookup_uri($url, $f->next);
    my $rc = $subr->run;

    return $rc;
}

42;

__END__

=head1 NAME 

Apache2::Layout - mod_perl 2.0 html layout engine

=head1 SYNOPSIS

httpd.conf:

  PerlModule Apache2::Layout

  Alias /layout /usr/local/apache2/htdocs
  <Location /layout>
    PerlOutputFilterHandler Apache2::Layout

    PerlSetVar LayoutFooter /footer.html
    PerlSetVar LayoutHeader /header.html
    PerlSetVar LayoutCSS /head.html
  </Location>

=head1 DESCRIPTION

Apache2::Layout is a filter module that can be used to inject HTML
layout into HTML documents. Very handy when trying to apply customizations
to existing HTML content without needing to change them.

Only documents with a content type of "text/html" are affected - all
others are passed through unaltered.

=head1 OPTIONS

=over 4

=item LayoutComments

Inserts HTML comments in the output, marking where inserted content begins
and ends

  PerlSetVar LayoutComments On

LayoutComments has no default.

=item LayoutDebug

Logs debugging information about the processing. Combined with L<LayoutComments>,
will insert a debug summary as an HTML comment at the end of the filtered document.

  PerlSetVar LayoutDebug On

LayoutDebug has no default.

=item LayoutCSS

Specifies a url to insert right before the end of the HTML E<lt>headE<gt> element,
typically used to inject stylesheets into the document.

  PerlSetVar LayoutCSS /css/style.css

LayoutCSS has no default.

=item LayoutHeader

Specifies a url to insert right after the beginning of the HTML E<lt>bodyE<gt> element,
typically used to inject the begging of a content wrapper into the document.

  PerlSetVar LayoutHeader /templates/header.html

LayoutHeader has no default.

=item LayoutFooter

Specifies a url to insert right before the end of the HTML E<lt>bodyE<gt> element,
typically used to inject the end of a content wrapper into the document.

  PerlSetVar LayoutHeader /templates/footer.html

LayoutFooter has no default.

=back

=head1 API

=head2 handler

This is the one and only user-visible function, it's the main filter
handler.

  PerlOutputFilterHandler Apache2::Layout

=head1 NOTES

This is alpha software, and as such has not been tested on multiple
platforms or environments.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3), mod_layout

=head1 AUTHOR

Philippe M. Chiasson E<lt>gozer@ectoplasm.orgE<gt>

=head1 REPOSITORY

http://svn.ectoplasm.org/projects/perl/Apache2-Layout/trunk/

=head1 COPYRIGHT

Copyright (c) 2007, Philippe M. Chiasson
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
