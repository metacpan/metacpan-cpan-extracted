
=head1 NAME

App::Basis::ConvertText2

=head1 SYNOPSIS

TO be used in conjuction with the supplied ct2 script, which is part of this distribution.
Not really to be used on its own.

=head1 DESCRIPTION

This is a perl module and a script that makes use of %TITLE%

This is a wrapper for [pandoc] implementing extra fenced code-blocks to allow the
creation of charts and graphs etc.
Documents may be created a variety of formats. If you want to create nice PDFs
then it can use [PrinceXML] to generate great looking PDFs or you can use [wkhtmltopdf] to create PDFs that are almost as good, the default is to use pandoc which, for me, does not work as well.

HTML templates can also be used to control the layout of your documents.

The fenced code block handlers are implemented as plugins and it is a simple process to add new ones.

There are plugins to handle

    * ditaa
    * mscgen
    * graphviz
    * uml
    * gnuplot
    * gle
    * sparklines
    * charts
    * barcodes and qrcodes
    * and many others

See 
https://github.com/27escape/App-Basis-ConvertText2/blob/master/README.md
for more information.

=head1 Todo

Consider adding plugins for 

    * http://blockdiag.com/en/index.html, 
    * https://metacpan.org/pod/Chart::Strip
    * https://metacpan.org/pod/Chart::Clicker

=head1 Public methods

=over 4

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2;
$App::Basis::ConvertText2::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use feature 'state';
use Moo;
use Data::Printer;
use Try::Tiny;
use Path::Tiny;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);
use Text::Markdown qw(markdown);
use GD;
use MIME::Base64;
use Furl;
use Module::Pluggable
    require          => 1,
    on_require_error => sub {
    my ( $plugin, $err ) = @_;
    warn "$plugin, $err";
    };
use App::Basis;
use App::Basis::ConvertText2::Support;

# ----------------------------------------------------------------------------
# this contents string is to be replaced with the body of the markdown file
# when it has been converted
use constant CONTENTS => '_CONTENTS_';
use constant PANDOC   => 'pandoc';
use constant PRINCE   => 'prince';
use constant WKHTML   => 'wkhtmltopdf';

my %valid_tags;

# ----------------------------------------------------------------------------
my $TITLE = "%TITLE%";

# ----------------------------------------------------------------------------

has 'name'    => ( is => 'ro', );
has 'basedir' => ( is => 'ro', );

has 'use_cache' => ( is => 'rw', default => sub { 0; } );

has 'cache_dir' => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        return "/tmp/" . get_program() . "/cache/";
    },
    writer => "_set_cache_dir"
);

has 'template' => (
    is      => 'rw',
    default => sub {
        "<!DOCTYPE html'>
<html>
    <head>
        <title>$TITLE</title>
        <style type='text/css'>
            \@page { size: A4 }
        </style>
    </head>
    <body>
        <h1>%TITLE%</h1>

        %_CONTENTS_%
    </body>
</html>\n";
    },
);

has 'replace' => (
    is      => 'ro',
    default => sub { {} },
);

has 'verbose' => (
    is      => 'ro',
    default => sub {0},
);

has '_output' => (
    is       => 'ro',
    default  => sub {""},
    init_arg => 0
);

has '_input' => (
    is       => 'ro',
    writer   => '_set_input',
    default  => sub {""},
    init_arg => 0
);

has '_md5id' => (
    is       => 'ro',
    writer   => '_set_md5id',
    default  => sub {""},
    init_arg => 0
);

has 'embed' => (
    is      => 'ro',
    default => sub {0},
);

# ----------------------------------------------------------------------------

=item new

Create a new instance of a of a data formating object

B<Parameters>  passed in a HASH
    name        - name of this formatting action - required
    basedir     - root directory of document being processed
    cache_dir   - place to store cache files - optional
    use_cache   - decide if you want to use a cache or not
    template    - HTML template to use, must contain %_CONTENTS_%
    replace     - hashref of extra keywords to use as replaceable variables
    verbose     - be verbose
    embed       - embed images, do not create links to them

=cut

