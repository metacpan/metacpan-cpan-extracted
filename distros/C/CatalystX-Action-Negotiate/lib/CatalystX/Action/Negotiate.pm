package CatalystX::Action::Negotiate;

use 5.010;
use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

use Path::Class;
use HTTP::Negotiate;

with 'Role::MimeInfo';

=head1 NAME

CatalystX::Action::Negotiate - ActionRole for content negotiation

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    sub default :Path :Does('+CatalystX::Action::Negotiate') {
        my ($self, $c) = @_;

        # obtain variants (if you care)
        my @variants = @{$c->stash->{variants}};

        # maybe manipulate them? i dunno

        # set them back, or set entirely new ones
        $c->stash->{variants} = \@variants;

        # action role negotiates variants and returns the winner
    }

=head1 DESCRIPTION

This module serves content-negotiated static content from the document
root. It also affords mixing dynamic variants in with static variants,
the list of which is passed directly into the
L<HTTP::Negotiate/choose> function. The winning variant is chosen from
the various C<Accept-*> request headers.

As with Apache and other Web servers, dimensions for static variants
are derived from file extensions. Currently the only supported
dimension is MIME content type.

There is a slight difference in the behaviour between this module and
Apache: whereas there is one or more files of the form C<foo.*>
alongside a directory called C<foo> containing one or more files with
the slug C<index>, these will all be lumped into the set of variants.
The customary trailing slash, however, will only be applied in the
case that a C<foo/index.*> file is chosen over a C<foo.*> file. This
is different from Apache in that the latter ignores C<foo.*> files if
there is also a directory present called C<foo>. The purpose of this
change is to provide an easy way to style URIs I<without> the trailing
slash while still providing for descendants along the same URI path.

Interacting with the action in a handler goes as follows:

=over 4

=item 1.

The action runs and first attempts to collect any eligible static
variants found by concatenating the request-URI to the document root.
It puts what it finds in C<< $c->stash->{variants} >>. To indicate the
indeterminate state of the response to the caller, the status is
initially set to 404.

=item 2.

The action runs the calling handler, offering it an opportunity to
manipulate the variant list or intercede in the response.

=item 3.

If the handler has not changed the response code to a value below 400,
the action proceeds to select a variant and set the appropriate headers.

=item 4.

The action performs a trailing-slash check to match the request-URI to
the internal representation, redirecting if necessary with a code 301.

=item 5.

An C<If-Modified-Since> check is performed, which will return 304 if
the client already has the latest version of the document.

=item 6.

If the action has not terminated the response by now, it sets the
response body to the variant and the status to 200. If you need to,
you can still manipulate it in a subsequent (e.g. C<end>) handler.

=back

The calling controller action is sandwiched between the
variant-generating operation and the variant-selecting operation. It
is placed as an C<ARRAY> reference for your convenience in
C<< $c->stash->{variants} >>. This structure is exactly the same as
that which is passed into L<HTTP::Negotiate>, save for these
exceptions:

=over 4

=item 1.

Variants do not need to be a string identifier, but in fact can be
anything that can be consumed by a view or middleware component, e.g.,
a file handle or any other kind of supported object.

=item 2.

L<Path::Class::File> objects get special treatment, as they are what
the initial static variant list is made out of.

=item 3.

Append an additional integer to the end of a variant's record to
supply an artificial C<Last-Modified> value as a UNIX time stamp.

=back

Otherwise, consult L<HTTP::Negotiate> for how to construct the
records. This modification enables you to mix static variants in with
dynamic ones, or overwrite the list with purely dynamic variants.

=head CAVEATS

Note that this module may conflict with L<Catalyst::Plugin::Static::Simple>.
In future releases I will attempt to bring this module up to par so
that it can be a viable replacement, or at the very least be a better
cohabitant.

=cut

