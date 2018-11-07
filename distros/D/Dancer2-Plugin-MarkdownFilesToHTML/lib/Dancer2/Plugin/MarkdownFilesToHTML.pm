package Dancer2::Plugin::MarkdownFilesToHTML ;
$Dancer2::Plugin::MarkdownFilesToHTML::VERSION = '0.014';
use 5.010; use strict; use warnings;

use Carp;
use Encode                qw( decode );
use Storable;
use File::Path            qw(make_path);
use Data::Dumper          'Dumper';
use File::Basename;
use Dancer2::Plugin;
use HTML::TreeBuilder;
use File::Spec::Functions qw(catfile);
use Text::Markdown::Hoedown;

plugin_keywords qw( mdfile_2html mdfiles_2html );

# Builds the routes from config file
sub BUILD {
  my $s      = shift;
  my $app    = $s->app;
  my $config = $s->config;
  #print Dumper $config;

  # add routes from config file
  foreach my $route (@{$config->{routes}}) {

    # validate resource arguments supplied from config file
    if ((ref $route) ne 'HASH') {
      die 'Config file misconfigured. Check syntax or consult documentation.';
    }

    my ($path) = keys %$route;
    my $dir    = $route->{$path}{dir};
    my $file   = $route->{$path}{file};

    if (defined $dir && defined $file) {
      die 'Ambiguous route. Both a file and directory given. Supply only one.';
    }
    my $method = defined $dir ? 'mdfiles_2html' : 'mdfile_2html';
    my $resource = $dir // $file;

    # fetch options to help determine if resource exists
    my $options = _set_options($route, $path, $config);

    my $is_abs = File::Spec->file_name_is_absolute($resource);
    if (!$is_abs) {
      $resource = File::Spec->catfile($options->{file_root}, $resource);
    }

    if (!-e $resource) {
      die "File or directory you associated with $path route does not exist.";
    }

    if (-f $resource && $dir) {
      die 'Your route expects a directory but you gave a file: ' . $resource;
    }

    if (-d $resource && $file) {
      die 'Your route expects a file but you gave a directory: ' . $resource;
    }

    # Do the route addin'
    $s->app->add_route(
      method => 'get',
      regexp => '/' . $options->{route_root} . $path,
      code => sub {
        my $app = shift;
        my ($html, $toc) = $s->$method($resource, $options);
        $app->template($options->{template},
                      { html => $html, toc => $toc },
                      { layout => $options->{layout} });
      },
    );
  }
}

# function for setting options
sub _set_options {
  my ($route, $path, $config) = @_;

  my %defaults = (
    route_root          => '',        template            => 'index.tt',
    layout              => 'main.tt', header_class        => '',
    generate_toc        => 0,         linkable_headers    => 0,
    cache               => 1,         exclude_files       => '',
    include_files       => '',        markdown_extensions => '',
    file_root           => 'lib/data/markdown_files',
  );

  my %options = ();
  foreach my $option (keys %defaults) {
    if ($path) {
      $options{$option} = $route->{$path}{$option} // $config->{defaults}{$option} // $defaults{$option};
    } else {
      $options{$option} = $route->{$option} // $config->{defaults}{$option} // $defaults{$option};
    }
  }

  if ($options{generate_toc}) { $options{linkable_headers} = 1; }
  if ($options{route_root})   { $options{route_root} .= '/'; }
  $options{set} = 1;

  return \%options;
}

sub _get_options {
  my $s = shift;
  my $options = shift;
  my $resource = shift;

  $options = _set_options($options, '', $s->config);
  my $is_abs = File::Spec->file_name_is_absolute($resource);
  if (!$is_abs) {
    $resource = File::Spec->catfile($options->{file_root}, $resource);
  }
  return ($options, $resource);
}

# Gathers lists of files in a directory and sends them off to mdfile_2html for
# parsing or cache retrieval
sub mdfiles_2html {
  my $s = shift;
  my $dir = shift;
  my $options = shift;

  # If options haven't been set yet, get defaults from cnofig file
  if (!$options->{set}) {
    ($options, $dir) = $s->_get_options($options, $dir);
  }

  my $html = '';
  my $toc = '';

  # gather the files according the options supplied
  my @files = ();
  if ($options->{include_files}) {
    my @files = map { File::Spec->catfile($dir, $_) } @{$options->{include_files}};
  } else {
    opendir my $d, $dir or die "Cannot open directory: $!";
    @files = grep { $_ !~ /^\./ } readdir $d;
    closedir $d;
    if ($options->{markdown_extensions}) {
      my @matching_files = ();
      foreach my $md_ext (@{$options->{markdown_extensions}}) {
        push @matching_files, grep { $_ =~ /\.$md_ext$/ } @files;
      }
      @files = @matching_files;
    }
  }

  if ($options->{exclude_files}) {
    foreach my $excluded_file (@{$options->{exclude_files}}) {
      @files = grep { $_ ne $excluded_file } @files;
    }
  }

  # concatenate html and toc into two strings
  foreach my $file (sort @files) {
    my ($file_html, $file_toc)  = $s->mdfile_2html(File::Spec->catfile($dir, $file), $options);
    $html                      .= $file_html;
    $toc                       .= $file_toc;
  }
  return wantarray ?  ($html, $toc) : $html;
}

