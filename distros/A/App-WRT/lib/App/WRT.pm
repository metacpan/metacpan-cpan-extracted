package App::WRT;

# From semver.org:
#
#   Given a version number MAJOR.MINOR.PATCH, increment the:
#
#       MAJOR version when you make incompatible API changes,
#       MINOR version when you add functionality in a backwards-compatible
#             manner, and
#       PATCH version when you make backwards-compatible bug fixes.
#
#   Additional labels for pre-release and build metadata are available as
#   extensions to the MAJOR.MINOR.PATCH format.
#
# Honestly I have always found it just about impossible to follow semver
# without overthinking a bunch of hair-splitting decisions and categories,
# but whatever.  I'll try to follow it, roughly.

use version; our $VERSION = version->declare("v8.0.0");

use strict;
use warnings;
no  warnings 'uninitialized';
use 5.14.0;
use utf8;

use open qw(:std :utf8);

use Carp;
use Cwd qw(getcwd abs_path);
use Encode qw(decode encode);
use File::Spec;
use HTML::Entities;
use JSON;
use JSON::Feed;
use Mojo::DOM;
use XML::Atom::SimpleFeed;

use App::WRT::Date qw(iso_date rfc_3339_date get_mtime month_name);
use App::WRT::EntryStore;
use App::WRT::FileIO;
use App::WRT::Filters;
use App::WRT::HTML qw(:all);
use App::WRT::Image qw(image_size);
use App::WRT::Markup qw(line_parse image_markup eval_perl);
use App::WRT::Util qw(dir_list file_get_contents);

=pod

=head1 NAME

App::WRT - WRiting Tool, a static site/blog generator and related utilities

=head1 SYNOPSIS

Using the commandline tools:

    $ mkdir project
    $ cd project
    $ wrt init         # set up some defaults
    $ wrt config       # dump configuration values
    $ wrt ls           # list entries
    $ wrt display new  # print HTML for new entries to stdout
    $ wrt render-all   # publish HTML to project/public/

Using App::WRT in library form:

    #!/usr/bin/env perl

    use App::WRT;
    my $w = App::WRT->new(
      entry_dir => 'archives',
      url_root  => '/',
      # etc.
    );
    print $w->display(@ARGV);

=head1 INSTALLING

It's possible this would run on a Perl as old as 5.14.0.  In practice, I know
that it works under 5.26.2.  It should be fine on any reasonably modern Linux
distribution, and might work on BSD of your choosing.  Maybe even MacOS.  It's
possible that it would run under the Windows Subsystem for Linux, but it would
definitely fail under vanilla Windows; it currently makes too many assumptions
about things like directory path separators and filesystem semantics.

