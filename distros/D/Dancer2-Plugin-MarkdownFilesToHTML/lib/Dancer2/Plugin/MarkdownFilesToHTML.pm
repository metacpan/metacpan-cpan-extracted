package Dancer2::Plugin::MarkdownFilesToHTML ;
$Dancer2::Plugin::MarkdownFilesToHTML::VERSION = '0.006';
use 5.13.2;
use strict;
use warnings;
use Dancer2::Plugin;
use Carp;
use Encode qw( decode );
use File::Spec::Functions qw(catfile);
use File::Slurper qw ( read_text );
use HTML::TreeBuilder;
use Data::Dumper 'Dumper';
use File::Basename;
use File::Path qw(make_path);
use Storable;
use Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser;

plugin_keywords qw( mdfile_2html mdfiles_2html );

# builds the routes from config file
sub BUILD {
  my $s = shift;
  my $app = $s->app;
  my $config = $s->config;


  # add routes from config file
  my $routes = $config->{routes};
  return if !$routes;
  foreach my $route (@$routes) {

    # validate arguments supplied from config file
    if ((ref $route) ne 'HASH') {
      die 'Config file misconfigured. Check syntax or consult documentation.';
    }

    my ($path) = keys %$route;

    if (defined $route->{$path}{dir} && defined $route->{$path}{file}) {
      die 'Ambiguous route. Both a file and directory given. Supply only one.';
    }
    my $method = defined $route->{$path}{dir} ? 'mdfiles_2html' : 'mdfile_2html';
    my $resource = $route->{$path}{dir} // $route->{$path}{file};

    my $options = _get_options($route, $path, $config);

    my $is_abs = File::Spec->file_name_is_absolute($resource);
    if (!$is_abs) {
      $resource = File::Spec->catfile($options->{file_root}, $resource);
    }

    if (!-e $resource) {
      die 'The file or directory you associated with route ' . $path
           . ' does not exist';
    }

    if (-f $resource && $route->{$path}{dir}) {
      die 'Your route expects a directory but you gave a file: ' . $resource;
    }

    if (-d $resource && $route->{$path}{file}) {
      die 'Your route expects a file but you gave a directory: ' . $resource;
    }

    $s->_add_route($path, $resource, $method, $options);
  }
}

# helper function for setting options
sub _set_options {
  my ($route, $path, $config, @options) = @_;

  my %defaults = (route_root => '', template => 'index.tt', layout => 'main.tt',
                  header_class => '', generate_toc => 0, linkable_headers => 0,
                  cache => 1, dialect => 'GitHub', exclude_files => '',
                  include_files => '', markdown_extensions => '',
                  file_root => 'lib/data/markdown_files');

  my %options = ();
  foreach my $option (@options) {
    if ($path) {
      $options{$option} = $route->{$path}{$option}
                        // $config->{defaults}{$option}
                        // $defaults{$option};
    } else {
      $options{$option} = $config->{$option} // $defaults{$option};
    }
  }
  if ($options{genereate_toc}) {
    $options{linkable_headers} = 1;
  }
  if ($options{route_root}) {
    $options{route_root} .= '/';
  }
  $options{processed} = 1;
  return \%options;
}

sub _get_options {
  my ($route, $path, $config) = @_;
  my $options = _set_options($route, $path, $config,
                   qw( file_root route_root template layout header_class generate_toc
                       linkable_headers cache dialect exclude_files include_files
                       markdown_extensions));

}

# helper function for adding a route
sub _add_route {
  my ($s, $path, $resource, $method, $options) = @_;

  my ($html, $toc) = '';
  $s->app->add_route(
    method => 'get',
    regexp => '/' . $options->{route_root} . "$path",
    code => sub {
      my $app = shift;
      ($html, $toc) = $s->$method($resource, $options);
      $app->template($options->{template}, { html => $html, toc => $toc },
                     { layout => $options->{layout} });
    },
  );
}