# Sends the markdown file to get parsed or retrieves html version from cache,
# if available. Also generates the table of contents.
sub mdfile_2html {
	my ($s, $file, $options) = @_;

  my ($base)   = fileparse($file, qr/\.[^.]*/);
  # If options haven't been set yet, get defaults from cnofig file
  if (!$options->{set}) {
    ($options, $file) = $s->_get_options($options, $file);
  }

  # generate the cache directory if it doesn't exist
  my $cache_dir = File::Spec->catfile(dirname($options->{'file_root'}), 'md_file_cache');
  if (!-d $cache_dir) {
    make_path $cache_dir or die "Cannot make cache directory $!";
  }

  # generate unique cache file name appended with values of two options
  my $cache_file = dirname($file);
  my $sep = File::Spec->catfile('', '');
  $cache_file =~ s/\Q$sep\E//g;
  $cache_file = File::Spec->catfile($cache_dir,
                 $cache_file . $base . $options->{linkable_headers} . $options->{generate_toc});

  # check for cache hit
  if (-f $cache_file && $options->{cache}) {
    if (-M $cache_file eq -M $file) {
      my $data = retrieve $cache_file;
      return ($data->{html}, $data->{toc});
    }
  }

  # no cache hit so we parse the file
  # slurp the file and parse it with Hoedown's markdown function
  my $markdown = '';
  {
    local $/;
    open my $md, '<:encoding(UTF-8)', $file or die "Can't open $file: $!";
    $markdown = <$md>;
    close $md;
  }
  my $out  = markdown($markdown, extensions => HOEDOWN_EXT_FENCED_CODE);
  my $tree = HTML::TreeBuilder->new_from_content($out);
  _add_single_line_class($tree);

  # See if we can cache and return the output without further processing
  # generate_toc makes linkable_headers true so we just need to test linkable_headers option
  if (!$options->{linkable_headers}) {
    my ($html, $toc) = $s->_cache_data($options, $cache_file, $file, $tree->guts->as_HTML);
    return wantarray ?  ($html, $toc) : $html;
  }

  my @elements = $tree->look_down(_tag => qr/^h\d$/);
  my $toc      = HTML::TreeBuilder->new();
  my $hdr_ct   = 0;
  foreach my $element (@elements) {
    my $id = 'header_' . ${hdr_ct};
    $hdr_ct++;
    $element->attr('id', $id . '_' . $base);
    $element->attr('class' => $options->{header_class}) if $options->{header_class};
    if ($options->{generate_toc}) {
      my ($level) = $element->tag =~ /(\d)/;
      my $toc_link = HTML::Element->new('a', href=> "#${id}_${base}", class => 'header_' . $level);
      $toc_link->push_content($element->as_text);
      $toc->push_content($toc_link);
      $toc->push_content(HTML::Element->new('br'));
    }
  }

  # Generate the final HTML from trees and cache
  # "guts" method gets rid of <html> and <body> tags added by TreeBuilder
  return $s->_cache_data($options, $cache_file, $file,
                         $tree->guts->as_HTML, $toc->guts->as_HTML);
}

# add a special class for code that has no siblings so it can be styled
sub _add_single_line_class {
  my $tree = shift;
  my @code_els = $tree->find_by_tag_name('code');
  foreach my $code_el (@code_els) {
    if (!$code_el->left && !$code_el->right) {
      $code_el->attr('class' => 'single-line');
    }
  }
}

# cache the data
sub _cache_data {
  my ($s, $options, $cache_file, $file, $content, $toc) = @_;
  $toc //= '';

  if ($options->{cache}) {
    store { html => $content, toc => $toc }, $cache_file;
    my ($read, $write) = (stat($file))[8,9];
    utime($read, $write, $cache_file);
  }

  return ($content, $toc);
}

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::MarkdownFilesToHTML

=head1 VERSION

version 0.014

=head1 SYNOPSIS

Include the plugin in your Dancer2 app:

  use Dancer2::Plugin::MarkdownFilesToHTML;

