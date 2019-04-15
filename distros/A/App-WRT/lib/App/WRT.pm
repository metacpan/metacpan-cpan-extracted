package App::WRT;

use version; our $VERSION = version->declare("v5.0.0");

use strict;
use warnings;
no  warnings 'uninitialized';
use 5.10.0;
use utf8;

use Carp;
use Cwd qw(getcwd abs_path);
use Data::Dumper;
use Encode qw(decode encode);
use File::Find;
use File::Spec;
use HTML::Entities;
use JSON;
use XML::Atom::SimpleFeed;

use App::WRT::Date;
use App::WRT::EntryStore;

use App::WRT::HTML     qw(:all);
use App::WRT::Image    qw(image_size);
use App::WRT::Markup   qw(line_parse image_markup eval_perl);
use App::WRT::Renderer qw(render);
use App::WRT::Util     qw(dir_list get_date file_get_contents);

=pod

=head1 NAME

App::WRT - WRiting Tool, a static site/blog generator and related utilities

=for HTML <a href="https://travis-ci.org/brennen/wrt"><img src="https://travis-ci.org/brennen/wrt.svg?branch=master"></a>

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

It's possible but not likely this would run on a Perl as old as 5.10.0.  In
practice, I know that it works under 5.26.2.  It should be fine on any
reasonably modern Linux distribution, and may work on MacOS or a BSD of your
choosing.  It's possible that it would run under the Windows Subsystem for
Linux, but it would definitely fail under vanilla Windows; it currently makes
too many assumptions about things like directory path separators and filesystem
semantics.

(Although I would like the code to be more robust across platforms, this is not
a problem I feel much urgency about solving at the moment, since I'm pretty
sure I am the only user of this software.  Patches would certainly be welcome.)

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

It's possible (although not as flexible as it ought to be) to redefine the
directory layout.  (See C<%default{entry_map}> below.)

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
interpretation), a supported form of lightweight markup, or some combination
thereof. Actually, an entry may consist of any darn thing you please, as long
as Perl will agree that it is text, but presumably you're going to be feeding
this to a browser.

Header tags (<h1>, <h2>, etc.) will be used to display titles in feeds and
other places.

Other special markup is indicated by a variety of HTML-like container tags.

B<Embedded Perl> - evaluated and replaced by whatever value you return
(evaluated in a scalar context):

     <perl>my $dog = "Ralph."; return $dog;</perl>

This code is evaluated before any other processing is done, so you can return
any other markup understood by the script and have it handled appropriately.

B<Interpolated variables> - actually keys to the hash underlying the App::WRT
object, for the moment:

     <perl>$self->title("About Ralph, My Dog"); return '';</perl>

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
of the current project, but is useful for including HTML generated by an
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

As it stands, freeverse, image, and list are not particularly robust.

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

=cut


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
      embedded_perl  => 1,           # evaluate embedded <perl> tags?
      default_entry  => 'new',       # what to display if no entry specified
      cache_includes => 0,           # should included files be cached in memory?

      # A license string for site content:
      license        => 'public domain',

      # A string value to replace all pages with (useful for occasional
      # situations where every page of a site should serve some other
      # content in-place, like Net Neutrality protest blackouts):
      overlay        => undef,

      # What gets considered an entry _path_:
      entrypath_expr => qr/^ ([a-z0-9_\/-]+) $/x,

      # What gets considered a subentry file (slightly misleading
      # terminology here):
      subentry_expr => qr/^[0-9a-z_-]+(\.(tgz|zip|tar[.]gz|gz|txt))?$/,

      # We'll show links for these, but not display them inline:
      binfile_expr   => qr/[.](tgz|zip|tar[.]gz|gz|txt|pdf)$/,
    );

=cut

my %default = (
  root_dir       => '.',         # dir for wrt repository
  root_dir_abs   => undef,       # for stashing absolute path to wrt repo
  entry_dir      => 'archives',  # dir for entry files
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
  embedded_perl  => 1,           # evaluate embedded <perl> tags?
  default_entry  => 'new',       # what to display if no entry specified
  cache_includes => 0,           # should included files be cached in memory?

  # A license string for site content:
  license        => 'public domain',

  # A string value to replace all pages with (useful for occasional
  # situations where every page of a site should serve some other
  # content in-place, like Net Neutrality protest blackouts):
  overlay        => undef,

  # What gets considered an entry _path_:
  entrypath_expr => qr/^ ([a-z0-9_\/-]+) $/x,

  # What gets considered a subentry file (slightly misleading
  # terminology here):
  subentry_expr => qr/^[0-9a-z_-]+(\.(tgz|zip|tar[.]gz|gz|txt))?$/,

  # We'll show links for these, but not display them inline:
  binfile_expr   => qr/[.](tgz|zip|tar[.]gz|gz|txt|pdf)$/,
);

