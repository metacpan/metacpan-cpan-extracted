package Apache2::HTML::Detergent;

use 5.010;
use strict;
use warnings FATAL => 'all';

# Apache stuff

use base qw(Apache2::Filter);

use Apache2::Const -compile => qw(OK DECLINED HTTP_BAD_GATEWAY);
use APR::Const     -compile => qw(SUCCESS);

use Apache2::Log         ();
use Apache2::FilterRec   ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Connection  ();
use Apache2::Response    ();
use Apache2::ServerRec   ();
use Apache2::CmdParms    ();
use Apache2::Module      ();
use Apache2::Directive   ();
use Apache2::ModSSL      ();

use APR::Table   ();
use APR::Bucket  ();
use APR::Brigade ();

# my contribution
use Apache2::TrapSubRequest ();

# non-Apache stuff

use URI               ();
use Encode            ();
use Encode::Detect    ();
use IO::Scalar        ();
use HTML::Detergent   ();
use Apache2::HTML::Detergent::Config;

#use Encode::Guess     ();
#use Encode::Detect::Detector ();

=head1 NAME

Apache2::HTML::Detergent - Clean the gunk off HTML documents on the fly

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    # httpd.conf or .htaccess

    # The + prefix forces the module to preload
    PerlOutputFilterHandler +Apache2::HTML::Detergent

    # These default matching content types can be overridden
    DetergentTypes text/html application/xhtml+xml

    # This invocation just pulls the matching element into a new document
    DetergentMatch /xpath/statement

    # An optional second argument can specify an XSLT stylesheet
    DetergentMatch /other/xpath/statement /path/to/transform.xsl

    # Configure <link> and <meta> tags

    DetergentLink relvalue http://href

    DetergentMeta namevalue "Content"

    # that's it!

=head1 DESCRIPTION

=cut

sub handler : FilterRequestHandler {
    #my $f = shift;
    my ($f, $bb)  = @_;
    my $r = $f->r;
    my $c = $r->connection;

    my $class = __PACKAGE__ . '::Config';

    my $config = Apache2::Module::get_config
        ($class, $r->server, $r->per_dir_config) ||
            Apache2::Module::get_config($class, $r->server);

    unless ($config) {
        $r->log->crit("Cannot find config from $class!");
        return Apache2::Const::DECLINED;
    }

    # store the context; initial content type, payload
    my $ctx;
    unless ($ctx = $f->ctx) {
        # turns out some things don't have a type!
        my $x = $r->content_type || '';
        my ($t, $c) =
            ($x =~ /^\s*([^;]*)(?:;.*?charset\s*=\s*['"]*([^'"]+)['"]*?)?/i);

        $ctx = [$t || 'application/octet-stream', ''];
        $f->ctx($ctx);
    }

    # get this before changing it
    my $type = $ctx->[0];

    unless ($config->type_matches($type)) {
        $r->log->debug("$type doesn't match");
        return Apache2::Const::DECLINED;
    }

    #$r->headers_out->set('Transfer-Encoding', 'chunked');

    # application/xml is the most reliable content type to
    # deliver to browsers that use XSLT.
    if ($config->xslt) {
        $r->log->debug("forcing $type -> application/xml");
        $r->content_type('application/xml; charset=utf-8');
    }

    # XXX will we need to restore $r->status == 200 to this condition?
    if ($r->is_initial_req) {
        # BEGIN BUCKET
        until ($bb->is_empty) {
            my $b = $bb->first;

            if ($b->is_eos) {
                # no further processing if the brigade only contains EOS
                return Apache2::Const::DECLINED if $ctx->[1] eq '';

                # nuke the brigade
                $bb->destroy;
                # this is where that xml code goes
                return _filter_content($f, $config, $ctx);
            }

            if ($b->read(my $data)) {
                if ($ctx->[1] eq '') {
                    # XXX here is where we would double-check the mime type
                }
                $ctx->[1] .= $data;
            }

            # remove this bucket only if it isn't EOS
            $b->remove;
        }

        # destroy the brigade only after exiting the loop
        $bb->destroy;
        # END BUCKET

        return Apache2::Const::OK;
    }

    Apache2::Const::DECLINED;
}