(Although I would like the code to be more robust across platforms, this is not
a problem I feel much urgency about solving at the moment, since I'm pretty
sure I am the only user of this software.  Please let me know if I'm mistaken.)

To install the latest development version from the main repo:

    $ git clone https://code.p1k3.com/gitea/brennen/wrt.git
    $ cd wrt
    $ perl Build.PL
    $ ./Build installdeps
    $ ./Build test
    $ ./Build install

To install the latest version released on CPAN:

    $ cpanm App::WRT

Or:

    $ cpan -i App::WRT

You will likely need to use C<sudo> or C<su> to get a systemwide install.

=head1 DESCRIPTION

This started life somewhere around 2001 as C<display.pl>, a CGI script to
concatenate fragments of handwritten HTML by date.  It has since accumulated
several of the usual weblog features (lightweight markup, feed generation,
embedded Perl, poetry tools, image galleries, and ill-advised dependencies),
but the basic idea hasn't changed that much.

The C<wrt> utility now generates static HTML files, instead of expecting to
run as a CGI script.  This is a better idea, for the most part.

By default, entries are stored in a simple directory tree under C<entry_dir>.

Like:

     archives/2001/1/1
     archives/2001/1/2/index
     archives/2001/1/2/sub_entry

Which will publish files like so:

     public/index.html
     public/all/index.html
     public/2001/index.html
     public/2001/1/index.html
     public/2001/1/1/index.html
     public/2001/1/2/index.html
     public/2001/1/2/sub_entry/index.html

Contents will be generated for each year and for the entire collection of dated
entries.  Month indices will consist of all entries for that month.  A
top-level index file will consist of the most recent month's entries.

An entry may be either a plain UTF-8 text file, or a directory containing
several such files.  If it's a directory, a file named "index" will be treated
as the text of the entry, and all other lower-case filenames without extensions
will be treated as sub-entries or documents within that entry, and displayed
accordingly.  Links to certain other filetypes will be displayed as well.

Directories may be nested to an arbitrary depth, although it's probably not a
good idea to go very deep with the current display logic.

A PNG or JPEG file with a name like

    2001/1/1.icon.png
    2001/1/1/index.icon.png
    2001/1/1/whatever.icon.png
    2001/1/1/whatever/index.icon.png

will be treated as an icon for the corresponding entry file.

=head2 MARKUP

Entries may consist of hand-written HTML (to be passed along without further
mangling), a supported form of lightweight markup, or some combination thereof.

Header tags (<h1>, <h2>, etc.) will be used to display titles in feeds,
navigation, and other places.

Other special markup is indicated by a variety of HTML-like container tags.

B<Embedded Perl> - evaluated and replaced by whatever value you return
(evaluated in a scalar context):

     <perl>my $dog = "Ralph."; return $dog;</perl>

This code is evaluated before any other processing is done, so you can return
any other markup understood by the script and have it handled appropriately.

B<Interpolated variables> - actually keys to the hash underlying the App::WRT
object, for the moment:

     <perl>$self->{title} = "About Ralph, My Dog"; return '';</perl>

     <p>The title is <em>${title}</em>.</p>

This is likely to change at some point, so don't build anything too elaborate
on it.

Embedded code and variables are intended only for use in the F<template> file,
where it's handy to drop in titles or conditionalize aspects of a layout. You
want to be careful with this sort of thing - it's useful in small doses, but
it's also a maintainability nightmare waiting to happen.

B<Includes> - replaced by the contents of the enclosed file path, from the
root of the current wrt project:

    <include>path/to/file</include>

This is a bit constraining, since it doesn't currently allow for files outside
of the current project, but is useful for including HTML generated by some
external script in a page.

B<Several forms of lightweight markup>:

     <markdown>John Gruber's Markdown, by way of
     Text::Markdown::Discount</markdown>

     <textile>Dean Allen's Textile, via Brad Choate's
     Text::Textile.</textile>

     <freeverse>An easy way to
     get properly broken lines
     plus -- em dashes --
     for poetry and such.</freeverse>

B<And a couple of shortcuts>:

     <image>filename.ext
     alt text, if any</image>

     <list>
     one list item

     another list item
     </list>

As it stands, freeverse, image, and list are not particularly robust.  In
practice, image and list have not proven all that useful, and may be deprecated
in a future release.

=head2 TEMPLATES

A single template, specified by the C<template_dir> and C<template> config
values, is used to render all pages.  See F<example/templates/basic> for an
example, or run C<wrt init> in an empty directory and look at
F<templates/default>.

Here's a short example:

    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${title_prefix} - ${title}</title>
    </head>

    <body>
    ${content}
    </body>

    </html>

Within templates, C<${foo}> will be replaced with the corresponding
configuration value.  C<${content}> will always be set to the content of the
current entry.

=head2 CONFIGURATION

Configuration is read from a F<wrt.json> in the directory where the C<wrt>
utility is invoked, or can (usually) be specified with the C<--config> option.

See F<example/wrt.json> for a sample configuration.

Under the hood, configuration is done by combining a hash called C<%default>
with values pulled out of the JSON file.  Most defaults can be overwritten
from the config file, but changing some would require writing Perl, since
they contain things like subroutine references.

=cut

=over

=item %default

Here's a verbatim copy of C<%default>, with some commentary about values.

    my %default = (
      root_dir       => '.',         # dir for wrt repository
      entry_dir      => 'archives',  # dir for entry files
      filter_dir     => 'filters',   # dir to contain filter scripts
      publish_dir    => 'public',    # dir to publish site to
      url_root       => "/",         # root URL for building links
      image_url_root => '',          # same for images
      template_dir   => 'templates', # dir for template files
      template       => 'default',   # template to use
      title          => '',          # current title (used in template)
      title_prefix   => '',          # a string to slap in front of titles
      stylesheet_url => undef,       # path to a CSS file (used in template)
      favicon_url    => undef,       # path to a favicon (used in template)
      feed_alias     => 'feed',      # what entry path should correspond to feed?
      feed_length    => 30,          # how many entries should there be in the feed?
      author         => undef,       # author name (used in template, feed)
      description    => undef,       # site description (used in template)
      content        => undef,       # place to stash content for templates
      default_entry  => 'new',       # what to display if no entry specified
      cache_includes => 0,           # should included files be cached in memory?

      # A license string for site content:
      license        => 'public domain',

      # A string value to replace all pages with (useful for occasional
      # situations where every page of a site should serve some other
      # content in-place, like Net Neutrality protest blackouts):
      overlay        => undef,

      # We'll show links for these, but not display them inline:
      binfile_expr   => qr/[.](tgz|zip|tar[.]gz|gz|txt|pdf)$/,
    );

=cut

my %default = (
  root_dir       => '.',         # dir for wrt repository
  root_dir_abs   => undef,       # for stashing absolute path to wrt repo
  entry_dir      => 'archives',  # dir for entry files
  filter_dir     => 'filters',   # dir to contain filter scripts
  publish_dir    => 'public',    # dir to publish site to
  url_root       => "/",         # root URL for building links
  image_url_root => '',          # same for images
  template_dir   => 'templates', # dir for template files
  template       => 'default',   # template to use
  title          => '',          # current title (used in template)
  title_prefix   => '',          # a string to slap in front of titles
  stylesheet_url => undef,       # path to a CSS file (used in template)
  favicon_url    => undef,       # path to a favicon (used in template)
  feed_alias     => 'feed',      # what entry path should correspond to feed?
  feed_length    => 30,          # how many entries should there be in feed?
  author         => undef,       # author name (used in template, feed)
  description    => undef,       # site description (used in template)
  content        => undef,       # place to stash content for templates
  default_entry  => 'new',       # what to display if no entry specified
  cache_includes => 0,           # should included files be cached in memory?

  # A license string for site content:
  license        => 'public domain',

  # A string value to replace all pages with (useful for occasional
  # situations where every page of a site should serve some other
  # content in-place, like Net Neutrality protest blackouts):
  overlay        => undef,

  # We'll show links for these, but not display them inline:
  binfile_expr   => qr/[.](tgz|zip|tar[.]gz|gz|txt|pdf)$/,
);

=item $default{entry_descriptions}

A hashref which contains a map of entry titles to entry descriptions.

=cut

# TODO: this has gotten more than a little silly.
$default{entry_descriptions} = {
  new => 'newest entries',
  all => 'all entries',
};

=item $default{title_cache}

A hashref which contains a cache of entry titles, populated by the renderer.

=cut

$default{title_cache} = { };

=back

=head2 METHODS AND INTERNALS

For no bigger than this thing is, the internals are convoluted.  (This is
because it's spaghetti code originally written in a now-archaic language by a
teenager who didn't know how to program.)

=over

=item new_from_file($config_file)

Takes a filename to pull JSON config data out of, and returns a new App::WRT
instance with the parameters set in that file.

=cut

sub new_from_file {
  my ($config_file) = @_;

  my $JSON = JSON->new->utf8->pretty;

  # Grab configuration from wrt.json or other file:
  my $config_hashref = $JSON->decode(file_get_contents($config_file));

  # Check for deprecated or removed configuration, and warn accordingly.
  # TODO: These are really user-facing errors, so Carp is probably the wrong
  #       tool for the job here.
  if ( defined $config_hashref->{entry_map} ) {
    carp(
      "Caution: wrt v7.0.0 and later no longer support entry_map.\n"
      . "Please check $config_file and remove this value."
    );
  }
  if ( defined $config_hashref->{embedded_perl} ) {
    carp(
      "Caution: wrt v7.0.0 and later no longer support toggling embedded_perl.\n"
      . "Please check $config_file and remove this value.\n"
      . "Note that embedded Perl may be deprecated in a future release."
    );
  }

  # decode() returns a hashref; this needs to be dereferenced:
  return App::WRT->new(%{ $config_hashref });
}

=item new(%params)

Get a new WRT object with the specified parameters set.

=cut

sub new {
  my $class = shift;
  my %params = @_;

  # Stash absolute path to root directory.
  #
  # TODO: This is bad.  It's here because imgsize() winds up calling getcwd() a
  # ton of times if you don't give it absolute paths, which is actually super
  # inefficient.  See icon_markup() and image_markup() for usage.
  # image_markup() in particular is awful and should be rewritten anyway.
  $params{root_dir_abs} = abs_path($params{root_dir});

  my %copy_of_default = %default;
  my $self = \%copy_of_default;
  bless $self, $class;

  # Configure from passed-in values, overwriting defaults:
  for my $p (keys %params) {
    $self->{$p} = $params{$p};
  }

  # Check and set up template path for later use:
  $self->{template_path} = File::Spec->catfile(
    $self->{template_dir},
    $self->{template}
  );
  unless (-f $self->{template_path}) {
    croak($self->{template_path} . ' does not exist or is not a plain file');
  }
  $self->{template_source} = file_get_contents($self->{template_path});

  $self->{entries} = App::WRT::EntryStore->new( $self->{entry_dir} );
  $self->{filters} = App::WRT::Filters->new( $self->{filter_dir} );

  $self->populate_entry_caches();
  $self->populate_metadata_cache();

  return $self;
}

=item populate_entry_caches()

Render each renderable path, cache the HTML, and parse to extract titles.

=cut

sub populate_entry_caches {
  my $self = shift;

  my %html_cache;
  my %title_cache;

  foreach my $entry ($self->{entries}->all_renderable()) {
    $html_cache{$entry} = $self->handle($entry);
    next unless length $html_cache{$entry};

    my @headers;

    eval {
      local $SIG{__WARN__} = sub { die; };
      my $dom = Mojo::DOM->new($html_cache{$entry});
      @headers = $dom->find('h1, h2, h3, h4, h5, h6')->map('text')->each;
    };
    if ($@) {
      carp("Parsing issues for $entry: $@");
    }
    if (@headers) {
      $title_cache{$entry} = join ' - ', @headers;
    }
  }

  $self->{html_cache} = \%html_cache;
  $self->{title_cache} = \%title_cache;
}

=item populate_metadata_cache()

If there's any metadata, such as tagged relationships, for a given entry,
populate an HTML blob for that stuff.

XXX: Here is where we put the list of pages for a given tag, but also maybe
other things about a page or its properties.  There should be a template /
partial involved.

=cut

sub populate_metadata_cache {
  my $self = shift;

  my %metadata_html_cache;
  foreach my $entry ($self->{entries}->all()) {
    my $result = '';

    my $tag_for_this_entry = 'tag.' . join('.', split('/', $entry));
    my (@tagged_entries) = $self->{entries}->by_prop($tag_for_this_entry);
    my (@alpha_entries, @dated_entries);
    for (@tagged_entries) {
      if (m{^\d}) {
        push @dated_entries, $_;
      } else {
        push @alpha_entries, $_;
      }
    }

    if (@tagged_entries) {
      $result .= "<h1>entries tagged " . encode_entities($entry)
               . "</h1>\n\n<table class=tags>";

      # Things starting with letters first, then things starting with digits:
      foreach my $tagged_entry (@alpha_entries, reverse @dated_entries) {
        $result .= table_row(
          table_cell(
            a($tagged_entry, { href => $self->{url_root} . "$tagged_entry" })
          ),
          table_cell(
            encode_entities($self->get_title($tagged_entry))
          )
        );
        $result .= "\n";
      }
      $result .= "</table>";
    }

    $metadata_html_cache{$entry} = $result;
  }

  $self->{metadata_html_cache} = \%metadata_html_cache;
}

=item display($entry1, $entry2, ...)

Return a string containing the given entries, which are in the form of
date/entry strings. If no parameters are given, default to C<default_entry>.

display() expands aliases ("new" and "all", for example) as necessary, collects
entry content and metadata from the pre-rendered HTML caches, and wraps
everything up in the template.

If C<overlay> is set, will return the value of overlay regardless of options.
(This is useful for hackily replacing every page in a site with a single blob
of HTML, for example if you're participating in some sort of blackout or
something.)

=cut

sub display {
  my $self = shift;
  my (@entries) = @_;

  return $self->{overlay} if defined $self->{overlay};

  # If no entries are defined, either...
  if ($self->{entries}->is_extant('index')) {
    # Fall back to the existing index file:
    $entries[0] = 'index';
  } else {
    # Or use the default:
    $entries[0] //= $self->{default_entry};
  }

  # Title and navigation for template:
  $self->{page_navigation} = '';
  $self->{title} = join ' ', map { encode_entities($_) } @entries;

  if (scalar @entries == 1) {
    # We've got a single path - it could be an alias that'll expand, or it
    # could be an individual entry.  See what can be done with navigation
    # and title:
    $self->{page_navigation} = $self->page_navigation($entries[0]);
    $self->{title} = encode_entities($self->get_title($entries[0]));
  }

  # Expand on any aliases:
  @entries = map { $self->expand_alias($_) } @entries;

  # To be accessed as ${content} in the template below:
  $self->{content} = join '', map {
    $self->{html_cache}{$_}
    . '<div class=entry-metadata>'
    . $self->{metadata_html_cache}{$_}
    . '</div>'
  } @entries;

  # TODO: There may be an optimization to be had below in only running
  # line_parse() against the template when the source is stashed.  This would
  # also lead to confusing weirdness if the template contained any special
  # markup besides an <include> or relied on any side effects of embedded Perl
  # code.  For now, I'm leaving it alone.

  # Evaluate the template much like an entry:
  # Eventually, the eval_perl() call should probably be hoisted up here and
  # only used for templates.
  return $self->line_parse($self->{template_source}, $self->{template_path});
}

=item handle($entry)

Return the text of an individual entry:

  nnnn/[nn/nn/]doc_name - a document within a day.
  nnnn/nn/nn            - a specific day.
  nnnn/nn               - a month.
  nnnn                  - a year.
  doc_name              - a document in the root directory.

=cut

sub handle {
  my ($self, $entry) = @_;

  for ($entry) {
    return entry(@_)                  if $_ eq 'index';
    return entry_stamped(@_, 'index') if m'^ [\d/]+ [[:lower:]_ /]+  $'x;
    return entry_stamped(@_, 'all')   if m'^ \d+ / \d{1,2} / \d{1,2} $'x;
    return month(@_)                  if m'^ \d+ / \d{1,2}           $'x;
    return year(@_)                   if m'^ \d+                     $'x;
    return entry_stamped(@_, 'index') if m'^ [[:lower:]_]             'x;
  }
}

=item expand_alias($option)

Expands/converts 'all', 'new', and 'fulltext' to appropriate values.

Removes trailing slashes.

=cut

sub expand_alias {
  my ($self, $alias) = @_;

  # Take care of trailing slashes:
  chop $alias if $alias =~ m{/$};

  return reverse $self->{entries}->all_years() if $alias eq 'all';
  return $self->{entries}->recent_days(5)      if $alias eq 'new';
  return $self->{entries}->all_days()          if $alias eq 'fulltext';

  # No expansion, just give back our original value:
  return $alias;
}

=item link_bar(@extra_links)

Returns a little context-sensitive navigation bar.

=cut

sub link_bar {
  my $self = shift;
  my (@extra_links) = @_;

  my $output;

  my (%description) = %{ $self->{entry_descriptions} };

  my @linklist = ( qw(new all), @extra_links );

  foreach my $link (@linklist) {
    my $link_title;
    if (exists $description{$link}) {
      $link_title = $description{$link};
    } else {
      $link_title = 'entries for ' . $link;
    }

    my $href = $self->{url_root} . $link . '/';
    if ($link eq 'new') {
      $href = $self->{url_root};
    }
    my $link_html = a({href => $href, title => $link_title}, $link) . "\n";

    if ($self->{title} eq $link) {
      $link_html = qq{<strong>$link_html</strong>};
    }

    $output .= $link_html;
  }

  return $output;
}

=item page_navigation($entry)

Returns context-sensitive page navigation (next / previous links).

=cut

sub page_navigation {
  my ($self) = shift;
  my ($entry) = @_;
  # Handle prev/next links.

  if ($entry eq 'new') {
    return qq{<a href="/all" title="all">&larr; all archives</a>};
  }

  my $output = '';

  my $prev = $self->{entries}->previous($entry);
  my $next = $self->{entries}->next($entry);

  if ($prev) {
    $output .= '<p>previous: <a title="previous" href="'
             . encode_entities($self->{url_root} . $prev)
             . '">'
             . encode_entities($self->get_title($prev))
             . '</a></p> ';
  }

  if ($next) {
    $output .= '<p>next: <a title="next" href="'
             . encode_entities($self->{url_root} . $next)
             . '">'
             . encode_entities($self->get_title($next))
             . '</a></p>';
  }

  return $output;
}

=item year($year)

List out the updates for a year.

=cut

sub year {
  my $self = shift;
  my ($year) = @_;

  # Year is a text file:
  return entry_markup($self->entry($year))
    if $self->{entries}->is_file($year);

  # If it's not a directory, we can't do anything further. Bail out:
  return p('No such year.')
    unless $self->{entries}->is_dir($year);

  my $result;

  # Handle year directories with index files:
  $result .= $self->entry($year)
    if $self->{entries}->has_index($year);

  my $header_text = $self->icon_markup($year, $year);
  $header_text ||= q{};

  $result .= heading("${header_text}${year}", 3);

  my @months = reverse $self->{entries}->months_for($year);

  my $year_text;
  my $count = 0; # explicitly defined for later printing.

  foreach my $month (@months) {
    my $month_text = '';
    my @days = $self->{entries}->days_for($month);
    $count += @days;

    foreach my $day (@days) {
      my ($day_file, $day_url) = $self->root_locations($day);
      $month_text .= a(
        { href => "${day_url}/" },
        $self->{entries}->basename($day)
      ) . "\n";
    }

    $month_text = small("( $month_text )");

    my ($month_file, $month_url) = $self->root_locations($month);
    my $link = a(
      { href => "${month_url}/" },
      month_name($self->{entries}->basename($month))
    );

    $year_text .= table_row(
      table_cell({class => 'datelink'}, $link),
      table_cell({class => 'datelink'}, $month_text)
    ) . "\n\n";
  }

  if ($count > 1) {
    $year_text .= table_row(
      table_cell(scalar(@months) . ' months'),
      table_cell("$count entries")
    );
  }
  elsif ($count == 0) { $year_text .= table_row(table_cell('No entries'));   }
  elsif ($count == 1) { $year_text .= table_row(table_cell("$count entry")); }

  $result .= "\n\n" . table($year_text) . "\n";

  return entry_markup($result);
}

=item month($month)

Prints the entries in a given month (nnnn/nn).

=cut

sub month {
  my ($self, $month) = @_;

  my ($month_file, $month_url) = $self->root_locations($month);

  # If $month is a directory, render those of its children with day-like names:
  if ($self->{entries}->is_dir($month)) {
    my $result;
    $result = $self->entry($month)
      if $self->{entries}->has_index($month);

    my @days = reverse $self->{entries}->days_for($month);

    foreach my $day (@days) {
      $result .= $self->entry_stamped($day);
    }

    return $result;
  } elsif ($self->{entries}->is_file($month)) {
    # If $month is a file, it should just be rendered as a regular entry, more
    # or less:
    return $self->entry($month);
  }
}

=item entry_stamped($entry, $level)

Wraps entry() + a datestamp in entry_markup().

=cut

sub entry_stamped {
  my $self = shift;
  my ($entry, $level) = @_;

  return entry_markup(
    $self->entry($entry, $level)
    . $self->datestamp($entry)
  );
}

=item entry_tag_list($entry)

Get tag links for the entry.

=cut

sub entry_tag_list {
  my $self = shift;
  my ($entry) = @_;

  my @tags = sort grep {
    m/^tag [.] .*/x
  } $self->{entries}->props_for($entry);

  if (@tags) {
    return '<b>tags:</b> ' . join ', ', map {
      s/^tag[.](.*)$/$1/;
      s{[.]}{/}g;
      a(encode_entities($_), { href => $self->{url_root} . $_ })
    } @tags;
  }

  return '';
}

=item entry($entry)

Returns the contents of a given entry.  May recurse, slightly.

=cut

sub entry {
  my ($self, $entry, $level) = @_;
  $level ||= 'index';

  my $result;

  # Display an icon, if we have one:
  if ( my $icon_markup = $self->icon_markup($entry) ) {
    $result = heading($icon_markup, 2) . "\n\n";
  }

  # Note this may be an empty string
  $result .= $self->get_entry_body($entry);

  # For text files we can bail out early:
  if ($self->{entries}->is_file($entry)) {
    return $result;
  }

  # Past this point, we're assuming a directory.

  # Head of entry is followed by any sub-entries:
  my @sub_entries = $self->{entries}->get_sub_entries($entry);

  if (@sub_entries >= 1) {
    if ($level eq 'index' || $self->{entries}->has_prop($entry, 'wrt-noexpand')) {
      # If we're only supposed to show the index, or the wrt-noexpand property
      # is present, then don't expand sub-entries.  A hack.

      # Icons or text links:
      $result .= $self->list_contents($entry, @sub_entries);
    }
    elsif ($level eq 'all') {
      # Everything displayable in the directory:
      foreach my $se (@sub_entries) {
        next if ($se =~ $self->{binfile_expr});

        # Recurse violently:
        $result .= p({class => 'centerpiece'}, '+')
                 . $self->entry("$entry/$se");
      }

      # Handle links to any remaining files that match binfile_expr:
      $result .= $self->list_contents(
        $entry,
        grep { $self->{binfile_expr} } @sub_entries
      );
    }
  }

  return $result;
}

=item get_entry_body($entry)

Returns the markup for an entry's body - which will be either the contents of
the entry if it's a text file, or an index file contained therein if it's a
directory.

Also handles any filters.

=cut

sub get_entry_body {
  my ($self, $entry) = @_;

  # Location of entry on local filesystem, and its URL:
  my ($entry_loc, $entry_url) = $self->root_locations($entry);

  my $path_to_body;

  # For entries which are text files:
  if ($self->{entries}->is_file($entry)) {
    $path_to_body = $entry_loc;
  }

  # For entries which are directories containing an index:
  if ($self->{entries}->has_index($entry)) {
    $path_to_body = "$entry_loc/index";
  }

  # Process filters
  my @filter_list;
  if ($self->{entries}->has_prop($entry, 'filters')) {
    my $filter_prop = $self->{entries}->prop_value($entry, 'filters');
    @filter_list = split("\n", $filter_prop);
  }

  if (defined $path_to_body) {
    my $html = $self->line_parse(
      file_get_contents($path_to_body),
      $path_to_body
    );
    if (scalar @filter_list) {
      return $self->{filters}->dispatch($entry, $html, @filter_list);
    }
    return $html;
  }

  return '';
}

=item list_contents($entry, @entries)

Returns links (maybe with icons) for a set of sub-entries within an entry.

=cut

sub list_contents {
  my $self = shift;
  my ($entry) = shift;
  my (@entries) = @_;

  my $contents;
  foreach my $se (@entries) {
    my $linktext = $self->icon_markup("$entry/$se", $se);
    $linktext ||= $se;

    $contents .= q{ }
              . a({ href  => $self->{url_root} . "$entry/$se",
                    title => $se },
                  $linktext);
  }

  return p( em('more:') . " $contents" ) . "\n";
}

=item get_title($entry)

Returns a title for the entry - potentially a cached one extracted earlier from
the entry's HTML; otherwise just reuse the entry path itself.

=cut

sub get_title {
  my ($self, $entry) = @_;

  # Base title - just the entry path:
  my $title = $entry;

  # Do we have anything in the cache?
  if (defined $self->{title_cache}{$entry}) {
    $title = $self->{title_cache}{$entry};
  }
  return $title;
}

=item icon_markup($entry, $alt)

Check if an icon exists for a given entry if so, return markup to include it.
Icons are PNG or JPEG image files following a specific naming convention:

  index.icon.[png|jp(e)g] for directories
  [filename].icon.[png|jp(e)g] for flat text files

Calls image_size, uses filename to determine type.

=cut

{ my %cache;
sub icon_markup {
  my ($self, $entry, $alt) = @_;

  return $cache{$entry . $alt}
    if defined $cache{$entry . $alt};

  my $icon_basepath;
  if ($self->{entries}->is_file($entry)) {
    $icon_basepath = "$entry.icon";
  }
  elsif ($self->{entries}->is_dir($entry)) {
    $icon_basepath = "$entry/index.icon";
  } else {
    # XXX there are bugs lurking here for virtual entries probably
    return;
  }

  # First suffix found will be used:
  my $suffix;
  for (qw(png jpg gif jpeg)) {
    if ($self->{entries}->is_extant( "$icon_basepath.$_")) {
        $suffix = $_;
        last;
    }
  }

  # Fail unless there's a file with one of the above suffixes:
  return 0 unless $suffix;

  my ($icon_loc, $icon_url) = $self->root_locations($icon_basepath);

  # Slurp width & height from the image file:
  my ($width, $height) = image_size(
    $self->{root_dir_abs} . '/' . "$icon_loc.$suffix"
  );

  return $cache{$entry . $alt} =
      qq{<img src="$icon_url.$suffix"\n width="$width" }
    . qq{height="$height"\n alt="$alt" />};
}
}

=item datestamp($entry)

Returns a nice html datestamp / breadcrumbs for a given entry.

=cut

sub datestamp {
  my $self = shift;
  my ($entry) = @_;

  my @fragment_stack;
  my @fragment_stamps = (
    a({ href => $self->{url_root} }, $self->{title_prefix}),
  );

  # Chop up by directory separator:
  my @pieces = split '/', $entry;

  foreach my $fragment (@pieces) {
    push @fragment_stack, $fragment;
    push @fragment_stamps,
         a({ href => $self->{url_root} . (join '/', @fragment_stack) . '/',
             title => $fragment }, $fragment);
  }

  my $stamp = p({class => 'datestamp'}, join(" /\n", @fragment_stamps));
  my $tag_list = $self->entry_tag_list($entry);
  if ($tag_list) {
    $stamp = "\n" . p({class => 'tags'}, $tag_list) . $stamp;
  }

  return "\n$stamp\n";
}

=item root_locations($file)

Given an entry, return the appropriate concatenations with entry_dir and
url_root.

=cut

sub root_locations {
  return (
    $_[0]->{entry_dir} . '/' . $_[1], # location on filesystem
    $_[0]->{url_root} . $_[1]         # URL
  );
}

=item feed_print_recent($count)

Print $count recent entries, falling back to the configured $feed_length.

=cut

sub feed_print_recent {
  my ($self, $count) = @_;

  $count //= $self->{feed_length};

  return $self->feed_print(
    $self->{entries}->recent_days($count)
  );
}

=item feed_print_json_recent($count)

Print $count recent entries in JSON, falling back to the configured
$feed_length.

=cut

sub feed_print_json_recent {
  my ($self, $count) = @_;

  $count //= $self->{feed_length};

  return $self->feed_print_json(
    $self->{entries}->recent_days($count)
  );
}

=item feed_print(@entries)

Return an Atom feed for the given list of entries.

Requires XML::Atom::SimpleFeed.

XML::Atom::SimpleFeed will give bogus results with input that's just a string
of octets (I think) if it contains characters outside of US-ASCII.  In order to
spit out clean UTF-8 output, we need to use Encode::decode() to flag entry
content as UTF-8 / represent it internally as a string of characters.  There's
a whole lot I don't really understand about how this is handled in Perl, and it
may be a locus of bugs elsewhere in wrt, but for now I'm just dealing with it
here.

Some references on that:

=over

=item * L<https://github.com/ap/XML-Atom-SimpleFeed/issues/2>

=item * L<https://rt.cpan.org/Public/Bug/Display.html?id=19722>

=item * L<https://cpanratings.perl.org/dist/XML-Atom-SimpleFeed>

=item * L<perlunitut>

=back

=cut

sub feed_print {
  my $self = shift;
  my (@entries) = @_;

  my $feed_url = $self->{url_root} . $self->{feed_alias};

  my ($first_entry_file, $first_entry_url) = $self->root_locations($entries[0]);

  my $feed = XML::Atom::SimpleFeed->new(
    -encoding => 'UTF-8',
    title     => $self->{title_prefix} . "::" . $self->{feed_alias},
    subtitle  => $self->{description},
    link      => $self->{url_root},
    link      => { rel => 'self', href => $feed_url, },
    icon      => $self->{favicon_url},
    author    => $self->{author},
    id        => $self->{url_root},
    generator => 'App::WRT.pm / XML::Atom::SimpleFeed',
    updated   => iso_date(get_mtime($first_entry_file)),
  );

  foreach my $entry (@entries) {
    my $content = $self->{html_cache}{$entry};
    if ( $self->{metadata_html_cache}{$entry} ) {
      $content .= '<div class=entry-metadata>'
                . $self->{metadata_html_cache}{$entry}
                . '</div>';
    }

    my ($entry_file, $entry_url) = $self->root_locations($entry);

    $feed->add_entry(
      title   => $self->get_title($entry),
      link    => $entry_url,
      id      => $entry_url,
      content => $content,
      updated => iso_date(get_mtime($entry_file)),
    );
  }

  # Note: This output should be served with
  # Content-type: application/atom+xml
  #
  # I'm not, to be frank, entirely clear on why the decode() call here is
  # necessary:
  return decode('UTF-8', $feed->as_string);
}

=item feed_print_json

Like feed_print(), but for JSON Feed.

L<https://jsonfeed.org/>

=cut

sub feed_print_json {
  my ($self, @entries) = @_;
  my ($first_entry_file, $first_entry_url) = $self->root_locations($entries[0]);

  my $json_feed_url = $self->{url_root} . $self->{feed_alias} . '.json';

  my $user_comment = "This feed allows you to read the posts from this site in"
    . " any feed reader that supports the JSON Feed format. To "
    . "add this feed to your reader, copy the following URL — "
    . "$json_feed_url — and add it your reader.";

  my $feed = JSON::Feed->new(
    user_comment  => $user_comment,
    title         => $self->{title_prefix} . "::" . $self->{feed_alias},
    home_page_url => $self->{url_root},
    feed_url      => $json_feed_url,
    description   => $self->{description},
    author        => +{ name => $self->{author}, },
  );

  if (defined $self->{favicon_url}) {
    $feed->set('favicon', $self->{favicon_url});
  }

  foreach my $entry (@entries) {
    my $content = $self->{html_cache}{$entry};
    if ($self->{metadata_html_cache}{$entry}) {
      $content .= '<div class=entry-metadata>'
                . $self->{metadata_html_cache}{$entry}
                . '</div>';
    }

    my ($entry_file, $entry_url) = $self->root_locations($entry);

    $feed->add_item(
      id             => $entry_url,
      title          => $self->get_title($entry),
      content_html   => $content,
      date_modified  => rfc_3339_date(get_mtime($entry_file)),
      date_published => rfc_3339_date(get_mtime($entry_file)),
    );
  }

  # Output
  return $feed->to_string;
}

=back

=head1 SEE ALSO

walawiki.org, Blosxom, rassmalog, Text::Textile, XML::Atom::SimpleFeed,
Image::Size, and about a gazillion static site generators.

=head1 AUTHOR

Copyright 2001-2022 Brennen Bearnes

=head1 LICENSE

    wrt is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 2 or 3 of the License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