No other perl code is necessary. Routes can be established to display the HTML
associated with a directory of markdown documents or a single document using
the Dancer2 C<config.yml> file:

  plugins:
    MarkdownFilesToHTML:
      defaults:
        header_class: 'elegantshadow scrollspy'  # class added to headers
        route_root: 'tutorials'                  # where routes get attached to
        file_root: 'lib/data/markdown_files'     # location of markdown files
        generate_toc: 1                          # generate a table of contents
        linkable_headers: 1                      # create unique id for headers
        template: 'index.tt'                     # template file to use
        layout: 'main.tt'                        # layout file to use
      routes:                                    # list of conversion routes
        - dzil_tutorial:
            dir: 'Dist-Zilla-for-Beginners'      # dir containing markdown files
            markdown_extensions:
              - md
              - mdwn
        - another_tutorial:
            file: 'intro.md'                     # markdown file to be converted
            template: 'doc.tt'                   # defaults can be overridden
            generate_toc: 0
            linkable_headers: 0

See the C<CONFIGURATION> section below for more details on configuration
settings.

Conversion with Perl code can also be accomplished using the keywords provided by
this is plugin, like so:

  # convert a single markdown file to HTML
  $html = mdfile_2html('/path/to/file.md', { header_class => 'header_style' });

  # convert directory of markdown files to HTML and generate table of contents
  ($html, $toc) = mdfiles_2html('/dir/with/markdown/files', { generate_toc => 1 });

=head1 DESCRIPTION

This module converts markdown files into a single HTML string using the Dancer2
web app framework. Using the Dancer2 config file, multiple routes can be
established in the web app, with each route converting a single markdown
document or all the markdown documents in a directory into an HTML string.
Optionally, it can return a second HTML string containing a hierarchical table
of contents based on the contents of the markdown documents. These strings can
then be inserted into your Dancer2 website using a config file or manually using
keywords. This module relies on the L<Text::Markdown::Hoedown> module to execute
the markdown conversions which uses a fast C module. To further enhance
performance, a caching mechanism using L<Storable> is employed for each
converted markdown file so markdown to HTML conversions are avoided except for
new and updated markdown files.

The module is particarly well-suited for markdown that follows a classic outline
structure with markdown headers, like so:

  # Title of Document

  ## Header 2

  ### Header 3

  #### Header 4

  And so on...

Each header is converted to a C<<hX\>> html tag where C<X> is the level
corresponding header level in the markdown file. If present, the headers can be
used to generate the table of contents and associated anchor tags for linking to
each of the sections within the document. If headers are not present in the
markdown file, a useful table of contents cannot be generated.

Conversion keywords can also be called directly from within your Dancer2 app.
Note that when called directly and a configuration file is also implemented,
most of the default settings apply (route, template, and layout settings don't)
but can also be overridden when using the keyword by passing an an optional hash
reference.

=head1 KEYWORDS

=head2 mdfile_2html($file, [ \%options ])

Converts a single markdown file into HTML. An optional hashref can be passed with
options as documented in the L<OPTIONS> section below.

Example:

  my $html = mdfile_2html('/path/to/file', { header_class => 'my_style' });

If the C<$file> argument is relative, it will be appended to the C<file_root>
setting in the configuration file. If C<file_root> is not set in the
configuration file, C<lib/data/markdown_files> is used.

=head2 mdfiles_2html($dir, [ \%options ]  )

Attempts to convert all the files present in a directory from markdown into a
single HTML string.

Example:

  my ($html, $toc) = mdfiles_2html('/path/to/dir/with/makrdown/files',
                      { generate_toc => 1 });

If the C<$dir> argument is relative, then it will be appended to the
C<file_root> setting in the configuration file. If C<file_root> is not set
in the configuration file, the default C<lib/data/markdown_files> is used.

Each file can be thought of as a chapter within a single larger document
comprised of all the individual files. Ideally, each file will have a single
level 1 header tag to serve as the title for the chapter.

The method asssumes all files present in a directory are markdown documents.
Hidden files (those beginning with a '.') are automatically excluded. These
defaults can be modified.

All the L<General Options> avialable to the C<mdfile_2html> keyword apply to the
C<mdfiles_html> keyword as well. See the L<Directory Options> section for more
additional options that let you control how files in a directory are processed
and selected.

=head1 OPTIONS

=head1 General Options

=head3 route_root => $route

The root route is the route the individual conversion routes are attached to.
For example, if the root route is C<tutorials>, a conversion route named C<perl>
will be found at C<tutorials/perl>. If no root route is supplied, C</> is used.

=head3 file_root => $path

The root directory where markdown files can be found. Defaults to the
C<lib/data/markdown_files> directory within the Dancer2 web app. Directories and
files supplied by each route will be relative to this path if they are relative.
If directory or file path is absolute, this value is ignored.

=head3 generate_toc => $bool

A boolean value that defaults to false. If true, the function will return a
second string containing a table of contents with anchor tags linking to the
associated headers in the content. This setting effectively sets the
C<linkable_headers> option to true (see below).

=head3 linkable_headers => $bool

A boolean value that defaults to false. If true, a unique id is inserted into
the header HTML tags so they can be linked to. Linkable headers are also
generated if the toc C<generate_toc> option is true.

=head3 header_class => $classes

Accepts a string which is added to each of the header tags' "class" attribute.

=head3 template => $template_file

The template file to use relative to directory where the app's views are store.
C<index.tt> is the default template.

=head3 layout => $layout_file

The layout file to use relative to the app's layout directory C<main.tt> is the
default layout.

=head3 cache => $bool

Stores generated html in files. If the timestamp of the cached file indicates
the original file been updated, a new version of page will be generated. The
cache defaults to true and there is no good reason to turn this off except to
troubleshoot problems with the cache.

=head1 Directory Options

=head3 include_files => [ $file1, $file2, ... ]

An array of strings representing the files that should be converted in the order
they are to be converted.

By default, the files are processed in alphabetical order. Though alphabetical
ordering can be overridden manually using the C<include_files> option, it's
easier to use a naming convention for your files that will places them in the
desired order:

  tutorial01.md
  tutorial02.md
  tutorial03.md
  etc.

=head3 exclude_files => [ $file1, $file2, ... ]

An array of strings represening the files that should not be converted to
HTML.

=head3 markdown_extensions => [ $ext1, $ext2, ... ]

An array of strings representing the extensions that should be used to determine
which files contain the markdown documents. This option is valid only with the
C<mdfiles_2html>) keyword. Only files with the listed extension will be
converted.