before execute => sub {

    my $self = shift;
    my ($ctl, $c) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    $resp->status(404);

    my $root = Path::Class::Dir->new($c->config->{root});

    $c->log->debug("trying $root");

    # get a clean URI path. (unfortunately Path::Class doesn't get it
    # this clean)
    my @ps = map { (/^([^;]*)(?:;.*)?$/) } split m!/+!, $req->path;
    my $i = 0;
    while ($i < @ps) {
        if ($ps[$i] eq '' or $ps[$i] eq '.') {
            splice @ps, $i, 1;
        }
        elsif ($ps[$i] eq '..') {
            $i > 0 ? splice @ps, $i-1, 2 : splice @ps, $i, 1;
        }
        else {
            $i++;
        }
    }

    # if the path terminates with a slash, what does it mean?

    # * the path is a legitimate directory /foo/ which should be
    # forwarded internally to /foo/index

    # * the client (probably robot) is appending a trailing slash to
    # /foo which ordinarily wouldn't have one.

    # ok, so how do we want it to behave?

    # if @ps is length 0, then we are looking at the root URI, so
    # append 'index' and start looking for variants.

    # if @ps is any longer than 0, then we are looking at something
    # beneath the root.

    # if there is a trailing slash in the request, we want to do an
    # exact match on the dir(/index) first, then exact match for
    # files, then fuzzy match on the files. if no trailing slash, then
    # exact match on files first, then fuzzy match on files, then
    # dir(/index). this is different from mod_negotiate.

    # if there is a trailing slash on the request and what was found
    # was a file, 301 to a url with no trailing slash. similarly, if
    # the request had no trailing slash and what was found was a dir,
    # 301 to a url with a trailing slash.

    my $slash = $req->path =~ m!/(?:;[^/]*)?$!;
    my $dpath = $root->file(@ps, 'index');
    my $fpath = $root->file(@ps);

    my @indices = grep { $_ and my $x = $_->stat; $x and -f $x }
        map { Path::Class::File->new($_) } glob(quotemeta($dpath) . "{,.*}");

    my @files = grep { $_ and my $x = $_->stat; $x and -f $x }
        ($fpath, map { Path::Class::File->new($_) }
             glob(quotemeta($fpath) . "{,.*}")) if @ps > 0;

    # XXX we needed to switch the order of operations around a bit,
    # otherwise this stashed stuff will never get assigned

    # gin up some maps so we can figure out where the chosen variant
    # came from
    my %i = map { $_->stringify => $_ } @indices;
    my %f = map { $_->stringify => $_ } @files;

    # stash goodies
    my $pkg         = __PACKAGE__;
    $pkg            = $c->stash->{$pkg} ||= {};
    $pkg->{ps}      = \@ps;
    $pkg->{slash}   = $slash;
    $pkg->{files}   = \%f;
    $pkg->{indices} = \%i;

    # if these arrays are both empty then this is a 404
    unless (@indices + @files > 0) {
        $resp->status(404);
        $resp->body("Not found (not for a lack of looking).");
        return;
    }

    # now construct variant list
    my @variants;
    for my $v (@indices, @files) {
        my $vs = $v->stringify;

        # we do the thing with the slash through the QS parameter
        my $qs = 1;
        if ($slash) {
            if ($vs eq $fpath->stringify) {
                $qs = 0.75;
            }
            elsif ($f{$vs}) {
                $qs = 0.5;
            }
            else {
                $qs = 1;
            }
        }
        else {
            if ($vs eq $fpath->stringify) {
                $qs = 1;
            }
            elsif ($i{$vs}) {
                $qs = 0.5;
            }
            else {
                $qs = 0.75;
            }
        }

        my $st = $v->stat or next;
        my ($size, $mtime) = ($st->size, $st->mtime);

        # we still include the variant if it isn't readable, because
        # that's how we will deliver a 403 rather than a 404
        $qs /= 100.0 unless -r $st;

        # note mtime does not get touched by HTTP::Negotiate; indeed
        # it gets stripped off with the return value
        push @variants, [$v, $qs, $self->mimetype($v->stringify),
                         undef, undef, undef, $st->size, $st->mtime ];
    }

    # assign variants to stash

    $c->stash->{variants} = \@variants;
};