=item $default{entry_map}

A hashref which will dispatch entries matching various regexen to the
appropriate output methods. The default looks something like this:

    nnnn/[nn/nn/]doc_name - a document within a day.
    nnnn/nn/nn            - a specific day.
    nnnn/nn               - a month.
    nnnn                  - a year.
    doc_name              - a document in the root directory.

You can re-map things to an arbitrary archive layout.

Since the entry map is a hash, and handle() simply loops over its keys, there
is no guaranteed precedence of patterns. Be extremely careful that no entry
will match more than one pattern, or you will wind up with unexpected behavior.
A good way to ensure that this does not happen is to use patterns like:

    qr(
        ^           # start of string
        [0-9/]{4}/  # year
        [0-9]{1,2}/ # month
        [0-9]{1,2]  # day
        $           # end of string
      )x

...always marking the start and end of the string explicitly.

This may eventually be rewritten to use an array so that the order can be
explicitly specified.

=cut

$default{entry_map} = {
  qr'^[0-9/]{5,11}[a-z_/]+$' => sub { entry_stamped (@_, 'index') },

  qr'^[0-9]{4}/[0-9]{1,2}/
               [0-9]{1,2}$'x => sub { entry_stamped (@_, 'all'  ) },

  qr'^[0-9]{4}/[0-9]{1,2}$'  => sub { month         (@_         ) },
  qr'^[0-9]{4}$'             => sub { year          (@_         ) },
  qr'^[a-z_]'                => sub { entry_stamped (@_, 'all'  ) },
};

=item $default{entry_descriptions}

A hashref which contains a map of entry titles to entry descriptions.

=cut

# TODO: this has gotten more than a little silly.
$default{entry_descriptions} = {
  new => 'newest entries',
  all => 'all entries',
};

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
  # TODO: This is bad.  It's here because imgsize() winds up calling getcwd()
  # a ton of times if you don't give it absolute paths, which is actually super
  # inefficient.  See icon_markup() and image_markup() for usage.  image_markup()
  # in particular is awful and should be rewritten anyway.
  $params{root_dir_abs} = abs_path($params{root_dir});

  my %copy_of_default = %default;
  my $self = \%copy_of_default;
  bless $self, $class;

  # Configure from passed-in values, overwriting defaults:
  for my $p (keys %params) {
    $self->{$p} = $params{$p};
  }

  $self->{entries} = App::WRT::EntryStore->new( $self->{entry_dir} );

  # Check and set up template path for later use:
  $self->{template_path} = File::Spec->catfile(
    $self->{template_dir},
    $self->{template}
  );
  unless (-f $self->{template_path}) {
    croak($self->{template_path} . ' does not exist or is not a plain file');
  }

  return $self;
}

=item display($entry1, $entry2, ...)

Return a string containing the given entries, which are in the form of
date/entry strings. If no parameters are given, default to default_entry().

display() expands aliases ("new" and "all", for example) as necessary, collects
output from handle($entry), and wraps the whole thing in a template file.

If C<overlay> is set, will return the value of overlay regardless of options.
(This is useful for hackily replacing every page in a site with a single blob
of HTML, for example if you're participating in some sort of blackout or
something.)

=cut

sub display {
  my $self = shift;
  my (@options) = @_;

  return $self->{overlay} if defined $self->{overlay};

  $options[0] ||= $self->{default_entry};

  # Title for template head/foot:
  $self->{title} = join ' ', map { encode_entities($_) } @options;

  # Expand on any aliases:
  @options = map { $self->expand_option($_) } @options;

  # Hacky special case for printing the feed:
  if ($options[0] eq $self->{feed_alias}) {
    return $self->feed_print(
      $self->{entries}->recent_days( $self->{feed_length} )
    );
  }

  # To be accessed as ${content} in the template below:
  $self->{content} = join '', map { $self->handle($_) } @options;
  return $self->fragment_slurp($self->{template_path});
}

=item handle($entry)

Return the text of an individual entry.

=cut

sub handle {
  my $self = shift;
  my ($entry) = @_;

  # Hashref:
  my $map = $self->{entry_map};

  # Find the first pattern in entry_map that matches this entry...
  my ($pattern) = grep { $entry =~ $_ } keys %{ $map };

  return unless defined $pattern;

  # ...and use the corresponding coderef to handle the entry:
  return $map->{$pattern}->($self, $entry);
}

=item expand_option($option)

Expands/converts 'all', 'new', and 'fulltext' to appropriate values.

=cut

