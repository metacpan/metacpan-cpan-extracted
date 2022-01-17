# Static site builder supporting thread macro language.
#
# This module translates a tree of files, possibly written in thread (a custom
# macro language) into an HTML static site.  It also handles formatting some
# other input types (text and POD, for example), copying other types of files
# to the output tree, and creating site navigation links.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Spin 6.01;

use 5.024;
use autodie;
use warnings;

use App::DocKnot::Spin::Pointer;
use App::DocKnot::Spin::RSS;
use App::DocKnot::Spin::Sitemap;
use App::DocKnot::Spin::Thread;
use App::DocKnot::Spin::Versions;
use App::DocKnot::Util qw(is_newer print_checked print_fh);
use Git::Repository ();
use IPC::System::Simple qw(capture);
use Path::Iterator::Rule ();
use Path::Tiny qw(path);
use Pod::Thread 3.01 ();
use POSIX qw(strftime);

# The default list of files and/or directories to exclude from spinning.  This
# can be added to (but not removed from) with the --exclude option.  Each of
# these should be a regular expression.
my @EXCLUDES = (
    qr{ ^ [.] (?!htaccess\z) }xms,
    qr{ ^ (?:CVS|Makefile|RCS) \z }xms,
);

# The URL to the software page for all of my web page generation software,
# used to embed a link to the software that generated the page.
my $URL = 'https://www.eyrie.org/~eagle/software/web/';

##############################################################################
# Output
##############################################################################

# Build te page footer, which consists of the navigation links, the regular
# signature, and the last modified date.
#
# $source    - Path::Tiny path to the source file
# $out_path  - Path::Tiny path to the output file
# $id        - CVS Id of the source file or undef if not known
# @templates - Two templates to use.  The first will be used if the
#              modification and current dates are the same, and the second
#              if they are different.  %MOD% and %NOW% will be replaced with
#              the appropriate dates and %URL% with the URL to the site
#              generation software.
#
# Returns: HTML output
sub _footer {
    my ($self, $source, $out_path, $id, @templates) = @_;
    my $output = q{};
    my $in_tree = 0;
    if ($self->{source} && $self->{source}->subsumes($source)) {
        $in_tree = 1;
    }

    # Add the end-of-page navbar if we have sitemap information.
    if ($self->{sitemap} && $self->{output}) {
        my $page = $out_path->relative($self->{output});
        $output .= join(q{}, $self->{sitemap}->navbar("/$page")) . "\n";
    }

    # Figure out the modification dates.  Use the RCS/CVS Id if available,
    # otherwise use the Git repository if available.
    my $modified;
    if (defined($id)) {
        my (undef, undef, $date) = split(q{ }, $id);
        if ($date && $date =~ m{ \A (\d+) [-/] (\d+) [-/] (\d+) }xms) {
            $modified = sprintf('%d-%02d-%02d', $1, $2, $3);
        }
    } elsif ($self->{repository} && $in_tree) {
        $modified
          = $self->{repository}->run('log', '-1', '--format=%ct', "$source");
        if ($modified) {
            $modified = strftime('%Y-%m-%d', gmtime($modified));
        }
    }
    if (!$modified) {
        $modified = strftime('%Y-%m-%d', gmtime($source->stat()->[9]));
    }
    my $now = strftime('%Y-%m-%d', gmtime());

    # Determine which template to use and substitute in the appropriate times.
    $output .= "<address>\n" . q{ } x 4;
    my $template = ($modified eq $now) ? $templates[0] : $templates[1];
    $template =~ s{ %MOD% }{$modified}xmsg;
    $template =~ s{ %NOW% }{$now}xmsg;
    $template =~ s{ %URL% }{$URL}xmsg;
    $output .= "$template\n";
    $output .= "</address>\n";

    return $output;
}

##############################################################################
# External converters
##############################################################################