# gathers lists of files in a directory to send them off for
# parsing or cache retrieval
sub mdfiles_2html {
  my $s = shift;
  my $dir = shift;
  my $options = shift;

  # check to see if we are calling argument directly. If so
  # get defauls from config file
  if (!$options->{processed}) {
    $options = _set_options($options, '', $s->config);
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

  foreach my $file (sort @files) {
    my ($content, $toc_file) = $s->mdfile_2html(File::Spec->catfile($dir, $file), $options);
    $html .= $content;
    $toc .= $toc_file
  }
  return ($html, $toc);
}


# The workhorse function of this module which sends the markdown file to get
# parsed or retrieves html version from cache. Also generates the table of
# contents

# TODO: make the TOC generation optional based on config setting
sub mdfile_2html {
	my $s        = shift;
  my $file     = shift;
  my $options  = shift;

  # check to see if options already set. If not
  # get defauls from config file
  if (!$options->{processed}) {
    $options = _set_options($options, '', $s->config);
  }

  # check the cache for a hit by comparing timestemps of cached file and
  # markdown file

  # generate the cache if it doesn't exist
  if (!-d 'lib/data/markdown_files/cache') {
    make_path 'lib/data/markdown_files'
  }

  my $cache_file = $file =~ s/\///gr;
  $cache_file = "lib/data/markdown_files/cache/$cache_file";
  if (-f $cache_file && $options->{cache}) {
    if (-M $cache_file eq -M $file) {
      my $data = retrieve $cache_file;
      if ($data->{linkable_headers} == $options->{linkable_headers}
          && $data->{generate_toc}  == $options->{generate_toc}) {
        return ($data->{html}, $data->{toc});
      }
    }
  }

  # no cache hit so we must parse the file

  # direct filehandle to a string instead of a file
  my $out = q{};
  open my $fh, '>:encoding(UTF-8)', \$out;

  my $h = Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser->new(
    output => $fh,
    linkable_headers => $options->{linkable_headers},
    header_class => $options->{header_class},
    dialect => $options->{dialect},
  );

  my $markdown = read_text($file);
  $h->parse(\$markdown);
  close $fh;

  if (!$options->{linkable_headers}  && !$options->{generate_toc}) {
    return $out;
  }


  # generate the TOC and modify header ids so they are linkable
  my $tree = HTML::TreeBuilder->new_from_content(decode ('UTF-8', $out));
  my @elements = $tree->look_down(id => qr/^header/);
  my ($base)   = fileparse($file, qr/\.[^.]*/);
  my $toc = '';
  if ($options->{linkable_headers} && !$options->{generate_toc}) {
    foreach my $element (@elements) {
      my $id = $element->attr('id');
      $element->attr('id', $id . "_$base");
    }
  } else {
    $toc = HTML::TreeBuilder->new();
    foreach my $element (@elements) {
      my $id = $element->attr('id');
      $element->attr('id', $id . "_$base");
      my $toc_link = HTML::Element->new('a', href=> "#${id}_$base");
      $id =~ s/^(header_\d+)_.*/$1/;
      $toc_link->attr('class', $id);
      my $br = HTML::Element->new('br');
      $toc_link->push_content($element->as_text);
      $toc->push_content($toc_link);
      $toc->push_content($br);
    }
  }

  # generate the HTML from trees
  # guts method gets rid of <html> and <body> tags added by TreeBuilder
  # regex hack needed because markdent does not handle strikethroughs
  my $struck_tree = $tree->guts->as_HTML =~ s/~~(.*?)~~/<strike>$1<\/strike>/gsr;
  my $struck_toc  = $toc->guts->as_HTML  =~ s/~~(.*?)~~/<strike>$1<\/strike>/gsr if $toc;

  # store the data for caching. set timestamp of cached file to timestamp of
  # original file
  if ($options->{cache}) {
    store { html => $struck_tree, toc => $struck_toc,
            linkable_headers => $options->{linkable_headers},
            generate_toc => $options->{generate_toc} },
          $cache_file;
    my ($read, $write) = (stat($file))[8,9];
    utime($read, $write, $cache_file);
  }

  return ($struck_tree, $struck_toc);
}

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::MarkdownFilesToHTML

=head1 VERSION

version 0.006

=head1 SYNOPSIS

No perl code is necessary. Markdown documents can be displayed as HTML inside a
Dancer2 app using the Dancer2 `config.yml` file:

  plugins:
    MarkdownFilesToHTML:
      defaults:
        header_class: 'elegantshadow scrollspy'  # class added to headers
        route_root: 'tutorials'                  # root where routes will get attached
        file_root: 'lib/data/markdown_files'     # where markdowns file are located
        generate_toc: 1                          # generate a table of contents
        linkable_headers: 1                      # generates unique id for headers
        template: 'index.tt'                     # template file to use
        layout: 'main.tt'                        # layout file to use
        dialect: 'GitHub'                        # dialect of markdown file
      routes:                                    # list of conversion routes
        - dzil_tutorial:
            dir: 'Dist-Zilla-for-Beginners'      # dir or file property must be set
            markdown_extensions:
              - md
              - mdwn
        - another_tutorial:
            file: 'intro.md'
            template: 'doc.tt'                   # defaults above can be overridden
            generate_toc: 0
            linkable_headers: 0

See the C<CONFIGURATION> section below for more details on configuration
settings.

No configuration file is required, however, and conversion using ordinary Perl
code can be accomplshed from with your Dancer2 app like so:

  use Dancer2::Plugin::MarkdownFilesToHTML;

  # convert a single markdown file to HTML
  my ($html, $toc) = mdfile_2html('/path/to/file.md',
                                  { generate_toc => 1, header_class => 'header' });

  # convert entire directory of markdown files to HTML
  my ($html, $toc) = mdfiles_2html('/dir/with/markdown/files', { generate_toc => 1 });

=head1 DESCRIPTION

This module converts markdown files into a single HTML string using the Dancer 2
web app framework. Using the Dancer2 config file, multiple routes can be
established in the web app, with each route converting a single markdown
document or all the markdown documents in a directory into an HTML string.
Optionally, it can return a second HTML string containing a hierarchical table
of contents based on the contents of the markdown documents. These strings can
then be inserted into your Dancer2 website. This module extends the L<Markdent>
module to perform the conversion.

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
most of the default settings (route, template, and layout settings don't apply)
still apply but can be overridden.

=head1 KEYWORDS

=head2 mdfile_2html($file, [ \%options ])

Converts a single markdown file into HTML. An optional hashref can be passed with
options as documented in the L<General Options> section below.

Example:

  my $html = mdile_2html('/path/to/dir/with/makrdown/files');

If the C<$file> argument is relative, then it will be appended to the
C<file_root> setting in the configuration file. If C<file_root> is not set
in the configuration file, C<lib/data/markdown_files> is used.

=head2 mdfiles_2html($dir, [ \%options ]  )

Attempts to convert all the files present in a directory to markdown and munges
them into a single HTML string. By default, the files are processed in
alphabetical order.

Example:

  my ($html, $toc) = mdiles_2html('/path/to/dir/with/makrdown/files',
                      { generate_toc => 1 });

If the C<$dir> argument is relative, then it will be appended to the
C<file_root> setting in the configuration file. If C<file_root> is not set
in the configuration file, C<lib/data/markdown_files> is used.

Each file can be thought of as a chapter within a single larger document
comprised of all the individual files. Ideally, each file will have a single
level 1 header tag to serve as the title for the chapter.

By default, the method asssumes all files present in a directory are markdown
documents and are converted in the order as listed alphabetically in the
directory. Hidden files (those beginning with a '.') are automatically
excluded. These defaults can be modified. See the L<mdfiles_2html Options>
section for details.

=head3 General Options

=head1 OPTIONS

=head2 route_root

The root route is the route the individual conversion routes are attached to.
For example, if the root route is C<tutorials>, a conversion route named C<perl>
will be found at C<tutorials/perl>. If no root route is supplied, C</> is used.

=head2 file_root

The root directory where markdown files can be found. Defaults to the
C<lib/data/markdown_files> directory within the Dancer2 web app. Directories and
files supplied by each route will be relative to this path if they are relative.
If directory or file path is absolute, this value is ignored.

=head2 generate_toc

A boolean value that defaults to false. If true, the function will return a
second string containing a table of contents with anchor tags linking to the
associated headers in the content. This setting effectively sets the
C<linkable_headers> option to true (see below).

=head2 linkable_headers

A boolean value that defaults to false. If true, a unique id is inserted into
the header HTML tags so they can be linked to. Linkable headers are also
generated if the toc C<generate_toc> option is true.

=head2 header_class

Accepts a string which is added to each of the header tags' "class" attribute.

=head2 template

The template file to use. C<index.tt> is the default template.

=head2 layout

The layout to use. C<main.tt> is the default layout.

=head2 dialect

As markdown has no standard, there are many different dialects. By default, the
GitHub dialect, as implemented by the Markdent module, is used.

=head2 cache

Stores generated html in files. If the timestamp of the cached file indicates
the original file been updated, a new version of page will be generated. The
cache defaults to true and there is no good reason to turn this off except to
troubleshoot problems with the cache.

=head3 mdfiles_2html Options

All the general options avialable to the C<mdfile_2html> keyword are available
plus the following additional options:

=head2 markdown_extensions

An array of strings representing the extensions that should be used to determine
which files contain the markdown documents. This option is valid only with the
C<mdfiles_2html>) keyword. Only files with the listed extension will be
converted.

=head2 exclude_files

An array of strings represening the files that should not be converted to
HTML.

=head2 include_files

An array of strings representing the files that should be converted in the order
they are to be converted.

=head1 CONFIGURATION

Though the C<mdfile_2html> and C<mdfile_2html> keywords can be passed arguments
directly, the configuration file can be used to associate routes with the HTML
generatd by the converted markdown files. This makes it very easy to generate
new pages on your website. Unless you need to modify the output of the HTML
generated by this module in some way, we recommend using the configuration file
to generate the pages.

All of the options listed above are supported by the configuration file.

The configuration settings are placed in the C<config.yml> file usually located
in the root of your Dancer2 app and begins with:

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

Routes must have either a C<dir> or C<file> property. Relative paths are
relative to the C<file_root> default. Consult the L<#Options> section for
defaults for each of the options.

The default options can be overridden for each route like so:

       routes:
         - my_page
           file: 'file.md'
           toc: 0
           header_class: ''

The options that apply to directories accept a list of arguments which are
create like this:

        routes:
          - another_page:
            dir: 'my_dir_containing_md_file'
            include_files:
              - 'file4.md'
              - 'file2.md'
              - 'file1.md'
              - 'file3.md'

Now only files with one of the four names will be get processed in the order
listed above.

=head1 REQUIRES

=over 4

=item * L<Carp|Carp>

=item * L<Dancer2::Plugin|Dancer2::Plugin>

=item * L<Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser|Dancer2::Plugin::MarkdownFilesToHTML::MarkdownParser>

=item * L<Data::Dumper|Data::Dumper>

=item * L<Encode|Encode>

=item * L<File::Basename|File::Basename>

=item * L<File::Path|File::Path>

=item * L<File::Slurper|File::Slurper>

=item * L<File::Spec::Functions|File::Spec::Functions>

=item * L<HTML::TreeBuilder|HTML::TreeBuilder>

=item * L<Storable|Storable>

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

L<Markdent>

L<Dancer2>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