sub BUILD {
    my $self = shift;

    die "No name provided" if ( !$self->name() );

    if ( $self->use_cache() ) {

        # need to add the name to the cache dirname to make it distinct
        $self->_set_cache_dir( fix_filename( $self->cache_dir() . "/" . $self->name() ) );

        if ( !-d $self->cache_dir() ) {

            # create the cache dir if needed
            try {
                path( $self->cache_dir() )->mkpath;
            }
            catch {};
            die "Could not create cache dir " . $self->cache_dir() if ( !-d $self->cache_dir() );
        }
    }

    # work out what plugins do what
    foreach my $plug ( $self->plugins() ) {
        my $obj = $plug->new();
        if ( !$obj ) {
            warn "Plugin $plug does not instantiate";
            next;
        }

        # the process method does the work for all the tag handlers
        if ( !$obj->can('process') ) {
            warn "Plugin $plug does not provide a process method";
            next;
        }
        foreach my $h ( @{ $obj->handles } ) {
            $h = lc($h);
            if ( $h eq 'buffer' ) {
                die "Plugin $plug cannot provide a handler for $h, as this is already provided for internally";
            }
            if ( $valid_tags{$h} ) {
                die "Plugin $plug cannot provide a handler for $h, as this is already provided by $valid_tags{ $h }";
            }

            # all handlers are lower case
            $valid_tags{$h} = $obj;
        }
    }

    # buffer is a special internal handler
    $valid_tags{buffer} = 1;
}

# ----------------------------------------------------------------------------

sub _append_output {
    my $self = shift;
    my $str  = shift;

    $self->{output} .= $str if ($str);
}

# ----------------------------------------------------------------------------
# store a file to the cache
# if the contents are empty then any existing cache file will be removed
sub _store_cache {
    my $self = shift;
    my ( $filename, $contents ) = @_;

    # don't do any cleanup if we are not using a cache
    return if ( !$self->use_cache() );

    # for some reason sometimes the full cache dir is not created or
    # something deletes part of it, cannot figure it out
    path( $self->cache_dir() )->mkpath if ( !-d $self->cache_dir() );

    # make sure we are working in the right dir
    my $f = $self->cache_dir() . "/" . path($filename)->basename;

    if ( !$contents && -f $f ) {
        unlink($f);
    }
    else {
        path($f)->spew_raw($contents);
    }
}

# ----------------------------------------------------------------------------
# get a file from the cache
sub _get_cache {
    my $self = shift;
    my ($filename) = @_;

    # don't do any cleanup if we are not using a cache
    return if ( !$self->use_cache() );

    # make sure we are working in the right dir
    my $f = $self->cache_dir() . "/" . path($filename)->basename;

    my $result;
    $result = path($f)->slurp_raw if ( -f $f );

    return $result;
}

# ----------------------------------------------------------------------------

=item clean_cache

Remove all files from the cache

=cut

sub clean_cache {
    my $self = shift;

    # don't do any cleanup if we are not using a cache
    return if ( !$self->use_cache() );

    try { path( $self->cache_dir() )->remove_tree } catch {};

    # and make it fresh again
    path( $self->cache_dir() )->mkpath();
}

