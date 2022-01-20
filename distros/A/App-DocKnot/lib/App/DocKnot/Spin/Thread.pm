# Generate HTML from the macro language thread.
#
# Thread is a macro language designed for producing HTML pages.  This module
# parses thread and generates the corresponding HTML.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Spin::Thread 7.01;

use 5.024;
use autodie;
use warnings FATAL => 'utf8';

use App::DocKnot;
use App::DocKnot::Util qw(print_fh);
use Encode qw(decode);
use Git::Repository ();
use Image::Size qw(html_imgsize);
use Path::Tiny qw(path);
use Perl6::Slurp qw(slurp);
use POSIX qw(strftime);
use Text::Balanced qw(extract_bracketed);

# The URL to the software page for all of my web page generation software,
# used to embed a link to the software that generated the page.
my $URL = 'https://www.eyrie.org/~eagle/software/web/';

# The table of available commands.  The columns are:
#
# 1. Number of arguments or -1 to consume as many arguments as it can find.
# 2. Name of the method to call with the arguments and (if wanted) format.
# 3. Whether to look for a format in parens before the arguments.
#<<<
my %COMMANDS = (
    # name       args  method             want_format
    block     => [1,  '_cmd_block',       1],
    bold      => [1,  '_cmd_bold',        1],
    break     => [0,  '_cmd_break',       0],
    bullet    => [1,  '_cmd_bullet',      1],
    class     => [1,  '_cmd_class',       1],
    cite      => [1,  '_cmd_cite',        1],
    code      => [1,  '_cmd_code',        1],
    desc      => [2,  '_cmd_desc',        1],
    div       => [1,  '_cmd_div',         1],
    emph      => [1,  '_cmd_emph',        1],
    entity    => [1,  '_cmd_entity',      0],
    h1        => [1,  '_cmd_h1',          1],
    h2        => [1,  '_cmd_h2',          1],
    h3        => [1,  '_cmd_h3',          1],
    h4        => [1,  '_cmd_h4',          1],
    h5        => [1,  '_cmd_h5',          1],
    h6        => [1,  '_cmd_h6',          1],
    heading   => [2,  '_cmd_heading',     0],
    image     => [2,  '_cmd_image',       1],
    include   => [1,  '_cmd_include',     0],
    italic    => [1,  '_cmd_italic',      1],
    link      => [2,  '_cmd_link',        1],
    number    => [1,  '_cmd_number',      1],
    pre       => [1,  '_cmd_pre',         1],
    quote     => [3,  '_cmd_quote',       1],
    release   => [1,  '_cmd_release',     0],
    rss       => [2,  '_cmd_rss',         0],
    rule      => [0,  '_cmd_rule',        0],
    signature => [0,  '_cmd_signature',   0],
    sitemap   => [0,  '_cmd_sitemap',     0],
    size      => [1,  '_cmd_size',        0],
    strike    => [1,  '_cmd_strike',      1],
    strong    => [1,  '_cmd_strong',      1],
    sub       => [1,  '_cmd_sub',         1],
    sup       => [1,  '_cmd_sup',         1],
    table     => [2,  '_cmd_table',       1],
    tablehead => [-1, '_cmd_tablehead',   1],
    tablerow  => [-1, '_cmd_tablerow',    1],
    under     => [1,  '_cmd_under',       1],
    version   => [1,  '_cmd_version',     0],
    q{=}      => [2,  '_define_variable', 0],
    q{==}     => [3,  '_define_macro',    0],
    q{\\}     => [0,  '_literal',         0],
);
#>>>

##############################################################################
# Input and output
##############################################################################

# Determine the path to a file relative to the current file being processed.
# If the current file being processed is standard input, the path is relative
# to the current working directory.
#
# $path - File path as a string
#
# Returns: Path::Tiny object holding the absolute path
sub _file_path {
    my ($self, $file) = @_;
    my $input_path = $self->{input}[-1][1];
    if (defined($input_path)) {
        my $path = $input_path->sibling($file);
        return $path->exists() ? $path->realpath() : $path;
    } else {
        return path($file);
    }
}

# Read a file and check it for bad line endings.
#
# $path - Path::Tiny object
#
# Returns: Contents of the file
sub _read_file {
    my ($self, $path) = @_;
    my $text = $path->slurp_utf8();

    # Check for broken line endings.
    if ("\n" !~ m{ \015 }xms && $text =~ m{ \015 }xms) {
        my $m = 'found CR characters; are your line endings correct?';
        $self->_warning($m, $path);
    }

    # Return the contents.
    return $text;
}

# Sends something to the output file with special handling of whitespace for
# more readable HTML output.
#
# @output - Strings to output
sub _output {
    my ($self, @output) = @_;
    my $output = join(q{}, @output);

    # If we have saved whitespace, separate any closing tags at the start of
    # the output from the rest of the output and insert that saved space
    # between those closing tags and the rest of the output.
    #
    # The effect of this is to move whitespace between element bodies and
    # their closing tags to outside of the closing tags, which makes the HTML
    # much more readable.
    if ($self->{space}) {
        my ($prefix, $body) = $output =~ m{
            \A
            (\s*
             (?: </(?!body)[^>]+> \s* )*
            )
            (.*)
        }xms;
        $prefix .= $self->{space};

        # Collapse multiple whitespace-only lines into a single blank line.
        $prefix =~ s{ \n\s* \n\s* \n }{\n\n}xmsg;

        # Replace the output with added whitespace and clear saved whitespace.
        $output = $prefix . $body;
        $self->{space} = q{};
    }

    # Remove and save any trailing whitespace.
    if ($output =~ s{ \n (\s+) \z }{\n}xms) {
        $self->{space} = $1;
    }

    # Send the results to the output file.
    print_fh($self->{out_fh}, $self->{out_path}, $output);
    return;
}

# Report a fatal problem with the current file and line.
#
# $problem - Error message to report
#
# Throws: Text exception with the provided error
sub _fatal {
    my ($self, $problem) = @_;
    my (undef, $file, $lineno) = $self->{input}[-1]->@*;
    $file //= q{-};
    die "$file:$lineno: $problem\n";
}

# Warn about a problem with the current file and line.
#
# $problem - Warning message to report
# $file    - Optional path where the problem was seen, otherwise the current
#            input file is used
sub _warning {
    my ($self, $problem, $file) = @_;
    my $lineno;
    if (!defined($file)) {
        (undef, $file, $lineno) = $self->{input}[-1]->@*;
        $file //= q{-};
    } else {
        $lineno = 0;
    }
    warn "$file:$lineno: $problem\n";
    return;
}

##############################################################################
# Basic parsing
##############################################################################

# Escapes &, <, and > characters for HTML output.
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

# Wrap something in paragraph markers, being careful to get newlines right.
# Special-case a paragraph consisting entirely of <span> by turning it into a
# <p> with the same class.
#
# $text - Text to wrap
#
# Returns: Text wrapped in <p> tags
sub _paragraph {
    my ($self, $text) = @_;

    # Trim leading newline and whitespace and ensure the paragraph ends with a
    # newline.
    $text =~ s{ \A \n (\s*\n)* }{}xms;
    $text =~ s{ ( \S [ \t]* ) \z }{$1\n}xms;

    # If the whole paragraph is wrapped in <span>, lift its attributes into
    # the <p> tag.  Otherwise, just add the <p> tags.  This unfortunately
    # means we also won't lift <span> for any paragraph with nexted \class
    # commands; doing that would require more HTML parsing than I want to do.
    my $re = qr{
        \A                      # start of paragraph
        (\s*)                   # any whitespace (1)
        <span([^>]*)>           # span tag before any text with class (2)
        (?! .* <span)           # no second span tag
        (.*)                    # text of the paragraph (3)
        </span>                 # close span tag
        (\s*)                   # any whitespace (4)
        \z                      # end of paragraph without other text
    }xms;
    if ($text =~ $re) {
        my ($lead, $attrs, $body, $trail) = ($1, $2, $3, $4);
        return "$lead<p$attrs>$body</p>$trail";
    } else {
        $text =~ s{ \A }{<p>\n}xms;
        $text =~ s{ (\n\s*) \z }{\n</p>$1}xms;
        return $text;
    }
}

