# Generate RSS and thread from a feed description file.
#
# This module generates RSS feeds and thread indexes of newly-published pages
# or change notes for a web site maintained with App::DocKnot::Spin.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Spin::RSS 7.00;

use 5.024;
use autodie;
use parent qw(App::DocKnot);
use warnings FATAL => 'utf8';

use App::DocKnot::Spin::Thread;
use App::DocKnot::Util qw(print_checked print_fh);
use Carp qw(croak);
use Date::Language ();
use Date::Parse qw(str2time);
use Path::Tiny qw(path);
use POSIX qw(strftime);

##############################################################################
# Utility functions
##############################################################################

# Escapes &, <, and > characters for HTML or XML output.
#
# $string - Input string
#
# Returns: Escaped string
sub _escape {
    my ($string) = @_;
    $string =~ s{ & }{&amp;}xmsg;
    $string =~ s{ < }{&lt;}xmsg;
    $string =~ s{ > }{&gt;}xmsg;
    return $string;
}

# List intersection.
#
# $one - First list
# $two - Second list
#
# Returns: Common elements of both lists as a list
sub _intersect {
    my ($one, $two) = @_;
    my %one = map { $_ => 1 } $one->@*;
    return grep { $one{$_} } $two->@*;
}

# Construct an absolute URL from a relative URL and a base URL.  This plays
# fairly fast and loose with schemes and the like, since we don't need to be
# precise for our purposes.
#
# $url  - Relative URL
# $base - Base URL to which it is relative
#
# Returns: Absolute URL
sub _absolute_url {
    my ($url, $base) = @_;

    # If $url is already absolute, return it.
    return $url if $url =~ m{ \A [[:lower:]]+ : }xms;

    # If $url starts with /, take only the scheme and host from the base URL.
    if ($url =~ m{ \A / }xms) {
        $base =~ s{ \A ( [[:lower:]]+ :// [^/]+ ) .* }{$1}xms;
        return $base . $url;
    }

    # Otherwise, strip the last component off the base URL, and then strip
    # more trailing components off the base URL for every ../ element in the
    # relative URL.  Then glue them together.  This does not deal with the
    # case where there are more ../ elements than there are elements in the
    # base URL.
    $base =~ s{ [^/]+ \z }{}xms;
    while ($url =~ s{ \A [.][.]/+ }{}xms) {
        $base =~ s{ [^/]+ /+ \z }{}xms;
    }
    return $base . $url;
}

# Construct a relative URL from an absolute URL and a base URL.  If there is
# no base URL or if the URLs cannot be made relative to each other, return the
# relative URL unchanged.
#
# $url  - Absolute URL
# $base - URL to which it should be relative
#
# Returns: Relative URL
sub _relative_url {
    my ($url, $base) = @_;
    return $url if !$base;

    # Remove the protocol and host portion from the base URL and ensure that
    # portion matches.
    if ($base =~ s{ \A ( https?:// [^/]+ ) /* }{}xms) {
        my $host = $1;
        if ($url !~ s{ \A \Q$host\E /* }{}xms) {
            return $url;
        }
    } else {
        return $url;
    }

    # Split the base URL into path segments.  While the input URL starts with
    # a matching segment, remove it.  When we run out of matching segments,
    # the relative URL is a number of ../ strings equal to the number of
    # remaining base segments, plus the remaining input URL.
    my @base = split(m{ /+ }xms, $base);
    while ($url && @base) {
        my $segment = shift(@base);
        if ($url !~ s{ \A \Q$segment\E (?: /+ | \z ) }{}xms) {
            return ('../' x (scalar(@base) + 1)) . $url;
        }
    }
    return ('../' x scalar(@base)) . $url;
}

# Spin a file into HTML.
#
# $file - Path::Tiny path to the file
#
# Returns: Rendered HTML as a list with one element per line
sub _spin_file {
    my ($self, $file) = @_;
    my $source = $file->slurp_utf8();
    my $page = $self->{spin}->spin_thread($source, $file);
    return map { "$_\n" } split(m{ \n }xms, $page);
}

# Report an action to standard output.
#
# $action - String description of the action
# $output - Output file generated
# $base   - Base path for all output
sub _report_action {
    my ($self, $action, $output) = @_;
    my $shortout = $output->relative($self->{base} // path(q{.}));
    print_checked("$action .../$shortout\n");
    return;
}

##############################################################################
# Parsing
##############################################################################

# Read key/value blocks in an RFC-2822-style file.
#
# $file - File to read
#
# Returns: List of hashes corresponding to the blocks in the file.
sub _read_rfc2822_file {
    my ($self, $file) = @_;
    my $key;
    my @blocks = ({});
    my $current = $blocks[0];

    # Parse the file.  $key holds the last key seen, used to append
    # continuation values to the previous key.  $current holds the current
    # block being parsed and @blocks all blocks seen so far.
    my $fh = $file->openr_utf8();
    while (defined(my $line = <$fh>)) {
        if ($line =~ m{ \A \s* \z }xms) {
            if ($key) {
                $current = {};
                push(@blocks, $current);
                undef $key;
            }
        } elsif ($line =~ m{ \A (\S+): [ \t]+ ([^\n]+) \Z }xms) {
            my ($new_key, $value) = ($1, $2);
            $value =~ s{ \s+ \z }{}xms;
            $key = lc($new_key);
            $current->{$key} = $value;
        } elsif ($line =~ m{ \A (\S+): \s* \z }xms) {
            my $new_key = $1;
            $key = lc($new_key);
            $current->{$key} //= q{};
        } elsif ($line =~ m{ \A \s }xms) {
            if (!$key) {
                die "$file:$.: invalid continuation line\n";
            }
            my $value = $line;
            $value =~ s{ \A \s }{}xms;
            if ($value =~ m{ \A [.] \s* \Z }xms) {
                $value = "\n";
            }
            if ($current->{$key} && $current->{$key} !~ m{ \n\z }xms) {
                $current->{$key} .= "\n";
            }
            $current->{$key} .= $value;
        } else {
            die "$file:$.: cannot parse line\n";
        }
    }
    close($fh);

    # If the file ends in a blank line, we'll have a stray empty block.
    # Remove it.
    if (!$key) {
        pop(@blocks);
    }

    # Return the parsed blocks.
    return \@blocks;
}

# Parse a change file.  Save the metadata into the provided hash reference and
# the changes into the provided array reference.  Each element of the array
# will be a hash with keys title, date, link, and description.
#
# $file - Path::Tiny path to file to read
#
# Returns: List of reference to metadata hash and reference to a list of
#          hashes of changes
sub _parse_changes {
    my ($self, $file) = @_;
    my $blocks_ref = $self->_read_rfc2822_file($file);

    # The first block is our metadata.  recent defaults to 15.
    my $metadata_ref = shift($blocks_ref->@*);
    if (!defined($metadata_ref->{recent})) {
        $metadata_ref->{recent} = 15;
    }

    # Canonicalize the data for the rest of the blocks, and check for
    # duplicate GUIDs.
    my %guids;
    my $base = $metadata_ref->{base};
    for my $block_ref ($blocks_ref->@*) {
        $block_ref->{date} = str2time($block_ref->{date})
          or die qq{cannot parse date "$block_ref->{date}"\n};

        # Relative links are relative to the base URL in the metadata.
        if ($block_ref->{link} && $base) {
            if ($block_ref->{link} eq q{/}) {
                $block_ref->{link} = $base;
            } else {
                $block_ref->{link} = $base . $block_ref->{link};
            }
        }

        # If no GUID was given, take it from the link for journal and review
        # entries, and otherwise from the date.  Then ensure it's unique.
        my $guid = $block_ref->{guid};
        if (!$guid) {
            if ($block_ref->{journal} || $block_ref->{review}) {
                $guid = $block_ref->{link};
            } else {
                $guid = $block_ref->{date};
            }
        }
        if ($guids{$guid}) {
            die "duplicate GUID for entry $guid\n";
        }
        $block_ref->{guid} = $guid;

        # Determine the tags.
        my @tags = $block_ref->{tags} ? split(q{ }, $block_ref->{tags}) : ();
        if ($block_ref->{review}) {
            push(@tags, 'review');
        }
        $block_ref->{tags} = \@tags;
    }

    # Return the results.
    return ($metadata_ref, $blocks_ref);
}

##############################################################################
# RSS output
##############################################################################

# Format a journal post into HTML for inclusion in an RSS feed.  This depends
# heavily on my personal layout for journal posts.
#
# $file - Path::Tiny path to the journal post
#
# Returns: HTML suitable for including in an RSS feed
sub _rss_journal {
    my ($self, $file) = @_;
    my @page = $self->_spin_file($file);

    # Remove the parts that don't go into the RSS feed.
    while (@page and $page[0] !~ m{ <h1> }xms) {
        shift(@page);
    }
    shift(@page);
    while (@page and $page[0] =~ m{ \A \s* \z }xms) {
        shift(@page);
    }
    while (@page and $page[-1] !~ m{ <div [ ] class="date"><p> }xms) {
        pop(@page);
    }
    pop(@page);
    while (@page and $page[-1] =~ m{ \A \s* \z }xms) {
        pop(@page);
    }

    # Return the rest.
    return join(q{}, @page) . "\n";
}

# Format a review into HTML for inclusion in an RSS feed.  This depends even
# more heavily on my personal layout for review posts.
#
# $file - Path::Tiny path to the review
#
# Returns: HTML suitable for inclusion in an RSS feed
sub _rss_review {
    my ($self, $file, $metadata) = @_;
    my @page = $self->_spin_file($file);

    # Find the title and author because we'll add them back in laater, and
    # remove the preamble of the page not included in the RSS feed.
    my ($title, $author);
    while (@page && $page[0] !~ m{ <table [ ] class="info"> }xms) {
        if ($page[0] =~ m{ <h1> <cite> (.*) </cite> </h1> }xms) {
            $title = $1;
        } elsif ($page[0] =~ m{ <p [ ] class="(?:author|date)">(.*)</p>}xms) {
            $author = $1;
        }
        shift(@page);
    }
    if (!$title || !$author) {
        die "cannot find title and author in $file\n";
    }

    # Remove more stuff not included in the RSS feed.  This is absurdly
    # specific to exactly how I format reviews.
    while (@page && $page[-1] !~ m{ <p [ ] class="rating"> }xms) {
        pop(@page);
    }
    my ($buy, $ebook);
    for my $i (0 .. $#page) {
        if ($page[$i] =~ m{ <p [ ] class="ebook"> }xms) {
            $ebook = $i;
        }
        if ($page[$i] =~ m{ <p [ ] class="buy"> }xms) {
            $buy = $i;
            last;
        }
    }
    if ($buy) {
        splice(@page, $buy, 2);
    }
    if ($ebook) {
        splice(@page, $ebook, 4);
    }

    # Done with line-by-lne processing.  Glue everything together into one
    # page and do a bunch more random HTML cleanup.
    my $page = join(q{}, @page);
    $page =~ s{ ^ \s* <table[^>]+> }{<table>}xmsg;
    $page =~ s{ ^ \s* <tr }{  <tr}xmsg;
    $page =~ s{ ^ \s* <td[^>]+> }{    <td>}xmsg;
    $page =~ s{ </tr> </table> </div> }{</tr></table>}xms;
    $page =~ s{ <div [ ] class="review">}{}xms;
    $page =~ s{ <p [ ] class="rating">}{<p>}xms;
    $page =~ s{
        <span [ ] class="story"><span [ ] id="\S+">(.*?)</span></span>
    }{<strong>$1</strong>}xmsg;

    # Add the author and title to the top of the HTML because we stripped out
    # the top-level heading where this would normally have been.
    $page = "<p>Review: <cite>$title</cite>, $author</p>\n\n" . $page;

    # Return the cleaned-up page.
    return $page . "\n";
}

# Print out the RSS version of the changes information given.  Lots of this is
# hard-coded.  Use the date of the last change as <pubDate> and the current
# time as <lastBuildDate>; it's not completely clear to me that this is
# correct.
#
# $file         - Path::Tiny path to the output file
# $base         - Base Path::Tiny path for input files
# $metadata_ref - Hash of metadata for the RSS feed
# $entries_ref  - Array of entries in the RSS feed
sub _rss_output {
    my ($self, $file, $base, $metadata_ref, $entries_ref) = @_;

    # Determine the current date and latest publication date of all of the
    # entries, published in the obnoxious format used by RSS.
    my $lang = Date::Language->new('English');
    my $format = '%a, %d %b %Y %H:%M:%S %z';
    my $now = $lang->strftime($format, [localtime()]);
    my $latest = $now;
    if ($entries_ref->@*) {
        $latest = strftime($format, localtime($entries_ref->[0]{date}));
    }

    # Determine the URL of the RSS file we're generating, if possible.
    my $url;
    if ($metadata_ref->{'rss-base'}) {
        my $name = $file->basename();
        $url = $metadata_ref->{'rss-base'} . $name;
    }

    # Format the entries.
    my @formatted_entries;
    for my $entry_ref ($entries_ref->@*) {
        my $date = $lang->strftime($format, [localtime($entry_ref->{date})]);
        my $description;
        if ($entry_ref->{description}) {
            $description = _escape($entry_ref->{description});
            $description =~ s{ ^ }{        }xmsg;
            $description =~ s{ \A (\s*) }{$1<p>}xms;
            $description =~ s{ \n* \z }{</p>\n}xms;
        } elsif ($entry_ref->{journal}) {
            my $path = path($entry_ref->{journal})->absolute($base);
            $description = $self->_rss_journal($path);
        } elsif ($entry_ref->{review}) {
            my $path = path($entry_ref->{review})->absolute($base);
            $description = $self->_rss_review($path);
        }

        # Make all relative URLs absolute.
        $description =~ s{
            ( < (?:a [ ] href | img [ ] src) = \" )
            (?!http:)
            ( [./\w] [^\"]+ ) \"
        }{ $1 . _absolute_url($2, $entry_ref->{link}) . qq{\"} }xmsge;

        # Convert this into an object suitable for the output template.
        #<<<
        my $formatted_ref = {
            date        => $date,
            description => $description,
            guid        => $entry_ref->{guid},
            link        => $entry_ref->{link},
            title       => $entry_ref->{title},
        };
        #>>>
        push(@formatted_entries, $formatted_ref);
    }

    # Generate the RSS output using the template.
    #<<<
    my %vars = (
        base            => $metadata_ref->{base},
        description     => $metadata_ref->{description},
        docknot_version => $App::DocKnot::VERSION,
        entries         => \@formatted_entries,
        language        => $metadata_ref->{language},
        latest          => $latest,
        now             => $now,
        title           => $metadata_ref->{title},
        url             => $url,
    );
    #>>>
    my $result;
    $self->{template}->process($self->{templates}{rss}, \%vars, \$result)
      or croak($self->{template}->error());

    # Write the result to the output file.
    $file->spew_utf8($result);
    return;
}

##############################################################################
# Thread output
##############################################################################

# Print out the thread version of the recent changes list.
#
# $file         - Path::Tiny output path
# $metadata_ref - RSS feed metadata
# $entries_ref  - Entries
sub _thread_output {
    my ($self, $file, $metadata_ref, $entries_ref) = @_;

    # The entries are in a flat list, but we want a two-level list of entries
    # by month so that the template can add appropriate month headings.
    # Restructure the entry list accordingly.
    my (@entries_by_month, $last_month);
    for my $entry_ref ($entries_ref->@*) {
        my $month = strftime('%B %Y', localtime($entry_ref->{date}));
        my $date = strftime('%Y-%m-%d', localtime($entry_ref->{date}));

        # Copy the entry with a reformatted description.
        my $description = $entry_ref->{description};
        $description =~ s{ ^ }{    }xmsg;
        $description =~ s{ \\ }{\\\\}xmsg;
        #<<<
        my $formatted_ref = {
            date        => $date,
            description => $description,
            link        => $entry_ref->{link},
            title       => $entry_ref->{title},
        };
        #<<<

        # Add the entry to the appropriate month.
        if (!$last_month || $month ne $last_month) {
            my $month_ref = { heading => $month, entries => [$formatted_ref] };
            push(@entries_by_month, $month_ref);
            $last_month = $month;
        } else {
            push($entries_by_month[-1]{entries}->@*, $formatted_ref);
        }
    }

    # Generate the RSS output using the template.
    #<<<
    my %vars = (
        prefix  => $metadata_ref->{'thread-prefix'},
        entries => \@entries_by_month,
    );
    #>>>
    my $result;
    $self->{template}->process($self->{templates}{changes}, \%vars, \$result)
      or croak($self->{template}->error());

    # Write the result to the output file.
    $file->spew_utf8($result);
    return;
}

##############################################################################
# Index output
##############################################################################

# Translate the thread of a journal entry for inclusion in an index page.
#
# $file - Path::Tiny to the journal entry
#
# Returns: Thread to include in the index page
sub _index_journal {
    my ($self, $file, $url) = @_;
    my $fh = $file->openr_utf8();

    # Skip to the first \h1 and exclude it.
    while (defined(my $line = <$fh>)) {
        last if $line =~ m{ \\h1 }xms;
    }

    # Skip an initial blank line.
    my $text = <$fh>;
    $text =~ s{ \A \s* \z}{}xms;

    # Grab the rest of the entry until the \date command that ends it.
    while (defined(my $line = <$fh>)) {
        last if $line =~ m{ \A \\date }xms;
        $text .= $line;
    }

    # All done.
    close($fh);
    return $text;
}

# Translate the thread of a book review for inclusion into an index page.
#
# $file - Path::Tiny to the book review
#
# Returns: Thread to include in the index page
sub _index_review {
    my ($self, $file) = @_;
    my $title;
    my $author;

    # Regex to match a single "character" in a macro argument.
    my $char = qr{ (?: [^\]\\] | \\entity \[ [^\]]+ \] ) }xms;

    # Scan for the author information and save it.  Handle the case where the
    # \header or \edited line is continued on the next line.
    my $fh = $file->openr_utf8();
    while (defined(my $line = <$fh>)) {
        if ($line =~ m{ \\ (?:header|edited) \s* \[ $char+ \] \s* \z }xms) {
            $line .= <$fh>;
        }
        if ($line =~ m{ \\(header|edited)\s*\[($char+)\]\s*\[($char+)\] }xms) {
            ($title, $author) = ($2, $3);
            if ($1 eq 'edited') {
                $author .= ' (ed.)';
            }
            last;
        }
    }
    if (!defined($author)) {
        die "cannot find author in review $file\n";
    }

    # Add the prefix saying what's being reviewed.
    my $text;
    if ($file =~ m{ /magazines/ }xms) {
        $text = "Review: \\cite[$title], $author\n\n";
    } else {
        $text = "Review: \\cite[$title], by $author\n\n";
    }

    # Add the metadata table.
    $text .= "\\table[][\n";
    while (defined(my $line = <$fh>)) {
        last if $line =~ m{ \A \\div [(]review[)] \[ }xms;
        if ($line =~ m{ \A \s* \\data \[($char+)\] \s* \[($char+)\] }xms) {
            $text .= "    \\tablerow[$1][$2]\n";
        }
    }
    $text .= "]\n\n";

    # Add the rest of the review.
    while (defined(my $line = <$fh>)) {
        last if $line =~ m{ \A \\done }xms;
        $line =~ s{ \\story \[ \d+ \] }{\\strong}xmsg;
        $line =~ s{ \\rating \s* \[($char+)\] }{Rating: $1 out of 10}xms;
        $text .= $line;
    }
    close($fh);
    return $text;
}

# Print out the index version of the recent changes list.
#
# $file         - Path::Tiny path to the output file
# $base         - Base Path::Tiny path for input files
# $metadata_ref - RSS feed metadata
# $entries_ref  - Entries
sub _index_output {
    my ($self, $file, $base, $metadata_ref, $entries_ref) = @_;

    # Format each entry.
    my @formatted_entries;
    for my $entry_ref ($entries_ref->@*) {
        my @time = localtime($entry_ref->{date});
        my $date = strftime('%Y-%m-%d %H:%M', @time);
        my $day = strftime('%Y-%m-%d', @time);

        # Get the text of the entry.
        my $text;
        if ($entry_ref->{journal}) {
            my $path = path($entry_ref->{journal})->absolute($base);
            $text = $self->_index_journal($path);
        } elsif ($entry_ref->{review}) {
            my $path = path($entry_ref->{review})->absolute($base);
            $text = $self->_index_review($path);
        } else {
            die "unknown entry type\n";
        }

        # Make all the URLs absolute and then convert images back to relative
        # based on the URL of the file we're creating.  This handles
        # correcting links from thread from elsewhere in the tree.
        $text =~ s{
            ( \\ (?: link | image ) \s* \[ ) ( [^\]]+ ) \]
        }{ $1 . _absolute_url($2, $entry_ref->{link}) . ']' }xmsge;
        $text =~ s{
            ( \\ image \s* \[ ) ( [^\]]+ ) \]
        }{$1 . _relative_url($2, $metadata_ref->{'index-base'}) . ']' }xmsge;

        # Add the entry to the list.
        #<<<
        my $formatted_ref = {
            date  => $date,
            day   => $day,
            link  => $entry_ref->{link},
            title => $entry_ref->{title},
            text  => $text,
        };
        #>>>
        push(@formatted_entries, $formatted_ref);
    }

    # Generate the RSS output using the template.
    #<<<
    my %vars = (
        prefix  => $metadata_ref->{'index-prefix'},
        suffix  => $metadata_ref->{'index-suffix'},
        entries => \@formatted_entries,
    );
    #>>>
    my $result;
    $self->{template}->process($self->{templates}{index}, \%vars, \$result)
      or croak($self->{template}->error());

    # Write the result to the output file.
    $file->spew_utf8($result);
    return;
}

##############################################################################
# Public interface
##############################################################################

# Create a new RSS generator object.
#
# $args_ref - Anonymous hash of arguments with the following keys:
#   base - Path::Tiny base path for output files
#
# Returns: Newly created object
sub new {
    my ($class, $args_ref) = @_;

    # Create and return the object.
    my $base = defined($args_ref->{base}) ? path($args_ref->{base}) : undef;
    my $tt = Template->new({ ABSOLUTE => 1, ENCODING => 'utf8' })
      or croak(Template->error());
    #<<<
    my $self = {
        base     => $base,
        spin     => App::DocKnot::Spin::Thread->new(),
        template => $tt,
    };
    bless($self, $class);
    $self->{templates} = {
        changes => $self->appdata_path('templates', 'changes.tmpl'),
        index   => $self->appdata_path('templates', 'index.tmpl'),
        rss     => $self->appdata_path('templates', 'rss.tmpl'),
    };
    #>>>
    return $self;
}

# Generate specified output files from an .rss input file.
#
# $source - Path::Tiny path to the .rss file
# $base   - Optional Path::Tiny base path for output
sub generate {
    my ($self, $source, $base) = @_;
    $source = path($source);
    $base //= $self->{base};
    $base = defined($base) ? path($base) : path(q{.});

    # Read in the changes.
    my ($metadata_ref, $changes_ref) = $self->_parse_changes($source);

    # The output key tells us what files to write out.
    my @output = ('*:rss:index.rss');
    if ($metadata_ref->{output}) {
        @output = split(q{ }, $metadata_ref->{output});
    }

    # Iterate through each specified output file.
    for my $output (@output) {
        my ($tags, $format, $file) = split(m{ : }xms, $output);
        $file = path($file);
        if ($file->is_relative()) {
            $file = $file->absolute($base);
        }

        # If the output file is newer than the input file, do nothing.
        next if ($file->exists() && -M "$file" <= -M "$source");

        # Find all the changes of interest to this output file.
        my @entries;
        if ($tags eq q{*}) {
            @entries = $changes_ref->@*;
        } else {
            my @tags = split(m{ , }xms, $tags);
            @entries
              = grep { _intersect($_->{tags}, \@tags) } $changes_ref->@*;
        }

        # Write the output.
        if ($format eq 'thread') {
            $self->_report_action('Generating thread file', $file);
            $self->_thread_output($file, $metadata_ref, \@entries);
        } elsif ($format eq 'rss') {
            if (scalar(@entries) > $metadata_ref->{recent}) {
                splice(@entries, $metadata_ref->{recent});
            }
            $self->_report_action('Generating RSS file', $file);
            $self->_rss_output($file, $base, $metadata_ref, \@entries);
        } elsif ($format eq 'index') {
            if (scalar(@entries) > $metadata_ref->{recent}) {
                splice(@entries, $metadata_ref->{recent});
            }
            $self->_report_action('Generating index file', $file);
            my $index_base = $source->parent();
            $self->_index_output($file, $index_base, $metadata_ref, \@entries);
        }
    }
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT RSS TimeDate YYYY-MM-DD
sublicense hoc rss

=head1 NAME

App::DocKnot::Spin::RSS - Generate RSS and thread from a feed description file

=head1 SYNOPSIS

    use App::DocKnot::Spin::RSS;

    my $rss = App::DocKnot::Spin::RSS->new({ base => 'path/to/tree' });
    $rss->generate('path/to/tree/.rss');

=head1 REQUIREMENTS

Perl 5.24 or later and the modules Date::Language, Date::Parse (both part of
the TimeDate distribution), List::SomeUtils, Path::Tiny, and Perl6::Slurp,
both of which are available from CPAN.

=head1 DESCRIPTION

App::DocKnot::Spin::RSS reads as input a feed description file consisting of
simple key/value pairs and writes out either thread (for input to
App::DocKnot::Spin::Thread) or RSS.  The feed description consists of a
leading block of metadata and then one block per entry in the feed.  Each
block can either include the content of the entry or can reference an external
thread file, in several formats, for the content.  The feed description file
defines one or more output files in the Output field of the metadata.

Output files are only regenerated if they are older than the input feed
description file.

App::DocKnot::Spin::RSS is designed for use with App::DocKnot::Spin.  It
relies on App::DocKnot::Spin::Thread to convert thread to HTML, both for
inclusion in RSS feeds and for post-processing of generated thread files.
App::DocKnot::Spin::RSS is invoked automatically by App::DocKnot::Spin when it
encounters an F<.rss> file in a directory it is processing.

See L<INPUT LANGUAGE> for the details of the language in which F<.rss> files
are written.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Spin::RSS object.  ARGS should be a hash reference
with one or more of the following keys, all of which are optional:

=over 4

=item base

By default, App::DocKnot::Spin::RSS output files are relative to the current
working directory.  If the C<base> argument is given, output files will be
relative to the value of C<base> instead.  Output files specified as absolute
paths will not be affected.  C<base> may be a string or a Path::Tiny object.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item generate(FILE[, BASE])

Parse the input file FILE and generate the output files that it specifies.
BASE, if given, specifies the root directory for output files specified with
relative paths, and overrides any C<base> argument given to new().  Both FILE
and BASE may be strings or Path::Tiny objects.

=back

=head1 INPUT LANGUAGE

The input for App::DocKnot::Spin::RSS is normally a F<.rss> file in a tree
being processed by App::DocKnot::Spin.  The file consists of one or more
blocks of RFC-2822-style fields with values, each separated by a blank line.
Each field and value looks like an e-mail header field, including possible
continuation lines:

    Field: value
     continuation of value

Any line beginning with whitespace is considered a continuation of the
previous line.  If a value should contain a blank line, indicate that blank
line with a continuation line containing only a period.  For example:

    Field: first paragraph
     .
     second paragraph

=head2 Metadata

The first block of the file sets the metadata for this set of output.  The
following fields are supported:

=over 4

=item Base

The base URL for entries in this file.  All links in subsequent blocks of the
file, if not absolute URLs, are treated as relative to this URL and are made
absolute by prepending this URL.  Always specify this key unless all Link
fields in the remainder of the file use absolute URLs.

This field value is also used as the C<< <link> >> element in the RSS feed,
indicating the web site corresponding to this feed.

=item Description

The description of the feed, used only in the RSS output.  This should always
be set if there are any RSS output files.

=item Index-Base

The base URL for output files of type C<index>.  This is used to canonicalize
relative URLs and should be the URL to the directory containing the HTML file
that will result from processing the thread output.  This should be set if
there are any output files of type C<index>; if it isn't set, relative links
may be rewritten incorrectly.

=item Index-Prefix

When generating output files of type C<index>, use the value as the initial
content of the generated thread.  This field should almost always be set if
any output files of type C<index> are defined.  It will contain such things as
the C<\heading> command, any prologue material, initial headings, and so
forth.

=item Index-Suffix

When generating output files of type C<index>, append the value to the end of
the generated thread.  The C<\signature> command is always appended and should
not be included here.  Set this field only if there is other thread that needs
to be appended (such as closing brackets for C<\div> commands).

=item Language

The language of the feed, used only in the RSS output.  This should always be
set if there are any RSS output files.  Use C<en-us> for US English.

=item Output

Specifies the output files for this input file in the form of a
whitespace-separated list of output specifiers.  This field must always be
set.

An output specifier is of the form I<tags>:I<type>:I<file>, where I<file> is
the output file (always a relative path), I<type> is the type of output, and
I<tags> indicates which entries to include in this file.  I<tags> is a
comma-separated list of tags or the special value C<*>, indicating all tags.

There are three types of output:

=over 4

=item index

Output thread containing all recent entries.  This output file honors the
Recent field similar to RSS output and is used to generate something akin to a
journal or blog front page: an HTML version of all recent entries.  It only
supports external entries (entries with C<Journal> or C<Review> fields).  The
C<Index-Base> and C<Index-Prefix> (and possibly C<Index-Suffix>) fields should
be set.

For output for entries with simple descriptions included in the input file,
see the C<thread> output type.

=item rss

Output an RSS file.  App::DocKnot::Spin::RSS only understands the RSS 2.0
output format.  The C<Description>, C<Language>, C<RSS-Base>, and C<Title>
fields should be set to provide additional metadata for the output file.

=item thread

Output thread containing all entries in this input file.  This should only be
used for input files where all entries have their description text inline in
the input file.  Every entry will be included.  The output will be divided
into sections by month, and each entry will be in a description list, with the
title prefixed by the date.  The C<Thread-Prefix> field should be set.

For output that can handle entries from external files, see the C<index>
output type.

=back

=item Recent

Sets the number of recent entries to include in output files of type C<rss> or
C<index> (but not C<thread>, which will include the full contents of the
file).  If this field is not present, the default is 15.

=item RSS-Base

The base URL for RSS files generated by this file.  Each generated RSS file
should have a link back to itself, and that link will be formed by taking the
output name and prepending this field.

=item Thread-Prefix

When generating thread output from this file, use the value as the initial
content of the generated thread.  This field should almost always be set if
any output files of type C<thread> are defined.  It will contain such things
as the C<\heading> command, any prologue material, initial headings, and so
forth.

=item Title

The title of the feed, used only in the RSS output.  This should always be set
if there are any RSS output files.

=back

=head2 Entries

After the first block, each subsequent block in the input file defines an
entry.  Entries take the following fields:

=over 4

=item Date

The date of this entry in ISO date format (YYYY-MM-DD HH:MM).  This field is
required.

=item Description

The inline contents of this entry.  One and only one of this field,
C<Journal>, or C<Review> should be present.  C<Description> fields can only be
used with output types of C<rss> or C<thread>.

=item Journal

Specifies that the content of this entry should be read from an external
thread file given by the value of this field.  The contents of that file are
expected to be in the thread format used by my journal entries:  specifically,
everything is ignored up to the first C<\h1> and after the C<\date> macro, and
the C<\date> line is stripped off (the date information from the C<Date> field
is used instead).

One and only one of this field, C<Description>, or C<Review> should be
present.

=item Link

The link to the page referenced by this entry.  The link is relative to the
C<Base> field set in the input file metadata.  This field is required.

=item Review

Specifies that the content of this entry should be read from an external
thread file given by the value of this field.  The contents of that file are
expected to be in the thread format used by my book reviews.

Many transformations are applied to entries of this sort based on the format
used by my book reviews and the URL layout they use, none of which is
documented at present.  For the time being, see the source code for what
transformations are done.  This support will require modification for use by
anyone else.

One and only one of this field, C<Description>, or C<Review> should be
present.

=item Tags

Whitespace-separated tags for this entry, used to determine whether this entry
will be included in a given output file given its output specification.  In
addition to any tags listed here, any entry with a C<Review> field will
automatically have the C<review> tag.

Entries may have no tags, in which case they're only included in output files
with a tag specification of C<*>.

=item Title

The title of the entry.  This field is required.

=back

=head1 NOTES

RSS 2.0 was chosen as the output format because it supports GUIDs for entries
separate from the entry URLs and hence supports multiple entries for the same
URL, something that I needed for an RSS feed of recent changes to my entire
site.

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2010-2012, 2021-2022 Russ Allbery <rra@cpan.org>

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

L<docknot(1)>, L<App::DocKnot::Spin>, L<App::DocKnot::Spin::Thread>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