sub _filter_content {
    my ($f, $config, $ctx) = @_;
    my $r = $f->r;
    my $c = $r->connection;

    my ($type, $content) = @$ctx;

    # this is where we hack the content

    # set up the input callbacks with subreq voodoo
    my $icb = $config->callback;
    $icb->register_callbacks([
        sub {
            # MATCH
            return $_[0] =~ m!^/!;
        },
        sub {
            # OPEN
            my $uri  = shift;
            $r->log->debug("opening XML at $uri");
            my $subr = $r->lookup_uri($uri);
            my $data = '';
            $subr->run_trapped(\$data);
            my $io = IO::Scalar->new(\$data);
            # HACK: the callback infrastructure doesn't like the globref
            \$io;
        },
        sub {
            # READ
            my ($io, $len) = @_;
            # HACK once again
            my $fh = $$io;
            my $buf;
            $fh->read($buf, $len);
            $buf;
        },
        sub {
            # CLOSE
            1;
        },
    ]);

    my $scrubber = HTML::Detergent->new($config);

    # $r->headers_in->get('Host') || $r->get_server_name;
    my $host   = $r->hostname || $r->get_server_name;
    my $scheme = $c->is_https ? 'https' :  'http';
    my $port   = $r->get_server_port;

    my $uri = URI->new
        (sprintf '%s://%s:%d%s', $scheme,
         $host, $port, $r->unparsed_uri)->canonical;
    $r->log->debug($uri);

    my $utf8 = Encode::decode(Detect => $content);
    $content = $utf8 if defined $utf8 and ($content ne '' and $utf8 ne '');
    undef $utf8;

    if ($type =~ m!/.*xml!i) {
        $r->log->debug("Attempting to use XML parser for $uri");
        $content = eval {
            XML::LibXML->load_xml
                  (string => $content, recover => 1, no_network => 1) };
        if ($@) {
            $r->log->error("Loading $uri failed: $@");
            return Apache2::Const::HTTP_BAD_GATEWAY;
        }
    }

    # note $content might be an XML::LibXML::Document
    my $doc = $scrubber->process($content, $uri);
    $doc->setEncoding('utf-8');

    my $root = $doc->documentElement;
    if ($root and lc $root->localName eq 'html') {
        # XML_DTD_NODE
        # $and not grep { $_->nodeType == 14 } $doc->childNodes) {
        $doc->removeInternalSubset;
        $doc->removeExternalSubset;
        $doc->createExternalSubset('html', undef, undef);
        $doc->createInternalSubset('html', undef, undef);
    }

    if (defined $config->xslt) {
        # check for existing xslt
        my $found;
        for my $child ($doc->childNodes) {
            if ($child->nodeType == 7
                    && lc($child->nodeName) eq 'xml-stylesheet'
                        && lc($child->getData) =~ /xsl/) {
                $found = $child;
                last;
            }
        }

        # TODO: config directive to override existing XSLT PI?
        unless ($found) {
            my $pi = $doc->createProcessingInstruction
                ('xml-stylesheet', sprintf 'type="text/xsl" href="%s"',
                 $config->xslt);

            if ($root) {
                $doc->insertBefore($pi, $root);
            }
        }
    }
    else {
        $r->content_type(sprintf '%s; charset=utf-8', $type);
    }
    #$r->log->debug($r->content_encoding || 'identity');
    #$r->log->debug($r->headers_in->get('Content-Encoding'));

    # reuse content
    $content = $doc->toString(1);

    # explicitly get rid of these big objects
    undef $scrubber;
    undef $doc;
    undef $config;

    # now deal with the rest
    use bytes;
    #        $r->log->debug(bytes::length($buf));
    $r->set_content_length(bytes::length($content));

    my $new_bb = APR::Brigade->new($c->pool, $c->bucket_alloc);
    my $b = APR::Bucket->new($new_bb->bucket_alloc, $content);
    $new_bb->insert_tail($b);
    $new_bb->insert_tail
        (APR::Bucket::eos_create($new_bb->bucket_alloc));

    my $rv = $f->next->pass_brigade($new_bb);
    return $rv unless $rv == APR::Const::SUCCESS;

    Apache2::Const::OK;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-html-detergent at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-HTML-Detergent>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::HTML::Detergent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-HTML-Detergent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-HTML-Detergent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-HTML-Detergent>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-HTML-Detergent/>

=back


=head1 SEE ALSO

=over 4

=item L<HTML::Detergent>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Apache2::HTML::Detergent