# Opens the border of a continued structure.
#
# spin, unlike HTML, does not require declaring structures like lists in
# advance of adding elements to them.  You start a bullet list by simply
# having a bullet item, and a list is started if one is not already open.
# This is the method that does that: check whether the desired structure is
# already open and, if not, open it and add it to the state stack.
#
# $border - Name of the border state to open
# $start  - The opening tag
# $end    - The closing tag
#
# Returns: Output to write to start the structure
sub _border_start {
    my ($self, $border, $start, $end) = @_;
    my $state = $self->{state}[-1];
    my $output = q{};

    # If we're at the top-level block structure or inside a structure other
    # than ours, open the structure and add it to the state stack.
    if ($state eq 'BLOCK' || $state->[0] ne $border) {
        $output .= $start;
        push($self->{state}->@*, [$border, $end]);
    }

    return $output;
}

# Closes the border of any currently-open continued structure.  This is done,
# for example, when a new block structure is opened or a paragraph of regular
# text is seen at the same level as the structure elements.
#
# Returns: Output to write to close the structure.
sub _border_end {
    my ($self) = @_;
    my $output = q{};

    # Find all open structures up to the first general block structure.  We'll
    # pop off the block structure so put it back when we're done.
    while (defined(my $state = pop($self->{state}->@*))) {
        last if $state eq 'BLOCK';
        $output .= $state->[1];
    }
    push($self->{state}->@*, 'BLOCK');

    return $output;
}

# Marks the beginning of major block structure.  Within this structure,
# borders will only clear to the level of this structure.
sub _block_start {
    my ($self) = @_;
    push($self->{state}->@*, 'BLOCK');
    return;
}

# Clears a major block structure.
sub _block_end {
    my ($self) = @_;
    my $output = $self->_border_end();
    pop($self->{state}->@*);
    return $output;
}

# Extract some number of arguments from the front of the given string.
#
# $text        - Text to parse arguments from
# $count       - How many arguments to extract, or -1 for as many as possible
# $want_format - If true, check for a parenthesized formatting instruction
#                first and extract it if present
#
# Returns: List of the following strings:
#            $format - Format or empty string, omitted if !$want_format
#            $text   - The remaining unparsed text
#            @args   - $count arguments (undef if the argument wasn't found)
sub _extract {
    my ($self, $text, $count, $want_format) = @_;
    my $format = q{};
    my @args;

    # Extract the format string if requested.
    if ($want_format) {
        $format = extract_bracketed($text, '()') // q{};
        if ($format) {
            $format = substr($format, 1, -1);
        }
    }

    # Extract the desired number of arguments, or all arguments present if
    # $count was negative.
    if ($count >= 0) {
        for my $i (1 .. $count) {
            my $arg = extract_bracketed($text, '[]');
            if (defined($arg)) {
                $arg = substr($arg, 1, -1);
            } else {
                $self->_warning("cannot find argument $i: $@");
                $arg = q{};
            }
            push(@args, $arg);
        }
    } else {
        while (defined(my $arg = extract_bracketed($text, '[]'))) {
            push(@args, substr($arg, 1, -1));
        }
    }

    # Return the results.
    return $want_format ? ($format, $text, @args) : ($text, @args);
}

# Expand a macro invocation.
#
# $definition - Definition of the macro
# $block      - True if currently in block context
# @args       - The arguments to the macro
#
# Returns: List with the macro expansion and the block context flag
sub _macro {
    my ($self, $definition, $block, @args) = @_;

    # The function that expands a macro substitution marker.  If the number of
    # the marker is higher than the number of arguments of the macro, leave it
    # as-is.  (We will have already warned about this when defining the
    # macro.)
    my $expand = sub {
        my ($n) = @_;
        return ($n > scalar(@args)) ? "\\\\$n" : $args[$n - 1];
    };

    # Replace the substitution markers in the macro definition.
    $definition =~ s{ \\(\d+) }{ $expand->($1) }xmsge;

    # Now parse the result as if it were input thread and return the results.
    return $self->_parse_context($definition, $block);
}

# Expand a given command into its representation.  This function is mutually
# recursive with _parse_context and _macro.
#
# $command - Name of the command
# $text    - Input text following the command
# $block   - True if currently in block context (if so, and if the command
#            doesn't generate its own container, it will need to be wrapped
#            in <p>
#
# Returns: List with the following elements:
#            $output - Output from expanding the command
#            $block  - Whether the output is block context
#            $text   - Remaining unparsed text
sub _expand {
    my ($self, $command, $text, $block) = @_;

    # Special handling for expanding variables.  These references look like
    # \=NAME and expand to the value of the variable "NAME".
    if ($command =~ m{ \A = \w }xms) {
        my $variable = substr($command, 1);
        if (exists($self->{variable}{$variable})) {
            return ($self->{variable}{$variable}, 0, $text);
        } else {
            $self->_warning("unknown variable \\=$variable");
            return (q{}, 0, $text);
        }
    }

    # Special handling for macros.  Macros shadow commands of the same name.
    if (exists($self->{macro}{$command})) {
        my ($args, $definition) = $self->{macro}{$command}->@*;

        # Extract the macro arguments, if any were requested.
        my @args;
        if ($args != 0) {
            ($text, @args) = $self->_extract($text, $args, 0);
        }

        # The macro runs in a block context if we're currently in block
        # context and there is no remaining non-whitespace text.  Otherwise,
        # use an inline context.
        $block &&= $text =~ m{ \A \s* \z }xms;

        # Expand the macro.
        my ($result, $blocktag) = $self->_macro($definition, $block, @args);

        # We have now double-counted all of the lines in the macro body
        # itself, so we need to subtract the line count in the macro
        # definition from the line number.
        #
        # This unfortunately means that the line number of errors that happen
        # inside macro arguments will be somewhat off if the macro definition
        # itself contains newlines.  I don't see a way to avoid that without
        # much more complex parsing and state tracking.
        $self->{input}[-1][2] -= $definition =~ tr{\n}{};

        # Return the macro results.
        return ($result, $blocktag, $text);
    }

    # The normal command-handling case.  Ensure it is a valid command.
    if (!ref($COMMANDS{$command})) {
        $self->_warning("unknown command or macro \\$command");
        return (q{}, 1, $text);
    }

    # Dispatch the command to its handler.
    my ($args, $handler, $want_format) = $COMMANDS{$command}->@*;
    if ($want_format) {
        my ($format, $rest, @args) = $self->_extract($text, $args, 1);
        my ($blocktag, $output) = $self->$handler($format, @args);
        return ($output, $blocktag, $rest);
    } else {
        my ($rest, @args) = $self->_extract($text, $args);
        my ($blocktag, $output) = $self->$handler(@args);
        return ($output, $blocktag, $rest);
    }
}

