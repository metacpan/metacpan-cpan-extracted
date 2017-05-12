package Daizu::Preview;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
    output_preview
    adjust_preview_links_html adjust_preview_links_css
    adjust_link_for_preview
    script_link
);

use utf8;
use HTML::Parser ();
use URI;
use Daizu::File;
use Daizu::HTML qw(
    html_escape_attr
);
use Daizu::Util qw(
    url_encode
    db_row_exists db_row_id db_select
);

=head1 NAME

Daizu::Preview - functions for generating preview versions of output content

=head1 DESCRIPTION

This code is used by the CGI script C<preview.cgi> to filter output so
that links refer back to the preview.  It is this code which makes it
possible to preview not only an HTML page, but also get preview versions
of all the CSS, images, and linked pages which it references.

=head1 CONSTANTS

=over

=item %PREVIEW_FILTER

A hash mapping MIME types (lowercase) to functions which can filter files
for previewing.  The following functions, defined below, are provided so
far:

=over

=item text/html

L<adjust_preview_links_html()|/adjust_preview_links_html($cms, $wc_id, $base_url, $html, $fh)>

=item text/css

L<adjust_preview_links_css()|/adjust_preview_links_css($cms, $wc_id, $base_url, $css, $fh)>

=back

=cut

our %PREVIEW_FILTER = (
    'text/html' => \&adjust_preview_links_html,
    'application/xhtml+xml' => \&adjust_preview_links_html,
    'text/css' => \&adjust_preview_links_css,
);

# TODO document, and provide some way to configure this.
our %ENABLE_SSI = (
    'text/html' => undef,
    'application/xhtml+xml' => undef,
);

=item %HTML_URL_ATTR

This hash is used to identify attributes in an HTML document which contain
a link which may need to be adjusted to make the preview work (so that for
example links to other pages or to embedded images are pointed at the
preview versions rather than ones on the live site).

Each key is the name of an element and the name of one of its attributes,
in lowercase and separated by a colon.  The values are either C<uri> if
the attribute is expected to contain a single URI, or C<uri-list> if it
might contain a whitespace-separated list of URIs.

This is derived from the HTML 4.01 specification, with a few additional values
to support non-standard or obsolete elements and attributes.