# ----------------------------------------------------------------------------
# _extract_args
sub _extract_args {
    my $buf = shift;
    my ( %attr, $eaten );
    return \%attr if ( !$buf );

    while ( $buf =~ s|^\s?(([a-zA-Z][a-zA-Z0-9\.\-_]*)\s*)|| ) {
        $eaten .= $1;
        my $attr = lc $2;
        my $val;

        # The attribute might take an optional value (first we
        # check for an unquoted value)
        if ( $buf =~ s|(^=\s*([^\"\'>\s][^>\s]*)\s*)|| ) {
            $eaten .= $1;
            $val = $2;

            # or quoted by " or '
        }
        elsif ( $buf =~ s|(^=\s*([\"\'])(.*?)\2\s*)||s ) {
            $eaten .= $1;
            $val = $3;

            # truncated just after the '=' or inside the attribute
        }
        elsif ($buf =~ m|^(=\s*)$|
            or $buf =~ m|^(=\s*[\"\'].*)|s )
        {
            $buf = "$eaten$1";
            last;
        }
        else {
            # assume attribute with implicit value
            $val = $attr;
        }
        $attr{$attr} = $val;
    }

    return \%attr;
}

# ----------------------------------------------------------------------------
# add into the replacements list
sub _add_replace {
    my $self = shift;
    my ( $key, $val ) = @_;

    $self->{replace}->{ uc($key) } = $val;
}

# ----------------------------------------------------------------------------
sub _do_replacements {
    my $self = shift;
    my ($content) = @_;

    foreach my $k ( keys %{ $self->replace() } ) {
        next if ( !$self->{replace}->{$k} );

        # in the text the variables to be replaced are surrounded by %
        # zero width look behind to make sure the variable name has
        # not been escaped _%VARIABLE% should be left alone
        $content =~ s/(?<!_)%$k%/$self->{replace}->{$k}/gsm;
    }

    return $content;
}

# ----------------------------------------------------------------------------
sub _call_function {
    my $self = shift;
    my ( $block, $params, $content, $linepos ) = @_;
    my $out;

    if ( !$valid_tags{$block} ) {
        debug( "ERROR:", "no valid handler for $block" );
    }
    else {
        try {

            # buffer is a special construct to allow us to hold output of content
            # for later, allows multiple use of content or adding things to
            # markdown tables that otherwise we could not do

            # over-ride content with buffered content
            my $from = $params->{from} || $params->{from_buffer};
            if ($from) {
                $content = $self->{replace}->{ uc($from) };
            }

            my $to = $params->{to} || $params->{to_buffer};

            if ( $block eq 'buffer' ) {
                if ($to) {
                    $self->_add_replace( $to, $content );
                }
            }
            else {
                # do any replacements we know about in the content block
                $content = $self->_do_replacements($content);

                # run the plugin with the data we have
                $out = $valid_tags{$block}->process( $block, $content, $params, $self->cache_dir() );

                if ( !$out ) {

                    # if we could not generate any output, lets put the block back together
                    $out .= "~~~~{.$block " . join( " ", map {"$_='$params->{$_}'"} keys %{$params} ) . " }\n" . "~~~~\n";
                }
                elsif ($to) {

                    # do we want to buffer the output?
                    $self->_add_replace( $to, $out );

                    # option not to show the output
                    $out = "" if ( $params->{no_output} );
                }
            }
            $self->_append_output("$out\n") if ( defined $out );
        }
        catch {
            debug( "ERROR", "failed processing $block near line $linepos, $_" );
            warn "Issue processing $block around line $linepos";
            $out = "~~~~{.$block " . join( " ", map {"$_='$params->{$_}'"} keys %{$params} ) . " }\n" . "~~~~\n";
            $self->_append_output($out);
        };
    }
}

# ----------------------------------------------------------------------------
### _parse_lines
# parse the passed data
sub _parse_lines {
    my $self  = shift;
    my $lines = shift;
    my $count = 0;

    return if ( !$lines );

    my ( $class, $block, $content, $attributes );
    my ( $buildline, $simple );
    try {
        foreach my $line ( @{$lines} ) {
            $count++;

            # header lines may have been removed
            next if ( !defined $line );

            if ( defined $simple ) {
                if ( $line =~ /^~{4,}\s?$/ ) {
                    $self->_append_output("~~~~\n$simple\n~~~~\n");
                    $simple = undef;
                }
                else {
                    $simple .= "$line\n";
                }

                next;
            }

            # we may need to add successive lines together to get a completed fenced code block
            if ( !$block && $buildline ) {
                $buildline .= " $line";
                if ( $line =~ /\}\s*$/ ) {
                    $line = $buildline;

                    # make sure to clear the builder
                    $buildline = undef;
                }
                else {
                    # continue to build the line
                    next;
                }
            }

            # a simple block does not have an identifying {.tag}
            if ( $line =~ /^~{4,}\s?$/ && !$block ) {
                $simple = "";
                next;
            }

            if ( $line =~ /^~{4,}/ ) {

                # does the fenced line wrap before its ended
                if ( !$block && $line !~ /\}\s*$/ ) {

                    # we need to start adding lines till its completed
                    $buildline = $line;
                    next;
                }

                if ( $line =~ /\{(.*?)\.(\w+)\s*(.*?)\}\s*$/ ) {
                    $class      = $1;
                    $block      = lc($2);
                    $attributes = $3;
                }
                elsif ( $line =~ /\{\.(\w+)\s?\}\s*$/ ) {
                    $block      = lc($1);
                    $attributes = {};
                }
                else {
                    my $params = _extract_args($attributes);

                    # must have reached the end of a block
                    if ( $block && $valid_tags{$block} ) {
                        chomp $content;
                        $self->_call_function( $block, $params, $content, $count );
                    }
                    else {
                        if ( !$block ) {

                            # put it back
                            $content ||= "";
                            $self->_append_output("~~~~\n$content\n~~~~\n");

                        }
                        else {
                            $content    ||= "";
                            $attributes ||= "";
                            $block      ||= "";

                            # put it back
                            $self->_append_output("~~~~{ $class .$block $attributes}\n$content\n~~~~\n");

                        }
                    }
                    $content    = "";
                    $attributes = "";
                    $block      = "";
                }
            }
            else {
                if ($block) {
                    $content .= "$line\n";
                }
                else {
                    $self->_append_output("$line\n");
                }
            }
        }
    }
    catch {
        die "Issue at line $count $_";
    };
}

# ----------------------------------------------------------------------------
# fetch any img references and copy into the cache, if the image is already
# in the cache then nothing will happen, will rewrite other img uri's
sub _rewrite_imgsrc {
    my $self = shift;
    my ( $pre, $img, $post, $want_size ) = @_;
    my $ext;
    if ( $img =~ /\.(\w+)$/ ) {
        $ext = $1;
    }

    # if its an image we have generated then it may already be here
    # check to see if we have this in the cache
    my $cachefile = cachefile( $self->cache_dir, $img );
    if ( !-f $cachefile ) {
        my $id = md5_hex($img);
        $id .= ".$ext";

        # this is what it will be named in the cache
        $cachefile = cachefile( $self->cache_dir, $id );

        # not in the cache so we must fetch it and store it local to the cache
        # if we are a local file
        if ( $img !~ m|^\w+://| || $img =~ m|^file://| ) {
            $img =~ s|^file://||;
            $img = fix_filename($img);

            if ( $img !~ m|/| ) {

                # if file is relative, then we need to add the basedir
                $img = $self->basedir . "/$img";
            }

            # copy it to the cache location
            try {
                path($img)->copy($cachefile);
            }
            catch {
                debug( "ERROR", "failed to copy $img to $cachefile" );
            };

            $img = $cachefile if ( -f $cachefile );
        }
        else {
            if ( $img =~ m|^(\w+)://(.*)| ) {

                my $furl = Furl->new(
                    agent   => get_program(),
                    timeout => 0.2,
                );

                my $res = $furl->get($img);
                if ( $res->is_success ) {
                    path($cachefile)->spew_raw( $res->content );
                    $img = $cachefile;
                }
                else {
                    debug( "ERROR", "unknown could not fetch $img" );
                }
            }
            else {
                debug( "ERROR", "unknown protocol for $img" );
            }
        }
    }
    else {
        $img = $cachefile;
    }

    # make sure we add the image size if its not already there
    if ( $want_size && $pre !~ /width=|height=/i && $post !~ /width=|height=/i ) {
        my $image = GD::Image->new($img);
        if ($image) {
            $post =~ s/\/>$//;
            $post .= " height='" . $image->height() . "' width='" . $image->width() . "' />";
        }
    }

    # do we need to embed the images, if we do this then libreoffice may be pants
    # however 'prince' is happy
    if ( $self->embed() ) {

        # we encode the image as base64 so that the HTML document can be moved with all images
        # intact
        my $base64 = MIME::Base64::encode( path($img)->slurp_raw );
        $img = "data:image/$ext;base64,$base64";
    }
    return $pre . $img . $post;
}

# ----------------------------------------------------------------------------
# grab all the h2/h3 elements and make them toc items

sub _build_toc {
    my $html = shift;

    my @items = ( $html =~ m|<h[23].*?><a name=['"'](.*?)['"]>(.*?)</a></h[23]>|gsm );

    my $toc = "<p>Contents</p>\n<ul>\n";
    for ( my $i = 0; $i < scalar(@items); $i += 2 ) {
        my $ref = $items[$i];

        my $h = $items[ $i + 1 ];

        # remove any href inside the header title
        $h =~ s/<\/?a.*?>//g;

        if ( $h =~ /^\d+\./ ) {
            $h = "&nbsp;&nbsp;&nbsp;$h";
        }

        # make sure reference is in lower case
        $toc .= "  <li><a href='#$ref'>$h</a></li>\n";
    }

    $toc .= "</ul>\n";

    return $toc;
}

# ----------------------------------------------------------------------------
# rewrite the headers so that they are nice for the TOC
sub _rewrite_hdrs {
    state $counters = { 2 => 0, 3 => 0, 4 => 0 };
    state $last_lvl = 0;
    my ( $head, $txt, $tail ) = @_;
    my $pre;

    my ($lvl) = ( $head =~ /<h(\d)/i );
    my $ref = $txt;

    if ( $lvl < $last_lvl ) {
        debug( "ERROR", "something odd happening in _rewrite_hdrs" );
    }
    elsif ( $lvl > $last_lvl ) {

        # if we are stepping back up a level then we need to reset the counter below
        if ( $lvl == 3 ) {
            $counters->{4} = 0;
        }
        elsif ( $lvl == 2 ) {
            $counters->{3} = 0;
            $counters->{4} = 0;
        }

    }
    $counters->{$lvl}++;

    if    ( $lvl == 2 ) { $pre = "$counters->{2}"; }
    elsif ( $lvl == 3 ) { $pre = "$counters->{2}.$counters->{3}"; }
    elsif ( $lvl == 4 ) { $pre = "$counters->{2}.$counters->{3}.$counters->{4}"; }

    $ref =~ s/\s/_/gsm;

    # remove things we don't like from the reference
    $ref =~ s/[\s'"\(\)\[\]<>]//g;

    my $out = "$head<a name='$pre" . "_" . lc($ref) . "'>$pre $txt</a>$tail";
    return $out;
}

# ----------------------------------------------------------------------------
# use pandoc to parse markdown into nice HTML
# pandoc has extra features over and above markdown, eg syntax highlighting
# and tables
# pandoc must be in user path

sub _pandoc_html {
    my $input = shift;

    my $resp = execute_cmd(
        command     => PANDOC . " --email-obfuscation=none -S -R --normalize -t html5 --highlight-style='kate'",
        timeout     => 30,
        child_stdin => $input
    );

    my $html;

    debug( "Pandoc: " . $resp->{stderr} ) if ( $resp->{stderr} );
    if ( !$resp->{exit_code} ) {
        $html = $resp->{stdout};
    }
    else {
        debug( "ERROR", "Could not parse with pandoc, using markdown" );
        warn "Could not parse with pandoc, using markdown";
        $html = markdown($input);
    }

    return $html;
}

# ----------------------------------------------------------------------------
# use pandoc to convert HTML into another format
# pandoc must be in user path

sub _pandoc_format {
    my ( $input, $output ) = @_;
    my $status = 1;

    my $resp = execute_cmd(

        command => PANDOC . " $input -o $output",
        timeout => 30,
    );

    debug( "Pandoc: " . $resp->{stderr} ) if ( $resp->{stderr} );
    if ( !$resp->{exit_code} ) {
        $status = 0;
    }
    else {
        debug( "ERROR", "Could not parse with pandoc" );
        $status = 1;
    }

    return $status;
}

# ----------------------------------------------------------------------------
# convert_file
# convert the file to a different format from HTML
#  parameters
#     file    - file to re-convert
#     format  - format to convert to
#     pdfconvertor  - use prince/wkhtmltopdf rather than pandoc to convert to PDF

sub _convert_file {
    my $self = shift ;
    my ( $file, $format, $pdfconvertor ) = @_;

    # we work on the is that pandoc should be in your PATH
    my $fmt_str = $format;
    my ( $outfile, $exit );

    $outfile = $file;
    $outfile =~ s/\.(\w+)$/.pdf/;

    # we can use prince to do PDF conversion, its faster and better, but not free for commercial use
    # you would have to ignore the P symbol on the resultant document
    if ( $format =~ /pdf/i && $pdfconvertor ) {
        my $cmd;

        if ( $pdfconvertor =~ /^prince/i ) {
            $cmd = PRINCE . " " ;
            $cmd.= "--pdf-title='$self->{replace}->{TITLE}' " if ($self->{replace}->{TITLE}) ;
            $cmd.= "--pdf-subject='$self->{replace}->{SUBJECT}' " if ($self->{replace}->{SUBJECT}) ;
            $cmd.= "--pdf-creator='$self->{replace}->{AUTHOR}' " if ($self->{replace}->{AUTHOR}) ;
            $cmd.= "--pdf-keywords='$self->{replace}->{KEYWORDS}' " if ($self->{replace}->{KEYWORDS}) ;
            $cmd .= " --media=print $file -o $outfile";
        }
        elsif ( $pdfconvertor =~ /^wkhtmltopdf/i ) {
            $cmd = WKHTML . " -q --print-media-type " ;
            $cmd.= "--title '$self->{replace}->{TITLE}' " if ($self->{replace}->{TITLE}) ;
            # do we want to specify the size
            $cmd .= "--page-size $self->{replace}->{PAGE_SIZE} " if( $self->{replace}->{PAGE_SIZE}) ;
            $cmd .= "$file $outfile";
        }
        else {
            warn "Unknown PDF converter ($pdfconvertor), using pandoc";

            # otherwise lets use pandoc to create the file in the other formats
            $exit = _pandoc_format( $file, $outfile );
        }
        if ($cmd) {
            my ( $out, $err );
            try {
                # say "$cmd" ;
                ( $exit, $out, $err ) = run_cmd($cmd);
            }
            catch {
                $err  = "run_cmd($cmd) died - $_";
                $exit = 1;
            };

            debug( "ERROR", $err ) if ($err);    # only debug if return code is not 0
        }
    }
    else {
        # otherwise lets use pandoc to create the file in the other formats
        $exit = _pandoc_format( $file, $outfile );
    }

    # if we failed to convert, then clear the filename
    return $exit == 0 ? $outfile : undef;
}

# ----------------------------------------------------------------------------

=item parse

parse the markup into HTML and return it, HTML is also stored internally

B<Parameter>  
    markdown text

=cut

sub parse {
    my $self = shift;
    my ($data) = @_;

    die "Nothing to parse" if ( !$data );

    my $id = md5_hex( encode_utf8($data) );

    # my $id = md5_hex( $data );
    $self->_set_md5id($id);
    $self->_set_input($data);

    my $cachefile = cachefile( $self->cache_dir, "$id.html" );
    if ( -f $cachefile ) {
        my $cache = path($cachefile)->slurp_utf8;
        $self->{output} = $cache;    # put cached item into output
    }
    else {
        $self->{output} = "";        # blank the output

        my @lines = split( /\n/, $data );

        # process top 20 lines for keywords
        # maybe replace this with some YAML processor?
        for ( my $i = 0; $i < 20; $i++ ) {
            ## if there is no keyword separator then we must have done the keywords
            last if ( $lines[$i] !~ /:/ );

            # allow keywords to be :keyword or keyword:
            my ( $k, $v ) = ( $lines[$i] =~ /^:?(\w+):?\s+(.*?)\s?$/ );
            next if ( !$k );

            $self->_add_replace( $k, $v );
            $lines[$i] = undef;    # essentially remove the line
        }

        # parse the data find all fenced blocks we can handle
        $self->_parse_lines( \@lines );

        # store the markdown before parsing
        $self->_store_cache( $self->cache_dir() . "/$id.md", encode_utf8( $self->{output} ) );

        # fixup any markdown simple tables | ------ | -> |---------|

        # my @tmp = split( /\n/, $self->{_output} );
        # my $done = 0;
        # for ( my $i = 0; $i < scalar @tmp; $i++ ) {
        #     if ( $tmp[$i] =~ /^\|[\s\|\-\+]+$/ ) {
        #         $tmp[$i] =~ s/\s/-/g;
        #         $done++;
        #     }
        # }
        # $self->{_output} = join( "\n", @tmp ) if ($done);

        # we have created something so we can cache it, if use_cache is off
        # then this will not happen lower down
        # now we convert the parsed output into HTML
        my $pan = _pandoc_html( $self->{output} );

        # add the converted markdown into the template
        my $html = $self->template;
        my $rep  = "%" . CONTENTS . "%";
        $html =~ s/$rep/$pan/gsm;

        # if the user has not used :title, the we need to grab the title from the page so far
        if ( !$self->{replace}->{TITLE} ) {
            my (@h1) = ( $html =~ m|<h1.*?>(.*?)</h1>|gsmi );

            # find the first header that does not contain %TITLE%
            # I failed to get the zero width look-behind wotking
            # my ($h) = ( $html =~ m|<h1.*?>.*?(?<!%TITLE%)(.*?)</h1>|gsmi );
            foreach my $h (@h1) {
                if ( $h !~ /%TITLE/ ) {
                    $self->{replace}->{TITLE} = $h;
                    last;
                }
            }
        }

        # do we need to add a table of contents
        if ( $html =~ /%TOC%/ ) {
            $html =~ s|(<h[234].*?>)(.*?)(</h[234]>)|_rewrite_hdrs( $1, $2, $3)|egsi;
            $self->{replace}->{TOC} = _build_toc($html);
        }

        # replace things we have saved
        $html = $self->_do_replacements($html);

        # and remove any uppercased %word% things that are not processed
        $html =~ s/(?<!_)%[A-Z-_]+\%//gsm;
        $html =~ s/_(%.*?%)/$1/gsm;

        # fetch any images and store to the cache, make sure they have sizes too
        $html =~ s/(<img.*?src=['"])(.*?)(['"].*?>)/$self->_rewrite_imgsrc( $1, $2, $3, 1)/egs;

        # write any css url images and store to the cache
        $html =~ s/(url\s*\(['"]?)(.*?)(['"]?\))/$self->_rewrite_imgsrc( $1, $2, $3, 0)/egs;

        # strip out any HTML comments that may have come in from template
        $html =~ s/<!--.*?-->//gsm;

        $self->{output} = $html;
        $self->_store_cache( $cachefile, $html );
    }
    return $self->{output};
}

# ----------------------------------------------------------------------------

=item save_to_file

save the created html to a named file

B<Parameters>  
    filename    filename to store/convert stored HTML into
    pdfconvertor   indicate that we should use prince or wkhtmltopdf to create PDF

=cut

sub save_to_file {
    state $counter = 0;
    my $self = shift;
    my ( $filename, $pdfconvertor ) = @_;
    my ($format) = ( $filename =~ /\.(\w+)$/ );    # get last thing after a '.'
    if ( !$format ) {
        warn "Could not determine outpout file format, using PDF";
        $format = '.pdf';
    }

    my $f = $self->_md5id() . ".html";

    # have we got the parsed data
    my $cf = cachefile( $self->cache_dir, $f );
    if ( !$self->{output} ) {
        die "parse has not been run yet";
    }

    if ( !-f $cf ) {
        if ( !$self->use_cache() ) {

            # create a file name to store the output to
            $cf = "/tmp/" . get_program() . "$$." . $counter++;
        }

        # either update the cache, or create temp file
        path($cf)->spew_utf8( encode_utf8( $self->{output} ) );
    }

    my $outfile = $cf;
    $outfile =~ s/\.html$/.$format/i;

    # if the marked-up file is more recent than the converted one
    # then we need to convert it again
    if ( $format !~ /html/i ) {

        # as we can generate PDF using a number of convertors we should
        # always regenerate PDF output incase the convertor used is different
        if ( !-f $outfile || $format =~ /pdf/i || ( ( stat($cf) )[9] > ( stat($outfile) )[9] ) ) {
            $outfile = $self->_convert_file( $cf, $format, $pdfconvertor );

            # if we failed to convert, then clear the filename
            if ( !$outfile || !-f $outfile ) {
                $outfile = undef;
                debug( "ERROR", "failed to create output file from cached file $cf" );
            }
        }
    }

    my $status = 0;

    # now lets copy it to its final resting place
    if ($outfile) {
        try {
            $status = path($outfile)->copy($filename);
        }
        catch {
            say STDERR "$_ ";
            debug( "ERROR", "failed to copy $outfile to $filename" );
        };
    }
    return $status;
}

=back

=cut

# ----------------------------------------------------------------------------

1;

__END__
