# Generate page components from a spin .sitemap file.
#
# The top of a web site source tree for use with spin may contain a .sitemap
# file.  This lists all the pages of the site and their relative structure,
# which is used to generate navigation links in both the HTML header and
# surrounding the page.  This module parses that file and generates the data
# that it controls.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Spin::Sitemap 6.01;

use 5.024;
use autodie;
use warnings;

use List::SomeUtils qw(pairwise);

##############################################################################
# File parsing
##############################################################################

# Read the sitemap data and populate the internal data structures.
#
# The format of the sitemap file is one line per web page, with indentation
# showing the tree structure, and with each line formatted as a partial URL, a
# colon, and a page description.  If two pages at the same level aren't
# related, a line with three dashes should be put between them at the same
# indentation level.
#
# $path - Path to the .sitemap file
#
# Raises: autodie exception on file read errors
#         Text exception on file parsing errors
sub _read_data {
    my ($self, $path) = @_;
    my %seen;

    # @indents holds a stack of indentation levels to detect indentation
    # changes that translate into page structure.  Each element in the stack
    # is an anonymous array of three elements: the indentation level, the
    # parent URL for that level of indentation, and the previous page at that
    # level of indentation.
    my @indents;

    # Parse the file.
    open(my $fh, '<', $path);
    while (defined(my $line = <$fh>)) {
        next if $line =~ m{ \A \s* \# }xms;
        chomp($line);

        # Break a prev/next chain at --- lines.
        if ($line =~ m{ \A ([ ]*) --- \z }xms) {
            my $indent = length($1);
            while (@indents && $indents[-1]->[0] > $indent) {
                pop(@indents);
            }
            if (@indents) {
                $indents[-1]->[2] = undef;
            }
            next;
        }

        # Regular line.  Parse it.
        my ($spaces, $url, $desc)
          = $line =~ m{ \A ([ ]*) ([^\s:]+): \s+ (.+) \z}xms;
        if (!defined($desc)) {
            die "invalid line $. in $path\n";
        }

        # Error on duplicate lines.
        if ($seen{$url}) {
            die "duplicate entry for $url in $path (line $.)\n";
        }
        $seen{$url} = 1;

        # Open or close indentation levels.
        my $indent = length($spaces);
        if (!@indents || $indent > $indents[-1]->[0]) {
            my $prev = @indents ? $indents[-1]->[2] : undef;
            push(@indents, [$indent, $prev, undef]);
        } else {
            while ($indents[-1]->[0] > $indent) {
                pop(@indents);
            }
        }

        # Store this page information in the object.
        $self->{pagedesc}{$url} = $desc;
        push($self->{sitemap}->@*, [$indent, $url, $desc]);

        # Create the links.  Gather all of the parent links to create the
        # links for this page, set this as the next URL of the previous URL if
        # any, and indicate that this page should be the previous page for the
        # next page on the same level.
        my @parents = map { $_->[1] } @indents;
        shift(@parents);
        $self->{links}{$url} = [$indents[-1]->[2], undef, reverse(@parents)];
        if (defined($indents[-1]->[2])) {
            $self->{links}{ $indents[-1]->[2] }[1] = $url;
        }
        $indents[-1]->[2] = $url;
    }
    close($fh);
    return;
}

##############################################################################
# Utility methods
##############################################################################

# Escape a page description so that it can be put in HTML output.
#
# $desc    - The string to escape
# $is_attr - If true, escape for putting in an HTML attribute
#
# Returns: $desc escaped so that it's safe to interpolate into an attribute
sub _escape {
    my ($desc, $is_attr) = @_;
    $desc =~ s{ &  }{&amp;}xmsg;
    $desc =~ s{ <  }{&lt;}xmsg;
    $desc =~ s{ >  }{&gt;}xmsg;
    if ($is_attr) {
        $desc =~ s{ \" }{&quot;}xmsg;
    }
    return $desc;
}

# Given the partial URL (relative to the top of the site) to the current page
# and the partial URL to another page, generate a URL to the second page
# relative to the first.
#
# $origin - The current page
# $dest   - A partial URL of another page
#
# Returns: A relative link from $origin to $dest
sub _relative {
    my ($origin, $dest) = @_;
    my @origin = split(qr{ / }xms, $origin, -1);
    my @dest = split(qr{ / }xms, $dest, -1);

    # Remove the common prefix.
    while (@origin && @dest && $origin[0] eq $dest[0]) {
        shift(@origin);
        shift(@dest);
    }

    # If there are the same number of components in both links, the link
    # should be relative to the current directory.  Otherwise, ascend to the
    # common prefix and then descend to the dest link.
    if (@origin == 1 && @dest == 1) {
        return length($dest[0]) > 0 ? $dest[0] : q{./};
    } else {
        return ('../' x $#origin) . join(q{/}, @dest);
    }
}

# Return the link data for a given page.
#
# $path - Path to the output, relative to the top of the web site
#
# Returns: List of links, each of which is a tuple of the relative URL and
#          the description (escaped for safe interpolation as an attribute).
#          The relative URL and description may be undef if missing.
sub _page_links {
    my ($self, $path) = @_;
    $path =~ s{ /index[.]html \z }{/}xms;

    # If the page is not present in the sitemap, return nothing.  There are
    # also no meaningful links to generate for the top page.
    return () if ($path eq q{/} || !$self->{links}{$path});

    # Convert all the links to relative and add the page descriptions.
    return
      map { defined ? [_relative($path, $_), $self->{pagedesc}{$_}] : undef }
      $self->{links}{$path}->@*;
}

##############################################################################
# Public interface
##############################################################################

# Parse a .versions file into a new App::DocKnot::Spin::Sitemap object.
#
# $path - Path to the .sitemap file
#
# Returns: Newly created object
#  Throws: Text exception on failure to parse the file
#          autodie exception on failure to read the file
sub new {
    my ($class, $path) = @_;

    # Create an empty object.
    #
    # sitemap is an array of anonymous arrays holding the complete site map.
    # Each element represents a page.  The element will contain three
    # elements: the numeric indent level, the partial output URL, and the
    # description.
    #
    # pagedesc maps partial URLs to page descriptions used for links to that
    # page.
    #
    # links maps partial URLs to a list of other partial URLs (previous, next,
    # and then the full upwards hierarchy to the top of the site) used for
    # interpage links.
    #<<<
    my $self = {
        links    => {},
        pagedesc => {},
        sitemap  => [],
    };
    #>>>
    bless($self, $class);

    # Parse the file into the newly-created object.
    $self->_read_data($path);

    # Return the populated object.
    return $self;
}

# Return the <link> tags for a given output file, suitable for its <head>
# section.
#
# $path - URL path to the output with leading slash
#
# Returns: List of lines to add to the <head> section
sub links {
    my ($self, $path) = @_;
    my @links = $self->_page_links($path);
    return () if !@links;

    # We only care about the first parent, not the rest of the chain to the
    # top of the site.  Add the names of the link types.
    my @types = qw(previous next up);
    @links = @links[0 .. 2];
    @links = pairwise { defined($b) ? [$a, $b->@*] : undef } @types, @links;

    # Generate the HTML for those links.
    my @output;
    for my $link (@links) {
        next unless defined($link);
        my ($type, $url, $desc) = $link->@*;
        $desc = _escape($desc, 1);

        # Break the line if it would be longer than 79 characters.
        my $line = qq{  <link rel="$type" href="$url"};
        if (length($line) + length($desc) + 12 > 79) {
            push(@output, $line . "\n");
            $line = (q{ } x 8) . qq{title="$desc"};
        } else {
            $line .= qq{ title="$desc"};
        }
        push(@output, $line . " />\n");
    }

    # Add the link to the top-level page.
    my $url = _relative($path, q{/});
    push(@output, qq{  <link rel="top" href="$url" />\n});

    # Return the results.
    return @output;
}

# Return the navigation bar for a given output file.
#
# $path - URL path to the output with leading slash
#
# Returns: List of lines that create the navbar
sub navbar {
    my ($self, $path) = @_;
    my ($prev, $next, @parents) = $self->_page_links($path);
    return () if !@parents;

    # Construct the left and right links (previous and next).
    my $prev_link = q{  <td class="navleft">};
    if (defined($prev)) {
        my ($url, $desc) = $prev->@*;
        $desc = _escape($desc);
        $prev_link .= qq{&lt;&nbsp;<a href="$url">$desc</a>};
    }
    $prev_link .= "</td>\n";
    my $next_link = q{  <td class="navright">};
    if (defined($next)) {
        my ($url, $desc) = $next->@*;
        $desc = _escape($desc);
        $next_link .= qq{<a href="$url">$desc</a>&nbsp;&gt;};
    }
    $next_link .= "</td>\n";

    # Construct the bread crumbs for the page hierarchy.
    my @breadcrumbs = ("  <td>\n");
    my $first = 1;
    for my $parent (reverse(@parents)) {
        my ($url, $desc) = $parent->@*;
        my $prefix = q{ } x 4;
        if ($first) {
            $first = 0;
        } else {
            $prefix .= '&gt; ';
        }
        push(@breadcrumbs, $prefix . qq{<a href="$url">$desc</a>\n});
    }
    push(@breadcrumbs, "  </td>\n");

    # Generate the HTML for the navbar.
    return (
        qq{<table class="navbar"><tr>\n},
        $prev_link,
        @breadcrumbs,
        $next_link,
        "</tr></table>\n",
    );
}

# Return the sitemap formatted as HTML.  The resulting HTML will only be valid
# from a page at the top of the output tree due to the relative links.
#
# Returns: List of lines presenting the sitemap in HTML
sub sitemap {
    my ($self) = @_;
    my @output;
    my @indents = (0);

    # Build the sitemap as nested unordered lists.
    for my $page ($self->{sitemap}->@*) {
        my ($indent, $url, $desc) = $page->@*;
        $url =~ s{ \A / }{}xms;

        # Skip the top page.
        next if $indent == 0;

        # Open or close <ul> elements as needed by the indentation.
        if ($indent > $indents[-1]) {
            push(@output, (q{ } x $indent) . "<ul>\n");
            push(@indents, $indent);
        } else {
            while ($indent < $indents[-1]) {
                push(@output, (q{ } x $indents[-1]) . "</ul>\n");
                pop(@indents);
            }
        }

        # Add the <li> for this page.
        my $spaces = q{ } x $indent;
        push(@output, $spaces . qq(<li><a href="$url">$desc</a></li>\n));
    }

    # Close the remaining open <ul> tags.
    for my $indent (reverse(@indents)) {
        last if $indent == 0;
        push(@output, (q{ } x $indent) . "</ul>\n");
    }

    # Return the results.
    return @output;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense

=head1 NAME

App::DocKnot::Spin::Sitemap - Generate page navigation links for spin

=head1 SYNOPSIS

    use App::DocKnot::Spin::Sitemap;
    my $sitemap = App::DocKnot::Spin::Sitemap->new('/path/to/.sitemap');
    my @links = $sitemap->links('some/output/page.html');
    my @navbar = $sitemap->navbar('some/output/page.html');

=head1 REQUIREMENTS

Perl 5.24 or later and List::SomeUtils, which is available from CPAN.

=head1 DESCRIPTION

App::DocKnot::Spin supports sitemap information stored in a C<.sitemap> file
at the top of the source directory.  If this is present, it is used to add
navigation information to every generated page.

App::DocKnot::Spin::Sitemap encapsulates parsing of that file and generating
the HTML for inter-page links.  It can also generate HTML for the entirety of
the sitemap to support the C<\sitemap> thread command.

The format of this file is one line per web page, with indentation showing the
tree structure.  Each line should be formatted as a partial URL (relative to
the top of the site) starting with C</>, a colon, and a page description.  The
partial URL should be for the generated pages, not the source files (so, for
example, should use an C<.html> extension).  The top of the generated site
should have the URL of C</> at the top of the sitemap.

If two pages at the same level aren't related and shouldn't have next and
previous links to each other, they should be separated by three dashes on a
line by themselves at the same indentation level.

Here's an example of a simple F<.sitemap> file:

    /personal/: Personal Information
      /personal/contact.html: Contact Information
      ---
      /personal/projects.html: Current Projects
    /links/: Links
      /links/lit.html: Other Literature
      /links/music.html: Music
      /links/sf.html: Science Fiction and Fantasy

This defines two sub-pages of the top page, C</personal/> and C</links/>.
C</personal/> has two pages under it that are not part of the same set and
therefore shouldn't have links to each other.  C</links/> has three pages
under it which are part of a set and should be linked between each other.

=head1 CLASS METHODS

=over 4

=item new(PATH)

Create a new App::DocKnot::Spin::Sitemap object for the F<.sitemap> file
specified by PATH.

=back

=head1 INSTANCE METHODS

=over 4

=item links(PAGE)

Generate the C<< <link> >> tags for the provided PAGE, which should be a URL
relative to the top of the generated site and starting with C</>.  The return
value is a list of lines to add to the HTML C<< <head> >> section, or an empty
list if the page was not found in the sitemap.

=item navbar(PAGE)

Generate the navigation bar for the provided PAGE, which should be a URL
relative to the top of the generated site and starting with C</>.  The return
value is a list of HTML lines suitable for injecting into the output page.

=item sitemap()

Return the sitemap as a list of lines of formatted HTML, suitable for
inclusion in a generated web page.  This is used to implement the C<\sitemap>
thread command.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2000, 2002-2004, 2008, 2021 Russ Allbery <rra@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<docknot(1)>, L<App::DocKnot::Spin>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
