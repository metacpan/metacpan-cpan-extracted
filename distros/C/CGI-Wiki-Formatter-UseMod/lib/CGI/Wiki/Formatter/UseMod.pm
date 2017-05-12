package CGI::Wiki::Formatter::UseMod;

use strict;

use vars qw( $VERSION @_links_found );
$VERSION = '0.18';

use URI::Escape;
use Text::WikiFormat as => 'wikiformat';
use HTML::PullParser;
use URI::Find::Delimited;

=head1 NAME

CGI::Wiki::Formatter::UseMod - UseModWiki-style formatting for CGI::Wiki

=head1 DESCRIPTION

A formatter backend for L<CGI::Wiki> that supports UseMod-style formatting.

=head1 SYNOPSIS

  use CGI::Wiki::Formatter::UseMod;

  # Instantiate - see below for parameter details.
  my $formatter = CGI::Wiki::Formatter::UseMod->new( %config );

  # Format some text.
  my $cooked = $formatter->format($raw);

  # Find out which other nodes that text would link to.
  my @links_to = $formatter->find_internal_links($raw);

=head1 METHODS

=over 4

=item B<new>

  my $formatter = CGI::Wiki::Formatter::UseMod->new(
                 extended_links      => 0, # $FreeLinks
                 implicit_links      => 1, # $WikiLinks
                 force_ucfirst_nodes => 1, # $FreeUpper
                 use_headings        => 1, # $UseHeadings
                 allowed_tags        => [qw(b i)], # defaults to none
                 macros              => {},
                 pass_wiki_to_macros => 0,
                 node_prefix         => 'wiki.pl?',
                 node_suffix         => '',
                 edit_prefix         => 'wiki.pl?action=edit;id=',
                 edit_suffix         => '',
                 munge_urls          => 0,
  );

Parameters will default to the values shown above (apart from
C<allowed_tags>, which defaults to allowing no tags).

=over 4

=item B<Internal links>

C<node_prefix>, C<node_suffix>, C<edit_prefix> and C<edit_suffix>
allow you to control the URLs generated for links to other wiki pages.
So for example with the defaults given above, a link to the Home node
will have the URL C<wiki.pl?Home> and a link to the edit form for the
Home node will have the URL C<wiki.pl?action=edit;id=Home>

(Note that of course the URLs that you wish to have generated will
depend on how your wiki application processes its CGI parameters - you
can't just put random stuff in there and hope it works!)

=item B<Internal links - advanced options>

If you wish to have greater control over the links, you may use the
C<munge_node_name> parameter.  The value of this should be a
subroutine reference.  This sub will be called on each internal link
after all other formatting and munging I<except> URL escaping has been
applied.  It will be passed the node name as its first parameter and
should return a node name.  Note that this will affect the URLs of
internal links, but not the link text.

Example:

  # The formatter munges links so node names are ucfirst.
  # Ensure 'state51' always appears in lower case in node names.
  munge_node_name => sub {
                         my $node_name = shift;
                         $node_name =~ s/State51/state51/g;
                         return $node_name;
                     }

B<Note:> This is I<advanced> usage and you should only do it if you
I<really> know what you're doing.  Consider in particular whether and
how your munged nodes are going to be treated by C<retrieve_node>.

=item B<URL munging>

If you set C<munge_urls> to true, then your URLs will be more
user-friendly, for example

  http://example.com/wiki.cgi?Mailing_List_Managers

rather than

  http://example.com/wiki.cgi?Mailing%20List%20Managers

The former behaviour is the actual UseMod behaviour, but requires a
little fiddling about in your code (see C<node_name_to_node_param>),
so the default is to B<not> munge URLs.

=item B<Macros>

Be aware that macros are processed I<after> filtering out disallowed
HTML tags and I<before> transforming from wiki markup into HTML.  They
are also not called in any particular order.

The keys of macros should be either regexes or strings. The values can
be strings, or, if the corresponding key is a regex, can be coderefs.
The coderef will be called with the first nine substrings captured by
the regex as arguments. I would like to call it with all captured
substrings but apparently this is complicated.

You may wish to have access to the overall wiki object in the subs
defined in your macro.  To do this:

=over

=item *

Pass the wiki object to the C<< ->formatter >> call as described below.

=item *

Pass a true value in the C<pass_wiki_to_macros> parameter when calling
C<< ->new >>.

=back

If you do this, then I<all> coderefs will be called with the wiki object
as the first parameter, followed by the first nine captured substrings
as described above.  Note therefore that setting C<pass_wiki_to_macros>
may cause backwards compatibility issues.

=back

Macro examples:

  # Simple example - substitute a little search box for '@SEARCHBOX'

  macros => {

      '@SEARCHBOX' =>
                qq(<form action="wiki.pl" method="get">
                   <input type="hidden" name="action" value="search">
                   <input type="text" size="20" name="terms">
                   <input type="submit"></form>),
  }

  # More complex example - substitute a list of all nodes in a
  # category for '@INDEX_LINK [[Category Foo]]'

  pass_wiki_to_macros => 1,
  macros              => {
      qr/\@INDEX_LINK\s+\[\[Category\s+([^\]]+)]]/ =>
          sub {
                my ($wiki, $category) = @_;
                my @nodes = $wiki->list_nodes_by_metadata(
                        metadata_type  => "category",
                        metadata_value => $category,
                        ignore_case    => 1,
                );
                my $return = "\n";
                foreach my $node ( @nodes ) {
                    $return .= "* "
                            . $wiki->formatter->format_link(
                                                       wiki => $wiki,
                                                       link => $node,
                                                           )
                            . "\n";
                 }
                 return $return;
               },
  }


