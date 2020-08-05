package App::Followme::Initialize;
use 5.008005;
use strict;
use warnings;

use Cwd;
use IO::File;
use MIME::Base64  qw(decode_base64);
use File::Spec::Functions qw(splitdir catfile);

our $VERSION = "1.95";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(initialize);

our $var = {};
use constant CMD_PREFIX => '#>>>';

#----------------------------------------------------------------------
# Initialize a new web site

sub initialize {
    my ($directory) = @_;

    chdir($directory) if defined $directory;
    my ($read, $unread) = data_readers();

    while (my ($command, $lines) = next_command($read, $unread)) {
        my @args = split(' ', $command);
        my $cmd = shift @args;

        write_error("Missing lines after command", $command)
            if $cmd eq 'copy' && @$lines == 0;

        write_error("Unexpected lines after command", $command)
            if $cmd ne 'copy' && @$lines > 0;

        if ($cmd  eq 'copy') {
            write_file($lines, @args);

        } elsif ($cmd eq 'set') {
            write_error("No name in set command", $command) unless @args;
            my $name = shift(@args);
            write_var($name, join(' ', @args));

        } else {
            write_error("Error in command name", $command);
        }
    }

    return;
}

#----------------------------------------------------------------------
# Copy a binary file

sub copy_binary {
    my($file, $lines, @args) = @_;

    my $out = IO::File->new($file, 'w') or die "Couldn't write $file: $!\n";
    binmode($out);

    foreach my $line (@$lines) {
        print $out decode_base64($line);
    }

    close($out);
    return;
}

#----------------------------------------------------------------------
# Copy a configuration file

sub copy_configuration {
    my ($file, $lines, @args) = @_;

    my $config_version = shift(@args);
    my $version = read_var('version', $file);
    return unless $version == 0 || $version == $config_version;

    my $configuration = read_var('configuration', $file);
    $lines = merge_configuration($configuration, $lines);

    copy_text($file, $lines, @args);
    return;
}

#----------------------------------------------------------------------
# Copy a text file

sub copy_text {
    my ($file, $lines, @args) = @_;

    my $out = IO::File->new($file, 'w') or die "Couldn't write $file: $!\n";
    foreach my $line (@$lines) {
        print $out $line;
    }

    close($out);
    return;
}

#----------------------------------------------------------------------
# Check path and create directories as necessary

sub create_dirs {
    my ($file) = @_;

    my @dirs = splitdir($file);
    pop @dirs;

    my @path;
    while (@dirs) {
        push(@path, shift(@dirs));
        my $path = catfile(@path);

        if (! -d $path) {
            mkdir($path) or die "Couldn't create $path: $!\n";
            chmod(0755, $path) or die "Couldn't set permissions: $!\n";
        }
    }

    return;
}

#----------------------------------------------------------------------
# Return closures to read the data section of this file

sub data_readers {
    my @pushback;

    my $read = sub {
        if (@pushback) {
            return pop(@pushback);
        } else {
            return <DATA>;
        }
    };

    my $unread = sub {
        my ($line) = @_;
        push(@pushback, $line);
    };

    return ($read, $unread);
}

#----------------------------------------------------------------------
# Get the confoguration file as a list of lines

sub get_configuration {
    my ($file) = @_;
    return read_file($file);
}

#----------------------------------------------------------------------
# Get the configuration file version

sub get_version {
    my ($file) = @_;

    my $configuration = read_var('configuration', $file);
    return 0 unless defined $configuration;

    return read_configuration('version') || 1;
}

#----------------------------------------------------------------------
# Is the line a command?

sub is_command {
    my ($line) = @_;

    my $command;
    my $prefix = CMD_PREFIX;

    if ($line =~ s/^$prefix//) {
        $command = $line;
        chomp $command;
    }

    return $command;
}

#----------------------------------------------------------------------
# Merge new lines into configuration file

sub merge_configuration {
    my ($old_config, $new_config) = @_;

    if ($old_config) {
        my $parser = parse_configuration($new_config);
        my $new_variable = {};
        while (my ($name, $value) = &$parser) {
            $new_variable->{$name} = $value;
        }

        $parser = parse_configuration($old_config);
        while (my ($name, $value) = &$parser) {
            delete $new_variable->{$name} if exists $new_variable->{$name};
        }

        while (my ($name, $value) = each %$new_variable) {
            push(@$old_config, "$name = $value\n");
        }

    } else {
        $old_config = [];
        @$old_config = @$new_config;
    }

    return $old_config;
}