# Given the output from a converter, the file to save the output in, and an
# anonymous sub that takes three arguments, the first being the captured
# blurb, the second being the document ID if found, and the third being the
# base name of the output file, and prints out a last modified line, reformat
# the output of an external converter.
sub _write_converter_output {
    my ($self, $page_ref, $output, $footer) = @_;
    my $page = $output->relative($self->{output});
    my $out_fh = $output->openw_utf8();

    # Grab the first few lines of input, looking for a blurb and Id string.
    # Give up if we encounter <body> first.  Also look for a </head> tag and
    # add the navigation link tags before it, if applicable.  Add the
    # navigation bar right at the beginning of the body.
    my ($blurb, $docid);
    while (defined(my $line = shift($page_ref->@*))) {
        if ($line =~ m{ <!-- \s* (\$Id.*?) \s* --> }xms) {
            $docid = $1;
        }
        if ($line =~ m{ <!-- \s* ( (?:Generated|Converted) .*? )\s* --> }xms) {
            $blurb = $1;

            # Only show the date of the output, not the time or time zone.
            $blurb =~ s{ [ ] \d\d:\d\d:\d\d [ ] -0000 }{}xms;

            # Strip the date from the converter version output.
            $blurb =~ s{ [ ] [(] \d{4}-\d\d-\d\d [)] }{}xms;
        }
        if ($self->{sitemap} && $line =~ m{ \A </head> }xmsi) {
            my @links = $self->{sitemap}->links($page);
            if (@links) {
                print_fh($out_fh, $output, @links);
            }
        }
        print_fh($out_fh, $output, $line);
        if ($line =~ m{ <body }xmsi) {
            if ($self->{sitemap}) {
                my @navbar = $self->{sitemap}->navbar($page);
                if (@navbar) {
                    print_fh($out_fh, $output, @navbar);
                }
            }
            last;
        }
    }
    warn "$0 spin: malformed HTML output for $output\n" unless $page_ref->@*;

    # Snarf input and write it to output until we see </body>, which is our
    # signal to start adding things.  We just got very confused if </body> was
    # on the same line as <body>, so don't do that.
    my $line;
    while (defined($line = shift($page_ref->@*))) {
        last if $line =~ m{ </body> }xmsi;
        print_fh($out_fh, $output, $line);
    }

    # Add the footer and finish with the output.
    print_fh($out_fh, $output, $footer->($blurb, $docid));
    if (defined($line)) {
        print_fh($out_fh, $output, $line, $page_ref->@*);
    }
    close($out_fh);
    return;
}

# These methods are all used, but are indirected through a table, so
# perlcritic gets confused.
#
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

# A wrapper around the cl2xhtml script, used to handle .changelog pointers in
# a tree being spun.  Adds the navigation links and the signature to the
# cl2xhtml output.
sub _cl2xhtml {
    my ($self, $source, $output, $options, $style) = @_;
    $style ||= $self->{style_url} . 'changelog.css';
    my @page = capture("cl2xhtml $options -s $style $source");
    my $footer = sub {
        my ($blurb, $id) = @_;
        if ($blurb) {
            $blurb =~ s{ cl2xhtml }{\n<a href="$URL">cl2xhtml</a>}xms;
        }
        $self->_footer($source, $output, $id, $blurb, $blurb);
    };
    $self->_write_converter_output(\@page, $output, $footer);
    return;
}

# A wrapper around the cvs2xhtml script, used to handle .log pointers in a
# tree being spun.  Adds the navigation links and the signature to the
# cvs2xhtml output.
sub _cvs2xhtml {
    my ($self, $source, $output, $options, $style) = @_;
    $style ||= $self->{style_url} . 'cvs.css';

    # Separate the source file into a directory and filename.
    my $name = $source->basename();
    my $dir = $source->parent();

    # Construct the options to cvs2xhtml.
    if ($options !~ m{ -n [ ] }xms) {
        $options .= " -n $name";
    }
    $options .= " -s $style";

    # Run the converter and write the output.
    my @page = capture("(cd $dir && cvs log $name) | cvs2xhtml $options");
    my $footer = sub {
        my ($blurb, $id, $file) = @_;
        if ($blurb) {
            $blurb =~ s{ cvs2xhtml }{\n<a href="$URL">cvs2xhtml</a>}xms;
        }
        $self->_footer($source, $output, $id, $blurb, $blurb);
    };
    $self->_write_converter_output(\@page, $output, $footer);
    return;
}