# This is the heart of the input parser.  Take a string of raw input, expand
# the commands in it, and format the results as HTML.  This function is
# mutually recursive with _expand and _macro.
#
# This function is responsible for maintaining the line number in the file
# currently being processed, for error reporting.  The strategy used is to
# increment the line number whenever a newline is seen in processed text.
# This means that newlines are not seen until the text containing them is
# parsed, which in turn means that every argument that may contain a newline
# must be parsed or must update the line number.
#
# $text  - Input text to parse
# $block - True if the parse is done in a block context
#
# Returns: List of the following values:
#            $output - HTML output corresponding to $text
#            $block  - Whether the result is suitable for block level
#
## no critic (Subroutines::ProhibitExcessComplexity)
sub _parse_context {
    my ($self, $text, $block) = @_;

    # Check if there are any commands in the input.  If not, we have a
    # paragraph of regular text.
    if (index($text, q{\\}) == -1) {
        my $output = $text;

        # Update the line number.
        $self->{input}[-1][2] += $text =~ tr{\n}{};

        # If we are at block context, we need to make the text into a block
        # element, which means wrapping it in <p> tags.  Since that is a
        # top-level block construct, also close any open block structure.
        if ($block) {
            $output = $self->_border_end() . $self->_paragraph($output);
        }

        # Return the result.
        return ($output, $block);
    }

    # The output seen so far.
    my $output = q{};

    # Output required to close any open block-level constructs that we saw
    # prior to the text we're currently parsing.
    my $border = q{};

    # Output with inline context that needs to be wrapped in <p> tags.
    my $paragraph = q{};

    # Leading whitespace that should be added to a created paragraph.  This is
    # only non-empty if $paragraph is empty.
    my $space = q{};

    # Whether we saw a construct not suitable for block level.
    my $nonblock = 0;

    # We have at least one command.  Parse the text into sections of regular
    # text and commands, expand the commands, and glue the results together as
    # HTML.
    #
    # If we are at block level, we have to distinguish between plain text and
    # inline commands, which have to be wrapped in paragraph tags, and
    # block-level commands, which shouldn't be.
    while ($text ne q{}) {
        my ($string, $command);

        # Extract text before the next command, or a command name (but none of
        # its arguments).  I think it's impossible for this regex to fail to
        # match as long as $text is non-empty, but do error handling just in
        # case.
        if ($text =~ s{ \A ( [^\\]+ | \\ ([\w=]+ | .) ) }{}xms) {
            ($string, $command) = ($1, $2);
        } else {
            my $context = substr($text, 0, 20);
            $context =~ s{ \n .* }{}xms;
            $self->_fatal(qq(unable to parse near "$context"));
        }

        # Update the line number.
        $self->{input}[-1][2] += $string =~ tr{\n}{};

        # If this is not a command, and we're not at the block level, just add
        # it verbatim to the output.
        #
        # if we are at the block level, pull off any leading space.  If there
        # is still remaining text, add it plus any accumulated whitespace to a
        # new paragraph.
        if (index($string, q{\\}) == -1) {
            if ($block) {
                if ($string =~ s{ \A (\s+) }{}xms) {
                    $space .= $1;
                }
                if ($paragraph ne q{} || $string ne q{}) {
                    if ($paragraph eq q{}) {
                        $border = $self->_border_end();
                    }
                    $paragraph .= $space . $string;
                    $space = q{};
                }
            } else {
                $output .= $string;
                $nonblock = 1;
            }
        }

        # Otherwise, we have a command.  Expand that command, setting block
        # context if we haven't seen any inline content so far.
        else {
            my ($result, $blocktag);
            ($result, $blocktag, $text)
              = $self->_expand($command, $text, $block && $paragraph eq q{});

            # If the result requires block context, output any pending
            # paragraph and then the result.  Otherwise, if we are already at
            # block context, start a new paragraph.  Otherwise, just append
            # the result to our output.
            if ($blocktag) {
                if ($block && $paragraph ne q{}) {
                    $output .= $border . $self->_paragraph($paragraph);
                    $border = q{};
                    $paragraph = q{};
                } else {
                    $output .= $space;
                }
                $output .= $result;
            } elsif ($block) {
                if ($paragraph eq q{}) {
                    $border = $self->_border_end();
                }
                $paragraph .= $space . $result;
                $nonblock = 1;
            } else {
                $output .= $result;
                $nonblock = 1;
            }
            $space = q{};
        }

        # If the next bit of unparsed text starts with a newline, extract it
        # and any following whitespace now.
        if ($text =~ s{ \A \n (\s*) }{}xms) {
            my $spaces = $1;

            # Update the line number.
            $self->{input}[-1][2] += 1 + $spaces =~ tr{\n}{};

            # Add it to our paragraph if we're accumulating one; otherwise,
            # add it to the output, but only add the newline if we saw inline
            # elements or there is remaining text.  This suppresses some
            # useless black lines.
            if ($paragraph ne q{}) {
                $paragraph .= "\n$spaces";
            } else {
                if ($text ne q{} || $nonblock) {
                    $output .= "\n";
                }
                $output .= $spaces;
            }
        }
    }

    # If there is any remaining paragraph text, wrap it in tags and append it
    # to the output.  If we were at block level, our output is always suitable
    # for block level.  Otherwise, it's suitable for block level only if all
    # of our output was from block commands.
    if ($paragraph ne q{}) {
        $output .= $border . $self->_paragraph($paragraph);
    }
    return ($output, $block || !$nonblock);
}
## use critic

# A wrapper around parse_context for callers who don't care about the block
# level of the results.
#
# $text  - Input text to parse
# $block - True if the parse is done in a block context
#
# Returns: HTML output corresponding to $text
sub _parse {
    my ($self, $text, $block) = @_;
    my ($output) = $self->_parse_context($text, $block);
    return $output;
}

# The top-level function for parsing a thread document.  Be aware that the
# working directory from which this function is run matters a great deal,
# since thread may contain relative paths to files that the spinning process
# needs to access.
#
# $thread     - Thread to spin
# $in_path    - Input file path as a Path::Tiny object, or undef
# $out_fh     - Output file handle to which to write the HTML
# $out_path   - Output file path as a Path::Tiny object, or undef
# $input_type - Optional one-word description of input type
sub _parse_document {
    my ($self, $thread, $in_path, $out_fh, $out_path, $input_type) = @_;

    # Parse the thread into paragraphs and reverse them to form a stack.
    my @input = reverse($self->_split_paragraphs($thread));

    # Initialize object state for a new document.
    #<<<
    $self->{input}      = [[\@input, $in_path, 1]];
    $self->{input_type} = $input_type // 'thread';
    $self->{macro}      = {};
    $self->{out_fh}     = $out_fh;
    $self->{out_path}   = $out_path;
    $self->{rss}        = [];
    $self->{space}      = q{};
    $self->{state}      = ['BLOCK'];
    $self->{variable}   = {};
    #>>>

    # Parse the thread file a paragraph at a time.  _split_paragraphs takes
    # care of ensuring that each paragraph contains the complete value of a
    # command argument.
    #
    # The stack of parsed input is maintained in $self->{input} and the file
    # being parsed at any given point is $self->{input}[-1].  _cmd_include
    # will push new file information into this stack, and we pop off the top
    # element of the stack when we exhaust its paragraphs.
    while ($self->{input}->@*) {
        while (defined(my $para = pop($self->{input}[-1][0]->@*))) {
            my $result = $self->_parse(_escape($para), 1);
            $result =~ s{ \A (?:\s*\n)+ }{}xms;
            if ($result !~ m{ \A \s* \z }xms) {
                $self->_output($result);
            }
        }
        pop($self->{input}->@*);
    }

    # Close open tags and print any deferred whitespace.
    print_fh($out_fh, $out_path, $self->_block_end(), $self->{space});
    return;
}

##############################################################################
# Supporting functions
##############################################################################