Note: this information is provided here, rather than using
L<%HTML::Tagset::linkElements|HTML::Tagset/hash %HTML::Tagset::linkElements>
because that doesn't have enough information.  It doesn't distinguish base
URIs (which we don't want to change) and it doesn't note whether there can be
multiple URIs in an attribute.

The C<profile> attribute (on the C<head> element) isn't included because
the spec says it can be used either as a globally unique ID or as a
dereferencable link, so we have to assume that it's already available at
the URL.  That's fine, because nobody ever uses it.

The C<usemap> element is a URI, but isn't included because it has to
point to a C<map> element inside the document.

TODO - implement using 'codebase' attribute as base URL.

TODO - if using the value of applet:codebase it must be validated to make
sure it's a subdirectory of the directory that would contain the current
document, for security reasons.  See:
L<http://www.w3.org/TR/html4/struct/objects.html#adef-codebase-APPLET>

=cut

our %HTML_URL_ATTR = (
    'a:href' => 'uri',
    'applet:archive' => 'uri-list',     # relative to applet:codebase
    'applet:code' => 'uri',             # relative to applet:codebase
    'applet:object' => 'uri',           # relative to applet:codebase
    'area:href' => 'uri',
    'blockquote:cite' => 'uri',
    'body:background' => 'uri',
    'del:cite' => 'uri',
    'form:action' => 'uri',
    'frame:longdesc' => 'uri',
    'frame:src' => 'uri',
    'iframe:longdesc' => 'uri',
    'iframe:src' => 'uri',
    'img:longdesc' => 'uri',
    'img:src' => 'uri',
    'input:src' => 'uri',
    'ins:cite' => 'uri',
    'link:href' => 'uri',
    'object:codebase' => 'uri',
    'object:archive' => 'uri-list',     # relative to object:codebase
    'object:classid' => 'uri',          # relative to object:codebase
    'object:data' => 'uri',             # relative to object:codebase
    'q:cite' => 'uri',
    'script:src' => 'uri',

    # These aren't defined in HTML 4.01, but were added from HTML::Tagset
    # for compatability with other HTML.
    'bgsound:src' => 'uri',
    'embed:pluginspage' => 'uri',
    'embed:src' => 'uri',
    'ilayer:background' => 'uri',
    'img:lowsrc' => 'uri',
    'isindex:action' => 'uri',
    'layer:background' => 'uri',
    'layer:src' => 'uri',
    #'script:for' => 'uri',             # XXX - what's this mean?
    'table:background' => 'uri',
    'td:background' => 'uri',
    'th:background' => 'uri',
    'tr:background' => 'uri',
    'xmp:href' => 'uri',
);

=back

=head1 FUNCTIONS

The following functions are available for export from this module.
None of them are exported by default.

=over

=item output_preview($cms, $url, $file, $generator, $method, $argument, $type, $fh)

Generate the output for C<$file> (a L<Daizu::File> object) which is meant
to be published at C<$url> (a simple string or L<URI> object).
The output will be generated
by calling C<$method> on the C<$generator> object, and using C<$argument>.

The output will sometimes (depending on the expected MIME type given
by C<$type>) be filtered to adjust embedded links so that they point to
preview versions instead of the live site.  Links will be adjusted if they
point to known URLs for the working copy.  Other URLs will be made absolute,
based on C<$url>.

L<%PREVIEW_FILTER|/%PREVIEW_FILTER> is used to determine whether the files
need to be filtered, and which function to use for the filtering.

The finished (possibly filtered) output is printed to C<$fh>.  The file handle
will be adjusted with C<binmode> to expect raw or utf8 output, depending on
whether the content type is a text or binary one.

=cut

sub output_preview
{
    my ($cms, $url, $file, $generator, $method, $argument, $type, $outfh) = @_;
    $url = URI->new($url)
        unless ref $url;
    $type = 'application/octet-stream'
        unless defined $type;

    binmode $outfh or die "binmode error: $!";

    my $preview_function = $PREVIEW_FILTER{$type};
    if ($preview_function) {
        # Write it to memory so that the URLs can be adjusted.
        my $content = '';
        open my $fh, '>', \$content or die $!;
        binmode $fh or die "binmode error: $!";
        my $url_info = {
            generator => ref($generator),
            url => $url,
            method => $method,
            argument => $argument,
            type => $type,
            fh => $fh,
        };
        $generator->$method($file, [ $url_info ]);
        if (defined $url_info->{fh}) {
            close $fh or die $!;
        }

        $preview_function->($cms, $file->{wc_id}, $url, $content, $outfh);
    }
    else {
        # Write it directly to the output without filtering.
        $generator->$method($file, [ {
            url => $url,
            method => $method,
            argument => $argument,
            type => $type,
            fh => $outfh,
        } ]);
    }
}

=item adjust_preview_links_html($cms, $wc_id, $base_url, $html, $fh)

Given a string containing HTML in C<$html>, parse it and adjust any
attributes which are meant to contain URIs to use the correct for of
links for a preview.  The output is written to C<$fh>.

Exactly which attributes are adjusted depends on the contents of
L<%HTML_URL_ATTR|/%HTML_URL_ATTR>.

In addition, inline CSS code in C<style> elements is filtered though
the CSS filtering function described below, so that CSS links are
adjusted as well.

=cut

sub adjust_preview_links_html
{
    my ($cms, $wc_id, $base_url, $html, $fh) = @_;
    $base_url = URI->new($base_url);

    # TODO - SSI processing should be optional, probably off by default.
    # TODO - this should be done in output_preview, for the right MIME types,
    # whether or not there's a preview function for them.
    _process_ssi($cms, $wc_id, $base_url, \$html);

    # When in <style> elements filter CSS to adjust links.
    my $in_style = 0;

    my $parser = HTML::Parser->new(
        api_version => 3,
        start_h => [
            sub { _start_h($cms, $wc_id, $base_url, $fh, \$in_style, @_) },
            'tagname, attr',
        ],
        end_h => [
            sub {
                my ($tagname) = @_;
                --$in_style if $tagname eq 'style';
                print $fh "</$tagname>";
            },
            'tagname',
        ],
        default_h => [
            sub {
                my ($css) = @_;
                if ($in_style) {
                    adjust_preview_links_css($cms, $wc_id, $base_url,
                                             $css, $fh);
                }
                else {
                    print $fh $css;
                }
            },
            'text',
        ],
    );
    $parser->parse($html);
    $parser->eof;
}

sub _start_h
{
    my ($cms, $wc_id, $base_url, $fh, $in_style, $tagname, $attr) = @_;

    ++$$in_style if $tagname eq 'style';

    delete $attr->{'/'};      # to cope with XHTML empty elements

    # The keys are sorted to allow for testing.
    my $attrtext = join ' ', map {
        "$_=\"" . html_escape_attr(exists $HTML_URL_ATTR{"$tagname:$_"}
            ? adjust_link_for_preview($cms, $wc_id, $base_url, $attr->{$_},
                                       $HTML_URL_ATTR{"$tagname:$_"})
            : $attr->{$_}) . '"';
    } sort keys %$attr;

    print $fh ($attrtext ? "<$tagname $attrtext>" : "<$tagname>");
}

sub _process_ssi
{
    my ($cms, $wc_id, $base_url, $html) = @_;
    my $output = '';

    LOOP: {
        # TODO - recognize other SSI directives and signal error
        if ($$html =~ m{\G<!--\#include \s+
                                virtual \s* = \s* ( "[^"]*" |
                                                    '[^']*' |
                                                    `[^`]*` )
                        \s+ -->}cgx)
        {
            my $url = $1;
            $url =~ s/\A"(.*)"\z/$1/ or
                    s/\A'(.*)'\z/$1/ or
                    s/\A`(.*)`\z/$1/;
            $url = URI->new($url);
            $output .= "[SSI error: only path allowed]", redo LOOP
                if $url->scheme;
            $url = $url->abs($base_url);
            my ($type, $fragment) = _load_ssi($cms, $wc_id, $url);
            $output .= "[SSI error: $fragment]", redo LOOP
                unless defined $type;
            _process_ssi($cms, $wc_id, $url, $fragment)
                if exists $ENABLE_SSI{$type};
            $output .= $$fragment;
            redo LOOP;
        }
        elsif ($$html =~ /\G([^<]+)/cg || $$html =~ /\G(.)/cgs) {
            $output .= $1;
            redo LOOP;
        }
    }

    $$html = $output;
}

# Returns either:
#   MIME type and reference to content - if URL is active
#   undef and error string - if URL is not active
sub _load_ssi
{
    my ($cms, $wc_id, $url) = @_;
    my $db = $cms->db;

    my ($guid_id, $gen_class, $method, $argument, $type, $status) =
        db_select($db,
            url => { wc_id => $wc_id, url => $url },
            qw( guid_id generator method argument content_type status ),
        );

    return (undef, 'URL not found in working copy')
        unless defined $guid_id;
    return (undef, 'URL no longer exists')
        if $status eq 'G';
    return (undef, 'URL is a redirect')     # might still work, but warn anyway
        if $status eq 'R';

    my ($file_id) = db_row_id($db, 'wc_file',
        wc_id => $wc_id, guid_id => $guid_id,
    );
    return (undef, 'URL marked active, but content no longer available')
        unless defined $file_id;
    my $file = Daizu::File->new($cms, $file_id);

    my $generator = $file->generator;
    die "generator '$gen_class' for '$url' is missing method '$method'\n"
        unless $generator->can($method);

    $type = 'application/octet-stream'  # TODO: should be configured somewhere
        unless defined $type;

    my $data = '';
    open my $fh, '>', \$data
        or die "error creating memory file handle: $!";
    my $url_info = {
        url => $url,
        method => $method,
        argument => $argument,
        type => $type,
        fh => $fh,
    };
    $generator->$method($file, [ $url_info ]);
    if (defined $url_info->{fh}) {
        close $fh or die $!;
    }

    return ($type, \$data);
}

=item adjust_preview_links_css($cms, $wc_id, $base_url, $css, $fh)

Filter CSS (cascading style sheet) code in C<$css> replacing links
with ones which point to the preview (if appropriate) or are absolute.
This means that if your CSS file references background images, or includes
other stylesheets, it will still work while previewing output.

The filtering is done with a simple lexical analyser, which looks for
C<url()> values and C<@import> commands.  It knows enough to skip over
string literals and comments which happen to contain things which might
look like these, but it doesn't make any great effort to understand the
CSS syntax.

=cut

{
    my $S = qr< [\x20\x09\x0D\x0A\x0C] >x;
    my $NL = qr< (?: \x0A | \x0D\x0A | \x0D | \x0C ) >x;
    my $NONASCII = qr< [^\0-\177] >x;

    # A CR/LF pair is treated as a single whitespace character, as per CSS 2.1.
    my $UNICODE = qr< \\ [0-9a-fA-F]{1,6} (?: \x0D\x0A | $S )? >x;
    my $ESCAPE = qr< $UNICODE | \\[^0-9a-fA-F\x0A\x0D\x0C] >x;
    my $COMMENT = qr< /\* [^*]*\*+ (?:[^/][^*]*\*+)* / >x;
    my $STRING = qr<
        " ( (?: [^\x0A\x0D\x0C\\"] | \\$NL | $ESCAPE )* ) "
      | ' ( (?: [^\x0A\x0D\x0C\\'] | \\$NL | $ESCAPE )* ) '
    >x;
    my $URI = qr<
        \burl\( $S* $STRING $S* \)
      | \burl\( $S* ( (?: [!\#\$%&*-~] | $NONASCII | $ESCAPE )* ) $S* \)
    >xi;

    sub adjust_preview_links_css
    {
        my ($cms, $wc_id, $base_url, $css, $fh) = @_;

        LOOP: {
            if ($css =~ m{\G($COMMENT|$STRING|[^uU\@'"/]+)}cogs) {
                print $fh $1;
                redo LOOP;
            }
            elsif ($css =~ /\G$URI/cogs) {
                my $url = defined $1 ? $1 :
                          defined $2 ? $2 : $3;
                my $folded_lines = !defined $3;
                $url = _css_unescape_string($url, $folded_lines);
                print $fh 'url(', _css_escape_string(adjust_link_for_preview($cms, $wc_id, $base_url, $url, 'uri')), ')';
                redo LOOP;
            }
            elsif ($css =~ /\G(\@import\s+)$STRING/cogsi) {
                my $before = $1;
                my $url = defined $2 ? $2 : $3;
                $url = _css_unescape_string($url, 1);
                print $fh $before, _css_escape_string(adjust_link_for_preview($cms, $wc_id, $base_url, $url, 'uri'));
                redo LOOP;
            }
            elsif ($css =~ /\G(.)/cogs) {
                print $fh $1;
                redo LOOP;
            }
        }
    }

    sub _css_unescape_string
    {
        my ($s, $folded_lines) = @_;

        $s =~ s/ \\ $NL //gx
            if $folded_lines;
        $s =~ s{ \\ ([0-9a-fA-F]{1,6}) (?: \x0D\x0A | $S )?
                 | \\ ([^0-9a-fA-F\x0A\x0D\x0C]) }
                 {defined $1 ? chr hex $1 : $2}gex;

        return $s;
    }

    sub _css_escape_string
    {
        my ($s) = @_;
        $s =~ s/([\\"'()\s])/\\$1/g;
        $s =~ s/([\x80-\x{10FFFF}])/sprintf '\\%06x ', ord $1/ge;
        return qq{"$s"};
    }
}

=item adjust_link_for_preview($cms, $wc_id, $base_url, $urls, $value_type)

Called by the filtering functions above to adjust a link.

C<$value_type> should be either C<uri> if C<$urls> is expected to contain
a single URI, or C<uri-list> if it might contain a whitespace-separated
list of URIs.

Returns a replacement for the value in C<$urls>, which can be substituted
back into the filtered content.

=cut

sub adjust_link_for_preview
{
    my ($cms, $wc_id, $base_url, $urls, $value_type) = @_;

    my @full_urls;
    for ($value_type eq 'uri-list' ? (split ' ', $urls) : ($urls)) {
        my $url = URI->new($_);
        my $scheme = $url->scheme;
        if (defined $scheme && $scheme !~ /^https?$/i) {
            push @full_urls, $_;
            next;
        }

        my $full_url = $url->abs($base_url);
        my $fragment = $full_url->fragment(undef);
        if (db_row_exists($cms->db, 'url', wc_id => $wc_id, url => $full_url)) {
            $full_url = script_link($cms, $wc_id, url => $full_url);
            $full_url .= "#$fragment" if defined $fragment;
        }
        else {
            $full_url->fragment($fragment);
            $full_url = $full_url->as_string;
        }

        push @full_urls, $full_url;
    }

    return join ' ', @full_urls;
}

=item script_link($cms, $wc_id, %args)

Return a properly encoded URL with query parameters which refers to the
current CGI script (based on the C<SCRIPT_NAME> environment variable).
The keys and values in C<%args> will be given as CGI parameters.

If C<$wc_id> is provided, and there is no C<wc> argument in C<%args>, then
a C<wc> argument may be added automatically.  It's assumed that this argument
will default to the live working copy ID, so it isn't added if C<$wc_id> is
the same as that.

=cut

sub script_link
{
    my ($cms, $wc_id, %args) = @_;

    if (!exists $args{wc} && defined $wc_id && $wc_id != $cms->{live_wc_id}) {
        $args{wc} = $wc_id;
    }

    my $args = join '&',
               map { url_encode($_) . '=' . url_encode($args{$_}) }
               keys %args;

    return $ENV{SCRIPT_NAME} . ($args ? "?$args" : '');
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