=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(@args) or return undef;
    return $self;
}

sub _init {
    my ($self, %args) = @_;

    # Store the parameters or their defaults.
    my %defs = ( extended_links      => 0,
                 implicit_links      => 1,
                 force_ucfirst_nodes => 1,
                 use_headings        => 1,
                 allowed_tags        => [],
                 macros              => {},
                 pass_wiki_to_macros => 0,
                 node_prefix         => 'wiki.pl?',
                 node_suffix         => '',
                 edit_prefix         => 'wiki.pl?action=edit;id=',
                 edit_suffix         => '',
                 munge_urls          => 0,
                 munge_node_name     => undef,
               );

    my %collated = (%defs, %args);
    foreach my $k (keys %defs) {
        $self->{"_".$k} = $collated{$k};
    }
    return $self;
}

=item B<format>

  my $html = $formatter->format($submitted_content, $wiki);

Escapes any tags which weren't specified as allowed on creation, then
interpolates any macros, then translates the raw Wiki language
supplied into HTML.

A L<CGI::Wiki> object can be supplied as an optional second parameter.
This object will be used to determine whether a linked-to node exists
or not, and alter the presentation of the link accordingly. This is
only really in here for use when this method is being called from
within L<CGI::Wiki>.

=cut

sub format {
    my ($self, $raw, $wiki) = @_;
    $raw =~ s/\r\n/\n/sg; # CGI newline is \r\n not \n
    my $safe = "";

    my %allowed = map {lc($_) => 1, "/".lc($_) => 1} @{$self->{_allowed_tags}};

    # Parse the HTML - even if we're not allowing any tags, because we're
    # using a custom escaping routine rather than CGI.pm
    my $parser = HTML::PullParser->new(doc   => $raw,
                                       start => '"TAG", tag, text',
                                       end   => '"TAG", tag, text',
                                       text  => '"TEXT", tag, text');
    while (my $token = $parser->get_token) {
        my ($flag, $tag, $text) = @$token;
        if ($flag eq "TAG" and !defined $allowed{lc($tag)}) {
            $safe .= $self->_escape_HTML($text);
        } else {
            $safe .= $text;
        }
    }

    # Now do any inline links.
    my $callback = sub {
        my ($open, $close, $url, $title, $whitespace) = @_;
        $title ||= $url;
        if ( $open && $close ) {
            return $self->make_external_link( title => $title, url => $url );
        } else {
            return $open
                   . $self->make_external_link( title => $title, url => $url )
                   . $close;
        }
    };
 
    my $finder = URI::Find::Delimited->new( ignore_quoted => 1, callback => $callback );
    $finder->find(\$safe);

    # Now process any macros.
    my %macros = %{$self->{_macros}};
    foreach my $key (keys %macros) {
        my $value = $macros{$key};
        if ( ref $value && ref $value eq 'CODE' ) {
	    if ( $self->{_pass_wiki_to_macros} and $wiki ) {
                $safe=~ s/$key/$value->($wiki, $1, $2, $3, $4, $5, $6, $7, $8, $9)/eg;
            } else {
                $safe=~ s/$key/$value->($1, $2, $3, $4, $5, $6, $7, $8, $9)/eg;
            }
        } else {
          $safe =~ s/$key/$value/g;
        }
    }

    # Finally set up config and call Text::WikiFormat.
    my %format_opts = $self->_format_opts;
    my %format_tags = (
        # chromatic made most of the regex below.  I will document it when
        # I understand it properly.
        indent   => qr/^(?:\t+|\s{4,}|\s*\*?(?=\**\*+))/,
        newline => "", # avoid bogus <br />
        paragraph       => [ "<p>", "</p>\n", "", "\n", 1 ], # no bogus <br />
        extended_link_delimiters => [ '[[', ']]' ],
        blocks                   => {
                         ordered         => qr/^\s*([\d]+)\.\s*/,
                         unordered       => qr/^\s*\*\s*/,
                         definition      => qr/^:\s*/,
                         pre             => qr/^\s+/,
                         table           => qr/^\|\|/,
                                    },
        definition               => [ "<dl>\n", "</dl>\n", "<dd>&nbsp;", "</dd>\n" ],
        pre                      => [ "<pre>\n", "</pre>\n", "", "\n" ],
        table                    => [ qq|<table class="user_table">\n|, "</table>\n",
                                       sub {
                                           my $line = shift;
                                           $line =~ s/\|\|$/<\/td>/;
                                           $line =~ s/\|\|/<\/td><td>/g;
                                           return ("<tr>","<td>$line","</tr>");
                                       },
                                    ],
        # we don't label unordered lists as "not indented" so we can nest them.
        indented   => {
                        definition => 0,
                        ordered    => 0,
                        pre        => 0,
                        table      => 0,
                       }, 
        blockorder => [ qw( header line ordered unordered code definition pre table paragraph )],
        nests      => { map { $_ => 1} qw( ordered unordered ) },
        link => sub {
                      my $link = shift;
                      return $self->format_link(
                                                 link => $link,
                                                 wiki => $wiki,
                                               );
        },
    );

    return wikiformat($safe, \%format_tags, \%format_opts );
}

