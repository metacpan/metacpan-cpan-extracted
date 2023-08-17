package App::Followme::Initialize;
use 5.008005;
use strict;
use warnings;
use lib '../..';

use IO::File;
use MIME::Base64  qw(decode_base64);
use File::Spec::Functions qw(splitdir catfile);

use App::Followme::FIO;
use App::Followme::NestedText;

our $VERSION = "2.03";

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
    return if -e $file;

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
    
    my $config;
    my %old_config = nt_parse_almost_yaml_string(join('', @$lines));

    if (-e $file) {
        my $page = fio_read_page($file);

        if ($page =~ /:[ \n]/) {
            my %new_config = nt_parse_almost_yaml_string($page);
            $config = nt_merge_items(\%old_config, \%new_config);

        } else {
            my $new_file = $file;
            $new_file =~ s/\.*$/ocfg/;
            rename($file, $new_file);
            $config = \%old_config;
        }

    } else {
        $config = \%old_config;
    }

    nt_write_almost_yaml_file($file, %$config);
    return;
}

#----------------------------------------------------------------------
# Copy a text file

sub copy_text {
    my ($file, $lines, @args) = @_;
    return if -e $file;

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

        if ($path && ! -d $path) {
            mkdir($path, 0755) or die "Couldn't create $path: $!\n";
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

1;
__DATA__
#>>> copy binary banner.jpg
/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAeAAD/4QMraHR0cDov
L25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENl
aGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4
OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjAtYzA2MCA2MS4xMzQ3NzcsIDIwMTAvMDIvMTItMTc6
MzI6MDAgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5
OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHht
bG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6
Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUu
Y29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBo
b3Rvc2hvcCBDUzUgTWFjaW50b3NoIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjBGMTg3OEQy
OTA5MjExRTE5OTJDQjgwQkE4RTNCQTdGIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjBGMTg3
OEQzOTA5MjExRTE5OTJDQjgwQkE4RTNCQTdGIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmlu
c3RhbmNlSUQ9InhtcC5paWQ6QjQ3NDNDNDk5MDkxMTFFMTk5MkNCODBCQThFM0JBN0YiIHN0UmVm
OmRvY3VtZW50SUQ9InhtcC5kaWQ6QjQ3NDNDNEE5MDkxMTFFMTk5MkNCODBCQThFM0JBN0YiLz4g
PC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9
InIiPz7/7gAOQWRvYmUAZMAAAAAB/9sAhAAQCwsLDAsQDAwQFw8NDxcbFBAQFBsfFxcXFxcfHhca
GhoaFx4eIyUnJSMeLy8zMy8vQEBAQEBAQEBAQEBAQEBAAREPDxETERUSEhUUERQRFBoUFhYUGiYa
GhwaGiYwIx4eHh4jMCsuJycnLis1NTAwNTVAQD9AQEBAQEBAQEBAQED/wAARCAH0A8ADASIAAhEB
AxEB/8QAegABAQEBAQEBAAAAAAAAAAAAAAEEAgMFBgEBAQAAAAAAAAAAAAAAAAAAAAEQAQACAQID
AwYMBgIDAQAAAAABAgMRBCExElFxsUGRwXITBWGBodEiMlIjUxQkFUKCkrIzNOHSYkNzohEBAAAA
AAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8A/YRyCOQKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAE8gnkBHISOSgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE8hJ5ARyVI5AKIAo
gCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiA
KIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAq
TyCeQEchI5KIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE8hJ5ARyVI5AKIAogCiAKIAo
gCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiA
KIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAqTyCeQJHJ
UjkAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIA
ogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCi
AKIAogCpPIJ5ARyCOQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATyCeQJHIIAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACeQSCQqQAogCiAKIAogCiAKIAogCiAKIAogCiAKIAog
CiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAK
IAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCpISBAkAKIAogCiAKIAogCiAKIAogCiA
KIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAo
gCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIApKEgQJACiAKIAogCiAKIA
ogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCi
AKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKIAogCiAKShIECQoAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABIkgQJCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
RE2mK1jWZ5QAO/YZ/wAOx7DP+HYHA6nDmrGs47adziJ1BR1XFltHVWk2jthzMTW01tGlo5xIAAAA
A6riy2jqrSbR2w5tW1J6bxNZnjpIAAALWtrzpSs27o1BB6RtdxPLHPniPSlsGevPHPxcfAHAnl05
T2O4w5bRFq0mYnlMA5HfsM/4dj2Gf8OwOBb48mOIm9ZrEzpEz2la2vOlY1nsgEFvjyUjW9ZrHLWU
AB1GHLaItWkzE8pgHIcYmYnhMcJgAFrS9/qVm3dD0/K7n8P5Y+cHkOr4stI1vSYjt01j5HETqCg7
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
DSOwAFTSOwANI7DSOwAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAU
QBRAFEABAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEA
UQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBR
AFEAUQBRAFEAUQAEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARUAU
QBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRA
FEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAU
QBUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAU
QBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRAFEAUQBRA
FEAUQBRAFEAUQBRAFEAUQBRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAEAH//2Q==
#>>> copy text followme.cfg
run_before:
    - App::Followme::FormatPage
    - App::Followme::ConvertPage
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
<div><img src="banner.jpg"></div>
<span class= "title"><a href="#">Your Title Here</a></span>
<div class="dropdown" style="float:right;">
    <button class="dropbtn">&#9776;</button>
    <nav class="dropdown-content">
      <a href="essays/index.html">Essays</a>
      <a href="photos/index.html">Photos</a>
    </nav>
</div>
</header>
<article>
<section id="primary">
<!-- section primary -->
<h2>Followme</h2>

<p>Usage: followme [file or directory]</p>

<p>Update a static website after changes. Constant portions of each page are
updated to match, text files are converted to html, and indexes are created
for new files in the archive.</p>

<p>The script is run on the directory or file passed as its argument. If no
argument is given, it is run on the current directory.</p>

<p>If a file is passed, the script is run on the directory the file is in. In
addition, the script is run in quick mode, meaning that only the directory
the file is in is checked for changes. Otherwise not only that directory, but
all directories below it are checked.</p>

<p>Followme can be downloaded from CPAN as App::Followme.</p>

<p>This file is used as a template for the site. Any markup outside the section 
comments will be shared between all pages. Modify it to get the desired look for 
your site. The subdirectories show some of the capabilities of this application.
Keep or modify them as you wish.</p>

<p>See <a href="help/index.html">help</a> for more information about this 
script.</p>

<!-- endsection primary-->
<section id="secondary">
<!-- section secondary -->
<!-- endsection secondary-->
</section>
</article>
<footer>
    <nav class="footer-content">
        <a href="essays/index.html">Essays</a>
        <a href="photos/index.html">Photos</a>
    </nav>
</footer>
</body>
</html>
#>>> copy text theme.css
/*
    Global styles
*****************/
body {
    font-family: helvetica, arial, sans-serif;
    line-height: 1.5;
    margin: 0 auto;
    max-width: 50em;
    padding: 0 1em;
}
h1, h2, h3, h4, h5, h6 {
    margin: 1em 0 0.5em 0;
    line-height: 1.2em;
}
img {
    max-width: 100%;
}
figure {
    margin: 1em 0;
    text-align: center;
}
figcaption {
    font-size: small;
}
pre, code, samp, kbd {
    color: #009;
    font-family: monospace, monospace;
    font-size: 0.9em;
}
pre code, pre samp, pre kbd {
    font-size: 1em;
}
pre kbd {
    color: #060;
}
pre {
    background: #eee;
    padding: 0.5em;
    overflow: auto;
}
blockquote {
    background: #eee;
    border-left: medium solid #ccc;
    margin: 1em 0;
    padding: 0.5em;
}
blockquote :first-child {
    margin-top: 0;
}
blockquote :last-child {
    margin-bottom: 0;
}  
/*
    Header
*****************/
header {
    padding: 0; 
    background: #222;
    border-radius: 6px;
}
.title {
    padding: 16px;
    font-size: 1.75em;
}
.title a {
    text-decoration: none;
    color: #aaa; 
}
.title a:hover {
      color: #fff;
}
/*
    Footer
*****************/
footer {
    padding: 8px; 
    background: #222;
    border-radius: 6px;
}
.footer-content a {
    padding: 16px;
    text-decoration: none;
    color: #aaa; 
}
.footer-content a:hover {
    color: #fff;
}
/*
    Menu
*****************/
.dropbtn {
    font-size: 1.75em;
    background-color: #222;
    color: #aaa;
    border: none;   
    cursor: pointer;
}  
.dropdown {
    position: relative;
    display: inline-block;
} 
.dropdown-content {
    display: none;
    position: absolute;
    right: 0;
    background-color: #222;
    min-width: 160px;
    border-radius: 6px;
    z-index: 1;
} 
.dropdown-content a {
    color: #aaa;
    padding: 12px 16px;
    border-radius: 6px;
    text-decoration: none;
    display: block;
} 
.dropdown-content a:hover {
    color: #fff;
}
.dropdown:hover .dropdown-content {
    display: block;
}
.dropdown:hover .dropbtn {
    color:#fff;
    background-color: #222;
    border-color: #222;
}
/*
    Photo Gallery
*****************/
#gallery { 
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    grid-gap: 10px;
    align-items: start;
    }
  
  .thumb {
      border: 1px solid #ccc;
      box-shadow: 2px 2px 6px 0px  rgba(0,0,0,0.3);
      max-width: 100%;
  }
  
  .lightbox {
      position: fixed;
      z-index: 999;
      height: 0;
      width: 0;
      text-align: center;
      top: 0;
      left: 0;
      background: rgba(0, 0, 0, 0.8);
      opacity: 0;
  }
  
  .lightbox img {
      max-width: 90%;
      max-height: 80%;
      margin-top: 2%;
      opacity: 0;
  }
  
  .lightbox:target {
      /** Remove default browser outline */
      outline: none;
      width: 100%;
      height: 100%;
      opacity: 1 !important;
      
  }
  
  .lightbox:target img {
      border: solid 17px rgba(77, 77, 77, 0.8);
      opacity: 1;
      webkit-transition: opacity 0.6s;
      transition: opacity 0.6s;
  }
  
  .light-btn {
      color: #fafafa;
      background-color: #333;
      border: solid 3px #777;
      padding: 5px 15px;
      border-radius: 1px;
      text-decoration: none;
      cursor: pointer;
      vertical-align: middle;
      position: absolute;
      top: 45%;
      z-index: 99;
  }
  
  .light-btn:hover {
      background-color: #111;
  }
  
  .btn-prev {
      left: 7%;
  }
  
  .btn-next {
      right: 7%;
  }
  
  .btn-close {
      position: absolute;
      right: 2%;
      top: 2%;
      color: #fafafa;
      background-color: #92001d;
      border: solid 5px #ef4036;
      padding: 10px 15px;
      border-radius: 1px;
      text-decoration: none;
  }
  
  .btn-close:hover {
      background-color: #740404;
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
<meta name="date" content="$mdate" />
<meta name="description" content="$description" />
<meta name="keywords" content="$keywords" />
<meta name="author" content="$author" />
<!-- endsection meta -->
<link rel="stylesheet" id="css_style" href="theme.css">
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
<a href="$index_url#$target">
<!-- for @thumb_file -->
<img class="thumb" src="$url">
<!-- endfor -->
</a>
<div class="lightbox" id="$target">
<a href="$index_url#$target_previous" class="light-btn btn-prev">prev</a>
<a href="$index_url#_" class="btn-close">X</a>
<img src="$url">
<a href="$index_url#$target_next" class="light-btn btn-next">next</a>
</div>
<!-- endfor -->
</section>
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
</section>
<section id="secondary">
<!-- section secondary -->
<h2>$title</h2>

<ul>
<!-- for @files_by_title -->
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
</section>
<section id="secondary">
<!-- section secondary -->
<!-- for @top_files_by_mdate_reversed -->
<p>$summary</p>
<p><a href="$url">More ...</a></p>

<!-- endfor -->
<h3>Archive</h3>
<p>Other essays can be found in the following sections:</p>
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
#>>> copy text essays/followme.cfg
run_before:
    - App::Followme::CreateIndex
template_file: create_news.htm
#>>> copy text essays/index.md
----
title: Essays Directory
description: A collection of short essays on various topics
keywords: essays
----
This folder is configured (via followme.cfg) to contain short essays 
on various topics. To use it, create subdirectories for each topic.
write your essay in Markdown format, and save the file in the appropriate
subdirectory. You can also include metadata for the essay, such as the 
title at the top of the file, just as has been done in this file. 

When followme is run, it will create an index for files in the current directory 
and its subdirectories that contain the text of the most recently modified files 
together with links to the files. It can also be used to create a basic weblog.
#>>> copy text essays/archive/followme.cfg
run_before:
    - App::Followme::CreateIndex
template_file: create_index.htm
#>>> copy text essays/archive/index.md
----
title: Archive Directory
description: Archive of short essays
keywords: essays, archive
----
This folder is configured (via followme.cfg) to contain an archive of
previously written essays. When followme is run, it will create an index 
for files in the current directory  containing a link to each essay in the 
archive.
#>>> copy text photos/followme.cfg
run_before:
    - App::Followme::CreateGallery
target_prefix: img
#>>> copy text photos/index.md
----
title: Photo Gallery
description: A collection of photos of interest
----
This folder is configured (via followme.cfg) to contain a photo 
gallery. If you add or subtract photos from this folder and run
followme, it will update the gallery. Each photo must have a 
thumbnail whose name is related to the photo like this:
photo-thumb.jpg. The suffix (-thumb) can be set in the configuration
file.
