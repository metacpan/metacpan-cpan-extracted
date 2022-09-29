package App::WRT::Markup;

use strict;
use warnings;
use feature "state";

use base qw(Exporter);
our @EXPORT_OK = qw(line_parse image_markup eval_perl);

use App::WRT::Image qw(image_size);
use App::WRT::Util qw(file_get_contents);

use Carp;
use File::Basename;
use Text::Textile;
use Text::Markdown::Discount;

# Some useful defaults:

my %tags = (
  retcon    => q{div class="retcon"},
  freeverse => 'p',
  list      => "ul>\n<li"
);

my %end_tags = (
  retcon    => 'div',
  freeverse => 'p',
  list      => "li>\n</ul"
);

my %blank_lines = (
  freeverse => "</p>\n\n<p>",
  list      => "</li>\n\n<li>"
);

my %newlines = (
  freeverse => "<br />\n"
);

my %dashes = (
  freeverse => ' &mdash; '
);

=over

=item eval_perl

Evaluate embedded Perl in a string, replacing blocks enclosed with <perl> tags
with whatever they return (well, evaluated in a scalar context). Returns the
modified string.

Also handles simple ${variables}, replacing them from the keys to $self.

=cut

sub eval_perl {
  my $self = shift;
  my ($text) = @_;

  while ($text =~ m{<perl>(.*?)</perl>}s) {
    my $block = $1;

    # Run the $block, and include anything returned:
    my $output = eval $block;

    if ($@) {
      # Errors - log and return an empty string:
      carp($@);
      $output = '';
    }

    $text =~ s{<perl>\Q$block\E</perl>}{$output}s;
  }

  # Interpolate variables:
  $text =~ s{
    \$\{ ([a-zA-Z_]+) \}
  }{
    if (defined $self->{$1}) {
      $self->{$1};
    } else {
      # TODO:  Possibly this should be fatal.
      "UNDEFINED: $1";
    }
  }gex;

  return $text;
}

=item line_parse

Performs substitutions on lines called by fragment_slurp, at least.  Calls
include_process(), image_markup(), textile_process(), markdown_process(),
eval_perl().

Applies before-parsing and after-parsing filters.

Returns string.

Parses some special markup.  Specifically:

    <perl>print "hello world";</perl>
    ${variable} interpolation from the WRT object

    <include>path/to/file/from/project/root</include>

    <textile></textile> - Text::Textile to HTML
    <markdown></markdown> - Text::Markdown::Discount to HTML

    <image>filename.ext
    optional alt tag
    optional title text</image>

    <freeverse></freeverse>
    <retcon></retcon>
    <list></list>

=cut

sub line_parse {
    my $self = shift;
    my ($everything, $file) = (@_);

    # Eventually, this should probably only happen for templates:
    $everything = $self->eval_perl($everything);

    # Take care of <include>, <textile>, <markdown>, and <image> tags:
    include_process($self, $everything);
    textile_process($everything);
    markdown_process($everything);
    $everything =~ s!<image>(.*?)</image>!$self->image_markup($file, $1)!seg;

    foreach my $key (keys %tags) {
       # Set some replacements, unless they've been explicitly set already:
       $end_tags{$key} ||= $tags{$key};

        # Transform blocks:
        while ($everything =~ m| (<$key>\n?) (.*?) (\n?</$key>) |sx) {
            my $open = $1;
            my $block = $2;
            my $close = $3;

            # Save the bits between instances of the block:
            my (@interstices) = split /\Q$open$block$close\E/s, $everything;

            # Transform dashes, blank lines, and newlines:
            dashes($dashes{$key}, $block)          if defined $dashes{$key};
            $block =~ s/\n\n/$blank_lines{$key}/gs if defined $blank_lines{$key};
            newlines($newlines{$key}, $block)      if defined $newlines{$key};

            # Slap it all back together as $everything, with start and end
            # tags:
            $block = "<$tags{$key}>$block</$end_tags{$key}>";
            $everything = join $block, @interstices;
        }
    }

    return $everything;
}

=item newlines($replacement, $block)

Inline replace single newlines (i.e., line ends) within the block, except those
preceded by a double-quote, which probably indicates a still-open tag.

=cut