sub _format_opts {
    my $self = shift;
    return (
             extended       => $self->{_extended_links},
             prefix         => $self->{_node_prefix},
             implicit_links => $self->{_implicit_links}
           );
}

=item B<format_link>

  my $string = $formatter->format_link(
                                        link => "Home Node",
                                        wiki => $wiki,
                                      );

An internal method exposed to make it easy to go from eg

  * Foo
  * Bar

to

  * <a href="index.cgi?Foo">Foo</a>
  * <a href="index.cgi?Bar">Bar</a>

See Macro Examples above for why you might find this useful.

C<link> should be something that would go inside your extended link
delimiters.  C<wiki> is optional but should be a L<CGI::Wiki> object.
If you do supply C<wiki> then the method will be able to check whether
the node exists yet or not and so will call C<< ->make_edit_link >>
instead of C<< ->make_internal_link >> where appropriate.  If you don't
supply C<wiki> then C<< ->make_internal_link >> will be called always.

This method used to be private so may do unexpected things if you use
it in a way that I haven't tested yet.

=cut

sub format_link {
    my ($self, %args) = @_;
    my $link = $args{link};
    my %opts = $self->_format_opts;
    my $wiki = $args{wiki};

    my $title;
    ($link, $title) = split(/\|/, $link, 2) if $opts{extended};
    $title =~ s/^\s*// if $title; # strip leading whitespace
    $title ||= $link;

    if ( $self->{_force_ucfirst_nodes} ) {
        $link = $self->_do_freeupper($link);
    }
    $link = $self->_munge_spaces($link);

    $link = $self->{_munge_node_name}($link)
        if $self->{_munge_node_name};

    my $editlink_not_link = 0;
    # See whether the linked-to node exists, if we can.
    if ( $wiki && !$wiki->node_exists( $link ) ) {
        $editlink_not_link = 1;
    }

    $link =~ s/ /_/g if $self->{_munge_urls};
    $link = uri_escape( $link );

    if ( $editlink_not_link ) {
        my $prefix = $self->{_edit_prefix};
        my $suffix = $self->{_edit_suffix};
        return $self->make_edit_link(
                                      title => $title,
                                      url   => $prefix.$link.$suffix,
                                    );
    } else {
        my $prefix = $self->{_node_prefix};
        my $suffix = $self->{_node_suffix};
        return $self->make_internal_link(
                                          title => $title,
                                          url   => $prefix.$link.$suffix,
                                        );
    }
}