# A wrapper around the faq2html script, used to handle .faq pointers in a tree
# being spun.  Adds the navigation links and the signature to the faq2html
# output.
sub _faq2html {
    my ($self, $source, $output, $options, $style) = @_;
    $style ||= $self->{style_url} . 'faq.css';
    my @page = capture("faq2html $options -s $style $source");
    my $footer = sub {
        my ($blurb, $id, $file) = @_;
        if ($blurb) {
            $blurb =~ s{ faq2html }{\n<a href="$URL">faq2html</a>}xms;
        }
        $self->_footer($source, $output, $id, $blurb, $blurb);
    };
    $self->_write_converter_output(\@page, $output, $footer);
    return;
}

# A wrapper around Pod::Thread and a nested spin_fh invocation, used to handle
# .pod pointers in a tree being spun.  Adds the navigation links and the
# signature to the output.
sub _pod2html {
    my ($self, $source, $output, $options, $style) = @_;
    $style //= 'pod';

    # Construct the Pod::Thread formatter object.
    my %options = (style => $style);
    if ($options) {
        if ($options =~ m{ -c ( \s | \z ) }xms) {
            $options{contents} = 1;
        }
        if ($options =~ m{ -t \s+ (?: '(.*)' | ( [^\'] \S+ ) ) }xms) {
            $options{title} = $1 || $2;
        }
    } else {
        $options{navbar} = 1;
    }
    my $podthread = Pod::Thread->new(%options);

    # Grab the thread output.
    my $data;
    $podthread->output_string(\$data);
    $podthread->parse_file("$source");

    # Spin that thread into HTML.
    my $page = $self->{thread}->spin_thread($data);

    # Push the result through _write_converter_output.
    my $footer = sub {
        my ($blurb) = @_;
        my $link = '<a href="%URL%">spun</a>';
        $self->_footer(
            $source, $output, undef,
            "Last modified and\n    $link %MOD%",
            "Last $link\n    %NOW% from POD modified %MOD%",
        );
    };
    my @page = map { "$_\n" } split(qr{\n}xms, $page);
    $self->_write_converter_output(\@page, $output, $footer);
    return;
}

## use critic

##############################################################################
# Per-file operations
##############################################################################

# Given a pointer file, read the master file name and any options, returning
# them as a list with the newlines chomped off.
#
# $file - Path::Tiny for the file to read
#
# Returns: List of the master file, any command-line options, and the style
#          sheet to use, as strings
#  Throws: Text exception if no master file is present in the pointer
#          autodie exception if the pointer file could not be read
sub _read_pointer {
    my ($self, $file) = @_;

    # Read the pointer file.
    my ($master, $options, $style) = $file->lines_utf8();

    # Clean up the contents.
    if (!$master) {
        die "no master file specified in $file\n";
    }
    chomp($master);
    if (defined($options)) {
        chomp($options);
    } else {
        $options = q{};
    }
    if (defined($style)) {
        chomp($style);
    }

    # Return the details.
    return ($master, $options, $style);
}

# Convert an input path to an output path.
#
# $input     - Path::Tiny input path
# $extension - If given, remove this extension and add .html in its place
sub _output_for_file {
    my ($self, $input, $extension) = @_;
    my $output = $input->relative($self->{source})->absolute($self->{output});
    if ($extension) {
        my $output_file = $input->basename($extension) . '.html';
        $output = $output->sibling($output_file);
    }
    return $output;
}

# Report an action to standard output.
#
# $action - String description of the action
# $output - Output file generated
sub _report_action {
    my ($self, $action, $output) = @_;
    my $shortout = $output->relative($self->{output});
    print_checked("$action .../$shortout\n");
    return;
}

# This routine is called for every file in the source tree.  It decides what
# to do with each file, whether spinning it or copying it.
#
# $input - Path::Tiny path to the input file
#
# Throws: Text exception on any processing error
#         autodie exception if files could not be accessed or written
#
## no critic (Subroutines::ProhibitExcessComplexity)
sub _process_file {
    my ($self, $input) = @_;

    # Conversion rules for pointers.  The key is the extension, the first
    # value is the name of the command for the purposes of output, and the
    # second is the name of the method to run.
    #<<<
    my %rules = (
        changelog => ['cl2xhtml',   '_cl2xhtml'],
        faq       => ['faq2html',   '_faq2html'],
        log       => ['cvs2xhtml',  '_cvs2xhtml'],
        rpod      => ['pod2thread', '_pod2html'],
    );
    #>>>

    # Figure out what to do with the input.
    if ($input->is_dir()) {
        my $output = $self->_output_for_file($input);
        $self->{generated}{"$output"} = 1;
        if ($output->exists() && !$output->is_dir()) {
            die "cannot replace $output with a directory\n";
        } elsif (!$output->is_dir()) {
            $self->_report_action('Creating', $output);
            $output->mkpath();
        }
        my $rss_path = path($input, '.rss');
        if ($rss_path->exists()) {
            $self->{rss}->generate("$rss_path", "$input");
        }
    } elsif ($input->basename() =~ m{ [.] spin \z }xms) {
        my $output = $self->_output_for_file($input, '.spin');
        $self->{generated}{"$output"} = 1;
        if ($self->{pointer}->is_out_of_date("$input", "$output")) {
            $self->_report_action('Converting', $output);
            $self->{pointer}->spin_pointer("$input", "$output");
        }
    } elsif ($input->basename() =~ m{ [.] th \z }xms) {
        my $output = $self->_output_for_file($input, '.th');
        $self->{generated}{"$output"} = 1;

        # See if we're forced to regenerate the file because it is affected by
        # a software release.
        if ($output->exists() && $self->{versions}) {
            my $relative = $input->relative($self->{source});
            my $time = $self->{versions}->latest_release("$relative");
            return
              if is_newer("$output", "$input")
              && $output->stat()->[9] >= $time;
        } else {
            return if is_newer("$output", "$input");
        }

        # The output file is not newer.  Respin it.
        $self->_report_action('Spinning', $output);
        $self->{thread}->spin_thread_file($input, $output);
    } else {
        my ($extension) = ($input->basename =~ m{ [.] ([^.]+) \z }xms);
        if (defined($extension) && $rules{$extension}) {
            my ($name, $sub) = $rules{$extension}->@*;
            my $output = $self->_output_for_file($input, $extension);
            $self->{generated}{"$output"} = 1;
            my ($source, $options, $style) = $self->_read_pointer($input);
            return if is_newer($output, $input, $source);
            $self->_report_action("Running $name for", $output);
            $self->$sub($source, $output, $options, $style);
        } else {
            my $output = $self->_output_for_file($input);
            $self->{generated}{"$output"} = 1;
            return if is_newer("$output", "$input");
            $self->_report_action('Updating', $output);
            $input->copy($output);
        }
    }
    return;
}
## use critic

# This routine is called for every file in the destination tree in depth-first
# order, if the user requested file deletion of files not generated from the
# source tree.  It checks each file to see if it is in the $self->{generated}
# hash that was generated during spin processing, and if not, removes it.
#
# $file - Path::Tiny path to the file
#
# Throws: autodie exception on failure of rmdir or unlink
sub _delete_files {
    my ($self, $file) = @_;
    return if $self->{generated}{"$file"};
    my $shortfile = $file->relative($self->{output});
    print_checked("Deleting .../$shortfile\n");
    if ($file->is_dir()) {
        rmdir($file);
    } else {
        $file->remove();
    }
    return;
}

##############################################################################
# Public interface
##############################################################################

# Create a new App::DocKnot::Spin object, which will be used for subsequent
# calls.
#
# $args  - Anonymous hash of arguments with the following keys:
#   delete    - Whether to delete files missing from the source tree
#   exclude   - List of regular expressions matching file names to exclude
#   style-url - Partial URL to style sheets
#
# Returns: Newly created object
sub new {
    my ($class, $args_ref) = @_;

    # Treat all exclude arguments as regular expressions and add them to the
    # global exclusion list.
    my @excludes = @EXCLUDES;
    if ($args_ref->{exclude}) {
        push(@excludes, map { qr{$_}xms } $args_ref->{exclude}->@*);
    }

    # Add a trailing slash to the partial URL for style sheets.
    my $style_url = $args_ref->{'style-url'} // q{};
    if ($style_url) {
        $style_url =~ s{ /* \z }{/}xms;
    }

    # Create and return the object.
    #<<<
    my $self = {
        delete    => $args_ref->{delete},
        excludes  => [@excludes],
        style_url => $style_url,
    };
    #>>>
    bless($self, $class);
    return $self;
}

# Spin a directory of files into a web site.
#
# $input  - The input directory
# $output - The output directory (which may not exist)
#
# Raises: Text exception on processing error
sub spin {
    my ($self, $input, $output) = @_;

    # Reset data from a previous run.
    delete $self->{repository};
    delete $self->{rss};
    delete $self->{sitemap};
    delete $self->{versions};

    # Canonicalize and check input.
    $input = path($input)->realpath();
    if (!$input->is_dir()) {
        die "input tree $input must be a directory\n";
    }
    $self->{source} = $input;

    # Canonicalize and check output.
    $output = path($output);
    if (!$output->is_dir()) {
        for my $created ($output->mkpath()) {
            print_checked("Creating $created\n");
        }
    }
    $output = $output->realpath();
    $self->{output} = $output;

    # Read metadata from the top of the input directory.
    my $sitemap_path = $input->child('.sitemap');
    if ($sitemap_path->exists()) {
        $self->{sitemap} = App::DocKnot::Spin::Sitemap->new("$sitemap_path");
    }
    my $versions_path = $input->child('.versions');
    if ($versions_path->exists()) {
        $self->{versions} = App::DocKnot::Spin::Versions->new($versions_path);
    }
    if ($input->child('.git')->is_dir()) {
        $self->{repository} = Git::Repository->new(work_tree => $input);
    }

    # Create a new RSS generator object.
    $self->{rss} = App::DocKnot::Spin::RSS->new({ base => $input });

    # Process an .rss file at the top of the tree, if present.
    my $rss_path = $input->child('.rss');
    if ($rss_path->exists()) {
        $self->{rss}->generate("$rss_path", "$input");
    }

    # Create a new thread converter object.
    #<<<
    $self->{thread} = App::DocKnot::Spin::Thread->new(
        {
            output      => $output,
            sitemap     => $self->{sitemap},
            source      => $input,
            'style-url' => $self->{style_url},
            versions    => $self->{versions},
        },
    );
    #>>>

    # Create the processor for pointers.
    #<<<
    $self->{pointer} = App::DocKnot::Spin::Pointer->new(
        {
            output      => "$output",
            sitemap     => $self->{sitemap},
            'style-url' => $self->{style_url},
            thread      => $self->{thread},
        },
    );
    #>>>

    # Process the input tree.
    my $rule = Path::Iterator::Rule->new();
    $rule = $rule->skip($rule->new()->name($self->{excludes}->@*));
    my $iter = $rule->iter("$input", { follow_symlinks => 0 });
    while (defined(my $file = $iter->())) {
        $self->_process_file(path($file));
    }

    # Remove stray files from the output tree.
    if ($self->{delete}) {
        my %options = (depthfirst => 1, follow_symlinks => 0);
        $iter = $rule->iter("$output", \%options);
        while (defined(my $file = $iter->())) {
            $self->_delete_files(path($file));
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
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense cvs2xhtml faq2html
cl2xhtml spin-rss

=head1 NAME

App::DocKnot::Spin - Static site builder supporting thread macro language

=head1 SYNOPSIS

    use App::DocKnot::Spin;

    my $spin = App::DocKnot::Spin->new({ delete => 1 });
    $spin->spin('/path/to/input', '/path/to/output');

=head1 REQUIREMENTS

Perl 5.24 or later and the modules Git::Repository, Image::Size,
List::SomeUtils, Path::Iterator::Rule, Path::Tiny, Pod::Thread, Template (part
of Template Toolkit), and YAML::XS, all of which are available from CPAN.
Also expects to find B<faq2html>, B<cvs2xhtml>, and B<cl2xhtml> on the user's
PATH to convert certain types of files.

=head1 DESCRIPTION

App::DocKnot::Spin is a static site builder that takes an input tree of files
and generates an output HTML site.  It is built around the macro language
thread, which is designed for writing simple HTML pages using somewhat nicer
syntax, catering to my personal taste, and supporting variables and macros to
make writing pages less tedious.

Each file in the input tree is examined recursively and either copied verbatim
to the same relative path in the output tree (the default action), used as
instructions to an external program, or converted to HTML.  When converted to
HTML, the output file will be named the same as the input file except the
extension will be replaced with C<.html>.  Missing directories are created.

If the timestamp of the output file is the same as or newer than the timestamp
of the input file, it will be assumed to be up-to-date and will not be
regenerated.  This optimization makes updating an existing static site much
quicker.

Most files in the input tree will normally be thread files ending in C<.th>.
These are processed into HTML using L<App::DocKnot::Spin::Thread>.  See that
module's documentation for the details of the thread macro language.

Files that end in various other extensions are taken to be instructions to run
an external converter on a file.  The first line of such a pointer file should
be the path to the source file, the second line any arguments to the
converter, and the third line the style sheet to use if not the default.
Which converter to run is based on the extension of the file as follows:

    .changelog  cl2xhtml
    .faq        faq2html
    .log        cvs log <file> | cvs2xhtml
    .rpod       Pod::Thread

All other files not beginning with a period are copied as-is, except that
files or directories named F<CVS>, F<Makefile>, or F<RCS> are ignored.  As an
exception, F<.htaccess> files are also copied.  This list of exclusions can
be added to with the C<exclude> constructor argument.

If there is a file named F<.sitemap> at the top of the input tree, it will be
parsed with L<App::DocKnot::Spin::Sitemap> and used for inter-page links and
the C<\sitemap> thread command.  See that module's documentation for the
format of this file.

If there is a file named F<.versions> at the top of the input tree, it will be
parsed with L<App::DocKnot::Spin::Versions> and used to determine when to
regenerate certain pages and for the C<\release> and C<\version> thread
commands.  See that module's documentation for the format of this file.

If there is a file named F<.rss> in any directory of the input tree,
B<spin-rss> will be run on that file, passing the B<-b> option to point to the
directory about to be processed.  This is done before processing the files in
that directory, so B<spin-rss> can create or update files that will then be
processed as normal.

If there is a directory named F<.git> at the top of the input tree,
App::DocKnot::Spin will assume that the input tree is a Git repository and
will try to use C<git log> to determine the last modification date of files.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Spin object.  ARGS should be a hash reference with
one or more of the following keys:

=over 4

=item delete

If set to a true value, after populating the output tree with the results of
converting or copying all the files in the source tree, delete all files and
directories in the output tree that do not have a corresponding file in the
source tree.

=item exclude

A list of strings, interpreted as regular expressions, which match files to
exclude from processing.  These patterns will be added to a built-in list of
exclude patterns.

=item style-url

The base URL for style sheets.  A style sheet specified in a C<\heading>
command will be considered to be relative to this URL and this URL will be
prepended to it.  If this option is not given, the name of the style sheet
will be used verbatim as its URL, except with C<.css> appended.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item spin(INPUT, OUTPUT)

Build the source tree rooted at INPUT into an HTML static site, storing it
in the directory OUTPUT.  If OUTPUT does not exist, it will be created.

=back

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

L<cl2xhtml(1)>, L<cvs2xhtml(1)>, L<docknot(1)>, L<faq2html(1)>,
L<spin-rss(1)>, L<App::DocKnot::Spin::Sitemap>, L<App::DocKnot::Spin::Thread>,
L<App::DocKnot::Spin::Versions>, L<Pod::Thread>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