=head1 CONFIGURATION

Though the C<mdfile_2html> and C<mdfile_2html> keywords can be passed arguments
directly, modifying the Dancer2 C<config.yml> file to associate routes with the
HTML generatd by the converted markdown files to makes it exceedingly easy to
add pages to your website. Unless you need to modify the output of the HTML
generated by this module in some way, using the configuration file is the
preferred method.

All of the options listed above are supported by the configuration file.

Configure the C<config.yml> file, usually located in the root of your Dancer2 app,
as follows:

  plugins:
    MarkdownFiletoHTML:

Follow these two lines with your default settings:

      defaults:
        header_class: 'my_header classes here'
        route_root: 'content'
        file_root: '/lib/data/content'
        genereate_toc: 1

...and so on.

After the defaults, you can list your routes:

       routes:
         - a_web_page:
           dir: 'convert/all/files/in/this/dir/relative/to/file_root'
         - another_web_page:
           file: '/convert/this/file/with/absolute/path.md'

Routes must have either a C<dir> or C<file> property. Paths can be absolute or
relative. Relative paths are appended to the path in C<file_root>.

The default options can be overridden for each route like so:

         - my_page
           file: 'file.md'
           toc: 0
           header_class: ''

Consult the L<#Options> section for defaults for each of the options.

The options that apply to directories accept a list of arguments, created like
this:

          - another_page:
            dir: 'my_dir_containing_md_file'
            include_files:
              - 'file4.md'
              - 'file2.md'
              - 'file1.md'
              - 'file3.md'

Now only the four files listed get processed in the order listed above.

=head1 MARKDOWN CONVERSION NOTES

The module aims to support the dialect of markdown as implemented by GitHub with
strikethroughs (C<~~strike~~>) and "fenced" code (C<```fenced code```>). This module
may make the dialect options configurable in the future.

The module will add a "single-line" class to single lines of code to facility additional styling.

=head1 REQUIRES

=over 4

=item * L<Carp|Carp>

=item * L<Dancer2::Plugin|Dancer2::Plugin>

=item * L<Data::Dumper|Data::Dumper>

=item * L<Encode|Encode>

=item * L<File::Basename|File::Basename>

=item * L<File::Path|File::Path>

=item * L<File::Spec::Functions|File::Spec::Functions>

=item * L<HTML::TreeBuilder|HTML::TreeBuilder>

=item * L<Storable|Storable>

=item * L<Text::Markdown::Hoedown|Text::Markdown::Hoedown>

=item * L<strict|strict>

=item * L<warnings|warnings>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dancer2::Plugin::MarkdownFilesToHTML

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Dancer2-Plugin-MarkdownFilesToHTML>

=back

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/sdondley/Dancer2-Plugin-MarkdownFilesToHTML>

  git clone git://github.com/sdondley/Dancer2-Plugin-MarkdownFilesToHTML.git

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/sdondley/Dancer2-Plugin-MarkdownFilesToHTML/issues>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

L<Dancer2>

L<Text::Markup::Hoedown>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