sub expand_option {
  my ($self, $option) = @_;

  # Take care of trailing slashes:
  chop $option if $option =~ m{/$};

  if ($option eq 'all') {
    return reverse $self->{entries}->all_years();
  } elsif ($option eq 'new') {
    return $self->{entries}->recent_days(5);
  } elsif ($option eq 'fulltext') {
    return $self->{entries}->all_days();
  }

  return $option;
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

=item year($year)

List out the updates for a year.

=cut

sub year {
  my $self = shift;
  my ($year) = @_;

  my ($year_file, $year_url) = $self->root_locations($year);

  # Year is a text file:
  return entry_markup($self->entry($year)) if -f $year_file;

  # If it's not a directory, we can't do anything. Bail out:
  return p('No such year.') if (! -d $year_file);

  my $result;

  # Handle year directories with index files.
  $result .= $self->entry($year)
    if -f "$year_file/index";

  my $header_text = $self->icon_markup($year, $year);
  $header_text ||= q{};

  $result .= heading("${header_text}${year}", 3);

  my @months = dir_list($year_file, 'high_to_low', qr/^[0-9]{1,2}$/);

  my $year_text;
  my $count = 0; # explicitly defined for later printing.

  foreach my $month (@months) {
    my @entries = dir_list(
      "$year_file/$month", 'low_to_high', qr/^[0-9]{1,2}$/
    );
    $count += @entries;

    my $month_text;
    foreach my $entry (@entries) {
      $month_text .= a({href => "$year_url/$month/$entry/"}, $entry) . "\n";
    }

    $month_text = small("( $month_text )");

    my $link = a({href => "$year_url/$month/"}, month_name($month));

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
  my $self = shift;
  my ($month) = @_;

  my ($month_file, $month_url) = $self->root_locations($month);

  my $result;

  # If a directory exists for $month, use dir_list to slurp the entry files it
  # contains into @entry_files, sorted numerically.  Then send each entry to
  # entry_markup().
  if (-d $month_file) {

    $result .= $self->entry($month)
      if -f "$month_file/index";

    my @entry_files = dir_list($month_file, 'high_to_low', qr/^[0-9]{1,2}$/);

    foreach my $entry_file (@entry_files) {
      $result .= $self->entry_stamped("$month/$entry_file");
    }

  } elsif (-f $month_file) {
    $result .= $self->entry($month);
  }

  return $result;
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

=item entry_topic_list($entry)

Get a list of topics (by tag-* files) for the entry.  This hardcodes part of a
p1k3-specific thing which should probably be moved into wrt entirely.

=cut

sub entry_topic_list {
  my $self = shift;
  my ($entry) = @_;

  my @tags = sort grep { m/^tag-.*/ } $self->{entries}->props_for($entry);

  return '' unless @tags;

  return join ', ', map {
    s/^tag-(.*)$/$1/;
    a($_, { href => $self->{url_root} . 'topics/' . $_ })
  } @tags;
}

=item entry($entry)

Returns the contents of a given entry. Calls dir_list and icon_markup.
Recursively calls itself.

=cut

sub entry {
  my $self = shift;
  my ($entry, $level) = @_;
  $level ||= 'index';

  # Location of entry on local filesystem, and its URL:
  my ($entry_loc, $entry_url) = $self->root_locations($entry);

  my $result;

  # Display an icon, if we have one:
  if ( my $ico_markup = $self->icon_markup($entry) ) {
    $result .= heading($ico_markup, 2) . "\n\n";
  }

  # For text files:
  if (-f $entry_loc) {
    return $result . $self->fragment_slurp($entry_loc);
  }

  return $result if ! -d $entry_loc;

  # Print index as head, if extant and a normal file:
  if (-f "$entry_loc/index") {
    $result .= $self->fragment_slurp("$entry_loc/index");
  }

  # Followed by any sub-entries:
  my @sub_entries = $self->get_sub_entries($entry_loc);

  if (@sub_entries >= 1) {
    # If the wrt-noexpand property is present, then don't expand sub-entries.
    # A hack.

    if ($level eq 'index' || -f "$entry_loc/wrt-noexpand.prop") {
      # Icons or text links:
      $result .= $self->list_contents($entry, @sub_entries);
    }
    elsif ($level eq 'all') {
      # Everything displayable in the directory:
      foreach my $se (@sub_entries) {
        next if ($se =~ $self->{binfile_expr});
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

=item get_sub_entries($entry_loc)

Returns "sub entries" based on the C<subentry_expr> regexp.

=cut

sub get_sub_entries {
  my $self = shift;
  my ($entry_loc) = @_;

  my %ignore = ('index' => 1);

  return grep { ! $ignore{$_} }
              dir_list($entry_loc, 'alpha', $self->{subentry_expr});
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

=item icon_markup($entry, $alt)

Check if an icon exists for a given entry if so, return markup to include it.
Icons are PNG or JPEG image files following a specific naming convention:

  index.icon.[png|jp(e)g] for directories
  [filename].icon.[png|jp(e)g] for flat text files

Calls image_size, uses filename to determine type.

=cut

{ my %cache;
sub icon_markup {
  my $self = shift;
  my ($entry, $alt) = @_;

  if ($cache{$entry . $alt}) {
    return $cache{$entry . $alt};
  }

  my ($entry_loc, $entry_url) = $self->root_locations($entry);

  my ($icon_loc, $icon_url);

  if (-f $entry_loc) {
    $icon_loc = "$entry_loc.icon";
    $icon_url = "$entry_url.icon";
  }
  elsif (-d $entry_loc) {
    $icon_loc = "$entry_loc/index.icon";
    $icon_url = "$entry_url/index.icon";
  }

  # First suffix found will be used:
  my (@suffixes) = qw(png jpg gif jpeg);
  my $suffix;
  for (@suffixes) {
    if (-e "$icon_loc.$_") {
        $suffix = $_;
        last;
    }
  }

  # fail unless there's a file with one of the above suffixes
  return 0 unless $suffix;

  # call image_size to slurp width & height from the image file
  my ($width, $height) = image_size($self->{root_dir_abs} . '/' . "$icon_loc.$suffix");

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

  my $stamp = $self->entry_topic_list($entry)
            . " :: "
            . join(" /\n", @fragment_stamps);

  return p({class => 'datelink'}, "\n$stamp\n");
}

=item fragment_slurp($file)

Read a text fragment, call line_parse() and eval_perl() to take care of
lightweight markup sections and interpret embedded code, and then return it as
a string. Takes one parameter, the name of the file.

=cut

sub fragment_slurp {
  my $self = shift;

  my ($file) = @_;
  my $everything = file_get_contents($file);

  return $self->line_parse(
    # Handle embedded perl first
    ($self->{embedded_perl} ? $self->eval_perl($everything) : $everything),
    $file # some context to work with
  );
}

=item month_name($number)

Turn numeric dates into English.

=cut

sub month_name {
  my ($number) = @_;

  # "Null" is here so that $month_name[1] corresponds to January, etc.
  my @months = qw(Null January February March April May June
                  July August September October November December);

  return $months[$number];
}

=item root_locations($file)

Given a file/entry, return the appropriate concatenations with entry_dir and
url_root.

=cut

sub root_locations {
  return (
    $_[0]->{entry_dir} . '/' . $_[1], # location on filesystem
    $_[0]->{url_root} . $_[1]         # URL
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

  # TODO: Probably ought to consider utf-8 in titles, authors, etc., as well as
  # entry content.

  my $feed = XML::Atom::SimpleFeed->new(
    -encoding => 'UTF-8',
    title     => $self->{title_prefix} . '::' . $self->{title},
    link      => $self->{url_root},
    link      => { rel => 'self', href => $feed_url, },
    icon      => $self->{favicon_url},
    author    => $self->{author},
    id        => $self->{url_root},
    generator => 'App::WRT.pm / XML::Atom::SimpleFeed',
    updated   => App::WRT::Date::iso_date(App::WRT::Date::get_mtime($first_entry_file)),
  );

  foreach my $entry (@entries) {
    my $content = $self->entry($entry) . "\n" . $self->datestamp($entry);
    my $utf8_content = decode('UTF-8', $content, Encode::FB_CROAK);

    my $title = $entry;
    my ($entry_file, $entry_url) = $self->root_locations($entry);

    # Try to pull out a header:
    my ($extracted_title) = $utf8_content =~ m{<h1.*?>(.*?)</h1>}s;
    my (@subtitles)       = $utf8_content =~ m{<h2.*?>(.*?)</h2>}sg;


    if ($extracted_title) {
      $title = $extracted_title;
      if (@subtitles) {
        $title .= ' - ' . join ' - ', @subtitles;
      }
    }

    $feed->add_entry(
      title   => $title,
      link    => $entry_url,
      id      => $entry_url,
      content => $utf8_content,
      updated => App::WRT::Date::iso_date(App::WRT::Date::get_mtime($entry_file)),
    );
  }

  # return "Content-type: application/atom+xml\n\n" . $feed->as_string;
  return $feed->as_string;
}

=back

=head1 SEE ALSO

walawiki.org, Blosxom, rassmalog, Text::Textile, XML::Atom::SimpleFeed,
Image::Size, CGI::Fast, and about a gazillion static site generators.

=head1 AUTHOR

Copyright 2001-2017 Brennen Bearnes

=head1 LICENSE

    wrt is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