# CGI.pm is sometimes awkward about actually performing CGI::escapeHTML
# if there's a previous instantiation - in the calling script, for example.
# So just do it here.
sub _escape_HTML {
    my ($self, $text) = @_;
    $text =~ s{&}{&amp;}gso;
    $text =~ s{<}{&lt;}gso;
    $text =~ s{>}{&gt;}gso;
    $text =~ s{"}{&quot;}gso;
    return $text;
}

=item B<find_internal_links> 
 
  my @links_to = $formatter->find_internal_links( $content ); 
 
Returns a list of all nodes that the supplied content links to. 
 
=cut 
 
sub find_internal_links { 
    my ($self, $raw) = @_;
 
    @_links_found = (); 
 
    my %format_opts = $self->_format_opts;

    my %format_tags = ( extended_link_delimiters => [ '[[', ']]' ],
                        link => sub {
                            my $link = shift;
                            my %opts = $self->_format_opts;
                            my $title;
                            ($link, $title) = split(/\|/, $link, 2)
                              if $opts{extended};
                            if ( $self->{_force_ucfirst_nodes} ) {
                                $link = $self->_do_freeupper($link);
                            }
                            $link = $self->{_munge_node_name}($link)
                              if $self->{_munge_node_name};
                            $link = $self->_munge_spaces($link);
                            push @CGI::Wiki::Formatter::UseMod::_links_found,
                                                                         $link;
                            return ""; # don't care about output
                                     }
    );

    my $foo = wikiformat($raw, \%format_tags, \%format_opts);

    my @links = @_links_found;
    @_links_found = ();
    return @links;
}


=item B<node_name_to_node_param>

  use URI::Escape;
  $param = $formatter->node_name_to_node_param( "Recent Changes" );
  my $url = "wiki.pl?" . uri_escape($param);

In usemod, the node name is encoded prior to being used as part of the
URL. This method does this encoding (essentially, whitespace is munged
into underscores). In addition, if C<force_ucfirst_nodes> is in action
then the node names will be forced ucfirst if they weren't already.

Note that unless C<munge_urls> was set to true when C<new> was called,
this method will do nothing.

=cut

sub node_name_to_node_param {
    my ($self, $node_name) = @_;
    return $node_name unless $self->{_munge_urls};
    my $param = $node_name;
    $param = $self->_munge_spaces($param);
    $param = $self->_do_freeupper($param) if $self->{_force_ucfirst_nodes};
    $param =~ s/ /_/g;

    return $param;
}

=item B<node_param_to_node_name>

  my $node = $q->param('node') || "";
  $node = $formatter->node_param_to_node_name( $node );

In usemod, the node name is encoded prior to being used as part of the
URL, so we must decode it before we can get back the original node name.

Note that unless C<munge_urls> was set to true when C<new> was called,
this method will do nothing.

=cut

sub node_param_to_node_name {
    my ($self, $param) = @_;
    return $param unless $self->{_munge_urls};

    # Note that this might not give us back exactly what we started with,
    # since in the encoding we collapse and trim whitespace; but this is
    # how usemod does it (as of 0.92) and usemod is what we're emulating.
    $param =~ s/_/ /g;

    return $param;
}

sub _do_freeupper {
    my ($self, $node) = @_;

    # This is the FreeUpper usemod behaviour, slightly modified from
    # their regexp, as we need to do it before we check whether the
    # node exists ie before we substitute the spaces with underscores.
    $node = ucfirst($node);
    $node =~ s|([- _.,\(\)/])([a-z])|$1.uc($2)|ge;

    return $node;
}

sub _munge_spaces {
    my ($self, $node) = @_;

    # Yes, we really do only munge spaces, not all whitespace. This is
    # how usemod does it (as of 0.92).
    $node =~ s/ +/ /g;
    $node =~ s/^ //;
    $node =~ s/ $//;

    return $node
}

=head1 SUBCLASSING

The following methods can be overridden to provide custom behaviour.

=over

=item B<make_edit_link>

    my $link = $self->make_edit_link(
        title => "Home Page",
        url   => "http://example.com/?id=Home",
                                   );

This method will be passed a title and a url and should return an HTML
snippet.  For example, you can add a C<title> attribute to the link
like so:

  sub make_edit_link {
      my ($self, %args) = @_;
      my $title = $args{title};
      my $url = $args{url};
      return qq|[$title]<a href="$url" title="create">?</a>|;
  }

=cut

sub make_edit_link {
    my ($self, %args) = @_;
    return qq|[$args{title}]<a href="$args{url}">?</a>|;
}

=item B<make_internal_link>

    my $link = $self->make_internal_link(
        title => "Home Page",
        url   => "http://example.com/?id=Home",
                                        );

This method will be passed a title and a url and should return an HTML
snippet.  For example, you can add a C<class> attribute to the link
like so:

  sub make_internal_link {
      my ($self, %args) = @_;
      my $title = $args{title};
      my $url = $args{url};
      return qq|<a href="$url" class="internal">$title</a>|;
  }

=cut

sub make_internal_link {
    my ($self, %args) = @_;
    return qq|<a href="$args{url}">$args{title}</a>|;
}

=item B<make_external_link>

    my $link = $self->make_external_link(
        title => "London Perlmongers",
        url   => "http://london.pm.org",
                                        );

This method will be passed a title and a url and should return an HTML
snippet.  For example, you can add a little icon after each external
link like so:

  sub make_external_link {
      my ($self, %args) = @_;
      my $title = $args{title};
      my $url = $args{url};
      return qq|<a href="$url">$title</a> <img src="external.gif">|;
  }

=cut

sub make_external_link {
    my ($self, %args) = @_;
    my ($open, $close) = ( "[", "]" );
    if ( $args{title} eq $args{url} ) {
        ($open, $close) = ( "", "" );
    }
    return qq|$open<a href="$args{url}">$args{title}</a>$close|;
}

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003-2004 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

The OpenGuides London team (L<http://openguides.org/london/>) sent
some very helpful bug reports. A lot of the work of this module is
done within chromatic's module, L<Text::WikiFormat>.

=head1 CAVEATS

This doesn't yet support all of UseMod's formatting features and
options, by any means.  This really truly I<is> a 0.* release. Please
send bug reports, omissions, patches, and stuff, to me at
C<kake@earth.li>.

=head1 NOTE ON USEMOD COMPATIBILITY

UseModWiki "encodes" node names before making them part of a URL, so
for example a node about Wombat Defenestration will have a URL like

  http://example.com/wiki.cgi?Wombat_Defenestration

So if we want to emulate a UseModWiki exactly, we need to munge back
and forth between node names as titles, and node names as CGI params.

  my $formatter = CGI::Wiki::Formatter::UseMod->new( munge_urls => 1 );
  my $node_param = $q->param('id') || $q->param('keywords') || "";
  my $node_name = $formatter->node_param_to_node_name( $node_param );

  use URI::Escape;
  my $url = "http://example.com/wiki.cgi?"
    . uri_escape(
       $formatter->node_name_to_node_param( "Wombat Defenestration" )
                 );

=head1 SEE ALSO

=over 4

=item * L<CGI::Wiki>

=item * L<Text::WikiFormat>

=item * UseModWiki (L<http://www.usemod.com/cgi-bin/wiki.pl>)

=back

=cut

1;