# Generate the format attributes for an HTML tag.
#
# $format - Format argument to the command
#
# Returns: String suitable for interpolating into the tag, which means it
#          starts with a space if non-empty
sub _format_attr {
    my ($self, $format) = @_;
    return q{} if !$format;

    # Formats starting with # become id tags.  Otherwise, it is a class.
    if ($format =~ s{ \A \# }{}xms) {
        if ($format =~ m{ \s }xms) {
            $self->_warning(qq(space in anchor "#$format"));
        }
        return qq{ id="$format"};
    } else {
        return qq{ class="$format"};
    }
}

# Split a block of text apart at paired newlines so that it can be reparsed as
# paragraphs, but combine a paragraph with the next one if it has an
# unbalanced number of open brackets.  Used to parse the top-level structure
# of a file and by containiners like \block that can contain multiple
# paragraphs.
#
# $text - Text to split
#
# Returns: List of paragraphs
sub _split_paragraphs {
    my ($self, $text) = @_;
    my @paragraphs;

    # Collapse any consecutive newlines at the start to a single newline.
    $text =~ s{ \A \n (\s*\n)+ }{\n}xms;

    # Pull paragraphs off the text one by one.
    while ($text ne q{} && $text =~ s{ \A ( .*? (?: \n\n+ | \s*\z ) )}{}xms) {
        my $para = $1;
        my $open_count = ($para =~ tr{\[}{});
        my $close_count = ($para =~ tr{\]}{});
        while ($text ne q{} && $open_count > $close_count) {
            if ($text =~ s{ \A ( .*? (?: \n\n+ | \s*\z ) )}{}xms) {
                my $extra = $1;
                $open_count += ($extra =~ tr{\[}{});
                $close_count += ($extra =~ tr{\]}{});
                $para .= $extra;
            } else {
                # This should be impossible.
                break;
            }
        }
        push(@paragraphs, $para);
    }

    # Return the paragraphs.
    return @paragraphs;
}

# A simple block element.  Handles splitting the argument on paragraph
# boundaries and surrounding things properly with the tag.
#
# $tag    - Name of the tag
# $border - Initial string to output before the block
# $format - Format string for the block
# $text   - Contents of the block
#
# Returns: Block context, output
sub _block {
    my ($self, $tag, $border, $format, $text) = @_;
    my $output = $border . "<$tag" . $self->_format_attr($format) . '>';
    $self->_block_start();

    # If the format is packed, the contents of the block should be treated as
    # inline rather than block and not surrounded by <p>.  This is how compact
    # bullet or number lists are done.  Otherwise, parse each containing
    # paragraph separately in block context.
    if ($format eq 'packed') {
        $output .= $self->_parse($text, 0);
    } else {
        my @paragraphs = $self->_split_paragraphs($text);
        $output .= join(q{}, map { $self->_parse($_, 1) } @paragraphs);
    }
    $output .= $self->_block_end();

    # Close the tag.  The tag may have contained attributes, which aren't
    # allowed in the closing tag.
    $tag =~ s{ [ ] .* }{}xms;
    $output =~ s{ \s* \z }{</$tag>}xms;
    if ($format ne 'packed') {
        $output .= "\n";
    }

    return (1, $output);
}

# A simple inline element.
#
# $tag    - Name of the tag
# $format - Format string
# $text   - Contents of the element
#
# Returns: Inline context, output
sub _inline {
    my ($self, $tag, $format, $text) = @_;
    my $output = "<$tag" . $self->_format_attr($format) . '>';
    $output .= $self->_parse($text) . "</$tag>";
    return (0, $output);
}

# A heading.  Handles formats of #something specially by adding an <a name>
# tag inside the heading tag to make it a valid target for internal links even
# in old browsers.
#
# $level  - Level of the heading
# $format - Format string
# $text   - Content of the heading
#
# Returns: Block context, output
sub _heading {
    my ($self, $level, $format, $text) = @_;
    my $output = $self->_border_end();
    $text = $self->_parse($text);

    # Special handling for anchors in the format string.
    if ($format =~ m{ \A \# }xms) {
        my $tag = $format;
        $tag =~ s{ \A \# }{}xms;
        $text = qq{<a name="$tag">$text</a>};
    }

    # Build the output.
    $output .= "<h$level" . $self->_format_attr($format) . '>' . $text;
    $output =~ s{ \n \z }{}xms;
    $output .= "</h$level>\n";
    return (1, $output);
}

# Enclose some text in another tag.  If the enclosed text is entirely enclosed
# in <span> or <div> tags, we pull the options of the <span> or <div> out and
# instead apply them to the parent tag.
#
# $tag  - Name of tag
# $text - Text to enclose
sub _enclose {
    my ($self, $tag, $text) = @_;

    # Strip any attributes from the tag.
    my $close_tag = $tag;
    $close_tag =~ s{ [ ] .*}{}xms;

    # Handle <div> and <span> wrapping.
    my $re = qr{
        \A                      # start of paragraph
        (\s*)                   # any whitespace (1)
        < (span | div)          # span or div tag before any text (2)
          ([^>]*)               #   any class attribute for that tag (3)
        >                       # close tag
        (?! .* <\2)             # no second tag
        (.*)                    # text of the paragraph (4)
        </\2>                   # close tag
        (\s*)                   # any whitespace (5)
        \z                      # end of paragraph without other text
    }xms;
    if ($text =~ $re) {
        my ($lead, $class, $body, $trail) = ($1, $3, $4, $5);
        return "$lead<$tag$class>$body</$close_tag>$trail";
    } else {
        return "<$tag>$text</$close_tag>";
    }
}

##############################################################################
# Special commands
##############################################################################

# These methods are all used, but are indirected through the above table, so
# perlcritic gets confused.
#
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

# Define a new macro.  This is the command handler for \==.
#
# $name       - Name of the macro
# $args       - Number of arguments
# $definition - Definition of the macro
#
# Returns: Block context, empty output
sub _define_macro {
    my ($self, $name, $args, $definition) = @_;
    $args = $self->_parse($args);

    # Verify the argument count and definition.
    if ($args !~ m{ \A \d+ \z }xms) {
        $self->_warning("invalid macro argument count for \\$name");
        return (1, q{});
    }
    for my $arg ($definition =~ m{ \\(\d+) }xmsg) {
        if ($arg > $args) {
            my $msg = "invalid macro placeholder \\$arg (greater than $args)";
            $self->_warning($msg);
        }
    }

    # We don't parse the macro definition now but we need to update the line
    # number for accurate error reporting.
    $self->{input}[-1][2] += $definition =~ tr{\n}{};

    # Define the macro.
    $self->{macro}{$name} = [$args, $definition];
    return (1, q{});
}

# Define a new variable.  This is the command handler for \=.
#
# $name  - Name of the variable
# $value - Value of the variable
#
# Returns: Block context, empty output
sub _define_variable {
    my ($self, $name, $value) = @_;
    $self->{variable}{$name} = $self->_parse($value);
    return (1, q{});
}

# Literal backslash.  This is the command handler for \\.
sub _literal { return (0, q{\\}) }

##############################################################################
# Regular commands
##############################################################################

# Basic inline commands.
#<<<
sub _cmd_break  { return (0, '<br />') }
sub _cmd_bold   { my ($self, @a) = @_; return $self->_inline('b',      @a) }
sub _cmd_cite   { my ($self, @a) = @_; return $self->_inline('cite',   @a) }
sub _cmd_class  { my ($self, @a) = @_; return $self->_inline('span',   @a) }
sub _cmd_code   { my ($self, @a) = @_; return $self->_inline('code',   @a) }
sub _cmd_emph   { my ($self, @a) = @_; return $self->_inline('em',     @a) }
sub _cmd_italic { my ($self, @a) = @_; return $self->_inline('i',      @a) }
sub _cmd_strike { my ($self, @a) = @_; return $self->_inline('strike', @a) }
sub _cmd_strong { my ($self, @a) = @_; return $self->_inline('strong', @a) }
sub _cmd_sub    { my ($self, @a) = @_; return $self->_inline('sub',    @a) }
sub _cmd_sup    { my ($self, @a) = @_; return $self->_inline('sup',    @a) }
sub _cmd_under  { my ($self, @a) = @_; return $self->_inline('u',      @a) }
#>>>

# The headings.
sub _cmd_h1 { my ($self, @a) = @_; return $self->_heading(1, @a); }
sub _cmd_h2 { my ($self, @a) = @_; return $self->_heading(2, @a); }
sub _cmd_h3 { my ($self, @a) = @_; return $self->_heading(3, @a); }
sub _cmd_h4 { my ($self, @a) = @_; return $self->_heading(4, @a); }
sub _cmd_h5 { my ($self, @a) = @_; return $self->_heading(5, @a); }
sub _cmd_h6 { my ($self, @a) = @_; return $self->_heading(6, @a); }

# A horizontal rule.
sub _cmd_rule {
    my ($self) = @_;
    return (1, $self->_border_end() . "<hr />\n");
}

# Simple block commands.

sub _cmd_div {
    my ($self, $format, $text) = @_;
    return $self->_block('div', q{}, $format, $text);
}

sub _cmd_block {
    my ($self, $format, $text) = @_;
    return $self->_block('blockquote', q{}, $format, $text);
}

sub _cmd_bullet {
    my ($self, $format, $text) = @_;
    my $border = $self->_border_start('bullet', "<ul>\n", "</ul>\n\n");
    return $self->_block('li', $border, $format, $text);
}

sub _cmd_number {
    my ($self, $format, $text) = @_;
    my $border = $self->_border_start('number', "<ol>\n", "</ol>\n\n");
    return $self->_block('li', $border, $format, $text);
}

# A description list entry.
#
# $format  - Format string
# $heading - Initial heading
# $text    - Body text
sub _cmd_desc {
    my ($self, $format, $heading, $text) = @_;
    $heading = $self->_parse($heading);
    my $format_attr = $self->_format_attr($format);
    my $border = $self->_border_start('desc', "<dl>\n", "</dl>\n\n");
    my $initial = $border . "<dt$format_attr>" . $heading . "</dt>\n";
    return $self->_block('dd', $initial, $format, $text);
}

# An HTML entity.  Check for and handle numeric entities properly, including
# special-casing [ and ] since the user may have needed to use \entity to
# express text that contains literal brackets.
#
# $entity - Entity specification, an HTML name or a Unicode number
sub _cmd_entity {
    my ($self, $char) = @_;
    $char = $self->_parse($char);
    if ($char eq '91') {
        return (0, '[');
    } elsif ($char eq '93') {
        return (0, ']');
    } elsif ($char =~ m{ \A \d+ \z }xms) {
        return (0, "&#$char;");
    } else {
        return (0, "&$char;");
    }
}

# Generates the page heading at the top of the document.  This is where the
# XHTML declarations come from.
#
# $title - Page title
# $style - Page style
sub _cmd_heading {
    my ($self, $title, $style) = @_;
    $title = $self->_parse($title);
    $style = $self->_parse($style);

    # Get the relative URL of the output page, used for sitemap information.
    my $page;
    if (defined($self->{out_path}) && defined($self->{output})) {
        $page = $self->{out_path}->relative($self->{output});
    }

    # Build the page header.
    my $output = qq{<?xml version="1.0" encoding="utf-8"?>\n};
    $output .= qq{<!DOCTYPE html\n};
    $output .= qq{    PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n};
    $output .= qq{    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n};
    $output .= qq{\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"};
    $output .= qq{ lang="en">\n};
    $output .= qq{<head>\n  <title>$title</title>\n};
    $output .= q{  <meta http-equiv="Content-Type"};
    $output .= qq{ content="text/html; charset=utf-8" />\n};

    # Add style sheet.
    if ($style) {
        $style .= '.css';
        if ($self->{style_url}) {
            $style = $self->{style_url} . $style;
        }
        $output .= qq{  <link rel="stylesheet" href="$style"};
        $output .= qq{ type="text/css" />\n};
    }

    # Add RSS links if any.
    for my $rss ($self->{rss}->@*) {
        my ($url, $rss_title) = $rss->@*;
        $output .= q{  <link rel="alternate" type="application/rss+xml"};
        $output .= qq{ href="$url"\n};
        $output .= qq{        title="$rss_title" />\n};
    }

    # Add <link> tags based on the sitemap.
    if ($self->{sitemap} && defined($page)) {
        my @links = $self->{sitemap}->links($page);
        if (@links) {
            $output .= join(q{}, @links);
        }
    }

    # End of the header.
    $output .= "</head>\n\n";

    # Add some generator comments.
    my $date = strftime('%Y-%m-%d %T -0000', gmtime());
    my $input_path = $self->{input}[-1][1];
    my $from = defined($input_path) ? ' from ' . $input_path->basename() : q{};
    my $version = $App::DocKnot::VERSION;
    $output .= "<!-- Spun$from by DocKnot $version on $date -->\n";

    # Add the <body> tag and the navbar (if we have a sitemap).
    $output .= "\n<body>\n";
    if ($self->{sitemap} && defined($page)) {
        my @navbar = $self->{sitemap}->navbar($page);
        if (@navbar) {
            $output .= join(q{}, @navbar);
        }
    }

    return (1, $output);
}

# Include an image.  The size is added to the HTML tag automatically.
#
# $format - Format string
# $image  - Path to the image (may be relative or an absolute URL)
# $alt    - Alt text of image
sub _cmd_image {
    my ($self, $format, $image, $text) = @_;
    $image = $self->_parse($image);
    $text = $self->_parse($text);

    # Determine the size attributes of the image if possible.
    my $path = $self->_file_path($image);
    my $size = $path->exists() ? q{ } . lc(html_imgsize("$path")) : q{};

    # Generate the tag.
    my $output = qq{<img src="$image" alt="$text"$size};
    $output .= $self->_format_attr($format) . ' />';
    return (1, $output);
}

# Include a file.  Note that this includes a file after the current paragraph,
# not immediately, which may be a bit surprising.
sub _cmd_include {
    my ($self, $file) = @_;
    $file = $self->_file_path($self->_parse($file));

    # Read the thread, split it on paragraphs, and reverse it to make a stack.
    my $thread = $self->_read_file($file);
    my @paragraphs = reverse($self->_split_paragraphs($thread));

    # Add it to the file stack.
    push($self->{input}->@*, [\@paragraphs, $file, 1]);

    # Expand into empty output.
    return (1, q{});
}

# A link to a URL or partial URL.
#
# $format - Format string
# $url    - Target URL
# $text   - Anchor text
sub _cmd_link {
    my ($self, $format, $url, $text) = @_;
    $url = $self->_parse($url);
    $text = $self->_parse($text);
    my $format_attr = $self->_format_attr($format);
    return (0, qq{<a href="$url"$format_attr>$text</a>});
}

# Preformatted text.  This does not use _block because we don't want to split
# the contained text into paragraphs and we want to parse it all in inline
# context always.
sub _cmd_pre {
    my ($self, $format, $text) = @_;
    my $output = $self->_border_end();
    $output .= '<pre' . $self->_format_attr($format) . '>';
    $output .= $self->_parse($text);
    $output .= "</pre>\n";
    return (1, $output);
}

# Used for the leading quotes that I have on many of my pages.  If the format
# is "broken", adds line breaks at the end of each line.
#
# $format - Format string, used as the format for the main <p> tag inside the
#           <blockquote>.  Values broken and short trigger special handling,
#           such as adding line breaks or changing the attribution class.
# $quote  - Text of the quote
# $author - Author of the quote
# $cite   - Attribution of the quote
sub _cmd_quote {
    my ($self, $format, $quote, $author, $cite) = @_;
    $author = $self->_parse($author);
    $cite = $self->_parse($cite);
    my $output = $self->_border_end() . q{<blockquote class="quote">};

    # Parse the contents of the quote in a new block context.
    $self->_block_start();
    my @paragraphs = $self->_split_paragraphs($quote);
    $quote = join(q{}, map { $self->_parse($_, 1) } @paragraphs);
    $quote .= $self->_block_end();

    # Remove trailing newlines.
    $quote =~ s{ \n+ \z }{}xms;

    # If this is a broken quote, add line breaks to each line.
    if ($format eq 'broken') {
        $quote =~ s{ ( \S [ ]* ) ( \n\s* (?!</p>)\S )}{$1<br />$2}xmsg;

        # Remove <br /> tags for blank lines or at the start.
        $quote =~ s{ \n <br [ ] /> }{\n}xmsg;
        $quote =~ s{ <p> <br [ ] /> }{<p>}xmsg;
    }

    # If there was a format, apply it to every <p> tag in the quote.
    if ($format) {
        my $format_attr = $self->_format_attr($format);
        $quote =~ s{ <p> }{<p$format_attr>}xmsg;
    }

    # Done with the quote.
    $output .= $quote;

    # Format the author and citation.
    if ($author) {
        my $prefix = q{};
        if ($format eq 'broken' || $format eq 'short') {
            $output .= qq{<p class="attribution">\n};
        } else {
            $output .= qq{<p class="long-attrib">\n};
            $prefix = '&mdash; ';
        }
        if ($cite) {
            $output .= "    $prefix$author,\n    $cite\n";
        } else {
            $output .= "    $prefix$author\n";
        }
        $output .= '</p>';
    } else {
        $output .= "\n";
    }

    # Close the HTML tag and return the output.
    $output .= "</blockquote>\n";
    return (1, $output);
}

# Given the name of a product, return the release date of the product.
sub _cmd_release {
    my ($self, $package) = @_;
    $package = $self->_parse($package);
    if (!$self->{versions}) {
        $self->_warning('no package release information available');
        return (0, q{});
    }
    my $date = $self->{versions}->release_date($package);
    if (!defined($date)) {
        $self->_warning(qq(no release date known for "$package"));
        return (0, q{});
    }
    return (0, $date);
}

# Used to save RSS feed information for the page.  Doesn't output anything
# directly; the RSS feed information is used later in _cmd_heading.
sub _cmd_rss {
    my ($self, $url, $title) = @_;
    $url = $self->_parse($url);
    $title = $self->_parse($title);
    push($self->{rss}->@*, [$url, $title]);
    return (1, q{});
}

# Used to end each page, this adds the navigation links and my standard
# address block.
sub _cmd_signature {
    my ($self) = @_;
    my $input_path = $self->{input}[-1][1];
    my $output = $self->_border_end();

    # If we're spinning from standard input to standard output, don't add any
    # of the standard footer, just close the HTML tags.
    if (!defined($input_path) && !defined($self->{out_path})) {
        $output .= "</body>\n</html>\n";
        return (1, $output);
    }

    # Add the end-of-page navbar if we have sitemap information.
    if ($self->{sitemap} && $self->{output}) {
        my $page = $self->{out_path}->relative($self->{output});
        $output .= join(q{}, $self->{sitemap}->navbar($page)) . "\n";
    }

    # Figure out the modification dates.  Use the Git repository if available.
    my $now = strftime('%Y-%m-%d', gmtime());
    my $modified = $now;
    if (defined($input_path)) {
        $modified = strftime('%Y-%m-%d', gmtime($input_path->stat()->[9]));
    }
    if ($self->{repository} && $self->{source}) {
        if (path($self->{source})->subsumes($input_path)) {
            my $repository = $self->{repository};
            $modified = $self->{repository}->run(
                'log', '-1', '--format=%ct', "$input_path",
            );
            if ($modified) {
                $modified = strftime('%Y-%m-%d', gmtime($modified));
            }
        }
    }

    # Determine which template to use and substitute in the appropriate times.
    $output .= "<address>\n";
    my $link = qq{<a href="$URL">spun</a>};
    if ($modified eq $now) {
        $output .= "    Last modified and\n    $link $modified\n";
    } else {
        $output .= "    Last $link\n";
        $output .= "    $now from $self->{input_type} modified $modified\n";
    }

    # Close out the document.
    $output .= "</address>\n</body>\n</html>\n";
    return (1, $output);
}

# Insert the formatted size in bytes, kilobytes, or megabytes of some local
# file.  We could use Number::Format here, but what we're doing is simple
# enough and doesn't seem worth the trouble of another dependency.
sub _cmd_size {
    my ($self, $file) = @_;
    $file = $self->_file_path($self->_parse($file));

    # Get the size of the file.
    my $size;
    if ($file->exists()) {
        $size = $file->stat()->[7];
    }
    if (!defined($size)) {
        $self->_warning("cannot stat file $file: $!");
        return (0, q{});
    }

    # Format the size using SI units.
    my @suffixes = qw(Ki Mi Gi Ti);
    my $suffix = q{};
    while ($size > 1024 && @suffixes) {
        $size /= 1024;
        $suffix = shift(@suffixes);
    }

    # Return the result.
    return (0, sprintf('%.0f', $size) . $suffix . 'B');
}

# Generates a HTML version of the sitemap and outputs that.
sub _cmd_sitemap {
    my ($self) = @_;
    if (!$self->{sitemap}) {
        $self->_warning('no sitemap file found');
        return (1, q{});
    }
    my $sitemap = join(q{}, $self->{sitemap}->sitemap());
    return (1, $self->_border_end() . $sitemap);
}

# Start a table.  Takes any additional HTML attributes to set for the table
# (this is ugly, but <table> takes so many attributes for which there is no
# style sheet equivalent that it's unavoidable) and the body of the table
# (which should consist of \tablehead and \tablerow lines).
sub _cmd_table {
    my ($self, $format, $options, $body) = @_;
    my $tag = $options ? "table $options" : 'table';
    return $self->_block($tag, q{}, $format, $body);
}

# A heading of a table.  Takes the contents of the cells in that heading.
sub _cmd_tablehead {
    my ($self, $format, @cells) = @_;
    my $output = '  <tr' . $self->_format_attr($format) . ">\n";
    for (@cells) {
        my $text = $self->_parse($_) . $self->_border_end();
        $output .= (q{ } x 4) . $self->_enclose('th', $text) . "\n";
    }
    $output .= "  </tr>\n";
    return (1, $output);
}

# A data line of a table.  Takes the contents of the cells in that row.
sub _cmd_tablerow {
    my ($self, $format, @cells) = @_;
    my $output = '  <tr' . $self->_format_attr($format) . ">\n";
    for (@cells) {
        my $text = $self->_parse($_) . $self->_border_end();
        $output .= (q{ } x 4) . $self->_enclose('td', $text) . "\n";
    }
    $output .= "  </tr>\n";
    return (1, $output);
}

# Given the name of a package, return the version number of its latest
# release.
sub _cmd_version {
    my ($self, $package) = @_;
    if (!$self->{versions}) {
        $self->_warning('no package version information available');
        return (0, q{});
    }
    my $version = $self->{versions}->version($package);
    if (!defined($version)) {
        $self->_warning(qq(no version known for "$package"));
        return (0, q{});
    }
    return (0, $version);
}

##############################################################################
# Public interface
##############################################################################

# Create a new thread to HTML converter.  This object can (and should) be
# reused for all thread conversions done while spinning a tree of files.
#
# $args - Anonymous hash of arguments with the following keys:
#   output    - Root of the output tree
#   sitemap   - App::DocKnot::Spin::Sitemap object
#   source    - Root of the source tree
#   style-url - Partial URL to style sheets
#   versions  - App::DocKnot::Spin::Versions object
#
# Returns: Newly created object
sub new {
    my ($class, $args_ref) = @_;
    my $output;
    if (defined($args_ref->{output})) {
        $output = path($args_ref->{output});
    }

    # Add a trailing slash to the partial URL for style sheets.
    my $style_url = $args_ref->{'style-url'} // q{};
    if ($style_url) {
        $style_url =~ s{ /* \z }{/}xms;
    }

    # Use a Git::Repository object to get modification timestamps if a source
    # tree was specified and it appears to be a git repository.
    my ($source, $repository);
    if (defined($args_ref->{source})) {
        $source = path($args_ref->{source});
        if ($source->child('.git')->is_dir()) {
            $repository = Git::Repository->new(work_tree => "$source");
        }
    }

    # Create and return the object.
    #<<<
    my $self = {
        output     => $output,
        repository => $repository,
        sitemap    => $args_ref->{sitemap},
        source     => $source,
        style_url  => $style_url,
        versions   => $args_ref->{versions},
    };
    #>>>
    bless($self, $class);
    return $self;
}

# Convert thread to HTML and return the output as a string.  The working
# directory still matters for file references in the thread.
#
# $thread - Thread to spin
# $input  - Optional input file path (for relative path and timestamps)
#
# Returns: Resulting HTML
sub spin_thread {
    my ($self, $thread, $input) = @_;
    my $result;
    open(my $out_fh, '>:raw:encoding(utf-8)', \$result);
    $self->_parse_document($thread, $input, $out_fh, undef);
    close($out_fh);
    return decode('utf-8', $result);
}

# Spin a single file of thread to HTML.
#
# $input  - Input file (if not given, assumes standard input)
# $output - Output file (if not given, assumes standard output)
#
# Raises: Text exception on processing error
sub spin_thread_file {
    my ($self, $input, $output) = @_;
    my $out_fh;
    my $thread;

    # Read the input file.
    if (defined($input)) {
        $input = path($input)->realpath();
        $thread = $input->slurp_utf8();
    } else {
        $thread = slurp(\*STDIN);
    }

    # Open the output file.
    if (defined($output)) {
        $output = path($output)->absolute();
        $out_fh = $output->openw_utf8();
    } else {
        open($out_fh, '>&:raw:encoding(utf-8)', 'STDOUT');
    }

    # Do the work.
    $self->_parse_document($thread, $input, $out_fh, $output);

    # Clean up.
    close($out_fh);
    return;
}

# Convert thread to HTML and write it to the given output file.  This is used
# when the thread isn't part of the input tree but instead is intermediate
# output from some other conversion process.
#
# $thread     - Thread to spin
# $input      - Original input file path (for relative path and timestamps)
# $input_type - One-word description of input type for the page footer
# $output     - Output file
#
# Returns: Resulting HTML
sub spin_thread_output {
    my ($self, $thread, $input, $input_type, $output) = @_;
    $input = path($input);

    # Open the output file.
    my $out_fh;
    if (defined($output)) {
        $output = path($output)->absolute();
        $out_fh = $output->openw_utf8();
    } else {
        open($out_fh, '>&:raw:encoding(utf-8)', 'STDOUT');
    }

    # Do the work.
    $self->_parse_document($thread, $input, $out_fh, $output, $input_type);

    # Clean up and restore the working directory.
    close($out_fh);
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense NARGS RCS RSS
preformatted respun

=head1 NAME

App::DocKnot::Spin::Thread - Generate HTML from the macro language thread

=head1 SYNOPSIS

    use App::DocKnot::Spin::Thread;

    my $input  = 'some thread';
    my $thread = App::DocKnot::Spin::Thread->new();
    my $output = $thread->spin_thread($input);

    use App::DocKnot::Spin::Sitemap;
    use App::DocKnot::Spin::Versions;

    my $sitemap  = App::DocKnot::Spin::Sitemap->new('/input/.sitemap');
    my $versions = App::DocKnot::Spin::Versions->new('/input/.versions');
    $thread = App::DocKnot::Spin::Thread->new({
        source   => '/input',
        output   => '/output',
        sitemap  => $sitemap,
        versions => $versions,
    });
    $thread->spin_thread_file('/input/file.th', '/output/file.html');
    $thread->spin_thread_output(
        $input, '/path/to/file.pod', 'POD', '/output/file.html'
    );

=head1 REQUIREMENTS

Perl 5.24 or later and the modules Git::Repository, Image::Size,
List::SomeUtils, and Path::Tiny, all of which are available from CPAN.

=head1 DESCRIPTION

This component of DocKnot implements the macro language thread, which is
designed for writing simple HTML pages using somewhat nicer syntax, catering
to my personal taste, and supporting variables and macros to make writing
pages less tedious.

For the details of the thread language, see L<THREAD LANGUAGE> below.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Spin::Thread object.  A single converter object
can be used repeatedly to convert a tree of files, or can convert a single
file.  ARGS should be a hash reference with one or more of the following
keys, all of which are optional:

=over 4

=item output

The path to the root of the output tree when converting a tree of files.  This
will be used to calculate relative path names for generating inter-page links
using the provided C<sitemap> argument.  If C<sitemap> is given, this option
should also always be given.

=item sitemap

An App::DocKnot::Spin::Sitemap object.  This will be used to create inter-page
links and implement the C<\sitemap> command.  For inter-page links, the
C<output> argument must also be provided.

=item source

The path to the root of the input tree.  If given, and if the input tree
appears to be a Git repository, C<git log> will be used to get more accurate
last modification timestamps for files, which in turn are used to add last
modified dates to the footer of the generated page.

=item style-url

The base URL for style sheets.  A style sheet specified in a C<\heading>
command will be considered to be relative to this URL and this URL will be
prepended to it.  If this option is not given, the name of the style sheet
will be used verbatim as its URL, except with C<.css> appended.

=item versions

An App::DocKnot::Spin::Versions object.  This will be used as the source of
data for the C<\release> and C<\version> commands.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item spin_thread(THREAD[, INPUT])

Convert the given thread to HTML, returning the result.  When run via this
API, App::DocKnot::Spin::Thread will not be able to obtain sitemap information
even if a sitemap was provided and therefore will not add inter-page links.
INPUT, if given, is the full path to the original source file, used for
relative paths and modification time information.

=item spin_thread_file([INPUT[, OUTPUT]])

Convert a single thread file to HTML.  INPUT is the path of the thread file
and OUTPUT is the path of the output file.  OUTPUT or both INPUT and OUTPUT
may be omitted, in which case standard input or standard output, respectively,
will be used.

If OUTPUT is omitted, App::DocKnot::Spin::Thread will not be able to obtain
sitemap information even if a sitemap was provided and therefore will not add
inter-page links.

=item spin_thread_output(THREAD, INPUT, TYPE[, OUTPUT])

Convert the given thread to HTML, writing the result to OUTPUT.  If OUTPUT is
not given, write the results to standard output.  This is like spin_thread()
but does use sitemap information and adds inter-page links.  It should be used
when the thread input is the result of an intermediate conversion step of a
known input file.  INPUT should be the full path to the original source file,
used for relative paths and modification time information.  TYPE should be set
to a one-word description of the format of the input file and is used for the
page footer.

=back

=head1 THREAD LANGUAGE

=head2 Basic Syntax

A thread file is Unicode text with a blank line between paragraphs.

There is no need to explicitly mark paragraphs; paragraph boundaries will be
inferred from the blank line between them and the appropriate C<< <p> >> tags
will be added to the HTML output.

There is no need to escape any character except C<\> (which should be written
as C<\\>) and an unbalanced C<[> or C<]> (which should be written as
C<\entity[91]> or C<\entity[93]> respectively).  Escaping C<[> or C<]> is not
necessary if the brackets are balanced within the paragraph, and therefore is
only rarely needed.

Commands begin with C<\>.  For example, the command to insert a line break
(corresponding to the C<< <br> >> tag in HTML) is C<\break>.  If the command
takes arguments, they are enclosed in square brackets after the command.  If
there are multiple arguments, they are each enclosed in square brackets and
follow each other.  Any amount of whitespace (but nothing else) is allowed
between the command and the arguments, or between the arguments.  So, for
example, all of the following are entirely equivalent:

    \link[index.html][Main page]
    \link  [index.html]  [Main page]

    \link[index.html]
    [Main page]

    \link
    [index.html]
    [Main page]

(C<\link> is a command that takes two arguments.)

Command arguments may contain paragraphs of text, other commands, and so
forth, nested arbitrarily (although this may not make sense for all arguments
of all commands, of course).

Some commands take an additional optional formatting instruction argument.
That argument is enclosed in parentheses and placed before any other
arguments.  It specifies the C<class> attribute for that HTML tag, for use
with style sheets, or the C<id> attribute, for use with style sheets or as an
anchor.  If the argument begins with C<#>, it will be taken to be an C<id>.
Otherwise, it will be taken as a C<class>.

For example, a first-level heading is normally written as:

    \h1[Heading]

(with one argument).  Either of the following will add a class attribute of
C<header> to that HTML container that can be referred to in style sheets:

    \h1(header)[Heading]
    \h1  (header)  [Heading]

and the following would add an id attribute of C<intro> to the heading so that
it could be referred to with the anchor C<#intro>:

    \h1(#intro)[Introduction]

Note that the heading commands have special handling for C<id> attributes; see
below for more details.

=head2 Basic Format

There are two commands that are required to occur in every document.

The first is C<\heading>, which must occur before any regular page text.  It
takes two arguments: the page title (the title that shows up in the window
title bar for the browser and is the default text for bookmarks, not anything
that's displayed as part of the body of the page), and the style sheet to use.
If there is no style sheet for this page, the second argument is still
required but should be empty (C<[]>).

The second required command is C<\signature>, which must be the last command
in the file.  C<\signature> will take care of appending the signature,
appending navigation links, closing any open blocks, and any other cleanup
that has to happen at the end of a generated HTML page.

You can include other files with the C<\include> command, although it has a
few restrictions.  The C<\include> command must appear either at the beginning
of the file or after a blank line, and should be followed by a blank line.  Be
careful not to include the same file recursively as there is no current
protection against infinite loops.

Thread files will not be automatically respun when included files change, so
you will need touch the thread file to force the corresponding output file to
be regenerated.

All further thread commands are divided into block commands and inline
commands.  These roughly correspond to HTML 5's "flow content" and "phrasing
content" respectively.

=head2 Block Commands

Block commands are commands that should occur in a paragraph by themselves,
not contained in a paragraph with other text.  They indicate high-level
structural elements of the page.  C<\heading> and C<\include> were already
discussed above, but here is a complete list.  Any argument of TEXT can be
multiple paragraphs and contain other embedded block commands (so you can nest
a list inside another list, for example).

=over 4

=item \block[TEXT]

Put TEXT in an indented block, equivalent to C<< <blockquote> >> in HTML.
Used primarily for quotations or license statements embedded in regular text.

=item \bullet[TEXT]

TEXT is formatted as an item in a bullet list.  This is like C<< <li> >>
inside C<< <ul> >> in HTML, but the surrounding list tags are inferred
automatically and handled correctly when multiple C<\bullet> commands are used
in a row.

Normally, TEXT is treated like a paragraph.  If used with a formatting
instruction of C<packed>, such as:

    \bullet(packed)[First item]

then the TEXT argument will not be treated as a paragraph and will not be
surrounded in C<< <p> >>.  No block commands should be used inside this type
of C<\bullet> command.  This variation will, on most browsers, not put any
additional whitespace around the line, which will produce better formatting
for bullet lists where each item is a single line.

=item \desc[HEADING][TEXT]

An element in a description list, where each item has a tag HEADING and an
associated body text of TEXT, like C<< <dt> >> and C<< <dd> >> in HTML.  As
with C<\bullet>, the C<< <dl> >> tags are inferred automatically.

=item \div[TEXT]

Does nothing except wrap TEXT in an HTML C<< <div> >> tag.  The only purpose
of this command is to use it with a formatting instruction to generate an HTML
C<class> attribute on the C<< <div> >> tag.

=item \h1[HEADING] .. \h6[HEADING]

Level one through level six headings, just like C<< <h1> >> .. C<< <h6> >> in
HTML.  If given an C<id> formatting instruction, such as:

    \h1(#anchor)[Heading]

then not only will an id attribute be added to the C<< <h1> >> container but
the text of the heading will also be enclosed in an C<< <a name> >> container
to ensure that C<#anchor> can be used as an anchor in a link in older browsers
that don't understand C<id> attributes.  This is special handling that only
works with C<\h1> through C<\h6>, not with other commands.

=item \heading[TITLE][STYLE]

Set the page title to TITLE and the style sheet to STYLE and emit the HTML
page header.  If a C<style-url> argument was given, that base URL will be
prepended to STYLE to form the URL for the style sheet; otherwise, STYLE will
be used verbatim as a URL except with C<.css> appended.

This command must come after any C<\id> or C<\rss> commands and may come after
commands that don't produce any output (such as macro definitions or
C<\include> of files that produce no output) but otherwise must be the first
command of the file.

=item \id[ID]

Sets the Subversion, CVS, or RCS revision number and time.  ID should be the
string C<< $Z<>Id$ >>, which will be expanded by Subversion, CVS, and RCS.
This string is embedded verbatim in an HTML comment near the beginning of the
generated output, and is used to determine last modified information for the
file (used by the C<\signature> command).

For this command to behave properly, it must be given before C<\heading>.

=item \include[FILE]

Include FILE after the current paragraph.  If multiple files are included in
the same paragraph, they're included in reverse order, but this behavior may
change in later versions and should not be relied on.  It's strongly
recommended to always put the C<\include> command in its own paragraph.  Don't
put C<\heading> or C<\signature> into an included file; the results won't be
correct.

=item \number[TEXT]

TEXT is formatted as an item in a numbered list, like C<< <li> >> inside C<<
<ol> >> in HTML.  As with C<\bullet> and C<\desc>, the surrounding tags are
inferred automatically.

As with C<\bullet>, a formatting instruction of C<packed> will omit the
paragraph tags around TEXT for better formatting with a list of short items.
See the description under C<\bullet> for more information.

=item \pre[TEXT]

Insert TEXT preformatted, preserving spacing and line breaks.  This uses the
HTML C<< <pre> >> tag, and therefore is normally also shown in a fixed-width
font by the browser.

When using C<\pre> inside indented blocks or lists, some care must be taken
with indentation whitespace.  Normally, the browser indents text inside
C<\pre> relative to the enclosing block, so you should only put as much
whitespace before each line in C<\pre> as those lines should be indented
relative to the enclosing text.  However B<lynx>, unfortunately, indents
relative to the left margin, so it's difficult to use indentation that looks
correct in both B<lynx> and other browsers.

=item \quote[TEXT][AUTHOR][CITATION]

Used for quotes at the top of a web page.

The whole text will be enclosed in a C<< <blockquote> >> tag with class
C<quote> for style sheets.  TEXT may be multiple paragraphs.  Any formatting
instruction given to C<\quote> will be used as the formatting instruction for
each paragraph in TEXT (so an C<id> is normally not appropriate).

If the formatting instruction is C<broken>, line breaks in TEXT will be
honored by inserting C<< <br> >> tags at the end of each line.  Use this for
poetry or other cases where line breaks are significant.

A final paragraph will then be added with class C<attribution> if the
formatting instruction is C<broken> or C<short> and class C<long-attrib>
otherwise.  This paragraph will contain the AUTHOR, a comma, and then
CITATION.  CITATION will be omitted if empty.

=item \rss[URL][TITLE]

Indicates that this page has a corresponding RSS feed at the URL URL.
The title of the RSS feed (particularly important if a page has more than
one feed) is given by TITLE.

The feed links are included in the page header output by C<\heading>, so this
command must be given before C<\heading> to be effective.

=item \rule

A horizontal rule, C<< <hr> >> in HTML.

=item \sitemap

Inserts a bullet list showing the structure of the whole site.  A C<sitemap>
argument must be provided to the constructor to use this command.  (If invoked
via App::DocKnot::Spin, this means a F<.sitemap> file must be present at the
root of the source directory.)

Be aware that B<spin> doesn't know whether a file contains a C<\sitemap>
command and hence won't know to regenerate a file when the F<.sitemap> file
has changed.  You will need touch the source file to force it to be respun.

=item \table[OPTIONS][BODY]

Creates a table.

The OPTIONS text is added verbatim to the <table> tag in the generated HTML,
so it can be used to set various HTML attributes like C<cellpadding> that
aren't easily accessible in a portable fashion from style sheets.

BODY is the body of the table, which should generally consist exclusively of
C<\tablehead> and C<\tablerow> commands.

An example table:

    \table[rules="cols" borders="1"][
        \tablehead [Older Versions]     [Webauth v3]
        \tablerow  [suauthSidentSrvtab] [WebAuthKeytab]
        \tablerow  [suauthFailAction]   [WebAuthLoginURL]
        \tablerow  [suauthDebug]        [WebAuthDebug]
        \tablerow  [suauthProxyHeader]  [(use mod_headers)]
    ]

=item \tablehead[CELL][CELL] ...

A heading row in a table.  C<\tablehead> takes any number of CELL arguments,
wraps them all in a C<< <tr> >> table row tag, and puts each cell inside C<<
<th> >>.

If a cell should have a class attribute, use a C<\class> command around the
CELL text.  The class attribute will be "lifted" up to become an attribute of
the enclosing C<< <th> >> tag.

=item \tablerow[CELL][CELL] ...

A regular row in a table.  C<\tablerow> takes any number of CELL arguments,
wraps them all in a C<< <tr> >> table row tag, and puts each cell inside C<<
<td> >>.

If a cell should have a class attribute, use a C<\class> command around the
CELL text.  The class attribute will be "lifted" up to become an attribute of
the enclosing C<< <td> >> tag.

=back

=head2 Inline Commands

Inline commands can be used in the middle of a paragraph intermixed with other
text.  Most of them are simple analogs to their HTML counterparts.  All of the
following take a single argument (the enclosed text), an optional formatting
instruction, and map to simple HTML tags:

    \bold       <b></b>                 (usually use \strong)
    \cite       <cite></cite>
    \code       <code></code>
    \emph       <em></em>
    \italic     <i></i>                 (usually use \emph)
    \strike     <strike></strike>       (should use styles)
    \strong     <strong></strong>
    \sub        <sub></sub>
    \sup        <sup></sup>
    \under      <u></u>                 (should use styles)

Here are the other inline commands:

=over 4

=item \break

A forced line break, C<< <br> >> in HTML.

=item \class[TEXT]

Does nothing except wrap TEXT in an HTML C<< <span> >> tag.  The only purpose
of this command is to use it with a formatting instruction to generate an HTML
C<class> attribute on the C<< <span> >> tag.  For example, you might write:

    \class(red)[A style sheet can make this text red.]

and then use a style sheet that changes the text color for class C<red>.

=item \entity[CODE]

An HTML entity with code CODE.  This normally becomes C<&CODE;> or C<&#CODE;>
in the generated HTML, depending on whether CODE is entirely numeric.

Use C<\entity[91]> and C<\entity[93]> for unbalanced C<[> and C<]> characters,
respectively.

Thread source is UTF-8, so this command is normally only necessary to escape
unbalanced square brackets.

=item \image[URL][TEXT]

Insert an inline image.  TEXT is the alt text for the image (which will be
displayed on non-graphical browsers).  Height and width tags are added
automatically if the URL is a relative path name and the corresponding file
exists and is supported by the Perl module Image::Size.

=item \link[URL][TEXT]

Create a link to URL with link text TEXT.  Equivalent to C<< <a href> >>.

=item \release[PACKAGE]

If the C<versions> argument was provided, replaced with the latest release
date of PACKAGE.  The date will be in the UTC time zone, not the local time
zone.

=item \size[FILE]

Replaced with the size of FILE in B, KB, MB, GB, or TB as is most appropriate,
without decimal places.  The next largest unit is used if the value is larger
than 1024.  1024 is used as the scaling factor, not 1000.

=item \version[PACKAGE]

If the C<versions> argument was provided, replaced with the latest version of
PACKAGE.

=back

=head2 Defining Variables and Macros

One of the reasons to use thread instead of HTML is the ability to define new
macros on the fly.  If there are constructs that are used more than once in
the page, you can define a macro at the top of that page and then use it
throughout the page.

A variable can be defined with the command:

    \=[VARIABLE][VALUE]

where VARIABLE is the name that will be used (can only be alphanumerics plus
underscore) and VALUE is the value that string will expand into.  Any later
occurrence of \=VARIABLE in the file will be replaced with <value>.  For
example:

    \=[FOO][some string]

will cause any later occurrences of C<\=FOO> in the file to be replaced with
the text C<some string>.  Consider using this to collect external URLs for
links at the top of a page for easy updating.

A macro can be defined with the command:

    \==[NAME][NARGS][DEFINITION]

where NAME is the name of the macro (again consisting only of alphanumerics or
underscore), NARGS is the number of arguments that it takes, and DEFINITION is
the definition of the macro.

When the macro is expanded, any occurrence of C<\1> in the definition is
replaced with the first argument, any occurrence of C<\2> with the second
argument, and so forth, and then the definition with those substitutions is
parsed as thread, as if it were written directly in the source page.

For example:

    \==[bolddesc] [2] [\desc[\bold[\1]][\2]]

defines a macro C<\bolddesc> that takes the same arguments as the regular
C<\desc> command but always wraps the first argument, the heading, in C<<
<strong> >>.

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2011, 2013, 2021-2022 Russ Allbery <rra@cpan.org>

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

L<docknot(1)>, L<App::DocKnot::Spin>, L<App::DocKnot::Spin::Sitemap>,
L<App::DocKnot::Spin::Versions>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