#----------------------------------------------------------------------
# Get the name and contents of the next file

sub next_command {
    my ($read, $unread) = @_;

    my $line = $read->();
    return unless defined $line;

    my $command = is_command($line);
    die "Command not supported: $line" unless $command;

    my @lines;
    while ($line = $read->()) {
        if (is_command($line)) {
            $unread->($line);
            last;

        } else {
            push(@lines, $line);
        }
    }

    return ($command, \@lines);
}

#----------------------------------------------------------------------
# Parse the configuration and return the next name-value pair

sub parse_configuration {
    my ($lines) = @_;
    my @lines = $lines ? @$lines : ();

    return sub {
        while (my $line = shift(@lines)) {
            # Ignore comments and blank lines
            next if $line =~ /^\s*\#/ || $line !~ /\S/;

            # Split line into name and value, remove leading and
            # trailing whitespace

            my ($name, $value) = split (/\s*=\s*/, $line, 2);
            next unless defined $value;
            $value =~ s/\s+$//;

            # Ignore run_before and run_after
            next if $name eq 'run_before' ||
                    $name eq 'run_after' ||
                    $name eq 'module';

            return ($name, $value);
        }

        return;
    };
}

#----------------------------------------------------------------------
# Read a field in the configuration lines

sub read_configuration {
    my ($lines, $field) = @_;

    my $parser = parse_configuration($lines);
    while (my ($name, $value) = &$parser) {
        return $value if $name eq $field;
    }

    return;
}

#----------------------------------------------------------------------
# Read a file as a list of lines

sub read_file {
    my ($file) = @_;

    my $fd = IO::File->new($file, 'r');
    return unless $fd;

    my @lines = <$fd>;
    $fd->close();
    return \@lines;
}

#----------------------------------------------------------------------
# Read the value of a variable

sub read_var {
    my ($name, @args) = @_;

    if (! exists $var->{$name}) {
        no strict;
        my $sub = "get_$name";
        write_var($name, &$sub($var, @args));
    }

    return $var->{$name};
}

#----------------------------------------------------------------------
# Die with error

sub write_error {
    my ($msg, $line) = @_;
    die "$msg: " . substr($line, 0, 30) . "\n";
}

#----------------------------------------------------------------------
# Write a copy of the input file

sub write_file {
    my ($lines, @args) = @_;

    no strict;
    my $type = shift(@args);
    my $file = shift(@args);

    create_dirs($file);

    my $sub = "copy_$type";
    &$sub($file, $lines, @args);

    return;
}

#----------------------------------------------------------------------
# Write the value of a variable

sub write_var {
    my ($name, $value) = @_;

    $var->{$name} = $value;
    return;
}

1;
__DATA__
#>>> copy configuration followme.cfg 0
run_before = App::Followme::FormatPage
run_before = App::Followme::ConvertPage

#>>> copy text index.html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<!-- section meta -->
<title>Your Site</title>
<!-- endsection meta -->
<link rel="stylesheet" id="css_style" href="theme.css">
</head>
<body>
<header>
<div id="banner">
<h1>Your Site Title</h1>
</div>
<nav>
<label for="hamburger">&#9776;</label>
<input type="checkbox" id="hamburger"/>
<ul>
<li><a href="index.html">Home</a></li>
<li><a href="about.html">About</a></li>
<li><a href="essays/index.html">Essays</a></li>
</ul>
</nav>
</header>
<article>
<section id="primary">
<!-- section primary -->
<h2>Test</h2>
<p>This is the top page</p>

<!-- endsection primary-->
<section id="secondary">
<!-- section secondary -->
<!-- endsection secondary-->
</section>
</article>
<footer>
</footer>
</body>
</html>
#>>> copy text menu.css
/* [ON BIG SCREEN] */
/* Wrapper */
header nav {
  width: 100%;
  background: #000;
  /* If you want the navigation bar to stick on top
  position: sticky;
  top: 0;
  */
}

/* Hide Hamburger */
header nav label, #hamburger {
  display: none;
}

/* Menu Items */
header nav ul {
  list-style-type: none;
  margin: 0;
  padding: 0; 
}
header nav ul li {
  display: inline-block;
  padding: 10px;
  box-sizing: border-box;
}
header nav ul li a {
  color: #fff;
  text-decoration: none;
  font-family: arial, sans-serif;
  font-weight: bold;
}