after execute => sub {
    my $self = shift;
    my ($ctl, $c) = @_;
    my $req  = $c->req;
    my $resp = $c->res;

    return if $resp->status < 400;

    my $pkg   = __PACKAGE__;
    $pkg      = $c->stash->{$pkg};
    my @ps    = @{$pkg->{ps}};
    my $slash = $pkg->{slash};
    my %f     = %{$pkg->{files}};
    my %i     = %{$pkg->{indices}};

    # overwrite whatever came back from the caller
    my %valt;
    my @variants = do {
        my $i = 0;

        map { my $k = sprintf '%08x', $i++; $valt{$k} = $_;
              [$k, @{$_}[1..$#{$_}]] } @{$c->stash->{variants} || []};
    };

    # now we check again
    unless (@variants > 0) {
        $resp->status(404);
        $resp->body('Not found (no variant)');
        return;
    }

    # add */* because for some reason the content negotiator won't
    # select if not in there (hi chrome)
    my $hdr = $req->headers;
    my $acc = $hdr->header('Accept') || '';
    $c->log->debug('Testing variants against Accept: ' . $acc);
    $hdr->push_header(Accept => '*/*;q=0.5') unless $acc and $acc =~ m!\*/\*!;
    # perform the negotiation


    my $chosen = HTTP::Negotiate::choose(\@variants, $hdr);

    unless ($chosen) {
        $resp->status(406);
        $resp->body('No Suitable Type');
        return;
    }

    # retrieve actual variant
    unless ($chosen = $valt{$chosen}) {
        $resp->status(500);
        $resp->body('Cannot find metainformation for chosen variant');
        return;
    }

    my ($body, $qs, $type, $encoding, $charset, $lang, $size, $mtime) =
        @$chosen;

    # now we check that slash again
    my $uri = $req->uri->clone->canonical;
    $uri->path('/');

    if (Scalar::Util::blessed($body) && $body->isa('Path::Class::File')) {

        # this will happen if the best variant was an unreadable one
        my $cstat = $body->stat;
        unless (-r $cstat) {
            $c->res->status(403);
            $c->res->body("Forbidden");
            return;
        }

        $size  ||= $cstat->size;
        $mtime ||= $cstat->mtime;

        if ($slash and $f{$chosen}) {
            # remove the slash and redirect
            $uri->path_segments('', @ps);
            $c->log->debug("Removed slash from $uri");
            $c->res->redirect($uri, 301) unless $uri->eq($req->uri);
        }
        elsif (!$slash and $i{$chosen}) {
            # add the slash and redirect
            $uri->path_segments('', @ps, '');
            $c->log->debug("Added slash to $uri");
            $c->res->redirect($uri, 301) unless $uri->eq($req->uri);
        }
        else {
            #noop
            $c->log->debug('No URI path to fix');
        }

        # replace body with reference to body
        $body = $body->openr;
    }

    my $rhdr = $resp->headers;

    if ($type) {
        $type .= ";charset=$charset" if $charset;
        $c->log->debug("setting content type to $type");
        $rhdr->content_type($type);
    }

    $rhdr->header('Content-Encoding' => $encoding) if $encoding;
    $rhdr->header('Content-Language' => $lang)     if $lang;

    if ($mtime) {
        $rhdr->last_modified($mtime);
        my $ims = $req->headers->if_modified_since;
        if ($ims and $mtime and $ims >= $mtime) {
            $c->log->debug($req->uri . ' not modified');
            $resp->status(304);
            return;
        }
    }

    # set this *after* we test for 304
    $rhdr->content_length($size) if defined $size;

    # assume something downstream knows what to do with this
    $resp->status(200);
    $resp->body($body);
};

=head1 SEE ALSO

=over 4

=item

L<Catalyst::Action>

=item

L<HTTP::Negotiate>

=item

L<Role::MimeInfo>

=back

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report bugs
L<on GitHub|https://github.com/doriantaylor/p5-catalystx-action-negotiate/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::Action::Negotiate

You can also look for information at:

=over 4

=item * MetaCPAN

L<http://metacpan.org/release/CatalystX-Action-Negotiate/>

=item * The source

L<https://github.com/doriantaylor/p5-catalystx-action-negotiate>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Dorian Taylor.

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

1; # End of CatalystX::Action::Negotiate