sub newlines {
  $_[1] =~ s/(?<=[^"\n])  # not a double-quote or newline
                          # don't capture

             \n           # end-of-line

             (?=[^\n])    # not a newline
                          # don't capture
            /$_[0]/xgs;
}

=item dashes($replacement, $block)

Inline replace double dashes in a block - " -- " - with a given replacement.

=cut

sub dashes {
  $_[1] =~ s/(\s+)      # whitespace - no capture
             \-{2}      # two dashes
             (\n|\s+|$) # newline, whitespace, or eol
            /$1$_[0]$2/xgs;

}

=item include_process

Inline replace <include>filename</include> tags, replacing them with the
contents of files.

=cut

sub include_process {
  my $wrt = shift;

  $_[0] =~ s{

    <include>  # start tag
      (.*?)     # anything (non-greedy)
    </include> # end tag

  }{
    retrieve_include($wrt, $1);
  }xesg;
}

=item retrieve_include

Get the contents of an included file.  This probably needs a great
deal more thought than I am presently giving it.

=cut

sub retrieve_include {
  my $wrt = shift;
  my ($file) = @_;

  # Trim leading and trailing spaces:
  $file =~ s/^\s+//;
  $file =~ s/\s+$//;

  if ($file =~ m{^ (/ | [.]/) }x) {
    # TODO: Leads with a slash or a ./
    croak('Tried to open an include path with a leading / or ./ - not yet supported.');
  } else {
    # Use the archive root as path.
    $file = $wrt->{root_dir} . '/' . $file;
  }

  if ($wrt->{cache_includes}) {
    if (defined $wrt->{include_cache}->{$file}) {
      return $wrt->{include_cache}->{$file};
    }
  }

  unless (-e $file) {
    carp "No such file: $file";
    return '';
  }

  if (-d $file) {
    carp("Tried to open a directory as an include path: $file");
    return '';
  }

  if ($wrt->{cache_includes}) {
    $wrt->{include_cache}->{$file} = file_get_contents($file);
    return $wrt->{include_cache}->{$file};
  } else {
    return file_get_contents($file);
  }
}

=item textile_process

Inline replace <textile> markup in a string.

=cut

# This is exactly the kind of code that, even though it isn't doing anything
# especially over the top, looks ghastly to people who don't read Perl, so I'll
# try to explain a bit.

sub textile_process {

  # First, there's a state variable here which can retain the Text::Textile
  # object between invocations of the function, saving us a bit of time on
  # subsequent calls.  This should be equivalent to creating a closure around
  # the function and keeping a $textile variable there.
  state $textile;

  # Second, instead of unrolling the arguments to the function, we just act
  # directly on the first (0th) one.  =~ more or less means "do a regexy
  # thing on this".  It's followed by s, the substitution operator, which can
  # use curly braces as delimiters between pattern and replacement.

  $_[0] =~ s{

    # Find tags...

    <textile>  # start tag
      (.*?)    # anything (non-greedy)
    </textile> # end tag

  }{

    # ...and replace them with the result of evaluating this block.

    # //= means "defined-or-equals"; if the var hasn't been defined yet,
    # then make a new Textile object:
    $textile //= Text::Textile->new();

    # Process the stuff we slurped out of our tags - this value will be
    # used to replace the entire match from above (in Perl, the last
    # expression evaluated is the return value of subs, evals, etc.):
    $textile->process($1);

  }xesg;

  # x: eXtended regexp - whitespace ignored by default, comments allowed
  # e: Execute the replacement as Perl code, and use its value
  # s: treat all lines of the search subject as a Single string
  # g: Globally replace all matches

  # For the genuinely concise version of this, see markdown_process().
}

=item markdown_process

Inline replace <markdown> markup in a string.

=cut

sub markdown_process {
  state $markdown;

  my $flags = Text::Markdown::Discount::MKD_EXTRA_FOOTNOTE();

  $_[0] =~ s{
    <markdown>(.*?)</markdown>
  }{
    $markdown //= Text::Markdown::Discount->new;
    $markdown->markdown($1, $flags);
  }xesg;
}

=item image_markup

Parse out an image tag and return the appropriate html.

Relies on image_size from App::WRT::Image.

=cut

sub image_markup {
    my $self = shift;
    my ($file, $block) = @_;

    # Get a basename and directory for the file (entry) referencing the image:
    my ($basename, $dir) = fileparse($file);

    # Truncated file date that just includes date + sub docs:
    my ($file_date) = $dir =~ m{
        (
            [0-9]{4}/   # year
            [0-9]{1,2}/ # month
            [0-9]{1,2}/ # day
            ([a-z]*/)*  # sub-entries
        )
        $
    }x;

    # Process the contents of the <image> tag:
    my ($image_url, $alt_text, $title_text) = split /\n/, $block;
    $alt_text   ||= q{};
    $title_text ||= $alt_text;

    # Resolve relative paths:
    my $image_file;
    if (-e "$dir/$image_url" ) {
        # The path is to an image file in the same directory as current entry:
        $image_file = "$dir/$image_url";
        $image_url = "${file_date}${image_url}";
    } elsif (-e $self->{entry_dir} . "/$image_url") {
        # The path is to an image file starting with the entry_dir, like
        # 2005/9/20/candles.jpg -> ./archives/2005/9/20/candles.jpg
        $image_file = $self->{entry_dir} . "/$image_url";
    }

    # Get width & height in pixels for known filetypes:
    my ($width, $height) = image_size($self->{root_dir_abs} . '/' . $image_file);

    # This probably relies on mod_rewrite working:
    $image_url = $self->{image_url_root} . $image_url;
    return <<"IMG";
<img src="$image_url"
     width="$width"
     height="$height"
     alt="$alt_text"
     title="$title_text" />
IMG
}

=back

1;