/* [ON SMALL SCREENS] */
@media screen and (max-width: 768px){
  /* Show Hamburger */
  header nav label {
    display: inline-block;
    color: #fff;
    background: #a02620;
    font-style: normal;
    font-size: 1.2em;
    font-weight: bold;
    padding: 10px;
  }

  /* Break down menu items into vertical */
  header nav ul li {
    display: block;
  }
  header nav ul li {
    border-top: 1px solid #333;
  }

  /* Toggle show/hide menu on checkbox click */
  header nav ul {
    display: none;
  }
  header nav input:checked ~ ul {
    display: block;
  }
}

/**
 * Copyright 2019 by Code Boxx
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * /
#>>> copy text normalize.css
/*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */

/* Document
   ========================================================================== */

/**
 * 1. Correct the line height in all browsers.
 * 2. Prevent adjustments of font size after orientation changes in iOS.
 */

html {
  line-height: 1.15; /* 1 */
  -webkit-text-size-adjust: 100%; /* 2 */
}

/* Sections
   ========================================================================== */

/**
 * Remove the margin in all browsers.
 */

body {
  margin: 0;
}

/**
 * Render the `main` element consistently in IE.
 */

main {
  display: block;
}

/**
 * Correct the font size and margin on `h1` elements within `section` and
 * `article` contexts in Chrome, Firefox, and Safari.
 */

h1 {
  font-size: 2em;
  margin: 0.67em 0;
}

/* Grouping content
   ========================================================================== */

/**
 * 1. Add the correct box sizing in Firefox.
 * 2. Show the overflow in Edge and IE.
 */

hr {
  box-sizing: content-box; /* 1 */
  height: 0; /* 1 */
  overflow: visible; /* 2 */
}

/**
 * 1. Correct the inheritance and scaling of font size in all browsers.
 * 2. Correct the odd `em` font sizing in all browsers.
 */

pre {
  font-family: monospace, monospace; /* 1 */
  font-size: 1em; /* 2 */
}

/* Text-level semantics
   ========================================================================== */

/**
 * Remove the gray background on active links in IE 10.
 */

a {
  background-color: transparent;
}

/**
 * 1. Remove the bottom border in Chrome 57-
 * 2. Add the correct text decoration in Chrome, Edge, IE, Opera, and Safari.
 */

abbr[title] {
  border-bottom: none; /* 1 */
  text-decoration: underline; /* 2 */
  text-decoration: underline dotted; /* 2 */
}

/**
 * Add the correct font weight in Chrome, Edge, and Safari.
 */

b,
strong {
  font-weight: bolder;
}

/**
 * 1. Correct the inheritance and scaling of font size in all browsers.
 * 2. Correct the odd `em` font sizing in all browsers.
 */

code,
kbd,
samp {
  font-family: monospace, monospace; /* 1 */
  font-size: 1em; /* 2 */
}

/**
 * Add the correct font size in all browsers.
 */

small {
  font-size: 80%;
}

/**
 * Prevent `sub` and `sup` elements from affecting the line height in
 * all browsers.
 */

sub,
sup {
  font-size: 75%;
  line-height: 0;
  position: relative;
  vertical-align: baseline;
}

sub {
  bottom: -0.25em;
}

sup {
  top: -0.5em;
}

/* Embedded content
   ========================================================================== */

/**
 * Remove the border on images inside links in IE 10.
 */

img {
  border-style: none;
}

/* Forms
   ========================================================================== */

/**
 * 1. Change the font styles in all browsers.
 * 2. Remove the margin in Firefox and Safari.
 */

button,
input,
optgroup,
select,
textarea {
  font-family: inherit; /* 1 */
  font-size: 100%; /* 1 */
  line-height: 1.15; /* 1 */
  margin: 0; /* 2 */
}

/**
 * Show the overflow in IE.
 * 1. Show the overflow in Edge.
 */

button,
input { /* 1 */
  overflow: visible;
}

/**
 * Remove the inheritance of text transform in Edge, Firefox, and IE.
 * 1. Remove the inheritance of text transform in Firefox.
 */

button,
select { /* 1 */
  text-transform: none;
}

/**
 * Correct the inability to style clickable types in iOS and Safari.
 */

button,
[type="button"],
[type="reset"],
[type="submit"] {
  -webkit-appearance: button;
}

/**
 * Remove the inner border and padding in Firefox.
 */

button::-moz-focus-inner,
[type="button"]::-moz-focus-inner,
[type="reset"]::-moz-focus-inner,
[type="submit"]::-moz-focus-inner {
  border-style: none;
  padding: 0;
}

/**
 * Restore the focus styles unset by the previous rule.
 */

button:-moz-focusring,
[type="button"]:-moz-focusring,
[type="reset"]:-moz-focusring,
[type="submit"]:-moz-focusring {
  outline: 1px dotted ButtonText;
}

/**
 * Correct the padding in Firefox.
 */

fieldset {
  padding: 0.35em 0.75em 0.625em;
}

/**
 * 1. Correct the text wrapping in Edge and IE.
 * 2. Correct the color inheritance from `fieldset` elements in IE.
 * 3. Remove the padding so developers are not caught out when they zero out
 *    `fieldset` elements in all browsers.
 */

legend {
  box-sizing: border-box; /* 1 */
  color: inherit; /* 2 */
  display: table; /* 1 */
  max-width: 100%; /* 1 */
  padding: 0; /* 3 */
  white-space: normal; /* 1 */
}

/**
 * Add the correct vertical alignment in Chrome, Firefox, and Opera.
 */

progress {
  vertical-align: baseline;
}

/**
 * Remove the default vertical scrollbar in IE 10+.
 */

textarea {
  overflow: auto;
}

/**
 * 1. Add the correct box sizing in IE 10.
 * 2. Remove the padding in IE 10.
 */

[type="checkbox"],
[type="radio"] {
  box-sizing: border-box; /* 1 */
  padding: 0; /* 2 */
}

/**
 * Correct the cursor style of increment and decrement buttons in Chrome.
 */

[type="number"]::-webkit-inner-spin-button,
[type="number"]::-webkit-outer-spin-button {
  height: auto;
}

/**
 * 1. Correct the odd appearance in Chrome and Safari.
 * 2. Correct the outline style in Safari.
 */

[type="search"] {
  -webkit-appearance: textfield; /* 1 */
  outline-offset: -2px; /* 2 */
}

/**
 * Remove the inner padding in Chrome and Safari on macOS.
 */

[type="search"]::-webkit-search-decoration {
  -webkit-appearance: none;
}

/**
 * 1. Correct the inability to style clickable types in iOS and Safari.
 * 2. Change font properties to `inherit` in Safari.
 */

::-webkit-file-upload-button {
  -webkit-appearance: button; /* 1 */
  font: inherit; /* 2 */
}

/* Interactive
   ========================================================================== */

/*
 * Add the correct display in Edge, IE 10+, and Firefox.
 */

details {
  display: block;
}

/*
 * Add the correct display in all browsers.
 */

summary {
  display: list-item;
}

/* Misc
   ========================================================================== */

/**
 * Add the correct display in IE 10+.
 */

template {
  display: none;
}

/**
 * Add the correct display in IE 10.
 */

[hidden] {
  display: none;
}
#>>> copy text sakura.css
/* Sakura.css v1.0.0
 * ================
 * Minimal css theme.
 * Project: https://github.com/oxalorg/sakura
 */
/* Body */
html {
  font-size: 62.5%;
  font-family: serif; }

body {
  font-size: 1.8rem;
  line-height: 1.618;
  color: #4a4a4a;
  background-color: #f9f9f9; }

article {
  max-width: 45em;
  margin: auto;
  padding: 13px; }
    
@media (max-width: 684px) {
  body {
    font-size: 1.53rem; } }

@media (max-width: 382px) {
  body {
    font-size: 1.35rem; } }

h1, h2, h3, h4, h5, h6 {
  line-height: 1.1;
  font-family: Verdana, Geneva, sans-serif;
  font-weight: 700;
  overflow-wrap: break-word;
  word-wrap: break-word;
  -ms-word-break: break-all;
  word-break: break-word;
  -ms-hyphens: auto;
  -moz-hyphens: auto;
  -webkit-hyphens: auto;
  hyphens: auto; }

h1 {
  font-size: 2.35em; }

h2 {
  font-size: 2.00em; }

h3 {
  font-size: 1.75em; }

h4 {
  font-size: 1.5em; }

h5 {
  font-size: 1.25em; }

h6 {
  font-size: 1em; }

small, sub, sup {
  font-size: 75%; }

hr {
  border-color: #2c8898; }

a {
  text-decoration: none;
  color: #2c8898; }
  a:hover {
    color: #982c61;
    border-bottom: 2px solid #4a4a4a; }

ul {
  padding-left: 1.4em; }

li {
  margin-bottom: 0.4em; }

blockquote {
  font-style: italic;
  margin-left: 1.5em;
  padding-left: 1em;
  border-left: 3px solid #2c8898; }

img {
  height: auto;
  max-width: 100%; }

/* Pre and Code */
pre {
  background-color: #f1f1f1;
  display: block;
  padding: 1em;
  overflow-x: auto; }

code {
  font-size: 0.9em;
  padding: 0 0.5em;
  background-color: #f1f1f1;
  white-space: pre-wrap; }

pre > code {
  padding: 0;
  background-color: transparent;
  white-space: pre; }

/* Tables */
table {
  text-align: justify;
  width: 100%;
  border-collapse: collapse; }

td, th {
  padding: 0.5em;
  border-bottom: 1px solid #f1f1f1; }

/* Buttons, forms and input */
input, textarea {
  border: 1px solid #4a4a4a; }
  input:focus, textarea:focus {
    border: 1px solid #2c8898; }

textarea {
  width: 100%; }

.button, button, input[type="submit"], input[type="reset"], input[type="button"] {
  display: inline-block;
  padding: 5px 10px;
  text-align: center;
  text-decoration: none;
  white-space: nowrap;
  background-color: #2c8898;
  color: #f9f9f9;
  border-radius: 1px;
  border: 1px solid #2c8898;
  cursor: pointer;
  box-sizing: border-box; }
  .button[disabled], button[disabled], input[type="submit"][disabled], input[type="reset"][disabled], input[type="button"][disabled] {
    cursor: default;
    opacity: .5; }
  .button:focus, .button:hover, button:focus, button:hover, input[type="submit"]:focus, input[type="submit"]:hover, input[type="reset"]:focus, input[type="reset"]:hover, input[type="button"]:focus, input[type="button"]:hover {
    background-color: #982c61;
    border-color: #982c61;
    color: #f9f9f9;
    outline: 0; }

textarea, select, input[type] {
  color: #4a4a4a;
  padding: 6px 10px;
  /* The 6px vertically centers text on FF, ignored by Webkit */
  margin-bottom: 10px;
  background-color: #f1f1f1;
  border: 1px solid #f1f1f1;
  border-radius: 4px;
  box-shadow: none;
  box-sizing: border-box; }
  textarea:focus, select:focus, input[type]:focus {
    border: 1px solid #2c8898;
    outline: 0; }

input[type="checkbox"]:focus {
  outline: 1px dotted #2c8898; }

label, legend, fieldset {
  display: block;
  margin-bottom: .5rem;
  font-weight: 600; }
#>>> copy text theme.css
/* Imports */
@import url("normalize.css");
@import url("sakura.css");
@import url("menu.css");



/*
    Header
*****************/
#banner {
    height: 300px;
    margin: 0;
    padding: 0;
	background-color: #2c8898;
    background-image: linear-gradient(#6a98e5, #2c8898); 
   }
/* Title */
#banner h1{
    color: #fff;
    padding: 0.5em;
    margin: 0;
}
#>>> copy text _templates/convert_page.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url/" />
<title>$title</title>
<meta name="date" content="$mdate" />
<meta name="description" content="$description" />
<meta name="keywords" content="$keywords" />
<meta name="author" content="$author" />
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<h2>$title</h2>
$body
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_gallery.htm
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url/" />
<title>$title</title>
<link href="gallery.css" rel="stylesheet">
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<section id="gallery">
<!-- for @files -->
<section class="item">
<a href="#img$count">
<!-- for @thumbfile -->
<img src="$url">
<!-- endfor -->
</a>
</section>
<!-- endfor -->
</section>
<!-- for @files -->
<div class="lightbox" id="img$count">
<div class="box">
<a class="close" href="#">X</a>
 $title
 <div class="content">
 <img src="$url">
 </div>
</div>
</div>
<!-- endfor-->
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_index.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url/" />
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<h2>$title</h2>

<ul>
<!-- for @files -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_news.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url/" />
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<!-- for @top_files -->
$body
<p><a href="$url">Written on $date</a></p>
<!-- endfor -->
<h3>Archive</h3>

<p>
<!-- for @folders -->
<a href="$url">$title</a>&nbsp;&nbsp;
<!-- endfor -->
</p>
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_news_index.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url/" />
<<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<h2>$title</h2>

<ul>
<!-- for @folders -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
<!-- for @files -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy configuration essays/followme.cfg 0
run_before = App::Followme::CreateNews
