package App::Followme::Initialize;
use 5.008005;
use strict;
use warnings;

use Cwd;
use IO::File;
use MIME::Base64  qw(decode_base64);
use File::Spec::Functions qw(splitdir catfile);

our $VERSION = "1.92";

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
            mkdir ($path) or die "Couldn't create $path: $!\n";
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
#>>> copy text README
"Simpliste" is a simple responsive HTML5 template

http://cssr.ru/simpliste/

Copyright (c) 2012 Renat Rafikov

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


How to use:

1. Choose a skin from the _skin directory
2. Copy it to "../skin.css" 
3. Open "index.html"
#>>> copy binary favicon.ico
AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAQAQAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAADqWgAA6sAAAOr/AADq/wAA6v8AAOr2AADqtAAA6j8AAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAOoVAADqrgAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6v8A
AOr/AADqjQAA6gkAAAAAAAAAAAAAAAAAAOokAADq5wAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA
6v8AAOr/AADq/wAA6v8AAOrPAADqDwAAAAAAAOoDAADqzAAA6v8AAOr/AADq/wAA6v8AAOr/AADq
/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6qgAAAAAAADqYwAA6v8AAOr/AADq/wAA6v//////
//////////////////////////8AAOr/AADq/wAA6v8AAOr/AADqOQAA6sMAAOr/AADq/wAA6v8A
AOr/AADq/wAA6v8AAOr/AADq/wAA6v8AAOr//////wAA6v8AAOr/AADq/wAA6pYAAOr8AADq/wAA
6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq//////8AAOr/AADq/wAA6v8AAOrbAADq
/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6v//////AADq/wAA6v8AAOr/
AADq+QAA6v8AAOr/AADq/wAA6v8AAOr/////////////////////////////////AADq/wAA6v8A
AOr/AADq/wAA6vYAAOr2AADq/wAA6v8AAOr//////wAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA
6v8AAOr/AADq/wAA6v8AAOrPAADqtAAA6v8AAOr/AADq//////8AAOr/AADq/wAA6v8AAOr/AADq
/wAA6v8AAOr/AADq/wAA6v8AAOr/AADqhwAA6ksAAOr/AADq/wAA6v//////AADq/wAA6v8AAOr/
AADq/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq+QAA6iQAAAAAAADqsQAA6v8AAOr/AADq////////
/////////////////////////wAA6v8AAOr/AADq/wAA6o0AAAAAAAAAAAAA6g8AAOrMAADq/wAA
6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq/wAA6q4AAOoDAAAAAAAAAAAAAAAAAADq
BgAA6oQAAOr8AADq/wAA6v8AAOr/AADq/wAA6v8AAOr/AADq8wAA6mYAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAADqMAAA6pMAAOrPAADq/wAA6vYAAOrJAADqhAAA6hsAAAAAAAAAAAAAAAAA
AAAA8A8AAMADAACAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAEAAIAB
AADABwAA8A8AAA==
#>>> copy text flexslider.css
.flexslider {
	width:100%;
	margin:0;
	padding:0;
}

.flexslider .slides>li {
	display:none;
}
.flexslider .slides img {
	max-width:100%;
	display:block;
}
.flex-pauseplay span {
	text-transform:capitalize;
}
.slides:after {
	content:".";
	display:block;
	clear:both;
	visibility:hidden;
	line-height:0;
	height:0;
}

html[xmlns] .slides {
	display:block;
}
* html .slides {
	height:1%;
}

.flexslider {
	background:#fff;
	border:4px solid #fff;
	position:relative;
	-webkit-border-radius:5px;
	-moz-border-radius:5px;
	-o-border-radius:5px;
	border-radius:5px;
	zoom:1;
}
.flexslider ul {list-style:none; margin:0; padding:0;}
.flexslider .slides {
	zoom:1;
}
.flexslider .slides>li {
	position:relative;
}
.flex-container {
	zoom:1;
	position: relative;
}

/* Caption style */
/* IE rgba() hack */
.flex-caption {
	background:none;
	-ms-filter:progid:DXImageTransform.Microsoft.gradient(startColorstr=#4C000000,endColorstr=#4C000000);
	filter:progid:DXImageTransform.Microsoft.gradient(startColorstr=#4C000000,endColorstr=#4C000000);
	zoom:1;
}
.flex-caption {
	width:96%;
	padding:2%;
	position:absolute;
	left:0;
	bottom:0;
	background:rgba(0,0,0,.3);
	color:#fff;
	text-shadow:0 -1px 0 rgba(0,0,0,.3);
	font-size:14px;
	line-height: 18px;
}

/* Direction Nav */
.flex-direction-nav li a {
	width:52px;
	height:50px;
	margin:-13px 0 0;
	display:block;
	background:#d4d4d4;
	position:absolute;
	top:50%;
	cursor:pointer;
	text-indent:-9999px;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius: 6px;
  -webkit-box-shadow:rgba(0,0,0,0.3) 0px 2px 2px;
  -moz-box-shadow:rgba(0,0,0,0.3) 0px 2px 2px;
  box-shadow:rgba(0,0,0,0.3) 0px 2px 2px;
}
.flex-direction-nav li .next {
	right:-21px;
}
.flex-direction-nav li .next:before {
  content:"";
  position:absolute;
  right:15px;
  top:8px;
	width:0;
	height:0;
	border-top:18px solid transparent;
	border-bottom:18px solid transparent;
	border-left:18px solid #6a6a6a;
}
.flex-direction-nav li .next:after {
  content:"";
  position:absolute;
  right:24px;
  top:17px;
	width:0;
	height:0;
	border-top:9px solid transparent;
	border-bottom:9px solid transparent; 
	border-left:9px solid #d4d4d4;
}

.flex-direction-nav li .prev {
	left:-20px;
}
.flex-direction-nav li .prev:before {
  content:"";
  position:absolute;
  left:15px;
  top:8px;
	width: 0;
	height: 0;
	border-top:18px solid transparent;
	border-bottom:18px solid transparent; 
	border-right:18px solid #6a6a6a;
}
.flex-direction-nav li .prev:after {
  content:"";
  position:absolute;
  left:24px;
  top:17px;
	width: 0;
	height: 0;
	border-top:9px solid transparent;
	border-bottom:9px solid transparent; 
	border-right:9px solid #d4d4d4;
}

.flex-direction-nav li .disabled {
	opacity:.3;
	filter:alpha(opacity=30);
	cursor: default;
}

/* Control Nav */
.flex-control-nav {
	width:100%;
	position:absolute;
	bottom:-30px;
	text-align:center;
}
.flex-control-nav li {
	margin:0 0 0 5px;
	display:inline-block;
	zoom:1;
	/display:inline;
}
.flex-control-nav li:first-child {
	margin:0;
}
.flex-control-nav li a {
	width:12px;
	height:12px;
	display:block;
	background:#ffffff;
	cursor:pointer;
	text-indent:-9999px;
  border:1px solid #bbbbbb;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius: 6px;
}
.flex-control-nav li a:hover {
	background:#82c5e7;
  border:1px solid #82c5e7;
}
.flex-control-nav li a.active {
  border:0;
	display:block;
	background:#289aca;
	cursor:default;
  border:1px solid #289aca;
}
#>>> copy configuration followme.cfg 0
run_before = App::Followme::FormatPage
run_before = App::Followme::ConvertPage

#>>> copy text index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<title>Test</title>
<meta name="date" content="2016-02-13T07:41:02" />
<meta name="description" content="This is the top page" />
<meta name="keywords" content="" />
<meta name="author" content="" />
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>Test</h2>
<p>This is the top page</p>

<!-- endsection primary -->
      <!-- section secondary -->
      <!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text jquery.flexslider-min.js
/*
 * jQuery FlexSlider v1.8
 * http://flex.madebymufffin.com
 * Copyright 2011, Tyler Smith
 */
(function(a){a.flexslider=function(c,b){var d=c;d.init=function(){d.vars=a.extend({},a.flexslider.defaults,b);d.data("flexslider",true);d.container=a(".slides",d);d.slides=a(".slides > li",d);d.count=d.slides.length;d.animating=false;d.currentSlide=d.vars.slideToStart;d.animatingTo=d.currentSlide;d.atEnd=(d.currentSlide==0)?true:false;d.eventType=("ontouchstart" in document.documentElement)?"touchstart":"click";d.cloneCount=0;d.cloneOffset=0;d.manualPause=false;d.vertical=(d.vars.slideDirection=="vertical");d.prop=(d.vertical)?"top":"marginLeft";d.args={};d.transitions="webkitTransition" in document.body.style;if(d.transitions){d.prop="-webkit-transform"}if(d.vars.controlsContainer!=""){d.controlsContainer=a(d.vars.controlsContainer).eq(a(".slides").index(d.container));d.containerExists=d.controlsContainer.length>0}if(d.vars.manualControls!=""){d.manualControls=a(d.vars.manualControls,((d.containerExists)?d.controlsContainer:d));d.manualExists=d.manualControls.length>0}if(d.vars.randomize){d.slides.sort(function(){return(Math.round(Math.random())-0.5)});d.container.empty().append(d.slides)}if(d.vars.animation.toLowerCase()=="slide"){if(d.transitions){d.setTransition(0)}d.css({overflow:"hidden"});if(d.vars.animationLoop){d.cloneCount=2;d.cloneOffset=1;d.container.append(d.slides.filter(":first").clone().addClass("clone")).prepend(d.slides.filter(":last").clone().addClass("clone"))}d.newSlides=a(".slides > li",d);var m=(-1*(d.currentSlide+d.cloneOffset));if(d.vertical){d.newSlides.css({display:"block",width:"100%","float":"left"});d.container.height((d.count+d.cloneCount)*200+"%").css("position","absolute").width("100%");setTimeout(function(){d.css({position:"relative"}).height(d.slides.filter(":first").height());d.args[d.prop]=(d.transitions)?"translate3d(0,"+m*d.height()+"px,0)":m*d.height()+"px";d.container.css(d.args)},100)}else{d.args[d.prop]=(d.transitions)?"translate3d("+m*d.width()+"px,0,0)":m*d.width()+"px";d.container.width((d.count+d.cloneCount)*200+"%").css(d.args);setTimeout(function(){d.newSlides.width(d.width()).css({"float":"left",display:"block"})},100)}}else{d.transitions=false;d.slides.css({width:"100%","float":"left",marginRight:"-100%"}).eq(d.currentSlide).fadeIn(d.vars.animationDuration)}if(d.vars.controlNav){if(d.manualExists){d.controlNav=d.manualControls}else{var e=a('<ol class="flex-control-nav"></ol>');var s=1;for(var t=0;t<d.count;t++){e.append("<li><a>"+s+"</a></li>");s++}if(d.containerExists){a(d.controlsContainer).append(e);d.controlNav=a(".flex-control-nav li a",d.controlsContainer)}else{d.append(e);d.controlNav=a(".flex-control-nav li a",d)}}d.controlNav.eq(d.currentSlide).addClass("active");d.controlNav.bind(d.eventType,function(i){i.preventDefault();if(!a(this).hasClass("active")){(d.controlNav.index(a(this))>d.currentSlide)?d.direction="next":d.direction="prev";d.flexAnimate(d.controlNav.index(a(this)),d.vars.pauseOnAction)}})}if(d.vars.directionNav){var v=a('<ul class="flex-direction-nav"><li><a class="prev" href="#">'+d.vars.prevText+'</a></li><li><a class="next" href="#">'+d.vars.nextText+"</a></li></ul>");if(d.containerExists){a(d.controlsContainer).append(v);d.directionNav=a(".flex-direction-nav li a",d.controlsContainer)}else{d.append(v);d.directionNav=a(".flex-direction-nav li a",d)}if(!d.vars.animationLoop){if(d.currentSlide==0){d.directionNav.filter(".prev").addClass("disabled")}else{if(d.currentSlide==d.count-1){d.directionNav.filter(".next").addClass("disabled")}}}d.directionNav.bind(d.eventType,function(i){i.preventDefault();var j=(a(this).hasClass("next"))?d.getTarget("next"):d.getTarget("prev");if(d.canAdvance(j)){d.flexAnimate(j,d.vars.pauseOnAction)}})}if(d.vars.keyboardNav&&a("ul.slides").length==1){function h(i){if(d.animating){return}else{if(i.keyCode!=39&&i.keyCode!=37){return}else{if(i.keyCode==39){var j=d.getTarget("next")}else{if(i.keyCode==37){var j=d.getTarget("prev")}}if(d.canAdvance(j)){d.flexAnimate(j,d.vars.pauseOnAction)}}}}a(document).bind("keyup",h)}if(d.vars.mousewheel){d.mousewheelEvent=(/Firefox/i.test(navigator.userAgent))?"DOMMouseScroll":"mousewheel";d.bind(d.mousewheelEvent,function(y){y.preventDefault();y=y?y:window.event;var i=y.detail?y.detail*-1:y.wheelDelta/40,j=(i<0)?d.getTarget("next"):d.getTarget("prev");if(d.canAdvance(j)){d.flexAnimate(j,d.vars.pauseOnAction)}})}if(d.vars.slideshow){if(d.vars.pauseOnHover&&d.vars.slideshow){d.hover(function(){d.pause()},function(){if(!d.manualPause){d.resume()}})}d.animatedSlides=setInterval(d.animateSlides,d.vars.slideshowSpeed)}if(d.vars.pausePlay){var q=a('<div class="flex-pauseplay"><span></span></div>');if(d.containerExists){d.controlsContainer.append(q);d.pausePlay=a(".flex-pauseplay span",d.controlsContainer)}else{d.append(q);d.pausePlay=a(".flex-pauseplay span",d)}var n=(d.vars.slideshow)?"pause":"play";d.pausePlay.addClass(n).text((n=="pause")?d.vars.pauseText:d.vars.playText);d.pausePlay.bind(d.eventType,function(i){i.preventDefault();if(a(this).hasClass("pause")){d.pause();d.manualPause=true}else{d.resume();d.manualPause=false}})}if("ontouchstart" in document.documentElement){var w,u,l,r,o,x,p=false;d.each(function(){if("ontouchstart" in document.documentElement){this.addEventListener("touchstart",g,false)}});function g(i){if(d.animating){i.preventDefault()}else{if(i.touches.length==1){d.pause();r=(d.vertical)?d.height():d.width();x=Number(new Date());l=(d.vertical)?(d.currentSlide+d.cloneOffset)*d.height():(d.currentSlide+d.cloneOffset)*d.width();w=(d.vertical)?i.touches[0].pageY:i.touches[0].pageX;u=(d.vertical)?i.touches[0].pageX:i.touches[0].pageY;d.setTransition(0);this.addEventListener("touchmove",k,false);this.addEventListener("touchend",f,false)}}}function k(i){o=(d.vertical)?w-i.touches[0].pageY:w-i.touches[0].pageX;p=(d.vertical)?(Math.abs(o)<Math.abs(i.touches[0].pageX-u)):(Math.abs(o)<Math.abs(i.touches[0].pageY-u));if(!p){i.preventDefault();if(d.vars.animation=="slide"&&d.transitions){if(!d.vars.animationLoop){o=o/((d.currentSlide==0&&o<0||d.currentSlide==d.count-1&&o>0)?(Math.abs(o)/r+2):1)}d.args[d.prop]=(d.vertical)?"translate3d(0,"+(-l-o)+"px,0)":"translate3d("+(-l-o)+"px,0,0)";d.container.css(d.args)}}}function f(j){d.animating=false;if(d.animatingTo==d.currentSlide&&!p&&!(o==null)){var i=(o>0)?d.getTarget("next"):d.getTarget("prev");if(d.canAdvance(i)&&Number(new Date())-x<550&&Math.abs(o)>20||Math.abs(o)>r/2){d.flexAnimate(i,d.vars.pauseOnAction)}else{d.flexAnimate(d.currentSlide,d.vars.pauseOnAction)}}this.removeEventListener("touchmove",k,false);this.removeEventListener("touchend",f,false);w=null;u=null;o=null;l=null}}if(d.vars.animation.toLowerCase()=="slide"){a(window).resize(function(){if(!d.animating){if(d.vertical){d.height(d.slides.filter(":first").height());d.args[d.prop]=(-1*(d.currentSlide+d.cloneOffset))*d.slides.filter(":first").height()+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}else{d.newSlides.width(d.width());d.args[d.prop]=(-1*(d.currentSlide+d.cloneOffset))*d.width()+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}}})}d.vars.start(d)};d.flexAnimate=function(g,f){if(!d.animating){d.animating=true;d.animatingTo=g;d.vars.before(d);if(f){d.pause()}if(d.vars.controlNav){d.controlNav.removeClass("active").eq(g).addClass("active")}d.atEnd=(g==0||g==d.count-1)?true:false;if(!d.vars.animationLoop&&d.vars.directionNav){if(g==0){d.directionNav.removeClass("disabled").filter(".prev").addClass("disabled")}else{if(g==d.count-1){d.directionNav.removeClass("disabled").filter(".next").addClass("disabled")}else{d.directionNav.removeClass("disabled")}}}if(!d.vars.animationLoop&&g==d.count-1){d.pause();d.vars.end(d)}if(d.vars.animation.toLowerCase()=="slide"){var e=(d.vertical)?d.slides.filter(":first").height():d.slides.filter(":first").width();if(d.currentSlide==0&&g==d.count-1&&d.vars.animationLoop&&d.direction!="next"){d.slideString="0px"}else{if(d.currentSlide==d.count-1&&g==0&&d.vars.animationLoop&&d.direction!="prev"){d.slideString=(-1*(d.count+1))*e+"px"}else{d.slideString=(-1*(g+d.cloneOffset))*e+"px"}}d.args[d.prop]=d.slideString;if(d.transitions){d.setTransition(d.vars.animationDuration);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.slideString+",0)":"translate3d("+d.slideString+",0,0)";d.container.css(d.args).one("webkitTransitionEnd transitionend",function(){d.wrapup(e)})}else{d.container.animate(d.args,d.vars.animationDuration,function(){d.wrapup(e)})}}else{d.slides.eq(d.currentSlide).fadeOut(d.vars.animationDuration);d.slides.eq(g).fadeIn(d.vars.animationDuration,function(){d.wrapup()})}}};d.wrapup=function(e){if(d.vars.animation=="slide"){if(d.currentSlide==0&&d.animatingTo==d.count-1&&d.vars.animationLoop){d.args[d.prop]=(-1*d.count)*e+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}else{if(d.currentSlide==d.count-1&&d.animatingTo==0&&d.vars.animationLoop){d.args[d.prop]=-1*e+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}}}d.animating=false;d.currentSlide=d.animatingTo;d.vars.after(d)};d.animateSlides=function(){if(!d.animating){d.flexAnimate(d.getTarget("next"))}};d.pause=function(){clearInterval(d.animatedSlides);if(d.vars.pausePlay){d.pausePlay.removeClass("pause").addClass("play").text(d.vars.playText)}};d.resume=function(){d.animatedSlides=setInterval(d.animateSlides,d.vars.slideshowSpeed);if(d.vars.pausePlay){d.pausePlay.removeClass("play").addClass("pause").text(d.vars.pauseText)}};d.canAdvance=function(e){if(!d.vars.animationLoop&&d.atEnd){if(d.currentSlide==0&&e==d.count-1&&d.direction!="next"){return false}else{if(d.currentSlide==d.count-1&&e==0&&d.direction=="next"){return false}else{return true}}}else{return true}};d.getTarget=function(e){d.direction=e;if(e=="next"){return(d.currentSlide==d.count-1)?0:d.currentSlide+1}else{return(d.currentSlide==0)?d.count-1:d.currentSlide-1}};d.setTransition=function(e){d.container.css({"-webkit-transition-duration":(e/1000)+"s"})};d.init()};a.flexslider.defaults={animation:"fade",slideDirection:"horizontal",slideshow:true,slideshowSpeed:7000,animationDuration:600,directionNav:true,controlNav:true,keyboardNav:true,mousewheel:false,prevText:"Previous",nextText:"Next",pausePlay:false,pauseText:"Pause",playText:"Play",randomize:false,slideToStart:0,animationLoop:true,pauseOnAction:true,pauseOnHover:false,controlsContainer:"",manualControls:"",start:function(){},before:function(){},after:function(){},end:function(){}};a.fn.flexslider=function(b){return this.each(function(){if(a(this).find(".slides li").length==1){a(this).find(".slides li").fadeIn(400)}else{if(a(this).data("flexslider")!=true){new a.flexslider(a(this),b)}}})}})(jQuery);
#>>> copy text reset.css
/* CSS reset. Based on HTML5 boilerplate reset http://html5boilerplate.com/  */
article, aside, details, figcaption, figure, footer, header, hgroup, nav, section { display:block; }
audio[controls], canvas, video { display:inline-block; *display:inline; *zoom:1; }
html { font-size: 100%; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
body { margin: 0; font-size: 14px; line-height: 1.4; }
body, button, input, select, textarea { font-family:sans-serif; }
a:focus { outline:thin dotted; }
a:hover, a:active { outline:0; }
abbr[title] { border-bottom:1px dotted; }
b, strong { font-weight:bold; }
blockquote { margin:1em 40px; }
dfn { font-style:italic; }
hr { display:block; height:1px; border:0; border-top:1px solid #ccc; margin:1em 0; padding:0; }
ins { background:#ff9; color:#000; text-decoration:none; }
mark { background:#ff0; color:#000; font-style:italic; font-weight:bold; }
pre, code, kbd, samp { font-family:monospace, monospace; _font-family:'courier new', monospace; font-size:1em; }
pre { white-space:pre; white-space:pre-wrap; word-wrap:break-word; }
q { quotes:none; }
q:before, q:after { content:""; content:none; }
small { font-size:85%; }
sub, sup { font-size:75%; line-height:0; position:relative; vertical-align:baseline; }
sup { top:-0.5em; }
sub { bottom:-0.25em; }
ul, ol { margin:1em 0; padding:0 0 0 2em; }
dd { margin:0 0 0 40px; }
nav ul, nav ol { list-style:none; margin:0; padding:0; }
img { border:0; -ms-interpolation-mode:bicubic; }
svg:not(:root) { overflow:hidden;}
figure { margin:0; }
form { margin:0; }
fieldset { border:0; margin:0; padding:0; }
legend { border:0; *margin-left:-7px; padding:0; }
label { cursor:pointer; }
button, input, select, textarea { font-size:100%; margin:0; vertical-align:baseline; *vertical-align:middle; }
button, input { line-height:normal; *overflow:visible; }
button, input[type="button"], input[type="reset"], input[type="submit"] { cursor:pointer; -webkit-appearance:button; }
input[type="checkbox"], input[type="radio"] { box-sizing:border-box; }
input[type="search"] { -moz-box-sizing:content-box; -webkit-box-sizing:content-box; box-sizing:content-box; }
button::-moz-focus-inner, input::-moz-focus-inner { border:0; padding:0; }
textarea { overflow:auto; vertical-align:top; }
input:valid, textarea:valid {  }
input:invalid, textarea:invalid { background-color:#f0dddd; }
table { border-collapse:collapse; border-spacing:0; }
.hidden { display:none; visibility:hidden; }
.clearfix:before, .clearfix:after { content:""; display:table; }
.clearfix:after { clear:both; }
.clearfix { zoom:1; }
/* End CSS reset */
#>>> copy text skin.css
/* Skin "Simple" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#333;
}

a { color:#004dd9; }
a:hover { color:#ea0000; }
a:visited { color:#551a8b; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
}

.logo {
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #000;
  font-size:18px;
  color:#ea0000;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}
.menu_main a,
.menu_main a:visited {
}
.menu_main a:hover,
.menu_main a:hover:visited {
}
.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_main li.active,
.menu_main li.active a {
  color:#000;
  text-decoration:none;
  cursor:default;
}


.info {
  padding:0 0 1em 2%;
}

.hero {}
.hero h1 {
  font-size:26px;
  font-family:georgia, serif;
  font-style:italic;
  color:#EA0000;
}

.article {}

.footer {
  border-top:1px solid #666;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom a,
.menu_bottom a:visited {
}
.menu_bottom a:hover,
.menu_bottom a:hover:visited {
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#666;
  text-decoration:none;
  cursor:default;
}

h1, h2 {
  font-weight:normal;
  color:#000;
}
h1 {
  font-size:22px;
}
h3, h4, h5, h6 {
  font-weight:bold;
  color:#000;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #d00303;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#ea0000;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ea0000), to(#d00303));
  background:-webkit-linear-gradient(#ea0000, #d00303);
  background:-moz-linear-gradient(#ea0000, #d00303);
  background:-ms-linear-gradient(#ea0000, #d00303);
  background:-o-linear-gradient(#ea0000, #d00303);
  background:linear-gradient(#ea0000, #d00303);
  color:#fff;
  padding:12px 20px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 1px #d03302;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#d00303), to(#ea0000));
  background:-webkit-linear-gradient(#d00303, #ea0000);
  background:-moz-linear-gradient(#d00303, #ea0000);
  background:-ms-linear-gradient(#d00303, #ea0000);
  background:-o-linear-gradient(#d00303, #ea0000);
  background:linear-gradient(#d00303, #ea0000);
}
a.button:active,
.button:active {
  color:#8c1515;
  text-shadow:1px 1px 1px #ffaeae;
  -webkit-box-shadow:#a10000 0px -3px 3px inset;
  -moz-box-shadow:#a10000 0px -3px 3px inset;
  box-shadow:#a10000 0px -3px 3px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#ffffff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ffffff), to(#F7F7F7));
  background:-webkit-linear-gradient(#ffffff, #F7F7F7);
  background:-moz-linear-gradient(#ffffff, #F7F7F7);
  background:-ms-linear-gradient(#ffffff, #F7F7F7);
  background:-o-linear-gradient(#ffffff, #F7F7F7);
  background:linear-gradient(#ffffff, #F7F7F7);
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#fff;
  padding:8px 14px;
  background:#EA0000;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #399f16;
  color:#fff;
  background:#399f16;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #f1edcf;
  color:#000;
  background:#fbf8e3;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text style.css
/* "Simpliste" template. Renat Rafikov. http://cssr.ru/simpliste/ */

/* Columns
-------
.col_33 | .col_33 | .col_33
.clearfix
-------
.col_75 | .col_25
.clearfix
-------
.col_66 | .col_33
.clearfix
-------
.col_50 | .col_50
.clearfix
-------
.col_100
-------
*/
.col_25 {
  width:23%;
  margin:0 2% 0 0;
  float:left;
}
.col_33 {
  width:31%;
  margin:0 2% 0 0;
  float:left;
}
.col_50 {
  width:48%;
  margin:0 2% 0 0;
  float:left;
}
.col_66 {
  width:64%;
  margin:0 2% 0 0;
  float:left;
}
.col_75 {
  width:73%;
  margin:0 2% 0 0;
  float:left;
}
.col_100 {
  width:98%;
  margin:0 2% 0 0;
}

.col_25.wrap { width:25%; margin:0;}
.col_33.wrap { width:33%; margin:0;}
.col_50.wrap { width:50%; margin:0;}
.col_66.wrap { width:66%; margin:0;}
.col_75.wrap { width:75%; margin:0;}
.col_100.wrap { width:100%; margin:0;}
/* End columns */


/* Helper classes */
.center {text-align:center;}
.left {text-align:left;}
.right {text-align:right;}

.img_floatleft {float:left; margin:0 10px 5px 0;}
.img_floatright {float:right; margin:0 0 5px 10px;}

.img {max-width:100%;}
/* End helper classes */

a.button { color:auto; }

@media only screen and (max-width:480px) { /* Smartphone */
  .header {
    margin-bottom:0;
  }

  .logo{
    display:block;
    float:none;
    text-align:center;
  }

  .menu_main {
    width:100%;
    text-align:center;
    float:none;
    padding:0;
    margin:1em 0 0 0;
  }

  .menu_main a {
    display:inline-block;
    padding:7px;
  }

  .copyright {
    width:100%;
    float:none;
    text-align:center;
  }

  .footer  {
    padding-bottom:0;
  }

  .menu_bottom {
    width:100%;
    float:none;
    text-align:center;
    margin:1em 0 0 0;
    padding:0;
  }
  .menu_bottom a {
    display:inline-block;
    padding:6px;
  }

  .form textarea {
    width:100%;
  }
  .form label {
    padding:10px 0 8px 0;
  }
}


@media only screen and (max-width:768px) { /* Tablet */
  .col_25,
  .col_33,
  .col_66,
  .col_50 ,
  .col_75  {
    width:98%;
    float:none;
  }

  .form label {
    padding:10px 0 8px 0;
  }
}


@media print { /* Printer */
  * { background:transparent !important; color:black !important; text-shadow:none !important; filter:none !important; -ms-filter:none !important; }
  a, a:visited { color:#444 !important; text-decoration:underline; }
  a[href]:after { content:" (" attr(href) ")"; }
  abbr[title]:after { content:" (" attr(title) ")"; }
  pre, blockquote { border:1px solid #999; page-break-inside:avoid; }
  thead { display:table-header-group; }
  tr, img { page-break-inside:avoid; }
  img { max-width:100% !important; }
  @page { margin:0.5cm; }
  p, h2, h3 { orphans:3; widows:3; }
  h2, h3{ page-break-after:avoid; }

  .header, .footer, .form {display:none;}
  .col_33, .col_66, .col_50  { width:98%; float:none; }
}
#>>> copy text _templates/convert_page.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<meta name="date" content="$mdate" />
<meta name="description" content="$description" />
<meta name="keywords" content="$keywords" />
<meta name="author" content="$author" />
<!-- endsection meta -->
</head>
<body>
<div id="header">
<h1>Site Title</h1>
</div>
<div id="conent">
<div id="primary">
<!-- section primary -->
<h2>$title</h2>
$body
<!-- endsection primary-->
</div>
<div id="secondary">
<!-- section secondary -->
<!-- endsection secondary-->
</div>
</div>
</body>
</html>
#>>> copy text _templates/create_gallery.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
  <base href="$site_url" />
  <title>$title</title>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
  <script src="jquery.flexslider-min.js"></script>
  <link rel="stylesheet" href="flexslider.css" type="text/css" media="screen" />
  <!-- Hook up the FlexSlider -->
  <script type="text/javascript">
    $(window).load(function() {
      $('.flexslider').flexslider();
    });
  </script>
 <!-- endsection meta -->
</head>
<body>
<div id="header">
<h1>Site Title</h1>
</div>
<div id="content">
<div id="primary">
<!-- section primary -->
<!-- endsection primary-->
</div>
<div id="secondary">
<!-- section secondary -->
    <div class="flexslider">
      <ul class="slides">
<!-- for @files -->
        <li>
          <img src="$url" width="$width" height="$height" />
          <p class="flex-caption">$title</p>
        </li>
<!-- endfor -->
      </ul>
    </div>
<!-- endsection secondary-->
</div>
</div>
</body>
</html>
#>>> copy text _templates/create_index.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<div id="header">
<h1>Site Title</h1>
</div>
<div id="content">
<div id="primary">
<!-- section primary -->
<!-- endsection primary-->
</div>
<div id="secondary">
<!-- section secondary -->
<h2>$title</h2>

<ul>
<!-- for @files -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary-->
</div>
</div>
</body>
</html>
#>>> copy text _templates/create_news.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<div id="header">
<h1>Site Title</h1>
</div>
<div id="content">
<div id="primary">
<!-- section primary -->
<!-- endsection primary-->
</div>
<div id="secondary">
<!-- section secondary -->
<!-- for @top_files -->
<h2>$title</h2>
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
</div>
</div>
</body>
</html>
#>>> copy text _templates/create_news_index.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<div id="header">
<h1>Site Title</h1>
</div>
<div id="content">
<div id="primary">
<!-- section primary -->
<!-- endsection primary-->
</div>
<div id="secondary">
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
</div>
</div>
</body>
</html>
#>>> copy configuration archive/followme.cfg 0
run_before = App::Followme::CreateNews
news_index_file = index.html
news_file = ../blog.html
#>>> copy text archive/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<title>Archive</title>
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>Test</h2>
<p>This is the top page</p>

<!-- endsection primary -->
      <!-- section secondary -->
<h2>First</h2>
<h2>First</h2>
<p>first blog post.</p>


<p><a href="2013/12december/first.html">Written on Feb 13, 2016 7:41</a></p>
<h2>Second</h2>
<h2>Second</h2>
<p>second blog post.</p>


<p><a href="2013/12december/second.html">Written on Feb 13, 2016 7:41</a></p>
<h2>Third</h2>
<h2>Third</h2>
<p>third blog post.</p>


<p><a href="2013/12december/third.html">Written on Feb 13, 2016 7:41</a></p>
<!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text archive/2013/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<<title>2013</title>
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>Test</h2>
<p>This is the top page</p>

<!-- endsection primary -->
      <!-- section secondary -->
<h2>2013</h2>

<ul>
<li><a href="2013/12december/index.html">December</a></li>
</ul>
<!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text archive/2013/12december/first.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<title>First</title>
<meta name="date" content="2016-02-13T07:41:02" />
<meta name="description" content="first blog post." />
<meta name="keywords" content="archive, 2013, 12december" />
<meta name="author" content="" />
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>First</h2>
<p>first blog post.</p>

<!-- endsection primary -->
      <!-- section secondary -->
<!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text archive/2013/12december/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<<title>December</title>
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>Test</h2>
<p>This is the top page</p>

<!-- endsection primary -->
      <!-- section secondary -->
<h2>December</h2>

<ul>
<li><a href="2013/12december/first.html">First</a></li>
<li><a href="2013/12december/second.html">Second</a></li>
<li><a href="2013/12december/third.html">Third</a></li>
</ul>
<!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text archive/2013/12december/second.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<title>Second</title>
<meta name="date" content="2016-02-13T07:41:03" />
<meta name="description" content="second blog post." />
<meta name="keywords" content="archive, 2013, 12december" />
<meta name="author" content="" />
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>Second</h2>
<p>second blog post.</p>

<!-- endsection primary -->
      <!-- section secondary -->
<!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text archive/2013/12december/third.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<title>Third</title>
<meta name="date" content="2016-02-13T07:41:04" />
<meta name="description" content="third blog post." />
<meta name="keywords" content="archive, 2013, 12december" />
<meta name="author" content="" />
<!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
<h2>Third</h2>
<p>third blog post.</p>

<!-- endsection primary -->
      <!-- section secondary -->
<h2>December</h2>

<ul>
<li><a href="2013/12december/first.html">First</a></li>
<li><a href="2013/12december/second.html">Second</a></li>
</ul>
<!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text skin/aim.css
/* Skin "Aim" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#7E8695;
  background:#000;
}

a { color:#7E8695; }
a:hover { color:#fff; }
a:visited { color:#8e86a8; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

input,
textarea,
select {
  background:#c6c7cc;
}


.container {
  max-width:1300px;
  margin:0 auto;
  position:relative;  
}

.header {
  margin:0;
  padding:2em 2% 0 2%;
  position:fixed;
  z-index:10;
  height:107px;
  width:96%;
  background:#000;
  max-width:1240px;
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  color:#fff;
  border-bottom:7px solid #1A1C21;
  width:19%;
  height:100px;
}

.menu_main {
  width:80%;
  height:100px;
  float:right;
  border-bottom:7px solid #1A1C21;
}
.menu_main a,
.menu_main a:visited {
  display:inline-block;
  width:100%;
  border-bottom:1px solid #32353C;
  color:#7E8695;
  text-decoration:none;
}
.menu_main a:hover,
.menu_main a:hover:visited {
  border-bottom:1px solid #fff;
  color:#fff;
}
.menu_main li {
  display:inline-block;
  width:30%;
  float:left;
  margin:0 2% 0 0;
}
.menu_main li.active a {
  border-bottom:1px solid #fff;
  color:#fff;
  cursor:default;
}


.info {
  padding:150px 0 1em 2%;
}

.hero {}
.hero h1 {
  font-size:26px;
  color:#fff;
}

.article {}

.footer {
  padding:2em 2% 3em 2%;
}

.copyright {
  border-top:7px solid #1A1C21;
  width:19%;
  float:left;
  padding:1em 0 0 0;
}

.menu_bottom {
  border-top:7px solid #1A1C21;
  width:80%;
  float:right;
  margin:0;
  padding:1em 0 0 0;;
}
.menu_bottom a,
.menu_bottom a:visited {
  display:inline-block;
  width:100%;
  border-bottom:1px solid #32353C;
  color:#7E8695;
  text-decoration:none;
}
.menu_bottom a:hover,
.menu_bottom a:hover:visited {
  border-bottom:1px solid #fff;
  color:#fff;
}
.menu_bottom li {
  display:inline-block;
  width:30%;
  float:left;
  margin:0 2% 0 0;
}
.menu_bottom li.active a {
  border-bottom:1px solid #fff;
  color:#fff;
  cursor:default;
}

h1, h2 {
  font-weight:normal;
  color:#fff;
}
h1 {
  font-size:22px;
}
h3, h4, h5, h6 {
  font-weight:bold;
  color:#fff;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #32353C;
  text-align:center; 
  text-decoration:none;
  color:#7E8695;
  padding:12px 20px;
  font-family:verdana, sans-serif;
  display:inline-block;
  background:none;
}
a.button:hover,
.button:hover {
  color:#fff;  
  border-bottom:1px solid #fff;
}
a.button:active,
.button:active {
  color:#555;
  -webkit-box-shadow:#fff 0px -1px 1px inset;
  -moz-box-shadow:#fff 0px -1px 1px inset;
  box-shadow:#fff 0px -1px 1px inset;
  border-bottom:1px solid #32353C;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #7E8695;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:4px 10px;
  background:#ec1165;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}
.success {
  color:#064d27;
  background:#11ec78;
  padding:4px 10px;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}
.message {
  color:#fff;
  background:#3c3d3e;
  padding:4px 10px;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
  .logo,
  .menu_main {
    border:none;
  }
  
  .header {
    border-bottom:7px solid #1A1C21;
    position:static;
  }
  
  .info {
    padding-top:1em;
  }
}

@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .logo {
    height:auto;
    width:100%;
  }
  
  .header {
    height:auto;
  }
  
  .menu_bottom {
    border-top:none;
  }
}
#>>> copy text skin/blackberry.css
/* Skin "Blackberry" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#333;
  background:#676D8F;
}

a { color:#004dd9; }
a:hover { color:#ea0000; }
a:visited { color:#551a8b; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  padding:2em 2% 2em;
  background:#70779C;
  color:#fff;
  margin:0 1% 1em;  
  -webkit-border-radius:0 0 30% 30% / 0 0 12px 12px;
  -moz-border-radius:0 0 30% 30% / 0 0 12px 12px;
  border-radius:0 0 30% 30% / 0 0 12px 12px;
  -webkit-box-shadow: rgba(0,0,0,0.1) 0px 3px 3px;
  -moz-box-shadow: rgba(0,0,0,0.1) 0px 3px 3px;
  box-shadow: rgba(0,0,0,0.1) 0px 3px 3px;  
  background: -moz-radial-gradient(center top, farthest-corner, #97A1D2 10%, #70779C 67%);
  background: -webkit-gradient(radial, center center, 0px, center center, 100%, color-stop(10%,#97A1D2), color-stop(67%,#70779C));
  background: -webkit-radial-gradient(center top, farthest-corner, #97A1D2 10%, #70779C 67%);
  background: -o-radial-gradient(center top, farthest-corner, #97A1D2 10%, #70779C 67%);
  background: -ms-radial-gradient(center top, farthest-corner, #97A1D2 10%, #70779C 67%);
  background: radial-gradient(center top, farthest-corner, #97A1D2 10%, #70779C 67%); 
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  color:#FFD400;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main a,
.menu_main a:visited {
  color:#fff;
}
.menu_main a:hover,
.menu_main a:visited:hover {
  color:#FFD400;
}


.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  text-decoration:none;
  cursor:default;
}

.hero {
  background:#70779C;
  color:#fff;
  padding:0.5em 0 1em 2%;
  margin:0 1% 1em;
  position:relative;
}
.hero:before {
  content:"";
  display:block!important;
  position:absolute;
  left:0;
  top:10%;
  height:80%;
  width:100%;
  z-index:-1;
  -webkit-border-radius:12px/90px;
  -moz-border-radius:12px/90px;
  border-radius:12px/90px;
  -webkit-box-shadow: rgba(0,0,0,0.5) 0px 0px 8px;
  -moz-box-shadow: rgba(0,0,0,0.5) 0px 0px 8px;
  box-shadow: rgba(0,0,0,0.5) 0px 0px 8px;
}

.hero a,
.hero a:visited {
  color:#fff;
}


.article {
  padding:0 0 2em 2%;
  margin:0 1% 0;
  background:#fff;
  -webkit-box-shadow: rgba(0,0,0,0.4) 0px 0px 4px;
  -moz-box-shadow: rgba(0,0,0,0.4) 0px 0px 4px;
  box-shadow: rgba(0,0,0,0.4) 0px 0px 4px;
}

.footer {
  padding:2em 2% 3em 2%;
  color:#fff;
}

.copyright {
  width:49%;
  float:left;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  text-decoration:none;
  cursor:default;
}

.menu_bottom a,
.menu_bottom a:visited {
  color:#fff;
}
.menu_bottom a:hover,
.menu_bottom a:visited:hover {
  color:#FFD400;
}


.hero h1 {
  font-size:26px;
  color:#fff;
}

h1, h2 {
  font-weight:normal;
  color:#000;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#000;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

.hero a.button,
a.button,
.button {
  border: 1px solid #EDB200;
  text-align:center; 
  text-decoration:none;
  text-shadow:1px 1px 0 #F9E67B;
  background:#FFD400;  
  background: -moz-radial-gradient(center top, farthest-corner, #F9E67B 10%, #FFD400 67%);
  background: -webkit-gradient(radial, center center, 0px, center center, 100%, color-stop(10%,#F9E67B), color-stop(67%,#ffd400));
  background: -webkit-radial-gradient(center top, farthest-corner, #F9E67B 10%, #FFD400 67%);
  background: -o-radial-gradient(center top, farthest-corner, #F9E67B 10%, #FFD400 67%);
  background: -ms-radial-gradient(center top, farthest-corner, #F9E67B 10%, #FFD400 67%);
  background: radial-gradient(center top, farthest-corner, #F9E67B 10%, #FFD400 67%);  
  color:#3F4256;
  padding:10px 20px;
  font-family:verdana, sans-serif;
  display:inline-block;
  -webkit-border-radius: 3px;
  -moz-border-radius: 3px;
  border-radius: 3px;
  -webkit-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  -moz-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
}

a.button:hover,
.button:hover {
  -webkit-box-shadow: rgba(0,0,0,0.5) 0px 1px 4px;
  -moz-box-shadow: rgba(0,0,0,0.5) 0px 1px 4px;
  box-shadow: rgba(0,0,0,0.5) 0px 1px 4px;
  background:#ffc000;
  background: -moz-radial-gradient(center top, farthest-corner, #F9E67B 10%, #ffc000 67%);
  background: -webkit-gradient(radial, center center, 0px, center center, 100%, color-stop(10%,#F9E67B), color-stop(67%,#ffc000));
  background: -webkit-radial-gradient(center top, farthest-corner, #F9E67B 10%, #ffc000 67%);
  background: -o-radial-gradient(center top, farthest-corner, #F9E67B 10%, #ffc000 67%);
  background: -ms-radial-gradient(center top, farthest-corner, #F9E67B 10%, #ffc000 67%);
  background: radial-gradient(center top, farthest-corner, #F9E67B 10%, #ffc000 67%);  
}
a.button:active,
.button:active {
  background:#ffc000;  
  color:#584B00;
  text-shadow:1px 1px 1px #fff;
  -webkit-box-shadow: rgba(0,0,0,0.7) 0px 1px 4px inset;
  -moz-box-shadow: rgba(0,0,0,0.7) 0px 1px 4px inset;
  box-shadow: rgba(0,0,0,0.7) 0px 1px 4px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:16px;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:8px 14px;
  background:#FF3E31;
  -webkit-border-radius:3px;
  -moz-border-radius:3px;
  border-radius:3px;
  -webkit-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  -moz-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
}
.success {
  color:#fff;
  background:#4ABF3B;
  padding:8px 14px;
  -webkit-border-radius:3px;
  -moz-border-radius:3px;
  border-radius:3px;
  -webkit-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  -moz-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
}
.message {
  color:#3F4256;
  background:#F9E678;
  padding:8px 14px;
  -webkit-border-radius:3px;
  -moz-border-radius:3px;
  border-radius:3px;
  -webkit-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  -moz-box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
  box-shadow: rgba(0,0,0,0.3) 0px 1px 2px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .header {
    margin: 0 0 0.4em;
    padding: 0.4em 0 0.4em;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/blue.css
/* Skin "Big Color Idea: Blue" by Egor Kubasov. http://egorkubasov.ru */
/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End webfonts */
body {
  font-family:'Ubuntu', Tahoma, sans-serif;
  color:#000000;
  background:#eeeeee;
}

a { color:#00b4ff; }
a:hover { color:#999999; }
a:visited { color:#00b4ff; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Ubuntu', Tahoma, sans-serif;
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #00b4ff;
  font-size:36px;
  color:#00b4ff;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
  text-align:center;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#00b4ff;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #00b4ff;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#00b4ff;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Ubuntu', Tahoma, sans-serif;
  font-style:bold;
  color:#00b4ff;
}

h1, h2 {
  font-weight:normal;
  color:#00b4ff;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#00b4ff;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:3px solid #00b4ff;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#8fd7f5;
  color:#fff;
  padding:5px 20px;
  font-family:'Ubuntu';
  font-weight: 700;
  font-size: 15px;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#77d1f7;
}
a.button:active,
.button:active {
  color:#fff;
  background: #30c0fc;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#8fd7f5;
  border:1px solid #00b4ff;
  color:#666;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #00b4ff;
}
.table tr:last-child {
  border-bottom:1px solid #00b4ff;
}

.warning {
  border:3px solid #ff0000;
  color:#000;
  padding:8px 14px;
  background:transperent;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.success {
  border:3px solid #399f16;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.message {
  border:3px solid #fff600;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/dark-blue.css
/* Skin "Big Color Idea: Dark-blue" by Egor Kubasov. http://egorkubasov.ru */
/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End webfonts */

body {
  font-family:'Ubuntu', Tahoma, sans-serif;
  color:#000000;
  background:#eeeeee;
}

a { color:#1200ff; }
a:hover { color:#999999; }
a:visited { color:#1200ff; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Ubuntu', Tahoma, sans-serif;
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #1200ff;
  font-size:36px;
  color:#1200ff;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
  text-align:center;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#1200ff;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #1200ff;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#1200ff;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Ubuntu', Tahoma, sans-serif;
  font-style:bold;
  color:#1200ff;
}

h1, h2 {
  font-weight:normal;
  color:#1200ff;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#1200ff;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:3px solid #1200ff;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#968ff5;
  color:#fff;
  padding:5px 20px;
  font-family:'Ubuntu';
  font-weight: 700;
  font-size: 15px;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#6a5ff8;
}
a.button:active,
.button:active {
  color:#fff;
  background: #3e30fc;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#968ff5;
  border:1px solid #1200ff;
  color:#666;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #1200ff;
}
.table tr:last-child {
  border-bottom:1px solid #1200ff;
}

.warning {
  border:3px solid #ff0000;
  color:#000;
  padding:8px 14px;
  background:transperent;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.success {
  border:3px solid #399f16;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.message {
  border:3px solid #fff600;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}

@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/default.css
/* Skin "Simple" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#333;
}

a { color:#004dd9; }
a:hover { color:#ea0000; }
a:visited { color:#551a8b; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
}

.logo {
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #000;
  font-size:18px;
  color:#ea0000;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}
.menu_main a,
.menu_main a:visited {
}
.menu_main a:hover,
.menu_main a:hover:visited {
}
.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_main li.active,
.menu_main li.active a {
  color:#000;
  text-decoration:none;
  cursor:default;
}


.info {
  padding:0 0 1em 2%;
}

.hero {}
.hero h1 {
  font-size:26px;
  font-family:georgia, serif;
  font-style:italic;
  color:#EA0000;
}

.article {}

.footer {
  border-top:1px solid #666;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom a,
.menu_bottom a:visited {
}
.menu_bottom a:hover,
.menu_bottom a:hover:visited {
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#666;
  text-decoration:none;
  cursor:default;
}

h1, h2 {
  font-weight:normal;
  color:#000;
}
h1 {
  font-size:22px;
}
h3, h4, h5, h6 {
  font-weight:bold;
  color:#000;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #d00303;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#ea0000;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ea0000), to(#d00303));
  background:-webkit-linear-gradient(#ea0000, #d00303);
  background:-moz-linear-gradient(#ea0000, #d00303);
  background:-ms-linear-gradient(#ea0000, #d00303);
  background:-o-linear-gradient(#ea0000, #d00303);
  background:linear-gradient(#ea0000, #d00303);
  color:#fff;
  padding:12px 20px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 1px #d03302;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#d00303), to(#ea0000));
  background:-webkit-linear-gradient(#d00303, #ea0000);
  background:-moz-linear-gradient(#d00303, #ea0000);
  background:-ms-linear-gradient(#d00303, #ea0000);
  background:-o-linear-gradient(#d00303, #ea0000);
  background:linear-gradient(#d00303, #ea0000);
}
a.button:active,
.button:active {
  color:#8c1515;
  text-shadow:1px 1px 1px #ffaeae;
  -webkit-box-shadow:#a10000 0px -3px 3px inset;
  -moz-box-shadow:#a10000 0px -3px 3px inset;
  box-shadow:#a10000 0px -3px 3px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#ffffff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ffffff), to(#F7F7F7));
  background:-webkit-linear-gradient(#ffffff, #F7F7F7);
  background:-moz-linear-gradient(#ffffff, #F7F7F7);
  background:-ms-linear-gradient(#ffffff, #F7F7F7);
  background:-o-linear-gradient(#ffffff, #F7F7F7);
  background:linear-gradient(#ffffff, #F7F7F7);
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#fff;
  padding:8px 14px;
  background:#EA0000;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #399f16;
  color:#fff;
  background:#399f16;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #f1edcf;
  color:#000;
  background:#fbf8e3;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/fresh.css
/* Skin "Fresh" by Renat Rafikov */
html {
  overflow-x:hidden;
}
body {
  font-family:tahoma, arial, sans-serif;
  color:#111;
}

a { color:#58a22c; }
a:hover { color:#333; }
a:visited { color:#7bbe53; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:0;
  padding:0 2% 0 2%;
  border-top:5px solid #58a22c;
  background:#fbfaf8;
  position:relative;
  z-index:2;
}
.header:before {
  content:"";
  display:block!important;
  height:100%;
  width:7000px;
  position:absolute;
  left:-2000px;
  top:-5px;
  border-top:5px solid #58a22c;
  background:#fbfaf8;
  z-index:-1;
}

.logo {
  float:left;
  display:inline-block;
  padding:1.3em 0 0;
  font-size:24px;
  color:#333;
}

.menu_main {
  width:60%;
  float:right;
  text-align:right;
  font-size:20px;
  margin:0;
}

.menu_main li {
  display:inline-block;
}

.menu_main li a {
  display:inline-block;
  height:85px;
  line-height:85px;
  padding:0 11px;
  color:#58a22c;
  text-transform:uppercase;
}
.menu_main li a:hover {
  color:#333;
}
.menu_main li a:visited {
  color:#7bbe53;
}

.menu_main li.active {
  background:#fff;
  position: relative;
  bottom:-12px;
  -webkit-box-shadow: rgba(0, 0, 0, 0.14) 0px 0px 3px;
  -moz-box-shadow: rgba(0, 0, 0, 0.14) 0px 0px 3px;
  box-shadow: rgba(0, 0, 0, 0.14) 0px 0px 3px;
}

.menu_main li.active a {
  color:#58a22c;
  text-decoration:none;
  cursor:default;
  position: relative;
  top: -4px;
}

.menu_main li.active:after {
  content:"";
  position:absolute;
  z-index:-1;
  bottom:15px;
  left:10px;
  width:50%;
  height:20%;
  -webkit-box-shadow:0 15px 10px rgba(0, 0, 0, 0.25);
  -moz-box-shadow:0 15px 10px rgba(0, 0, 0, 0.25);
  box-shadow:0 15px 10px rgba(0, 0, 0, 0.25);
  -webkit-transform:rotate(-4deg);
  -moz-transform:rotate(-4deg);
  -o-transform:rotate(-4deg);
  transform:rotate(-4deg);
}

.hero {
  border-top:4px solid #d5f0c6;
  padding:20px 0 20px 2%;
  background:#e0ffed;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#e2f7d6), to(#E0FFED));
  background: -webkit-linear-gradient(#e2f7d6, #E0FFED);
  background: -moz-linear-gradient(#e2f7d6, #E0FFED);
  background: -ms-linear-gradient(#e2f7d6, #E0FFED);
  background: -o-linear-gradient(#e2f7d6, #E0FFED);
  background: linear-gradient(#e2f7d6, #E0FFED);
  position:relative;
  z-index:1;
}
.hero:before {
  content:"";
  display:block!important;
  height:100%;
  width:7000px;
  position:absolute;
  left:-2000px;
  top:-4px;
  border-top:4px solid #d5f0c6;
  background:#e0ffed;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#e2f7d6), to(#E0FFED));
  background: -webkit-linear-gradient(#e2f7d6, #E0FFED);
  background: -moz-linear-gradient(#e2f7d6, #E0FFED);
  background: -ms-linear-gradient(#e2f7d6, #E0FFED);
  background: -o-linear-gradient(#e2f7d6, #E0FFED);
  background: linear-gradient(#e2f7d6, #E0FFED);
  z-index:-1;
}

.info {
  margin:0 0 20px 0;
}

.article {
  padding:0 0 0 2%;
}

.footer {
  border-top:2px solid #d5f0c6;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:39%;
  float:left;
}

.menu_bottom {
  width:60%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
  text-transform:uppercase;
}
.menu_bottom li a {
  color:#58a22c;
  display:inline-block;
  padding:3px 6px;
}
.menu_bottom li a:hover {
  color:#333;
}
.menu_bottom li.active a {
  text-decoration:none;
  cursor:default;
  background:#fff;
  -webkit-box-shadow: rgba(0, 0, 0, 0.14) 0px 0px 3px;
  -moz-box-shadow: rgba(0, 0, 0, 0.14) 0px 0px 3px;
  box-shadow: rgba(0, 0, 0, 0.14) 0px 0px 3px;
}
.menu_bottom li.active a:hover {
  color:#58a22c;
}


.hero h1 {
  font-size:32px;
  color:#333;
}

h1, h2 {
  font-weight:normal;
  color:#58a22c;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#58a22c;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  text-align:center; 
  text-decoration:none;
  border:0;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
  -webkit-box-shadow:#a2dcb7 0px 5px 5px;
  -moz-box-shadow:#a2dcb7 0px 5px 5px;
  box-shadow:#a2dcb7 0px 5px 5px;
  background:#fff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#fff), to(#e0feeb));
  background:-webkit-linear-gradient(#fff, #e0feeb);
  background:-moz-linear-gradient(#fff, #e0feeb);
  background:-ms-linear-gradient(#fff, #e0feeb);
  background:-o-linear-gradient(#fff, #e0feeb);
  background:linear-gradient(#fff, #e0feeb);
  color:#58a22c;
  padding:6px 10px;
  font-family:verdana, sans-serif;
  display:inline-block;
  margin:5px 0 0 0;
  position:relative;
}
a.button:before {
  content:"";
  display:block!important;
  position:absolute;
  z-index:-1;
  padding:7px 6px;
  width:100%;
  left:-7px;
  height:100%;
  top:-7px;
  background:#e0feeb;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#CAF0D8), to(#e0feeb));
  background: -webkit-linear-gradient(#CAF0D8, #e0feeb);
  background: -moz-linear-gradient(#CAF0D8, #e0feeb);
  background: -ms-linear-gradient(#CAF0D8, #e0feeb);
  background: -o-linear-gradient(#CAF0D8, #e0feeb);
  background: linear-gradient(#CAF0D8, #e0feeb);
  -webkit-border-radius:9px;
  -moz-border-radius:9px;
  border-radius:9px;
  border:1px solid #99d8b1;
}

a.button:hover,
.button:hover {
  -webkit-box-shadow:#a2dcb7 0px 3px 3px;
  -moz-box-shadow:#a2dcb7 0px 3px 3px;
  box-shadow:#a2dcb7 0px 3px 3px;
  background:#fff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#e0feeb), to(#fff));
  background:-webkit-linear-gradient(#e0feeb, #fff);
  background:-moz-linear-gradient(#e0feeb, #fff);
  background:-ms-linear-gradient(#e0feeb, #fff);
  background:-o-linear-gradient(#e0feeb, #fff);
  background:linear-gradient(#e0feeb, #fff);
}
a.button:active,
.button:active {
  color:#58a22c;
  -webkit-box-shadow:#a2dcb7 0px 2px 3px inset;
  -moz-box-shadow:#a2dcb7 0px 2px 3px inset;
  box-shadow:#a2dcb7 0px 2px 3px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:16px;
  background:#ffffff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ffffff), to(#eafae1));
  background:-webkit-linear-gradient(#ffffff, #eafae1);
  background:-moz-linear-gradient(#ffffff, #eafae1);
  background:-ms-linear-gradient(#ffffff, #eafae1);
  background:-o-linear-gradient(#ffffff, #eafae1);
  background:linear-gradient(#ffffff, #eafae1);
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:2px solid #d5f0c6;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #c07306;
  color:#fff;
  padding:4px 14px;
  background:#e0901e;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #307904;
  color:#fff;
  background:#58a22c;
  padding:4px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #def7a0;
  color:#75932b;
  background:#f6ffe0;
  padding:4px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .menu_main li a {
    height:auto;
    line-height:auto;
    line-height:inherit;
    display:inline-block;
    padding:7px;
  }
  .menu_main li.active  {
    bottom:0;  
  }
  
   .menu_main li.active a {
    position:static;
  }
  
  .header:before,
  .hero:before {
    display:none!important;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
  .menu_main {
    font-size:15px;
  }  
  .menu_main li a {
    padding:0 6px;
  }

  .header:before,
  .hero:before {
    display:none!important;
  }
}
#>>> copy text skin/fruitjuice.css
/* Skin "Fruit juice" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#111;
}

a { color:#ff7d01; }
a:hover { text-decoration:none; }
a:visited { color:#ea206c; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:0 0 2em 0;
  padding:0 2% 0 2%;
}

.logo {
  float:left;
  display:inline-block;
  font-size:27px;
  color:#ff7d01;
  font-family:tahoma, sans-serif;
  text-transform:uppercase;
  padding:16px 0 0 0;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 2px;
}

.menu_main li a {
  display:inline-block;
  padding:30px 8px 10px 8px;
  background:#ffebc0;
  font-family:georgia, serif;
  color:#ff7d01;
  -webkit-border-radius:0 0 4px 4px;
  -moz-border-radius:0 0 4px 4px;
  border-radius:0 0 4px 4px;
}

.menu_main li a:hover {
  background:#fff4dd;
}

.menu_main li.active,
.menu_main li.active a {
  text-decoration:none;
  cursor:default;
  background:none;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  padding:2em 2% 3em 2%;
  color:#ff7d01;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
  font-size:14px;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom a,
.menu_bottom a:visited {
  font-family:georgia, serif;
  font-style:italic;
  color:#ff7d01;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:19px;
  font-family:georgia, serif;
  font-style:italic;
  background:#ffebc0;
  display:inline-block;
}
.hero p {
  font-family:georgia, serif;
  font-style:italic;
  line-height: 1.4;
}

h1 {
  font-size:21px;
}

h1, h2 {
  font-size:19px;
  font-weight:normal;
  font-family:georgia, serif;
  font-style:italic;
}

.col_33 h2 {
  background:#ffebc0;
  display:inline-block;
}

h3, h4, h5, h6 {
  font-weight:bold;
  font-family:georgia, serif;
  font-style:italic;
}


.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:0;
  text-align:center; 
  text-decoration:none;
  background:#8aac00;
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  color:#fff;
  padding:9px 17px;
  font-family:verdana, sans-serif;
  display:inline-block;
  font-style:normal;
}
a.button:hover,
.button:hover {
  color:#fff;
  background:#ff7d01;
}
a.button:active,
.button:active {
  color:#b25700;
  text-shadow:1px 1px 1px #ffcc9c;
  -webkit-box-shadow:#da6a00 0px 2px 0 inset;
  -moz-box-shadow:#da6a00 0px 2px 0 inset;
  box-shadow:#da6a00 0px 2px 0 inset;
  background:#ff7d01;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:16px;
  background:#ffebc0;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ff7d01;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:8px 14px;
  background:#ff3701;
}
.success {
  color:#fff;
  background:#8aac00;
  padding:8px 14px;
}
.message {
  background:#ffebc0;
  padding:8px 14px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .menu_main li a {
    display:inline-block;
    padding:7px;
    -webkit-border-radius: 4px;
    -moz-border-radius: 4px;
    border-radius: 4px;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/glimpse.css
/* Skin "Glimpse" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#898989;
  background:#eeeeee;
}

a { color:#1b737d; }
a:hover { color:#278691; text-decoration:none;}
a:visited { color:#1b327d; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 0 0;
  padding:2em 2% 3em 2%;
  background:#fff;
  border-left:1px solid #dedede;
  border-right:1px solid #dedede;
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  color:#c7c5c6;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
  font-weight:bold;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main a,
.menu_main a:visited {
  color:#1b737d;
}

.menu_main li.active,
.menu_main li.active a {
  color:#898989;
  text-decoration:none;
  cursor:default;
}
.hero {
  background:#fff;
  border-left:1px solid #dedede;
  border-right:1px solid #dedede;
  border-bottom:1px solid #dedede;
  padding:0 0 1em 2%;
}

.article {
  padding:0 0 2em 2%;
}

.footer {
  padding:2em 2% 3em 2%;
  background:#fff;
  border-left:1px solid #dedede;
  border-right:1px solid #dedede;
  border-top:1px solid #dedede;
}

.copyright {
  width:49%;
  float:left;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  font-weight:bold;
}
.menu_bottom a,
.menu_bottom a:visited {
  color:#1b737d;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#666;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:20px;
  font-style:italic;
  display:inline-block;
  clear:both;
  background:#eee;
  margin-bottom: 0;
}

h1, h2 {
  font-weight:normal;
}

h3, h4, h5, h6 {
  font-weight:bold;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:6px solid #898989;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  background:#bfbfbf;
  color:#fff;
  padding:6px 15px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 0px #898989;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#898989;
  text-shadow:none;
  background:-webkit-gradient(linear, 0 0, center center, from(#c9c9c9), to(#bfbfbf));
  background:-webkit-linear-gradient(#c9c9c9 50%, #bfbfbf 50%);
  background:-moz-linear-gradient(#c9c9c9 50%, #bfbfbf 50%);
  background:-ms-linear-gradient(#c9c9c9 50%, #bfbfbf 50%);
  background:-o-linear-gradient(#c9c9c9 50%, #bfbfbf 50%);
  background:linear-gradient(#c9c9c9 50%, #bfbfbf 50%);
}
a.button:active,
.button:active {
  color:#8c1515;
  text-shadow:none;
  background:#898989;
  color:#dedede;
  text-shadow:none;
  -webkit-box-shadow:#454545 0px 0px 7px inset;
  -moz-box-shadow:#454545 0px 0px 7px inset;
  box-shadow:#454545 0px 0px 7px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:9px 14px;
  background:#dca623;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
}
.success {
  color:#fff;
  background:#578647;
  padding:9px 14px;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
}
.message {
  background:#fff;
  padding:9px 14px;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .header {
    padding-bottom:0;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/green.css
/* Skin "Modern Dark: Green" by Egor Kubasov. http://egorkubasov.ru */

/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End Webfonts */

body {
  font-family:'Ubuntu';
  color:#d5d5d5;
  background:#131313;
}

a { color:#42ff00; }
a:hover { color:#d5d5d5; }
a:visited { color:#42ff00; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:900px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Lobster';
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #42ff00;
  font-size:18px;
  color:#42ff00;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#42ff00;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #42ff00;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#42ff00;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Lobster';
  font-style:normal;
  color:#42ff00;
}

h1, h2 {
  font-weight:normal;
  color:#42ff00;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#42ff00;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #42ff00;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#32a30a;
  color:#fff;
  padding:12px 20px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#3ad105;
}
a.button:active,
.button:active {
  color:#181818;
  background: #2a7610;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#2b2b2b;
  border:1px solid #ddd;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#fff;
  padding:8px 14px;
  background:#291111;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #399f16;
  color:#fff;
  background:#172113;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #f1edcf;
  color:#878473;
  background:#2b2a28;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles*/
}
#>>> copy text skin/humble.css
/* Skin "Humble" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#000;
  background:#58595b;
}

a { color:#000; }
a:hover { color:#444; }
a:visited { color:#666; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:13px 0 11px 0;
  padding:1em 2% 0 2%;
  border-top:1px solid #fff;
}

.logo {
  float:left;
  display:inline-block;
  font-size:24px;
  color:#fff;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
  font-size:15px;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li a {
  color:#fff;
}
.menu_main li a:hover {
  color:#dad9d9;
}
.menu_main li a:visited {
  color:#b3b3b3;
}

.menu_main li.active,
.menu_main li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
  position:relative;
}

.menu_main li.active:before {
  content:"";
  display:block;
  width: 0;
  height: 0;
  border-left: 5px solid transparent;
  border-right: 5px solid transparent;
  border-bottom: 5px solid #fff;
  position:absolute;
  left:50%;
  bottom:-12px;
  margin:0 0 0 -2px;
}


.hero {
  border:2px solid #fff;
  margin:0 1% 24px 1%;
  padding:10px 0 0 1%;
  color:#fff;
}
.hero a {
  color:#fff;
}
.hero a:hover {
  color:#eee;
}

.article {
  background:#fff;
  padding:7px 0 3em 2%;
}

.footer {
  padding:12px 2% 2em 2%;
  color:#aaaaaa;
}

.copyright {
  width:49%;
  float:left;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_bottom li a {
  color:#fff;
}
.menu_bottom li a:hover {
  color:#dad9d9;
}
.menu_bottom li a:visited {
  color:#b3b3b3;
}

.menu_bottom li.active,
.menu_bottom li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
  position:relative;
}

.menu_bottom li.active:before {
  content:"";
  display:block;
  width: 0;
  height: 0;
  border-left: 5px solid transparent;
  border-right: 5px solid transparent;
  border-top: 5px solid #fff;
  position:absolute;
  left:50%;
  top:-12px;
  margin:0 0 0 -2px;
}

.hero h1 {
  font-size:22px;
  color:#fff;
}

.hero h1, .hero h2, .hero h3, .hero h4 {
  color:#fff;
}

h1, h2 {
  font-weight:normal;
  color:#010101;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#010101;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #000;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#fff;
  color:#000;
  padding:7px 12px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  border:2px solid #000;
  padding:6px 11px;
  color:#616161;  
}
a.button:active,
.button:active {
  color:#000;
  border:1px solid #000;
  padding:7px 12px;
  -webkit-box-shadow:#888 0px 3px 2px inset;
  -moz-box-shadow:#888 0px 3px 2px inset;
  box-shadow:#888 0px 3px 2px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:15px;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #000;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #8e011e;
  color:#fff;
  padding:8px 14px;
  background:#c21c3f;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
}
.success {
  border:1px solid #1c8b31;
  color:#fff;
  background:#1c8b31;
  padding:8px 14px;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
}
.message {
  border:1px solid #ac9701;
  color:#fff;
  background:#e2cf48;
  padding:8px 14px;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .header {
    margin-top:3px;
  }
  .menu_main a {
    display:inline-block;
    padding:2px 7px 7px 7px!important;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/illusion.css
/* "Simpliste" template. Renat Rafikov. http://cssr.ru/simpliste/ */

/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Play:700&subset=latin,cyrillic);
/* End webfonts */

/* CSS reset. Based on HTML5 boilerplate reset http://html5boilerplate.com/  */
article, aside, details, figcaption, figure, footer, header, hgroup, nav, section { display:block; }
audio[controls], canvas, video { display:inline-block; *display:inline; *zoom:1; }
html { font-size:100%; overflow-y:scroll; -webkit-overflow-scrolling:touch; -webkit-tap-highlight-color:rgba(0,0,0,0); -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; }
body { margin:0; font-size:13px; line-height:1.231; }
body, button, input, select, textarea { font-family:sans-serif; color:#222; }
a { color:#00e; }
a:visited { color:#551a8b; }
a:focus { outline:thin dotted; }
a:hover, a:active { outline:0; }
abbr[title] { border-bottom:1px dotted; }
b, strong { font-weight:bold; }
blockquote { margin:1em 40px; }
dfn { font-style:italic; }
hr { display:block; height:1px; border:0; border-top:1px solid #ccc; margin:1em 0; padding:0; }
ins { background:#ff9; color:#000; text-decoration:none; }
mark { background:#ff0; color:#000; font-style:italic; font-weight:bold; }
pre, code, kbd, samp { font-family:monospace, monospace; _font-family:'courier new', monospace; font-size:1em; }
pre { white-space:pre; white-space:pre-wrap; word-wrap:break-word; }
q { quotes:none; }
q:before, q:after { content:""; content:none; }
small { font-size:85%; }
sub, sup { font-size:75%; line-height:0; position:relative; vertical-align:baseline; }
sup { top:-0.5em; }
sub { bottom:-0.25em; }
ul, ol { margin:1em 0; padding:0 0 0 2em; }
dd { margin:0 0 0 40px; }
nav ul, nav ol { list-style:none; margin:0; padding:0; }
img { border:0; -ms-interpolation-mode:bicubic; }
svg:not(:root) { overflow:hidden;}
figure { margin:0; }
form { margin:0; }
fieldset { border:0; margin:0; padding:0; }
legend { border:0; *margin-left:-7px; padding:0; }
label { cursor:pointer; }
button, input, select, textarea { font-size:100%; margin:0; vertical-align:baseline; *vertical-align:middle; }
button, input { line-height:normal; *overflow:visible; }
button, input[type="button"], input[type="reset"], input[type="submit"] { cursor:pointer; -webkit-appearance:button; }
input[type="checkbox"], input[type="radio"] { box-sizing:border-box; }
input[type="search"] { -moz-box-sizing:content-box; -webkit-box-sizing:content-box; box-sizing:content-box; }
button::-moz-focus-inner, input::-moz-focus-inner { border:0; padding:0; }
textarea { overflow:auto; vertical-align:top; }
input:valid, textarea:valid {  }
input:invalid, textarea:invalid { background-color:#f0dddd; }
table { border-collapse:collapse; border-spacing:0; }
.hidden { display:none; visibility:hidden; }
.clearfix:before, .clearfix:after { content:""; display:table; }
.clearfix:after { clear:both; }
.clearfix { zoom:1; }
/* End CSS reset */


/* Columns 
-------
.col_33 | .col_33 | .col_33
.clearfix
-------
.col_66 | .col_33
.clearfix
-------
.col_50 | .col_50
.clearfix
-------
.col_100
-------
*/
.col_33 {
  width:31%;
  margin:0 2% 0 0;
  float:left;
}

.col_50 {
  width:48%;
  margin:0 2% 0 0;
  float:left;
}

.col_66 {
  width:64%;
  margin:0 2% 0 0;
  float:left;
}

.col_100 {
  width:98%;
  margin:0 2% 0 0;
}
/* End columns */


/* Helper classes */
.center {text-align:center;}
.left {text-align:left;}
.right {text-align:right;}

.img_floatleft {float:left; margin:0 10px 5px 0;}
.img_floatright {float:right; margin:0 0 5px 10px;}

.img {max-width:100%;}
/* End helper classes */


/* [Skin "Illusion"] */
body{
  background-color: #16a8cd;
  background-image: -webkit-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -webkit-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -webkit-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -webkit-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -webkit-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4), -webkit-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4);
  background-image: -moz-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -moz-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -moz-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -moz-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -moz-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4), -moz-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4);
  background-image: -o-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -o-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -o-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -o-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -o-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4), -o-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4);
  background-image: -ms-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -ms-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -ms-linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -ms-linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), -ms-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4), -ms-linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4);
  background-image: linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), linear-gradient(60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), linear-gradient(-60deg, #1283ab 12%, transparent 12.5%, transparent 87%, #1283ab 87.5%, #1283ab), linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4), linear-gradient(30deg, #198ab4 25%, transparent 25.5%, transparent 75%, #198ab4 75%, #198ab4);
  background-position: 0 0pt, 0 0pt, 40px 70px, 40px 70px, 0 0pt, 40px 70px;
  background-size: 80px 140px;
  background-attachment:fixed;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:0 0 3em 0;
  padding:2em 2% 0 2%;
  height:300px;
}

.logo {
  font-size:15em;
  text-align:center;
  color:#fff;
  color:rgba(255,255,255,0.8);
  font-family:Play, verdana, sans-serif;
  position: fixed;
  width: 100%;
  z-index: -1;
  left:0;
  top:0;
}

.menu_main {
  float:right;
  text-align:right;
  position:fixed;
  z-index:1000;
  top:0;
  right:0;
  background:#fff;
  background:rgba(255,255,255,0.9);
  padding:10px;
  -webkit-border-radius:0 0 0 10px;
  -moz-border-radius:0 0 0 10px;
  border-radius:0 0 0 10px;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main a,
.menu_main a:visited {
  color:#111;
}
.menu_main a:hover,
.menu_main a:visited:hover {
  color:#f00;
}

.menu_main li.active,
.menu_main li.active a {
  color:#000;
  text-decoration:none;
  cursor:default;
}

.hero {
  padding:200px 0 200px 2%;
  background-attachment: fixed;
  background-clip: border-box, border-box, border-box, border-box;
  background-color: #111;
  background-image: -webkit-linear-gradient(45deg, #222 45px, transparent 45px), -webkit-linear-gradient(45deg, #222 45px, transparent 45px), -webkit-linear-gradient(225deg, transparent 46px, #111 46px, #111 91px, transparent 91px), -webkit-linear-gradient(-45deg, #222 23px, transparent 23px, transparent 68px, #222 68px, #222 113px, transparent 113px, transparent 158px, #222 158px);
  background-image: -moz-linear-gradient(45deg, #222 45px, transparent 45px), -moz-linear-gradient(45deg, #222 45px, transparent 45px), -moz-linear-gradient(225deg, transparent 46px, #111 46px, #111 91px, transparent 91px), -moz-linear-gradient(-45deg, #222 23px, transparent 23px, transparent 68px, #222 68px, #222 113px, transparent 113px, transparent 158px, #222 158px);
  background-image: -o-linear-gradient(45deg, #222 45px, transparent 45px), -o-linear-gradient(45deg, #222 45px, transparent 45px), -o-linear-gradient(225deg, transparent 46px, #111 46px, #111 91px, transparent 91px), -o-linear-gradient(-45deg, #222 23px, transparent 23px, transparent 68px, #222 68px, #222 113px, transparent 113px, transparent 158px, #222 158px);
  background-image: -ms-linear-gradient(45deg, #222 45px, transparent 45px), -ms-linear-gradient(45deg, #222 45px, transparent 45px), -ms-linear-gradient(225deg, transparent 46px, #111 46px, #111 91px, transparent 91px), -ms-linear-gradient(-45deg, #222 23px, transparent 23px, transparent 68px, #222 68px, #222 113px, transparent 113px, transparent 158px, #222 158px);
  background-image: linear-gradient(45deg, #222 45px, transparent 45px), linear-gradient(45deg, #222 45px, transparent 45px), linear-gradient(225deg, transparent 46px, #111 46px, #111 91px, transparent 91px), linear-gradient(-45deg, #222 23px, transparent 23px, transparent 68px, #222 68px, #222 113px, transparent 113px, transparent 158px, #222 158px);
  background-origin: padding-box, padding-box, padding-box, padding-box;
  background-position: 0 0%, 64px 64px, 0 0%, 0 0;
  background-repeat: repeat, repeat, repeat, repeat;
  background-size: 128px 128px;
  color:#fdfdfd;
}

.article {
  padding:3em 0 2em 2%;
  background-clip: border-box, border-box, border-box, border-box;
  background-color: #fff;
  background-image: -webkit-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -webkit-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -webkit-linear-gradient(#e2f0f4 8px, transparent 8px), -webkit-linear-gradient(0pt 50% , #e2f0f4 8px, transparent 8px);
  background-image: -moz-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -moz-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -moz-linear-gradient(#e2f0f4 8px, transparent 8px), -moz-linear-gradient(0pt 50% , #e2f0f4 8px, transparent 8px);
  background-image: -o-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -o-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -o-linear-gradient(#e2f0f4 8px, transparent 8px), -o-linear-gradient(0pt 50% , #e2f0f4 8px, transparent 8px);
  background-image: -ms-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -ms-radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), -ms-linear-gradient(#e2f0f4 8px, transparent 8px), -ms-linear-gradient(0pt 50% , #e2f0f4 8px, transparent 8px);
  background-image: radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), radial-gradient(circle , transparent 20%, #fff 20%, #fff 80%, transparent 80%, transparent), linear-gradient(#e2f0f4 8px, transparent 8px), linear-gradient(0pt 50% , #e2f0f4 8px, transparent 8px);
  background-origin: padding-box, padding-box, padding-box, padding-box;
  background-position: 0 0%, 50px 50px, 0 -4px, -4px 0;
  background-repeat: repeat, repeat, repeat, repeat;
  background-size: 100px 100px, 100px 100px, 50px 50px, 50px 50px;
  background-attachment:fixed;
}

.footer {
  padding:6em 2% 6em 2%;
  background-color: #f36d00;
  background-image: -webkit-repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.5) 35px, rgba(255, 255, 255, 0.5) 70px);
  background-image: -moz-repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.5) 35px, rgba(255, 255, 255, 0.5) 70px);
  background-image: -o-repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.5) 35px, rgba(255, 255, 255, 0.5) 70px);
  background-image: -ms-repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.5) 35px, rgba(255, 255, 255, 0.5) 70px);
  background-image: repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.5) 35px, rgba(255, 255, 255, 0.5) 70px);
  background-attachment: fixed;
}

.copyright {
  width:100%;
  text-align:center;
  font-family:Play, verdana, sans-serif;
  color:#f36d00;
  font-size:17em;
  text-shadow: 5px 5px 0 #f9b680;
  overflow:hidden;
  overflow:hidden;
}

.menu_bottom {
  display:none;
}

/* Skin appearance */
body {
  font-family:arial, sans-serif;
  color:#333;
}

a { color:#1283ab; }
a:hover { color:#f00; }
a:visited { color:#1283ab; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.hero h1 {
  font-size:30px;
  font-style:italic;
  color:#980000;
}

h1, h2 {
  font-weight:bold;
  color:#198AB4;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#198AB4;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:0;
  border-right:4px solid #2294bf;
  border-bottom:4px solid #137295;
  background:#198AB4;
  text-align:center; 
  text-decoration:none;
  color:#fff;
  padding:12px 18px 10px 20px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  border:0;
  border-left:4px solid #2294bf;
  border-top:4px solid #137295;
  color:#fff;   
  padding:8px 22px 14px 16px;
}
a.button:active,
.button:active {
  border:0;
  border-left:4px solid #137295;
  border-top:4px solid #2294bf;
  color:#baecff;
  padding:8px 22px 14px 16px;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border-bottom:5px solid #bf1f3d;
  border-right:5px solid #dd294b;
  color:#fff;
  padding:12px 14px;
  background:#cf2041;
}
.success {
  border-bottom:5px solid #119e53;
  border-right:5px solid #1bc86d;
  color:#fff;
  background:#12ab5a;
  padding:12px 14px;
}
.message {
  border-bottom:5px solid #b9c175;
  border-right:5px solid #dee78e;
  color:#34380e;
  background:#d4db95;
  padding:12px 14px;
}
/* [End skin] */


@media only screen and (max-width:480px) { /* Smartphone */
  .header {
    margin:5em 0 1em 0;
    height:auto;
  }

  .logo{
    display:block;
    float:none;
    text-align:center;
    font-size:2em;
    position:static;
  }
  
  .menu_main {
    width:100%;
    text-align:center;
    float:none;
    padding:0;
    -webkit-border-radius:0;
    -moz-border-radius:0;
    border-radius:0;
  }
  
  .menu_main a {
    display:inline-block;
    padding:7px;
  }
  
  .hero {
    padding:1em 2%;
  }
  
  .copyright {
    width:100%;
    float:none;
    font-size:2em;
  }

  .footer  {
    padding-bottom:0;
    height:10em;
  }
  
 
  .form textarea {
    width:100%;
  }  
  .form label {
    padding:10px 0 8px 0;
  }
}


@media only screen and (max-width:768px) { /* Tablet */
  .col_33,
  .col_66,
  .col_50  {
    width:98%;
    float:none;
  } 
  
  .form label {
    padding:10px 0 8px 0;
  }
  
  .copyright {
    font-size:2em;
  }
}


@media print { /* Printer */
  * { background:transparent !important; color:black !important; text-shadow:none !important; filter:none !important; -ms-filter:none !important; }
  a, a:visited { color:#444 !important; text-decoration:underline; }
  a[href]:after { content:" (" attr(href) ")"; }
  abbr[title]:after { content:" (" attr(title) ")"; }
  pre, blockquote { border:1px solid #999; page-break-inside:avoid; }
  thead { display:table-header-group; }
  tr, img { page-break-inside:avoid; }
  img { max-width:100% !important; }
  @page { margin:0.5cm; }
  p, h2, h3 { orphans:3; widows:3; }
  h2, h3{ page-break-after:avoid; }
  
  .header, .footer, .form {display:none;}
  .col_33, .col_66, .col_50  { width:98%; float:none; } 
}
#>>> copy text skin/isimple.css
/* Skin "iSimple" by Renat Rafikov */
body {
  background:#f2f2f2;
  font-family:arial, sans-serif;
}

a { color:#0085c5; }
a:hover { text-decoration:none; }
a:visited { color:#4a00c5; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 0.5em 0;
  padding:1.5em 3% 0 3%;
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  text-shadow:1px 1px 1px #ffffff;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
  font-size:12px;
}
.menu_main a,
.menu_main a:hover {
  color:#0085c5;
}
.menu_main li {
  display:inline-block;
  margin:0 0 0 4px;
}
.menu_main li.active,
.menu_main li.active a {
  color:#000;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 1% 1em 1%;
}

.hero {
  background:#fff;
  border:1px solid #fff;
  -webkit-border-radius:5px;
  -moz-border-radius:5px;
  border-radius:5px;
  -webkit-box-shadow:#8b8b8b 0px 0px 5px inset;
  -moz-box-shadow:#8b8b8b 0px 0px 5px inset;
  box-shadow:#8b8b8b 0px 0px 5px inset;
  padding:15px 0 15px 2%;
  margin:0 0 15px 0;
}

.hero h1 {
  font-size:24px;
  font-size:18px;
  color:#3d3d3d;
}

.article {
  background:#fff;
  border:1px solid #cbcbcb;
  -webkit-border-radius:5px;
  -moz-border-radius:5px;
  border-radius:5px;
  -webkit-box-shadow:#8b8b8b 0px 0px 3px;
  -moz-box-shadow:#8b8b8b 0px 0px 3px;
  box-shadow:#8b8b8b 0px 0px 3px;
  padding:15px 0 15px 2%;
}

.footer {
  padding:1em 3% 3em 3%;
  color:#717171;
  font-size:12px;
}

.copyright {
  width:49%;
  float:left;
  text-shadow:1px 1px 1px #ffffff;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  font-size:12px;
}
.menu_bottom a,
.menu_bottom a:hover {
  color:#0085c5;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 4px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#666;
  text-decoration:none;
  cursor:default;
}

h1 {
  font-size:22px;
}
h1, h2, h3, h4 {
  font-weight:normal;
}
h5, h6 {
  font-weight:bold;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:0;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  -webkit-box-shadow:#999 0px 0px 1px;
  -moz-box-shadow:#999 0px 0px 1px;
  box-shadow:#999 0px 0px 1px;
  background:#4aa6d6;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#1f7daa), to(#4aa6d6));
  background:-webkit-linear-gradient(#1f7daa, #4aa6d6);
  background:-moz-linear-gradient(#1f7daa, #4aa6d6);
  background:-ms-linear-gradient(#1f7daa, #4aa6d6);
  background:-o-linear-gradient(#1f7daa, #4aa6d6);
  background:linear-gradient(#1f7daa, #4aa6d6);
  color:#fff;
  padding:10px 20px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 1px #12455d;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#4aa6d6), to(#1f7daa));
  background:-webkit-linear-gradient(#4aa6d6, #1f7daa);
  background:-moz-linear-gradient(#4aa6d6, #1f7daa);
  background:-ms-linear-gradient(#4aa6d6, #1f7daa);
  background:-o-linear-gradient(#4aa6d6, #1f7daa);
  background:linear-gradient(#4aa6d6, #1f7daa);
}
a.button:active,
.button:active {
  color:#093950;
  text-shadow:1px 1px 1px #7ac8f0;
  -webkit-box-shadow:#093950 0px 2px 3px inset;
  -moz-box-shadow:#093950 0px 2px 3px inset;
  box-shadow:#093950 0px 2px 3px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:bold;
  text-align:left;
  font-size:0.9em;
  border-bottom:1px solid #ddd;
}
.table td {
  padding:9px 7px;
  border-left:1px solid #ddd;
}
.table tr td:first-child {border-left:0;}

.table tr {
  border-bottom:1px solid #fbfbfb;
}
.table tr:nth-child(even) {
  background:#F2F2F2;
}

.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  background:#ec252e;
  color:#fff;
  padding:8px 14px;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ec252e), to(#F05057));
  background:-webkit-linear-gradient(#ec252e, #F05057);
  background:-moz-linear-gradient(#ec252e, #F05057);
  background:-ms-linear-gradient(#ec252e, #F05057);
  background:-o-linear-gradient(#ec252e, #F05057);
  background:linear-gradient(#ec252e, #F05057);
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #6e9e30;
  color:#fff;
  background:#0bbe2e;
  padding:8px 14px;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#6e9e30), to(#87c03b));
  background:-webkit-linear-gradient(#6e9e30, #87c03b);
  background:-moz-linear-gradient(#6e9e30, #87c03b);
  background:-ms-linear-gradient(#6e9e30, #87c03b);
  background:-o-linear-gradient(#6e9e30, #87c03b);
  background:linear-gradient(#6e9e30, #87c03b);
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #2180ff;
  color:#1f49bf;
  background:#bcd9ff;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/liner.css
/* Skin "Liner" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#333;
}

a { color:#004dd9; }
a:hover { color:#ea0000; }
a:visited { color:#551a8b; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:0 0 1em 0;
  padding:2em 2% 0 2%;
  color:#fff;
  text-align:center;
  background:#6699CC;
  background:-moz-linear-gradient(left center , rgba(255, 255, 255, 0.1) 1px, rgba(255, 255, 255, 0.1) 2px, rgba(255, 255, 255, 0) 3px), #6699CC;
  background: -webkit-gradient(linear, left top, right top, color-stop(1px,rgba(255, 255, 255, 0.1)), color-stop(2px,rgba(255, 255, 255, 0.1)), color-stop(3px,rgba(255,255,255,0))), #6699CC;
  background: -webkit-linear-gradient(left, rgba(255, 255, 255, 0.1) 1px,rgba(255, 255, 255, 0.1) 2px,rgba(255,255,255,0) 3px), #6699CC;
  background: -o-linear-gradient(left, rgba(255, 255, 255, 0.1) 1px,rgba(255, 255, 255, 0.1) 2px,rgba(255,255,255,0) 3px), #6699CC;
  background: -ms-linear-gradient(left, rgba(255, 255, 255, 0.1) 1px,rgba(255, 255, 255, 0.1) 2px,rgba(255,255,255,0) 3px), #6699CC;
  background: linear-gradient(left, rgba(255, 255, 255, 0.1) 1px,rgba(255, 255, 255, 0.1) 2px,rgba(255,255,255,0) 3px), #6699CC;
  background-size:20px auto;
  position:relative;
}

.header:before {
  content:"";
  position:absolute;
  z-index:-1;
  left:0;
  top:0;
  height:100%;
  width:100%;
  display: block!important;
  border-radius: 0 0 67px 67px;
  box-shadow: 0 -13px 12px -1px rgba(0,0,0,0.4);
}

.logo {
  font-size:18px;
  width:100%;
}

.menu_main {
  margin:0.3em 0 -1em 0;
  display:inline-block;
  background:#484848;
  padding:0 30px;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius:6px 6px 10px 10px;
  -webkit-box-shadow:rgba(0, 0, 0, 0.3) 0 14px 4px -9px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  -moz-box-shadow:rgba(0, 0, 0, 0.3) 0 14px 4px -9px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  box-shadow:rgba(0, 0, 0, 0.3) 0 14px 4px -9px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
}

.menu_main li {
  display:inline-block;
  padding:0;
}

.menu_main li a,
.menu_main li a:visited {
	display:inline-block;
	padding:12px 9px 14px;
	color:#ccc;
}

.menu_main li a:hover {
  background:#888888;
  background: -moz-linear-gradient(top, rgba(136,136,136,0.7) 0%, rgba(255,255,255,0) 100%);
  background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(136,136,136,0.7)), color-stop(100%,rgba(255,255,255,0)));
  background: -webkit-linear-gradient(top, rgba(136,136,136,0.7) 0%,rgba(255,255,255,0) 100%);
  background: -o-linear-gradient(top, rgba(136,136,136,0.7) 0%,rgba(255,255,255,0) 100%);
  background: -ms-linear-gradient(top, rgba(136,136,136,0.7) 0%,rgba(255,255,255,0) 100%);
  background: linear-gradient(top, rgba(136,136,136,0.7) 0%,rgba(255,255,255,0) 100%);
  color:#fff;
}

.menu_main li.active,
.menu_main li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
  background:none;
}

.hero {
  padding:0 0 0 2%;
}

.article {
  background:#F0F0F0;
  padding:0 0 2em 2%;
}

.footer {
  padding:3em 2% 6em 2%;
  color:#666;
  background:#333;
  background:-moz-linear-gradient(left center , rgba(255, 255, 255, 0.05) 1px, rgba(255, 255, 255, 0.05) 2px, rgba(255, 255, 255, 0) 3px), #333;
  background: -webkit-gradient(linear, left top, right top, color-stop(1px,rgba(255, 255, 255, 0.05)), color-stop(2px,rgba(255, 255, 255, 0.05)), color-stop(3px,rgba(255,255,255,0))), #333;
  background: -webkit-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #333;
  background: -o-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #333;
  background: -ms-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #333;
  background: linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #333;
  background-size:20px auto;
  -webkit-box-shadow:#000 0 10px 42px -10px inset;
  -moz-box-shadow:#000 0 10px 42px -10px inset;
  box-shadow:#000 0 10px 42px -10px inset;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}

.menu_bottom li {
  display:inline-block;
  padding:0;
  margin:0 5px 0 0;
}

.menu_bottom li a,
.menu_bottom li a:visited {
	color:#ccc;
}

.menu_bottom li a:hover {
  color:#fff;
}

.menu_bottom li.active,
.menu_bottom li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
  background:none;
}


.hero h1 {
  font-size:23px;
  font-family:georgia, serif;
  font-style:italic;
  color:#6699CC;
}

h1, h2 {
  font-weight:normal;
  color:#000;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#000;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #666;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius: 6px 6px 10px 10px;
  -moz-border-radius: 6px 6px 10px 10px;
  border-radius:6px 6px 10px 10px;
  -webkit-box-shadow:rgba(0, 0, 0, 0.3) 0 14px 4px -9px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  -moz-box-shadow:rgba(0, 0, 0, 0.3) 0 14px 4px -9px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  box-shadow:rgba(0, 0, 0, 0.3) 0 14px 4px -9px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  background:#555;
  background: -moz-linear-gradient(top, rgba(255,255,255,0) 0%, rgba(255,255,255,0.2) 55%, rgba(255,255,255,0) 56%, rgba(255,255,255,0) 100%), #555;
  background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(255,255,255,0)), color-stop(55%,rgba(255,255,255,0.2)), color-stop(56%,rgba(255,255,255,0)), color-stop(100%,rgba(255,255,255,0))), #555;
  background: -webkit-linear-gradient(top, rgba(255,255,255,0) 0%,rgba(255,255,255,0.2) 55%,rgba(255,255,255,0) 56%,rgba(255,255,255,0) 100%), #555;
  background: -o-linear-gradient(top, rgba(255,255,255,0) 0%,rgba(255,255,255,0.2) 55%,rgba(255,255,255,0) 56%,rgba(255,255,255,0) 100%), #555;
  background: -ms-linear-gradient(top, rgba(255,255,255,0) 0%,rgba(255,255,255,0.2) 55%,rgba(255,255,255,0) 56%,rgba(255,255,255,0) 100%), #555;
  background: linear-gradient(top, rgba(255,255,255,0) 0%,rgba(255,255,255,0.2) 55%,rgba(255,255,255,0) 56%,rgba(255,255,255,0) 100%), #555;
  color:#ccc;
  padding:8px 20px 10px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;
  text-shadow:1px 1px 0px #444;
  -webkit-box-shadow:rgba(0, 0, 0, 0.4) 0 6px 4px -3px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  -moz-box-shadow:rgba(0, 0, 0, 0.4) 0 6px 4px -3px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
  box-shadow:rgba(0, 0, 0, 0.4) 0 6px 4px -3px, rgba(0, 0, 0, 0.7) 0 0 4px inset;
}
a.button:active,
.button:active {
  color:#333;
  background:#555;
  text-shadow:1px 1px 0px #888;
  -webkit-box-shadow:#000 0px -3px 14px inset;
  -moz-box-shadow:#000 0px -3px 14px inset;
  box-shadow:#000 0px -3px 14px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:2px solid #d63f46;
  color:#fff;
  padding:8px 14px;
  background:#de6969;
  background:-moz-linear-gradient(left center , rgba(255, 255, 255, 0.05) 1px, rgba(255, 255, 255, 0.05) 2px, rgba(255, 255, 255, 0) 3px), #de6969;
  background: -webkit-gradient(linear, left top, right top, color-stop(1px,rgba(255, 255, 255, 0.05)), color-stop(2px,rgba(255, 255, 255, 0.05)), color-stop(3px,rgba(255,255,255,0))), #de6969;
  background: -webkit-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #de6969;
  background: -o-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #de6969;
  background: -ms-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #de6969;
  background: linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #de6969;
  background-size:20px auto;
  -webkit-border-radius: 6px 6px 10px 10px;
  -moz-border-radius: 6px 6px 10px 10px;
  border-radius:6px 6px 10px 10px;
}
.success {
  border:2px solid #46a533;
  color:#fff;
  background:#7cde69;
  background:-moz-linear-gradient(left center , rgba(255, 255, 255, 0.05) 1px, rgba(255, 255, 255, 0.05) 2px, rgba(255, 255, 255, 0) 3px), #7cde69;
  background: -webkit-gradient(linear, left top, right top, color-stop(1px,rgba(255, 255, 255, 0.05)), color-stop(2px,rgba(255, 255, 255, 0.05)), color-stop(3px,rgba(255,255,255,0))), #7cde69;
  background: -webkit-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #7cde69;
  background: -o-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #7cde69;
  background: -ms-linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #7cde69;
  background: linear-gradient(left, rgba(255, 255, 255, 0.05) 1px,rgba(255, 255, 255, 0.05) 2px,rgba(255,255,255,0) 3px), #7cde69;
  background-size:20px auto;
  padding:8px 14px;
  -webkit-border-radius: 6px 6px 10px 10px;
  -moz-border-radius: 6px 6px 10px 10px;
  border-radius:6px 6px 10px 10px;
}
.message {
  border:2px solid #d3c7a1;
  color:#878473;
  background:#f2ead3;
  padding:8px 14px;
  -webkit-border-radius: 6px 6px 10px 10px;
  -moz-border-radius: 6px 6px 10px 10px;
  border-radius:6px 6px 10px 10px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .menu_bottom {
    margin:1em 0 1em 0!important;
  }  
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/maple.css
/* Skin "Maple" by Alexandr Loginov. http://atatakobry.tumblr.com */
body {
  font-family:'arial narrow', arial, sans-serif;
  font-size:16px;
  line-height:1.2;
  background-color:#f2f2f2;
  color:#6e6e6e;
}

p {
  margin:0.8em 0 0.8em 0; 
}

.info a, .info a:visited { 
  color:#e45338;
  background-color:#f6ecea;
  outline:none;  
}

.info a:hover { 
  color:#8b2f20; 
  background-color:#f6ecea;
  outline:none;  
}

ul li, ol li {
  padding:0 0 0.2em 0;
}


.container {
  max-width:1300px;
  margin:auto;      
  background-color:#f2f2f2;
}

.header { 
  font-size:20px;
  padding:1.5em 2% 1.5em 2%;
  background-color:#e45338;  
  margin:0;
}

.logo {
  float:left;
  display:inline-block;
  font-size:28px;
  letter-spacing:0.25em;
  color:#fff;  
  margin:0;
  padding:0; 
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  font-size:14px;
  text-transform:uppercase; 
  letter-spacing:0.18em;
  color:#fff;
}

.menu_main li {
  display:inline-block;
  margin:0.2em;  
  padding:0.4em;
  border: 1px dashed #8b2f20;
}

.menu_main li a {
  text-decoration:none;
  color:#fff;
}
.menu_main li a:hover {
  text-decoration:underline;
}

.menu_main li.active,
.menu_main li.active a {    
  cursor:default;
  background-color:#8b2f20;
  text-decoration:none;
}

.info {
  padding:2em 2% 2em 2%; 
  margin:0;
}

.footer {    
  color:#fff;
  font-size:20px;
  padding:1.5em 2% 1.5em 2%;
  background-color:#e45338;
}

.copyright {
  width:49%;
  float:left;  
  font-size:18px;  
  margin-top:0.25em;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  font-size:14px;
  text-transform:uppercase; 
  letter-spacing:0.18em;
  color:#fff;
}

.menu_bottom li {
  display:inline-block;
  margin:0.2em;  
  padding:0.4em;
  border: 1px dashed #8b2f20;
}

.menu_bottom li a {
  text-decoration:none;
  color:#fff;
}
.menu_bottom li a:hover {
  text-decoration:underline;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  cursor:default;
  background-color:#8b2f20;
  text-decoration:none;
}


.hero h1 {
  font-size:20px;
  font-weight:bold;  
  text-transform:uppercase;
  margin:0.8em 0 0.8em 0;
  padding:0;
}

h1 {
  font-weight:bold;
  color:#2d2d2d; 
  font-size:24px; 
  margin:0.6em 0 0.6em 0;
  padding:0; 
}

h2 {
  font-weight:bold;
  color:#4d4d4d; 
  font-size:20px;  
  margin:0.8em 0 0.8em 0;
  padding:0; 
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#6f6f6f;
  margin:1em 0 1em 0;
  padding:0;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

select, input, textarea, label  {  
  font-size:14px;
}

a.button,
.button {
  display:inline-block;
  zoom:1; /* zoom and *display = ie7 hack for display:inline-block  */  
  vertical-align:baseline;  
  outline:none;
  cursor:pointer;
  margin:0 0.1em;
  padding:0.6em 1.5em 0.6em 1.5em;
  text-align:center;
  text-decoration:none;
  color:#6d6d6d;
  font:13px/100% arial, sans-serif;     
  text-shadow:0 1px 1px rgba(0, 0, 0, 0.3);
  border:1px solid #b7b7b7;   
  -webkit-border-radius:0.5em;
  -moz-border-radius:0.5em;
  -ms-border-radius:0.5em;
  -o-border-radius:0.5em;
  border-radius:0.5em;   
  -webkit-box-shadow:0 1px 2px rgba(0, 0, 0, 0.2);
  -moz-box-shadow:0 1px 2px rgba(0, 0, 0, 0.2);
  -ms-box-shadow:0 1px 2px rgba(0, 0, 0, 0.2);
  -o-box-shadow:0 1px 2px rgba(0, 0, 0, 0.2);
  box-shadow:0 1px 2px rgba(0, 0, 0, 0.2);  
  background-color:#fff;
  background-image:-webkit-gradient(linear, left top, left bottom, from(#fff), to(#ededed));
  background-image:-moz-linear-gradient(top, #fff, #ededed);
  background-image:-ms-linear-gradient(top, #fff, #ededed); 
  background-image:-o-linear-gradient(top, #fff, #ededed);  
  background-image:linear-gradient(top, #fff, #ededed); 
  filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#ededed');
}

a.button:hover,
.button:hover {
  text-decoration:none;
  background-color:#eee;
  background-image:-webkit-gradient(linear, left top, left bottom, from(#fff), to(#dcdcdc));
  background-image:-moz-linear-gradient(top, #fff, #dcdcdc);
  background-image:-ms-linear-gradient(top, #fff, #dcdcdc);
  background-image:-o-linear-gradient(top, #fff, #dcdcdc);
  background-image:linear-gradient(top, #fff, #dcdcdc);
  filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#dcdcdc');
  color:#6d6d6d;
}

a.button:active,
.button:active {
  position:relative;
  top:1px;
  color:#6d6d6d;
  background-color:#ededed;
  background-image:-webkit-gradient(linear, left top, left bottom, from(#ededed), to(#fff));
  background-image:-moz-linear-gradient(top, #ededed, #fff);
  background-image:-ms-linear-gradient(top, #ededed, #fff);
  background-image:-o-linear-gradient(top, #ededed, #fff);
  background-image:linear-gradient(top, #ededed, #fff);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#ededed', endColorstr='#ffffff');
} 

.table {
  width:100%;  
}
.table th {
  padding:5px 7px;  
  text-align:left;
  font-size:1em;   
  color:#8f8f8f;
  text-transform:uppercase;
  letter-spacing:0.3em;
}
.table td {
  padding:8px 7px;
}
.table tr {
  border-bottom:1px solid #887777;
}
.table tr:last-child {
  border:0;
}

.warning {  
  color:#2d2d2d;
  text-align:center;
  border:0.4em dotted #e45338;
  padding:8px 14px; 
}
.success {
  color:#2d2d2d;
  text-align:center;
  border:0.4em dotted #2fac7b;  
  padding:8px 14px; 
}
.message {  
  color:#2d2d2d;
  text-align:center;
  border:0.4em dotted #6d6d6d;
  padding:8px 14px; 
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/mentol.css
/* Skin "Mentol" by Renat Rafikov */

/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Kelly+Slab&subset=latin,cyrillic);
/* End webfonts */


body {
  background:#fbfbf1;
  font-family:arial, sans-serif;
  color:#7d7b71;
}

a { color:#7d7b71; }
a:hover { color:#67e594; }
a:visited { color:#8d739e; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  color:#67e594;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:-0.3em 0 0 0;
}

.menu_main ul {
  width:auto;
  border:2px solid #f1eee7;
  display: inline-block;
  padding:10px 17px 10px 10px;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
  font-weight:bold;
  padding:0;
}

.menu_main li a,
.menu_main li a:visited {
  color:#8d8b84;
}
.menu_main li a:hover,
.menu_main li a:visited:hover {
  color:#67e594;
}

.menu_main li.active,
.menu_main li.active a:hover,
.menu_main li.active a {
  color:#52504a;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:'Kelly Slab', georgia, serif;
  color:#67e594;
  font-size:14px;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
  font-weight:bold;
}
.menu_bottom li a,
.menu_bottom li a:visited {
  color:#8d8b84;
}
.menu_bottom li a:hover,
.menu_bottom li a:visited:hover {
  color:#67e594;
}

.menu_bottom li.active,
.menu_bottom li.active a:hover,
.menu_bottom li.active a {
  color:#52504a;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:29px;  
  color:#67e594;
}

h1, h2 {
  font-family:'Kelly Slab', georgia, serif;
  font-weight:normal;
  color:#67e594;
}

h3, h4, h5, h6 {
  font-family:'Kelly Slab', georgia, serif;
  font-weight:normal;
  color:#67e594;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #51d480;
  text-align:center; 
  text-decoration:none;
  background:#67e594;
  color:#fff;
  padding:10px 20px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#38C76B;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#67e594), to(#38C76B));
  background: -webkit-linear-gradient(#67e594, #38C76B);
  background: -moz-linear-gradient(#67e594, #38C76B);
  background: -ms-linear-gradient(#67e594, #38C76B);
  background: -o-linear-gradient(#67e594, #38C76B);
  background: linear-gradient(#67e594, #38C76B);
  border:1px solid #3ab566;
  text-shadow:1px 1px 0px #51d480;
  -webkit-box-shadow: rgba(0,0,0,0.2) 0px 0px 2px;
  -moz-box-shadow: rgba(0,0,0,0.2) 0px 0px 2px;
  box-shadow: rgba(0,0,0,0.2) 0px 0px 2px;
}
a.button:active,
.button:active {
  color:#35b060;
  background:#67e594;
  text-shadow:1px 1px 1px #b6efca;
  -webkit-box-shadow:#51d480 0px 0 3px inset;
  -moz-box-shadow:#51d480 0px 0 3px inset;
  box-shadow:#51d480 0px 0 3px inset;
  border:1px solid #51d480;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:16px;
}
.table td {
  padding:8px 7px;
}
.table tr {
  border-bottom:1px solid #dddddd;
}

.warning {
  color:#fff;
  padding:9px 14px;
  background:#d12c33;
  -webkit-box-shadow: #8d8b84 0px 0px 6px inset;
  -moz-box-shadow: #8d8b84 0px 0px 6px inset;
  box-shadow: #8d8b84 0px 0px 6px inset;
}
.success {
  color:#fff;
  background:#67e594;
  padding:9px 14px;
  -webkit-box-shadow: #8d8b84 0px 0px 6px inset;
  -moz-box-shadow: #8d8b84 0px 0px 6px inset;
  box-shadow: #8d8b84 0px 0px 6px inset;
}
.message {
  color:#8d8b84;
  background:#f0f1e1;
  padding:9px 14px;
  -webkit-box-shadow: #8d8b84 0px 0px 6px inset;
  -moz-box-shadow: #8d8b84 0px 0px 6px inset;
  box-shadow: #8d8b84 0px 0px 6px inset;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/nightroad.css
/* Skin "Night road" by Renat Rafikov */
body {
  background:#171612;
  font-family:arial, sans-serif;
  color:#7f7c77;
}

a { color:#7f7c77; }
a:hover { color:#fefefe; }
a:visited { color:#6a6762; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
  border-top:4px solid #169fe5;
}

.logo {
  float:left;
  display:inline-block;
  border-bottom:1px solid #000;
  font-size:18px;
  color:#169fe5;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li a {
  color:#778493;
}

.menu_main li a:hover {
  color:#169fe5;
}

.menu_main li.active,
.menu_main li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 2em 2%;
}

.hero {
  color:#778493;
  border-bottom:1px solid #169fe5;
  margin:0 2% 40px 0;
  padding:0 0 10px 0;
}
.hero a { color:#778493; }
.hero a:hover { color:#fefefe; }
.hero a:visited { color:#5f6e7f; }

.footer {
  border-top:1px solid #169fe5;
  padding:2em 2% 3em 2%;
  color:#169fe5;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li a {
  color:#778493;
}
.menu_bottom li a:hover {
  color:#169fe5;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:24px;
  color:#dde5ef;
}

h1, h2 {
  font-weight:normal;
  color:#fefefe;
  font-family:georgia, serif;
}

h3, h4, h5, h6 {
  font-weight:normal;
  color:#fefefe;
  font-family:georgia, serif;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
a.button:visited,
.button {
  border:0;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 8px inset;
  -moz-box-shadow:#000 0px 0px 8px inset;
  box-shadow:#000 0px 0px 8px inset;
  background:#169fe5;
  color:#d1efff;
  padding:7px 14px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  -webkit-box-shadow:#000 0px 0px 3px inset;
  -moz-box-shadow:#000 0px 0px 3px inset;
  box-shadow:#000 0px 0px 3px inset;
}
a.button:active,
.button:active {
  color:#094766;
  text-shadow:1px 1px 1px #fff;
  -webkit-box-shadow:#000 0px 3px 4px inset;
  -moz-box-shadow:rgba(0, 0, 0, 0.66) 0px 3px 4px inset;
  box-shadow:#000 0px 3px 4px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:16px;
  color:#778493;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #7f7c77;
}
.table tr:first-child {
  border-bottom:1px solid #169fe5;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:8px 14px;
  background:#ea0021;
  -webkit-box-shadow:#000 0px 0px 5px inset;
  -moz-box-shadow:#000 0px 0px 5px inset;
  box-shadow:#000 0px 0px 5px inset;
}
.success {
  color:#fff;
  background:#399f16;
  padding:8px 14px;
  -webkit-box-shadow:#000 0px 0px 5px inset;
  -moz-box-shadow:#000 0px 0px 5px inset;
  box-shadow:#000 0px 0px 5px inset;
}
.message {
  color:#776800;
  background:#ecd747;
  padding:8px 14px;
  -webkit-box-shadow:#000 0px 0px 5px inset;
  -moz-box-shadow:#000 0px 0px 5px inset;
  box-shadow:#000 0px 0px 5px inset;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/orange.css
/* Skin "big Color Idea: Orange" by Egor Kubasov. http://egorkubasov.ru */
/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End webfonts */

body {
  font-family:'Ubuntu', Tahoma, sans-serif;
  color:#000000;
  background:#eeeeee;
}

a { color:#ff7800; }
a:hover { color:#999999; }
a:visited { color:#ff7800; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Ubuntu', Tahoma, sans-serif;
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #ff7800;
  font-size:36px;
  color:#ff7800;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
  text-align:center;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#v;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #ff7800;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#ff7800;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Ubuntu', Tahoma, sans-serif;
  font-style:bold;
  color:#ff7800;
}

h1, h2 {
  font-weight:normal;
  color:#ff7800;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#ff7800;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:3px solid #ff7800;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#f5bf8f;
  color:#fff;
  padding:5px 20px;
  font-family:'Ubuntu';
  font-weight: 700;
  font-size: 15px;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#f8a75f;
}
a.button:active,
.button:active {
  color:#fff;
  background: #fc9030;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#f5bf8f;
  border:1px solid #ff7800;
  color:#666;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ff7800;
}
.table tr:last-child {
  border-bottom:1px solid #ff7800;
}

.warning {
  border:3px solid #ff0000;
  color:#000;
  padding:8px 14px;
  background:transperent;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.success {
  border:3px solid #399f16;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.message {
  border:3px solid #fff600;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}

@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/passion.css
/* Skin "Passion" by Renat Rafikov */
html {
  overflow-x:hidden;
}
body {
  font-family:arial, sans-serif;
  color:#333;
}

a { color:#004dd9; }
a:hover { color:#ea0000; }
a:visited { color:#551a8b; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:10px 1% 3em 1%;
  padding:2em 2% 2em 2%;
  background-color:#8C0000;
  background-image: -moz-linear-gradient(top, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.1) 40%, rgba(255,255,255,0) 100%);
  background-image: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(255,255,255,0.1)), color-stop(40%,rgba(255,255,255,0.1)), color-stop(100%,rgba(255,255,255,0)));
  background-image: -webkit-linear-gradient(top, rgba(255,255,255,0.1) 0%,rgba(255,255,255,0.1) 40%,rgba(255,255,255,0) 100%);
  background-image: -o-linear-gradient(top, rgba(255,255,255,0.1) 0%,rgba(255,255,255,0.1) 40%,rgba(255,255,255,0) 100%);
  background-image: -ms-linear-gradient(top, rgba(255,255,255,0.1) 0%,rgba(255,255,255,0.1) 40%,rgba(255,255,255,0) 100%);
  background-image: linear-gradient(top, rgba(255,255,255,0.1) 0%,rgba(255,255,255,0.1) 40%,rgba(255,255,255,0) 100%);
  -webkit-box-shadow: #666 0px 5px 0px;
  -moz-box-shadow: #666 0px 5px 0px;
  box-shadow: rgba(0,0,0,0.8) 0px 5px 0px;
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  color:#fff;
}

.menu_main {
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 1px;
  padding:0;
  float:left;
}

.menu_main a,
.menu_main  a:visited {
  display:inline-block;
  background:#000;
  background:rgba(0,0,0,0.4);
  color:#ddd;
  padding:4px 10px;
  -webkit-border-radius: 2px;
  -moz-border-radius: 2px;
  border-radius: 2px;
}

.menu_main a:hover {
  background:rgba(0,0,0,0.6);
  color:#fff;
}

.menu_main li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
  background:rgba(0,0,0,0.6);
}


.hero {
  background-color:#fff;
  background-image: -moz-linear-gradient(left, rgba(242,242,242,0) 1%, rgba(242,242,242,0.65) 15%, rgba(199,199,199,0) 30%, rgba(0,0,0,0) 100%);
  background-image: -webkit-gradient(linear, left top, right top, color-stop(1%,rgba(242,242,242,0)), color-stop(15%,rgba(242,242,242,0.65)), color-stop(30%,rgba(199,199,199,0)), color-stop(100%,rgba(0,0,0,0)));
  background-image: -webkit-linear-gradient(left, rgba(242,242,242,0) 1%,rgba(242,242,242,0.65) 15%,rgba(199,199,199,0) 30%,rgba(0,0,0,0) 100%);
  background-image: -o-linear-gradient(left, rgba(242,242,242,0) 1%,rgba(242,242,242,0.65) 15%,rgba(199,199,199,0) 30%,rgba(0,0,0,0) 100%);
  background-image: -ms-linear-gradient(left, rgba(242,242,242,0) 1%,rgba(242,242,242,0.65) 15%,rgba(199,199,199,0) 30%,rgba(0,0,0,0) 100%);
  background-image: linear-gradient(left, rgba(242,242,242,0) 1%,rgba(242,242,242,0.65) 15%,rgba(199,199,199,0) 30%,rgba(0,0,0,0) 100%);
  background-size:5px auto;
  position:relative;
  padding:0.1em 0 1em 2%;
  margin:0 1% 3em 1%;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}

.hero:before {
  content:"";
  display:block!important;
  width:7000px;
  left:50%;
  margin:0 0 0 -3500px;
  height:200%;
  top:-90%;
  z-index:-1;
  background-color:#000;
  background-image: -moz-linear-gradient(left, rgba(255,255,255,0) 0%, rgba(255,255,255,0) 42%, rgba(255,255,255,0.2) 50%, rgba(255,255,255,0) 58%, rgba(255,255,255,0) 100%);
  background-image: -webkit-gradient(linear, left top, right top, color-stop(0%,rgba(255,255,255,0)), color-stop(42%,rgba(255,255,255,0)), color-stop(50%,rgba(255,255,255,0.2)), color-stop(58%,rgba(255,255,255,0)), color-stop(100%,rgba(255,255,255,0)));
  background-image: -webkit-linear-gradient(left, rgba(255,255,255,0) 0%,rgba(255,255,255,0) 42%, rgba(255,255,255,0.2) 50%,rgba(255,255,255,0) 58%,rgba(255,255,255,0) 100%);
  background-image: -o-linear-gradient(left, rgba(255,255,255,0) 0%,rgba(255,255,255,0) 42%, rgba(255,255,255,0.2) 50%,rgba(255,255,255,0) 58%,rgba(255,255,255,0) 100%);
  background-image: -ms-linear-gradient(left, rgba(255,255,255,0) 0%,rgba(255,255,255,0) 42%, rgba(255,255,255,0.2) 50%,rgba(255,255,255,0) 58%,rgba(255,255,255,0) 100%);
  background-image: linear-gradient(left, rgba(255,255,255,0) 0%,rgba(255,255,255,0) 42%, rgba(255,255,255,0.2) 50%,rgba(255,255,255,0) 58%,rgba(255,255,255,0) 100%);
  position:absolute;
}

.article {
  padding:0 2% 3em 2%;
  margin:0 1%;
}

.footer {
  padding:2em 2% 3em 2%;
  color:#fff;
  position:relative;
}

.footer:before {
  content:"";
  display:block!important;
  width:7000px;
  left:-2000px;
  height:100%;
  top:0;
  z-index:-1;
  background:#000;
  position:absolute;
}

.copyright {
  width:49%;
  float:left;
  color:#666;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom a,
.menu_bottom a:visited {
  color:#ddd;
}
.menu_bottom a:hover {
  color:#fff;
}

.menu_bottom li.active,
.menu_bottom li.active a {
  color:#fff;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:26px;
  color:#8C0000;
}

h1, h2 {
  font-weight:normal;
  color:#000;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#000;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #CACACA;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
  background:#ECECEC;
  color:#6E6E6E;
  padding:6px 15px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  background: #F9F9F9;
  border-color: #aaa;
  color: #3C3C3D;
  text-shadow: 1px 1px 0 #fff;
}
a.button:active,
.button:active {
  position:relative;
  top:1px;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#ffffff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ffffff), to(#F7F7F7));
  background:-webkit-linear-gradient(#ffffff, #F7F7F7);
  background:-moz-linear-gradient(#ffffff, #F7F7F7);
  background:-ms-linear-gradient(#ffffff, #F7F7F7);
  background:-o-linear-gradient(#ffffff, #F7F7F7);
  background:linear-gradient(#ffffff, #F7F7F7);
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:8px 14px;
  background:#8C0000;
  border-bottom:3px solid #000;
}
.success {
  color:#fff;
  background:#008c00;
  padding:8px 14px;
  border-bottom:3px solid #000;
}
.message {
  color:#666;
  background:#fffee0;
  padding:8px 14px;
  border-bottom:3px solid #666;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .header {
    margin-bottom:0.1em!important;
    padding:10px 0;
  }
  .menu_main li {
    float:none;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
  .header {
    margin-bottom:1em;
  }
  
  .hero {
    margin-bottom:1em;
  }
  
  .hero:before {
    height:193%;
  }
}
#>>> copy text skin/pink.css
/* Skin "Big Color Idea: Pink" by Egor Kubasov. http://egorkubasov.ru */
/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End webfonts */

body {
  font-family:'Ubuntu', Tahoma, sans-serif;
  color:#000000;
  background:#eeeeee;
}

a { color:#ff00f6; }
a:hover { color:#999999; }
a:visited { color:#ff00f6; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Ubuntu', Tahoma, sans-serif;
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #ff00f6;
  font-size:36px;
  color:#ff00f6;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
  text-align:center;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#ff00f6;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #ff00f6;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#ff00f6;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Ubuntu', Tahoma, sans-serif;
  font-style:bold;
  color:#ff00f6;
}

h1, h2 {
  font-weight:normal;
  color:#ff00f6;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#ff00f6;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:3px solid #ff00f6;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#f58ff1;
  color:#fff;
  padding:5px 20px;
  font-family:'Ubuntu';
  font-weight: 700;
  font-size: 15px;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#f85ff3;
}
a.button:active,
.button:active {
  color:#fff;
  background: #fc30f4;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#f58ff1;
  border:1px solid #ff00f6;
  color:#666;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ff00f6;
}
.table tr:last-child {
  border-bottom:1px solid #ff00f6;
}

.warning {
  border:3px solid #ff0000;
  color:#000;
  padding:8px 14px;
  background:transperent;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.success {
  border:3px solid #399f16;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.message {
  border:3px solid #fff600;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}

@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/purple.css
/* Skin "Big Color Idea: Purple" by Egor Kubasov. http://egorkubasov.ru */
/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End webfonts */

body {
  font-family:'Ubuntu', Tahoma, sans-serif;
  color:#000000;
  background:#eeeeee;
}

a { color:#a200ff; }
a:hover { color:#999999; }
a:visited { color:#a200ff; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Ubuntu', Tahoma, sans-serif;
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #a200ff;
  font-size:36px;
  color:#a200ff;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
  text-align:center;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#a200ff;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #a200ff;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#a200ff;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Ubuntu', Tahoma, sans-serif;
  font-style:bold;
  color:#a200ff;
}

h1, h2 {
  font-weight:normal;
  color:#a200ff;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#a200ff;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:3px solid #a200ff;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#d08ff5;
  color:#fff;
  padding:5px 20px;
  font-family:'Ubuntu';
  font-weight: 700;
  font-size: 15px;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#c05ff8;
}
a.button:active,
.button:active {
  color:#fff;
  background: #b130fc;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#d08ff5;
  border:1px solid #a200ff;
  color:#666;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #a200ff;
}
.table tr:last-child {
  border-bottom:1px solid #a200ff;
}

.warning {
  border:3px solid #ff0000;
  color:#000;
  padding:8px 14px;
  background:transperent;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.success {
  border:3px solid #399f16;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.message {
  border:3px solid #fff600;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}

@media only screen and (max-width:480px) { /* Smartphone custom styles*/
}

@media only screen and (max-width:768px) { /* Tablet custom styles*/
}
#>>> copy text skin/red.css
/* Skin "Big Color Idea: Red" by Egor Kubasov. http://egorkubasov.ru */
/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End webfonts */

body {
  font-family:'Ubuntu', Tahoma, sans-serif;
  color:#000000;
  background:#eeeeee;
}

a { color:#ff0000; }
a:hover { color:#999999; }
a:visited { color:#ff0000; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Ubuntu', Tahoma, sans-serif;
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #ff0000;
  font-size:36px;
  color:#ff0000;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
  text-align:center;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#ff0000;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #ff0000;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#ff0000;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Ubuntu', Tahoma, sans-serif;
  font-style:bold;
  color:#ff0000;
}

h1, h2 {
  font-weight:normal;
  color:#ff0000;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#ff0000;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:3px solid #ff0000;
  text-align:center; 
  text-decoration:none;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#f58f8f;
  color:#fff;
  padding:5px 20px;
  font-family:'Ubuntu';
  font-weight: 700;
  font-size: 15px;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#f85f5f;
}
a.button:active,
.button:active {
  color:#fff;
  background: #fc3030;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#f58f8f;
  border:1px solid #ff0000;
  color:#666;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ff0000;
}
.table tr:last-child {
  border-bottom:1px solid #ff0000;
}

.warning {
  border:3px solid #ff0000;
  color:#000;
  padding:8px 14px;
  background:transperent;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.success {
  border:3px solid #399f16;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}
.message {
  border:3px solid #fff600;
  color:#000;
  background:transperent;
  padding:8px 14px;
  font-size: 16px;
  -webkit-box-shadow:#666 1px 1px 2px;
  -moz-box-shadow:#666 1px 1px 2px;
  box-shadow:#666 1px 1px 2px;
}

@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet */
}
#>>> copy text skin/simplesoft.css
/* Skin "Simple soft" by Renat Rafikov */
html {
  height:100%;
  overflow-x:hidden;
}
body {
  font-family:arial, sans-serif;
  color:#000;
  background:#f2f2f2;
  height:100%;
}

a { color:#000; }
a:hover { color:#666; }
a:visited { color:#444; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  padding:2em 2% 2em 2%;
  background:#313131;
  border-bottom:1px solid #88c8f6;
  position:relative;
}
.header:before {
  content:"";
  display:block!important;
  background:#313131;
  border-bottom:1px solid #88c8f6;
  height:100%;
  width:6000px;
  position:absolute;
  left:-2000px;
  top:0;
  z-index:-1;
}

.logo {
  float:left;
  display:inline-block;
  font-size:24px;
  color:#ededed;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li a,
.menu_main li a:visited {
  color:#ededed;
  text-decoration:none;
}
.menu_main li a:hover,
.menu_main li a:visited:hover {
  color:#fff;
}

.menu_main li.active,
.menu_main li.active a {
  color:#666;
  text-decoration:none;
  cursor:default;
}

.hero {
  background:#499cd7;
  color:#fff;
  border-bottom:1px solid #fff;
  padding:10px 0 10px 2%;
  margin:0 0 2em 0;
  position:relative;
}
.hero:before {
  content:"";
  display:block!important;
  background:#499cd7;
  border-bottom:1px solid #fff;
  height:100%;
  width:6000px;
  position:absolute;
  left:-2000px;
  top:0;
  z-index:-1;
}

.info {
  padding:0 0 2.5em 0;
}

.article {
  padding:0 0 0 2%;
}

.footer {
  padding:2em 2% 5em 2%;
  color:#666;
  background:#fff;
  position:relative;
}
.footer:before {
  content:"";
  display:block!important;
  background:#fff;
  height:100%;
  width:6000px;
  position:absolute;
  left:-2000px;
  top:0;
  z-index:-1;
  -webkit-box-shadow: #d8d8d8 0px -1px 5px;
  -moz-box-shadow: #d8d8d8 0px -1px 5px;
  box-shadow: #d8d8d8 0px -1px 5px;
}

.copyright {
  width:49%;
  float:left;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li a {
  color:#666;
}
.menu_bottom li a:hover {
  color:#444;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#666;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:24px;
  color:#fff;
}

h1, h2 {
  font-weight:normal;
  color:#010101;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#010101;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #9a9a9a;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:3px;
  -moz-border-radius:3px;
  border-radius:3px;
  -webkit-box-shadow:rgba(0, 0, 0, 0.64) 0px 1px 4px;
  -moz-box-shadow:rgba(0, 0, 0, 0.64) 0px 1px 4px;
  box-shadow:rgba(0, 0, 0, 0.64) 0px 1px 4px;
  background:#ffffff;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#ffffff), to(#e2e2e2));
  background:-webkit-linear-gradient(#ffffff, #e2e2e2);
  background:-moz-linear-gradient(#ffffff, #e2e2e2);
  background:-ms-linear-gradient(#ffffff, #e2e2e2);
  background:-o-linear-gradient(#ffffff, #e2e2e2);
  background:linear-gradient(#ffffff, #e2e2e2);
  color:#484848;
  font-size:14px;
  padding:5px 14px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  border:1px solid #5a5a5a;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#e2e2e2), to(#ffffff));
  background:-webkit-linear-gradient(#e2e2e2, #ffffff);
  background:-moz-linear-gradient(#e2e2e2, #ffffff);
  background:-ms-linear-gradient(#e2e2e2, #ffffff);
  background:-o-linear-gradient(#e2e2e2, #ffffff);
  background:linear-gradient(#e2e2e2, #ffffff);
}
a.button:active,
.button:active {
  color:#666;
  -webkit-box-shadow:#5a5a5a 0px 3px 5px inset;
  -moz-box-shadow:#5a5a5a 0px 3px 5px inset;
  box-shadow:#5a5a5a 0px 3px 5px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:bold;
  text-align:left;
}
.table td {
  padding:5px 7px;
}
.table tr:nth-child(even) {
  background:#fff;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #d03f3f;
  color:#fff;
  padding:8px 14px;
  background:#d03f3f;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #49d76e;
  color:#fff;
  background:#49d76e;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #d7cf49;
  color:#fff;
  background:#d7cf49;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .header:before,
  .hero:before,
  .footer:before {
    display:none!important;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
  .header:before,
  .hero:before {
    display:none!important;
  }
}
#>>> copy text skin/simpleswiss.css
/* Skin "Simple swiss" by Renat Rafikov */
body {
  background:#fff220;
  font-family:arial, sans-serif;
  color:#565656;
}

a { color:#565656; }
a:hover { color:#565656; text-decoration:none; }
a:visited { color:#727272; text-decoration:line-through;}
a:visited:hover { text-decoration:underline;}

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1em 1% 0 1%;
  padding:2em 2% 1em 2%;
  background:#fff;
}

.logo {
  float:left;
  display:inline-block;
  font-size:18px;
  color:#383838;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.2em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#565656;
  text-decoration:none;
  cursor:default;
}

.info {
  margin:0 1%;
}

.hero {
  background:#fff;
  margin:0 0 2em 0;
  padding:0 0 1em 2%;
}
.hero .col_66 {
  border-right:1px solid #cecece;
  margin-right:1%;
  padding-right:1%;
}

.article {
  background:#fff;
  padding:1.5em 0 2em 2%;
}

.footer {
  padding:1em 2% 2em 2%;
  color:#565656;
  margin:0 1%;
}

.copyright {
  width:49%;
  float:left;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  color:#565656;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom a {
  color:#565656;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#565656;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:18px;
  color:#565656;
}

h1, h2 {
  font-weight:normal;
  font-size:17px;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#737373;
}

h1 {
  font-size:22px;
}

.article .col_33 h2:first-child,
.article .col_50 h2:first-child,
.article .col_66 h2:first-child {
  border-bottom:1px solid #cecece;
  padding: 0 0 0.5em;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:0;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:1px;
  -moz-border-radius:1px;
  border-radius:1px;
  -webkit-box-shadow: #969696 0px 2px 6px;
  -moz-box-shadow: #969696 0px 2px 6px;
  box-shadow: #969696 0px 2px 6px;  
  background:#565656;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#8D8D8D), to(#565656));
  background: -webkit-linear-gradient(#8D8D8D, #565656);
  background: -moz-linear-gradient(#8D8D8D, #565656);
  background: -ms-linear-gradient(#8D8D8D, #565656);
  background: -o-linear-gradient(#8D8D8D, #565656);
  background: linear-gradient(#8D8D8D, #565656);
  color:#d3d3d3;
  padding:12px 20px;
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#565656), to(#8D8D8D));
  background: -webkit-linear-gradient(#565656, #8D8D8D);
  background: -moz-linear-gradient(#565656, #8D8D8D);
  background: -ms-linear-gradient(#565656, #8D8D8D);
  background: -o-linear-gradient(#565656, #8D8D8D);
  background: linear-gradient(#565656, #8D8D8D);
  -webkit-box-shadow: #898989 0px 2px 4px;
  -moz-box-shadow: #898989 0px 2px 4px;
  box-shadow: #898989 0px 2px 4px;  
}
a.button:active,
.button:active {
  color:#323232;
  text-shadow:0px 1px 1px #bdbdbd;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#565656), to(#8D8D8D));
  background: -webkit-linear-gradient(#565656, #8D8D8D);
  background: -moz-linear-gradient(#565656, #8D8D8D);
  background: -ms-linear-gradient(#565656, #8D8D8D);
  background: -o-linear-gradient(#565656, #8D8D8D);
  background: linear-gradient(#565656, #8D8D8D);
  -webkit-box-shadow: #323232 0px -2px 2px inset;
  -moz-box-shadow: #323232 0px -2px 2px inset;
  box-shadow: #323232 0px -2px 2px inset;  
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#fff;
  padding:8px 14px;
  background:#eb4161;
  -webkit-border-radius:1px;
  -moz-border-radius:1px;
  border-radius:1px;
}
.success {
  border:1px solid #399f16;
  color:#fff;
  background:#12d878;
  padding:8px 14px;
  -webkit-border-radius:1px;
  -moz-border-radius:1px;
  border-radius:1px;
}
.message {
  border:1px solid #efe65d;
  color:#9a9855;
  background:#fffbc0;
  padding:8px 14px;
  -webkit-border-radius:1px;
  -moz-border-radius:1px;
  border-radius:1px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .hero .col_66 {
    border-right:0;
    margin-right:2%;
  }
  .header {
    padding: 1em 2% 0;
    margin: 3px 1% 0;
  }
  .hero {
      margin: 0 0 6px;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
  .hero .col_66 {
    border-right:0;
    margin-right:2%;
  }
}
#>>> copy text skin/simploid.css
/* Skin "Simploid" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
}

a { color:#000; }
a:hover { color:#33b5e5; }
a:visited { color:#888; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 1.5em 0;
  padding:2em 2% 1.4em 2%;
  border-bottom:1px solid #ccc;
}

.logo {
  float:left;
  display:inline-block;
  font-size:22px;
  color:#86c300;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
  font-size:15px;
}
.menu_main a,
.menu_main a:visited {
  color:#000;
}
.menu_main a:hover,
.menu_main a:visited:hover {
  color:#33b5e5;
}
.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_main li.active,
.menu_main li.active a {
  color:#33b5e5;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #86c300;
  padding:2em 2% 3em 2%;
  color:#717171;
}

.copyright {
  width:49%;
  float:left;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  font-size:15px;
}
.menu_bottom a,
.menu_bottom a:visited {
  color:#000;
}
.menu_bottom a:hover,
.menu_bottom a:visited:hover {
  color:#33b5e5;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#33b5e5;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:18px;
  font-weight:bold;
}

h1 {
  font-size:22px;
}
h1, h2 {
  font-weight:bold;
  color:#3d3d3d;
}
h3, h4, h5, h6 {
  font-weight:bold;
  color:#3d3d3d;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #2FADDB;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
  background:#0099CC;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#2FADDB), to(#0099CC));
  background:-webkit-linear-gradient(center top , #2FADDB, #0099CC);
  background:-moz-linear-gradient(center top , #2FADDB, #0099CC);
  background:-ms-linear-gradient(center top , #2FADDB, #0099CC);
  background:-o-linear-gradient(center top , #2FADDB, #0099CC);
  background:linear-gradient(center top , #2FADDB, #0099CC);
  color:#fff;
  padding:5px 10px;
  display:inline-block;
  font-size:15px;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#4CADCB;
  background:-webkit-gradient(linear, 0 0, 0 bottom, from(#5DBCD9), to(#4CADCB));
  background:-webkit-linear-gradient(center top , #5DBCD9, #4CADCB));
  background:-moz-linear-gradient(center top , #5DBCD9, #4CADCB);
  background:-ms-linear-gradient(center top , #5DBCD9, #4CADCB));
  background:-o-linear-gradient(center top , #5DBCD9, #4CADCB));
  background:linear-gradient(center top , #5DBCD9, #4CADCB));
}
a.button:active,
.button:active {
  background:#1E799A;
  border:1px solid #30B7E6;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:bold;
  text-align:left;
  font-size:1.1em;
  background:#ffffff;
}
.table td {
  padding:8px 7px;
}
.table tr {
  border-bottom:1px solid #ccc;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#ec252e;
  padding:8px 14px;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}
.success {
  border:1px solid #399f16;
  color:#399f16;
  padding:8px 14px;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}
.message {
  border:1px solid #ccc;
  color:#717171;
  padding:8px 14px;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/snobbish.css
/* Skin "Snobbish" by Renat Rafikov */
html {
  overflow-x:hidden;
}
body {
  font-family:arial, sans-serif;
  color:#333;
}

a { color:#000; }
a:hover { color:#C40005; }
a:visited { color:#555; }

ul li, ol li {
  padding:0 0 0.4em 0;
}
.container {
  max-width:1300px;
  margin:0 auto;
}


.header {
  padding:2em 2% 2em 2%;
  border-top:4px solid #000000;
  border-bottom:2px solid #000000;
  position:relative;
}
.header:before {
  content:"";
  position:absolute;
  display:block!important;
  width:7000px;
  left:-3000px;
  top:-4px;
  height:70%;
  border-top:4px solid #000000;
  background: -moz-linear-gradient(top, rgba(188,188,188,0.65) 0%, rgba(228,228,228,0) 60%, rgba(255,255,255,0) 100%);
  background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(188,188,188,0.65)), color-stop(60%,rgba(228,228,228,0)), color-stop(100%,rgba(255,255,255,0)));
  background: -webkit-linear-gradient(top, rgba(188,188,188,0.65) 0%,rgba(228,228,228,0) 60%,rgba(255,255,255,0) 100%);
  background: -o-linear-gradient(top, rgba(188,188,188,0.65) 0%,rgba(228,228,228,0) 60%,rgba(255,255,255,0) 100%);
  background: -ms-linear-gradient(top, rgba(188,188,188,0.65) 0%,rgba(228,228,228,0) 60%,rgba(255,255,255,0) 100%);
  background: linear-gradient(top, rgba(188,188,188,0.65) 0%,rgba(228,228,228,0) 60%,rgba(255,255,255,0) 100%);
  z-index:-1;
}

.logo {
  float:left;
  display:inline-block;
  font-size:24px;
  color:#000;
  font-family:georgia, sans-serif;
  font-weight:bold;
}

.menu_main {
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
  font-family:'Helvetica Neue',Helvetica,Arial;
  font-weight:bold;
  font-size:18px;
}

.menu_main li {
  display:inline-block;
  padding:0 0 0 12px;
  margin:0 0 0 5px;
  border-left: 1px solid #B2B2B2;
}

.menu_main  li:first-child {
  border:0;
  padding-left:0;
  margin-left:0;
}

.menu_main a,
.menu_main a:visited {
  color:#000;
  text-decoration:none;
}

.menu_main a:hover,
.menu_main a:visited:hover {
  color:#f00;
}

.menu_main li.active,
.menu_main li.active a {
  color:#ACACAC;
  cursor:default;
}

.hero {
  padding:1em 0 0 2%;
  background:#333;
  color:#fff;
}

.hero a,
.hero a:visited {
  color:#fff;
}

.article {
  padding:0 0 2em 2%;
  border-left:1px solid #ccc;
  border-right:1px solid #ccc;
}

.footer {
  padding:2em 2% 3em 2%;
  color:#fff;
  background:#000;
  border-bottom:8px solid #313131;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-weight:bold;
  color:#4D4B4B;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
  font-weight:bold;
}

.menu_bottom li {
  display:inline-block;
  padding:0 0 0 12px;
  margin:0 0 0 5px;
  border-left: 1px solid #4D4D4D;
}

.menu_bottom  li:first-child {
  border:0;
  padding-left:0;
  margin-left:0;
}

.menu_bottom a,
.menu_bottom a:visited {
  color:#fff;
  text-decoration:none;
}

.menu_bottom a:hover,
.menu_bottom a:visited:hover {
  color:#ACACAC;
}

.menu_bottom li.active,
.menu_bottom li.active a {
  color:#BC0404;
  cursor:default;
}


.hero h1 {
  font-size: 23px;
  margin: 0.4em 0 0.5em;
  font-family:'Helvetica Neue',Helvetica,Arial;
  color:#fff;
  display:inline-block;
  border-bottom:1px dotted #fff;
  font-style:normal;
}

h1, h2 {
  font-weight:normal;
  color:#000;
  font-family:georgia, serif;
  font-style:italic;
  font-weight:bold;
}

h3, h4, h5, h6 {
  font-family:georgia, serif;
  font-style:italic;
  font-weight:bold;
  color:#000;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:0;
  text-align:center; 
  text-decoration:none;
  background:#c40005;
  color:#fff;
  padding:4px 14px;
  border-bottom:2px solid #000;
  border-bottom:2px solid rgba(0,0,0,0.8);
  font-family:verdana, sans-serif;
  display:inline-block;
}
a.button:hover,
.button:hover {
  background:#e12d32;
  color:#fff;  
}
a.button:active,
.button:active {
  color:#c8a5a5;
  background:#9c0004;
  border:0;
  margin-bottom:2px;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px dotted #666;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:8px 14px;
  background:#c40005;
  border-color:#c40005;
  position:relative;
  -webkit-box-shadow: #d1d1d1 6px 6px 10px;
  -moz-box-shadow: #d1d1d1 6px 6px 10px;
  box-shadow: #d1d1d1 6px 6px 10px;
}
.success {
  color:#000;
  background:#89BFDC;
  border-color:#89BFDC;
  padding:8px 14px;
  position:relative;
  -webkit-box-shadow: #d1d1d1 6px 6px 10px;
  -moz-box-shadow: #d1d1d1 6px 6px 10px;
  box-shadow: #d1d1d1 6px 6px 10px;
}
.message {
  color:#000;
  background:#eee;
  border-color:#eee;
  padding:8px 14px;
  position:relative;
  -webkit-box-shadow: #f4f4f4 6px 6px 10px;
  -moz-box-shadow: #f4f4f4 6px 6px 10px;
  box-shadow: #f4f4f4 6px 6px 10px;
}

.warning:before,
.success:before,
.message:before {
  content:"";
  display:block;
  width:0px;
  height:0px;
  position:absolute;
  bottom:-10px;
  left:14px;
  border-top: 10px solid black;
  border-top-color: inherit;
  border-left: 0px dotted transparent;
  border-right: 10px solid transparent;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/solution.css
/* Skin "Solution" by Renat Rafikov */
html {
  overflow-x:hidden;
}
body {
  font-family:arial, sans-serif;
  color:#000;
}

a { color:#85ccd3; }
a:hover { text-decoration:none; }
a:visited { color:#b769cd; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:0 0 2em 0;
  padding:0 2% 0 2%;
  border-top:10px solid #111111;
  position:relative;
}

.header:before {
  content:"";
  display:block;
  width:5000px;
  left:-2000px;
  top:-10px;
  border-top:10px solid #111111;
  position:absolute;
}

.logo {
  float:left;
  display:inline-block;
  padding:0.7em 11px 0.7em;
  font-size:18px;
  color:#fff;
  background:#111111;
  font-family:times new roman, serif;
  font-variant:small-caps;
  font-size:26px;
  -webkit-border-radius:0 0 7px 7px;
  -moz-border-radius:0 0 7px 7px;
  border-radius:0 0 7px 7px;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:1.7em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main a,
.menu_main a:visited {
  color:#b1b1b1;
}

.menu_main li.active,
.menu_main li.active a {
  color:#48c6d3;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.hero {
  border-bottom:1px solid #e5e5e5;
  margin:0 2% 0 0;
}

.footer {
  border-top:8px solid #111;
  padding:2em 2% 3em 2%;
  position:relative;
}
.footer:before {
  content:"";
  display:block;
  width:5000px;
  left:-2000px;
  top:-10px;
  border-top:10px solid #111111;
  position:absolute;
}

.copyright {
  width:49%;
  float:left;
  font-family:times new roman, serif;
  font-variant:small-caps;
  color:#b1b1b1;
  font-size:18px;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom a,
.menu_bottom a:visited {
  color:#b1b1b1;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#48c6d3;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:22px;
  border-top:1px solid #e5e5e5;
  border-bottom:1px solid #e5e5e5;
  padding:5px 0;
}

h1, h2 {
  font-family:tahoma, sans-serif;
  font-weight:normal;
  color:#000;
}

h3, h4, h5, h6 {
  font-family:tahoma, sans-serif;
  font-weight:bold;
  color:#000;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #969696;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:7px;
  -moz-border-radius:7px;
  border-radius:7px;
  -webkit-box-shadow:#fff 0px 1px 2px inset;
  -moz-box-shadow:#fff 0px 1px 2px inset;
  box-shadow:#fff 0px 1px 2px inset;
  color:#575757;
  padding:6px 10px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 0px #fff;
  display:inline-block;
  background: #CBCBCB;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#CBCBCB), to(#e5e5e5));
  background: -webkit-linear-gradient(#CBCBCB, #e5e5e5);
  background: -moz-linear-gradient(#CBCBCB, #e5e5e5);
  background: -ms-linear-gradient(#CBCBCB, #e5e5e5);
  background: -o-linear-gradient(#CBCBCB, #e5e5e5);
  background: linear-gradient(#CBCBCB, #e5e5e5);
}
a.button:hover,
.button:hover {
  color:#575757;  
  -webkit-box-shadow:#fff 0px 4px 2px inset;
  -moz-box-shadow:#fff 0px 4px 2px inset;
  box-shadow:#fff 0px 4px 2px inset;
  background: #E5E5E5;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#E5E5E5), to(#cbcbcb));
  background: -webkit-linear-gradient(#E5E5E5, #cbcbcb);
  background: -moz-linear-gradient(#E5E5E5, #cbcbcb);
  background: -ms-linear-gradient(#E5E5E5, #cbcbcb);
  background: -o-linear-gradient(#E5E5E5, #cbcbcb);
  background: linear-gradient(#E5E5E5, #cbcbcb);
}
a.button:active,
.button:active {
  color:#b4b4b4;
  text-shadow:1px 1px 0px #000000;
  background: #1E1E1E;
  -webkit-box-shadow:none;
  -moz-box-shadow:none;
  box-shadow:none;  
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#1E1E1E), to(#4f4f4f));
  background: -webkit-linear-gradient(#1E1E1E, #4f4f4f);
  background: -moz-linear-gradient(#1E1E1E, #4f4f4f);
  background: -ms-linear-gradient(#1E1E1E, #4f4f4f);
  background: -o-linear-gradient(#1E1E1E, #4f4f4f);
  background: linear-gradient(#1E1E1E, #4f4f4f);
  border:1px solid #171717;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:16px;
  background:#111;
  color:#fff;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #e5e5e5;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:2px solid #dc102d;
  color:#fff;
  padding:8px 14px;
  background:#ff2443;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:2px solid #3b8c1b;
  color:#fff;
  background:#56a637;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:2px solid #85ccd3;
  color:#85ccd3;
  background:#ecfbfd;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/stylus.css
/* Skin "Stylus" by Renat Rafikov */
html {
  background:#999;
}

body {
  font-family:arial, sans-serif;
  color:#333;
  
  background: -moz-linear-gradient(top,  rgba(255,255,255,0) 0%, rgba(255,255,255,0.7) 250px, rgba(255,255,255,0) 600px);
  background: -webkit-gradient(linear, left top, left 600px, color-stop(0%,rgba(255,255,255,0)), color-stop(250px,rgba(255,255,255,0.7)), color-stop(600px,rgba(255,255,255,0)));
  background: -webkit-linear-gradient(top,  rgba(255,255,255,0) 0%,rgba(255,255,255,0.7) 250px,rgba(255,255,255,0) 600px);
  background: -o-linear-gradient(top,  rgba(255,255,255,0) 0%,rgba(255,255,255,0.7) 250px,rgba(255,255,255,0) 600px);
  background: -ms-linear-gradient(top,  rgba(255,255,255,0) 0%,rgba(255,255,255,0.7) 250px,rgba(255,255,255,0) 600px);
  background: linear-gradient(top,  rgba(255,255,255,0) 0%,rgba(255,255,255,0.7) 250px,rgba(255,255,255,0) 600px);
}

a { color:#336699; }
a:hover { color:#ea0000; }
a:visited { color:#551a8b; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:0 0 1em 0;
  padding:1em 0 0 0;
}

.logo {
  padding:0 0 0.4em 0;
  font-size:24px;
  color:#333;
  font-weight:bold;
}

.menu_main {
  margin:0.3em 0 0 0;
  background-color:#dcdcdc;
  height:35px;
  background-image: -moz-linear-gradient(top, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0) 100%);
  background-image: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(255,255,255,0.4)), color-stop(100%,rgba(255,255,255,0)));
  background-image: -webkit-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -o-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -ms-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  -webkit-box-shadow:0 9px 5px -7px #777;
  -moz-box-shadow:0 9px 5px -7px #777;
  box-shadow:0 9px 5px -7px #777;
}
.menu_main a,
.menu_main a:visited {
  color:#333;
  text-decoration:none;
  display:inline-block;
  height:35px;
  line-height:35px;
  padding:0 44px 0 24px;
  font-weight:bold;
  border-right:1px solid #fff;
}
.menu_main a:hover,
.menu_main a:hover:visited {
  background:#666;
  color:#fff;
  text-decoration:underline;
}
.menu_main li {
  display:inline-block;
  float:left;
  padding:0;
}

.menu_main li.active a,
.menu_main li.active a:hover {
  color:#000;
  text-decoration:none;
  cursor:default;
  background:#d1d1d1;
  background: -moz-linear-gradient(top, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0) 100%);
  background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(0,0,0,0.1)), color-stop(100%,rgba(0,0,0,0)));
  background: -webkit-linear-gradient(top, rgba(0,0,0,0.1) 0%,rgba(0,0,0,0) 100%);
  background: -o-linear-gradient(top, rgba(0,0,0,0.1) 0%,rgba(0,0,0,0) 100%);
  background: -ms-linear-gradient(top, rgba(0,0,0,0.1) 0%,rgba(0,0,0,0) 100%);
  background: linear-gradient(top, rgba(0,0,0,0.1) 0%,rgba(0,0,0,0) 100%);
}


.info {
}

.hero {
  color:#111;
  padding:0 0 10px 2%;
}
.hero h1 {
  font-size:26px;
  color:#111;
}

.article {
  background:#f5f5f5;
  padding:0 2% 2em 2%;
  -webkit-box-shadow:#777 0 9px 5px -7px;
  -moz-box-shadow:#777 0 9px 5px -7px;
  box-shadow:#777 0 9px 5px -7px;
}

.footer {
  padding:4em 2% 1em 2%;
  color:#333;
}

.copyright {
  width:49%;
  float:left;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom a,
.menu_bottom a:visited {
  color:#333;
}
.menu_bottom a:hover,
.menu_bottom a:hover:visited {
  color:#000;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#333;
  text-decoration:none;
  cursor:default;
}

h1, h2 {
  font-weight:normal;
  color:#000;
}
h1 {
  font-size:22px;
}
h3, h4, h5, h6 {
  font-weight:bold;
  color:#000;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:2px;
  -moz-border-radius:2px;
  border-radius:2px;
  -webkit-box-shadow:rgba(0,0,0,0.9) 0 4px 3px -4px;
  -moz-box-shadow:rgba(0,0,0,0.9) 0 4px 3px -4px;
  box-shadow:rgba(0,0,0,0.9) 0 4px 3px -4px;
  background:#aec720;
  color:#fff;
  padding:7px 10px;
  font-family:verdana, sans-serif;
  display:inline-block;
  border:0;
}
a.button:hover,
.button:hover {
  color:#fff;
  background:#c1db2e;
}
a.button:active,
.button:active {
  background:#aec720;
  text-shadow:1px 1px 1px #8ca20f;
  -webkit-box-shadow:#8ca20f 0px -3px 3px inset;
  -moz-box-shadow:#8ca20f 0px -3px 3px inset;
  box-shadow:#8ca20f 0px -3px 3px inset;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #888;
}
.table tr:last-child {
  border:0;
}

.warning {
  color:#fff;
  padding:8px 14px;
  background-color:#af243b;
  background-image: -moz-linear-gradient(top, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0) 100%);
  background-image: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(255,255,255,0.4)), color-stop(100%,rgba(255,255,255,0)));
  background-image: -webkit-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -o-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -ms-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  -webkit-box-shadow:0 9px 5px -7px #999;
  -moz-box-shadow:0 9px 5px -7px #999;
  box-shadow:0 9px 5px -7px #999;
}
.success {
  color:#fff;
  background:#31b754;
  padding:8px 14px;
  background-image: -moz-linear-gradient(top, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0) 100%);
  background-image: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(255,255,255,0.4)), color-stop(100%,rgba(255,255,255,0)));
  background-image: -webkit-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -o-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -ms-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  -webkit-box-shadow:0 9px 5px -7px #999;
  -moz-box-shadow:0 9px 5px -7px #999;
  box-shadow:0 9px 5px -7px #999;
}
.message {
  color:#444;
  background:#f1b369;
  padding:8px 14px;
  background-image: -moz-linear-gradient(top, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0) 100%);
  background-image: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(255,255,255,0.4)), color-stop(100%,rgba(255,255,255,0)));
  background-image: -webkit-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -o-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: -ms-linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  background-image: linear-gradient(top, rgba(255,255,255,0.4) 0%,rgba(255,255,255,0) 100%);
  -webkit-box-shadow:0 9px 5px -7px #999;
  -moz-box-shadow:0 9px 5px -7px #999;
  box-shadow:0 9px 5px -7px #999;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .menu_main a {
    padding:7px 15px;
  }
  .menu_main li {
    float:none;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
  .menu_main {
    height:auto;
    overflow:hidden;
  }
  .menu_main a {
    border:0;
  }
}
#>>> copy text skin/teawithmilk.css
/* Skin "Tea with milk" by Renat Rafikov */
body {
  font-family:arial, sans-serif;
  color:#222;
  background:#f3f1e5;
}

a { color:#52a6c7; }
a:hover { color:#878787; }
a:visited { color:#9c52c7; }

ul li, ol li {
  padding:0 0 0.4em 0;
}


.container {
  max-width:1300px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
}

.logo {
  float:left;
  display:inline-block;
  font-size:22px;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  padding:0 0 0 7px;
  border-left:1px solid #222;
}
.menu_main li:first-child {
  border:0;
}
.menu_main a,
.menu_main a:visited {
  color:#222;
}
.menu_main li.active,
.menu_main li.active a {
  color:#8faf6c;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.hero {
  background:#fff;
  border:6px solid #f7f6ee;
  -webkit-box-shadow: rgba(0, 0, 0, 0.08) 0px 0px 8px;
  -moz-box-shadow: rgba(0, 0, 0, 0.08) 0px 0px 8px;
  box-shadow: rgba(0, 0, 0, 0.08) 0px 0px 8px;
  padding:5px 0 10px 2%;
  margin: 0 2% 0 0;
}

.footer {
  border-top:2px solid #f7f6ee;
  padding:2em 2% 3em 2%;
}

.copyright {
  width:49%;
  float:left;
  font-family:tahoma, sans-serif;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom a,
.menu_bottom a:visited {
  color:#222;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#8faf6c;
  text-decoration:none;
  cursor:default;
}


.hero h1 {
  font-size:29px;
}

h1, h2 {
  font-family:tahoma, sans-serif;
  font-weight:normal;
}

h3, h4, h5, h6 {
  font-family:tahoma, sans-serif;
  font-weight:bold;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #6aa12e;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:15px;
  -moz-border-radius:15px;
  border-radius:15px;
  -webkit-box-shadow:#e4ffc6 0px 2px 3px inset;
  -moz-box-shadow:#e4ffc6 0px 2px 3px inset;
  box-shadow:#e4ffc6 0px 2px 3px inset;
  background:#88bf4c;
  color:#e2eed6;
  padding:7px 15px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 0px #6aa12e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  -webkit-box-shadow:#e4ffc6 0px 1px 1px inset;
  -moz-box-shadow:#e4ffc6 0px 1px 1px inset;
  box-shadow:#e4ffc6 0px 1px 1px inset;
  background: -webkit-gradient(linear, 0 0, 0 bottom, from(#88bf4c), to(#B6DE8A));
  background: -webkit-linear-gradient(#88bf4c, #B6DE8A);
  background: -moz-linear-gradient(#88bf4c, #B6DE8A);
  background: -ms-linear-gradient(#88bf4c, #B6DE8A);
  background: -o-linear-gradient(#88bf4c, #B6DE8A);
  background: linear-gradient(#88bf4c, #B6DE8A);
}
a.button:active,
.button:active {
  color:#65982d;
  text-shadow:1px 1px 1px #b9e38c;
  -webkit-box-shadow:#ef420c 0px -3px 3px inset;
  -moz-box-shadow:#ef420c 0px -3px 3px inset;
  box-shadow:#ef420c 0px -3px 3px inset;
  -webkit-box-shadow:#53841e 0px 2px 3px inset;
  -moz-box-shadow:#53841e 0px 2px 3px inset;
  box-shadow:#53841e 0px 2px 3px inset;
  background:#88bf4c;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:bold;
  text-align:left;
}

.table td {
  padding:5px 7px;
}
.table tr {
  background:#eaeade;
}
.table tr:nth-child(even) {
  background:#f8f7f2;
}
.table tr:first-child {
  background:none;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#fff;
  padding:8px 14px;
  background:#bb5f5f;
  border:3px solid #b74545;
}
.success {
  color:#fff;
  background:#8faf6c;
  padding:8px 14px;
  border:3px solid #a9c987;  
}
.message {
  background:#f8f7f2;
  padding:8px 14px;
  border:3px solid #ece9d8;
}


@media only screen and (max-width:480px) { /* Smartphone custom styles */
  .header {
    padding:10px 0;
  }
}

@media only screen and (max-width:768px) { /* Tablet custom styles */
}
#>>> copy text skin/yellow.css
/* Skin "Modern Dark: Yellow" by Egor Kubasov. http://egorkubasov.ru */

/* Webfonts */
@import url(http://fonts.googleapis.com/css?family=Ubuntu:300,400,500,700,300italic,400italic,500italic,700italic|Lobster);
/* End Webfonts */

body {
  font-family:'Ubuntu';
  color:#d5d5d5;
  background:#131313;
}

a { color:#fff600; }
a:hover { color:#d5d5d5; }
a:visited { color:#fff600; }

ul li, ol li {
  padding:0 0 0.4em 0;
}

.container {
  max-width:900px;
  margin:0 auto;
}

.header {
  margin:1px 0 3em 0;
  padding:2em 2% 0 2%;
}

.logo {
  font-family:'Lobster';
  float:left;
  display:inline-block;
  padding:0 0 1em;
  border-bottom:1px solid #fff600;
  font-size:18px;
  color:#fff600;
}

.menu_main {
  width:50%;
  float:right;
  text-align:right;
  margin:0.3em 0 0 0;
}

.menu_main li {
  display:inline-block;
  margin:0 0 0 7px;
}

.menu_main li.active,
.menu_main li.active a {
  color:#fff600;
  text-decoration:none;
  cursor:default;
}

.info {
  padding:0 0 1em 2%;
}

.footer {
  border-top:1px solid #fff600;
  padding:2em 2% 3em 2%;
  color:#666;
}

.copyright {
  width:49%;
  float:left;
  font-family:georgia, serif;
  font-style:italic;
}

.menu_bottom {
  width:50%;
  float:right;
  text-align:right;
  margin:0;
  padding:0;
}
.menu_bottom li {
  display:inline-block;
  margin:0 0 0 7px;
}
.menu_bottom li.active,
.menu_bottom li.active a {
  color:#fff600;
  text-decoration:none;
  cursor:default;
}

.hero h1 {
  font-size:26px;
  font-family:'Lobster';
  font-style:normal;
  color:#fff600;
}

h1, h2 {
  font-weight:normal;
  color:#fff600;
}

h3, h4, h5, h6 {
  font-weight:bold;
  color:#fff600;
}

h1 {
  font-size:22px;
}

.form label {
  display:inline-block;
  padding:0 0 4px 0;
}

a.button,
.button {
  border:1px solid #fff600;
  text-align:center; 
  text-decoration:none;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  -webkit-box-shadow:#000 0px 0px 1px;
  -moz-box-shadow:#000 0px 0px 1px;
  box-shadow:#000 0px 0px 1px;
  background:#a39e0a;
  color:#fff;
  padding:12px 20px;
  font-family:verdana, sans-serif;
  text-shadow:1px 1px 1px #2e2e2e;
  display:inline-block;
}
a.button:hover,
.button:hover {
  color:#fff;  
  background:#d1ca05;
}
a.button:active,
.button:active {
  color:#181818;
  background: #767210;
}

.table {
  width:100%;
}
.table th {
  padding:5px 7px;
  font-weight:normal;
  text-align:left;
  font-size:1.2em;
  background:#2b2b2b;
  border:1px solid #ddd;
}
.table td {
  padding:5px 7px;
}
.table tr {
  border-bottom:1px solid #ddd;
}
.table tr:last-child {
  border:0;
}

.warning {
  border:1px solid #ec252e;
  color:#fff;
  padding:8px 14px;
  background:#291111;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.success {
  border:1px solid #399f16;
  color:#fff;
  background:#172113;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}
.message {
  border:1px solid #f1edcf;
  color:#878473;
  background:#2b2a28;
  padding:8px 14px;
  -webkit-border-radius:8px;
  -moz-border-radius:8px;
  border-radius:8px;
}

@media only screen and (max-width:480px) { /* Smartphone custom styles */
}


@media only screen and (max-width:768px) { /* Tablet custom styles*/
}
#>>> copy text xtensions/ie/ie.css
/* Skin styles for IE */

/*
  IE < 8 not supported by Simpliste skins. But you can manually fix some problems using the styles below. Either copy them into your style.css file or make links to ie.css file from your site pages.
  "/" is a hack used to apply styles to IE 7 and below.
*/

/* For IE 7 "inline-block" property has to be replaced with "inline" */
.menu_main li,
.menu_bottom li {
  /display:inline;
}

/* If you don't like the way headers' default styles look in IE 7 */
h1,h2,h3,h4,h5,h6 {
  /display:block; 
  /clear:both; 
  /margin:0.7em 0;
}

/* End skin styles for IE */
#>>> copy text xtensions/ie/pie/PIE.js
/*
PIE: CSS3 rendering for IE
Version 1.0beta5
http://css3pie.com
Dual-licensed for use under the Apache License Version 2.0 or the General Public License (GPL) Version 2.
*/
(function(){
var doc = document;var f=window.PIE;
if(!f){f=window.PIE={Q:"-pie-",nb:"Pie",La:"pie_",Ac:{TD:1,TH:1},cc:{TABLE:1,THEAD:1,TBODY:1,TFOOT:1,TR:1,INPUT:1,TEXTAREA:1,SELECT:1,OPTION:1,IMG:1,HR:1},fc:{A:1,INPUT:1,TEXTAREA:1,SELECT:1,BUTTON:1},Gd:{submit:1,button:1,reset:1},aa:function(){}};try{doc.execCommand("BackgroundImageCache",false,true)}catch(aa){}for(var X=4,Y=doc.createElement("div"),ca=Y.getElementsByTagName("i"),Z;Y.innerHTML="<!--[if gt IE "+ ++X+"]><i></i><![endif]--\>",ca[0];);f.V=X;if(X===6)f.Q=f.Q.replace(/^-/,"");f.Ba=doc.documentMode||
f.V;Y.innerHTML='<v:shape adj="1"/>';Z=Y.firstChild;Z.style.behavior="url(#default#VML)";f.zc=typeof Z.adj==="object";(function(){var a,b=0,c={};f.p={Za:function(d){if(!a){a=doc.createDocumentFragment();a.namespaces.add("css3vml","urn:schemas-microsoft-com:vml")}return a.createElement("css3vml:"+d)},Aa:function(d){return d&&d._pieId||(d._pieId="_"+ ++b)},Eb:function(d){var e,g,i,j,h=arguments;e=1;for(g=h.length;e<g;e++){j=h[e];for(i in j)if(j.hasOwnProperty(i))d[i]=j[i]}return d},Rb:function(d,e,
g){var i=c[d],j,h;if(i)Object.prototype.toString.call(i)==="[object Array]"?i.push([e,g]):e.call(g,i);else{h=c[d]=[[e,g]];j=new Image;j.onload=function(){i=c[d]={i:j.width,f:j.height};for(var k=0,n=h.length;k<n;k++)h[k][0].call(h[k][1],i);j.onload=null};j.src=d}}}})();f.Na={gc:function(a,b,c,d){function e(){k=i>=90&&i<270?b:0;n=i<180?c:0;l=b-k;q=c-n}function g(){for(;i<0;)i+=360;i%=360}var i=d.ra;d=d.zb;var j,h,k,n,l,q,s,m;if(d){d=d.coords(a,b,c);j=d.x;h=d.y}if(i){i=i.jd();g();e();if(!d){j=k;h=n}d=
f.Na.tc(j,h,i,l,q);a=d[0];d=d[1]}else if(d){a=b-j;d=c-h}else{j=h=a=0;d=c}s=a-j;m=d-h;if(i===void 0){i=!s?m<0?90:270:!m?s<0?180:0:-Math.atan2(m,s)/Math.PI*180;g();e()}return{ra:i,xc:j,yc:h,td:a,ud:d,Vd:k,Wd:n,rd:l,sd:q,kd:s,ld:m,rc:f.Na.dc(j,h,a,d)}},tc:function(a,b,c,d,e){if(c===0||c===180)return[d,b];else if(c===90||c===270)return[a,e];else{c=Math.tan(-c*Math.PI/180);a=c*a-b;b=-1/c;d=b*d-e;e=b-c;return[(d-a)/e,(c*d-b*a)/e]}},dc:function(a,b,c,d){a=c-a;b=d-b;return Math.abs(a===0?b:b===0?a:Math.sqrt(a*
a+b*b))}};f.ea=function(){this.Gb=[];this.oc={}};f.ea.prototype={ba:function(a){var b=f.p.Aa(a),c=this.oc,d=this.Gb;if(!(b in c)){c[b]=d.length;d.push(a)}},Ha:function(a){a=f.p.Aa(a);var b=this.oc;if(a&&a in b){delete this.Gb[b[a]];delete b[a]}},wa:function(){for(var a=this.Gb,b=a.length;b--;)a[b]&&a[b]()}};f.Oa=new f.ea;f.Oa.Qd=function(){var a=this;if(!a.Rd){setInterval(function(){a.wa()},250);a.Rd=1}};(function(){function a(){f.K.wa();window.detachEvent("onunload",a);window.PIE=null}f.K=new f.ea;
window.attachEvent("onunload",a);f.K.sa=function(b,c,d){b.attachEvent(c,d);this.ba(function(){b.detachEvent(c,d)})}})();f.Qa=new f.ea;f.K.sa(window,"onresize",function(){f.Qa.wa()});(function(){function a(){f.mb.wa()}f.mb=new f.ea;f.K.sa(window,"onscroll",a);f.Qa.ba(a)})();(function(){function a(){c=f.kb.md()}function b(){if(c){for(var d=0,e=c.length;d<e;d++)f.attach(c[d]);c=0}}var c;f.K.sa(window,"onbeforeprint",a);f.K.sa(window,"onafterprint",b)})();f.lb=new f.ea;f.K.sa(doc,"onmouseup",function(){f.lb.wa()});
f.ge=function(){function a(h){this.Y=h}var b=doc.createElement("length-calc"),c=doc.documentElement,d=b.style,e={},g=["mm","cm","in","pt","pc"],i=g.length,j={};d.position="absolute";d.top=d.left="-9999px";for(c.appendChild(b);i--;){b.style.width="100"+g[i];e[g[i]]=b.offsetWidth/100}c.removeChild(b);b.style.width="1em";a.prototype={Kb:/(px|em|ex|mm|cm|in|pt|pc|%)$/,ic:function(){var h=this.Id;if(h===void 0)h=this.Id=parseFloat(this.Y);return h},yb:function(){var h=this.$d;if(!h)h=this.$d=(h=this.Y.match(this.Kb))&&
h[0]||"px";return h},a:function(h,k){var n=this.ic(),l=this.yb();switch(l){case "px":return n;case "%":return n*(typeof k==="function"?k():k)/100;case "em":return n*this.xb(h);case "ex":return n*this.xb(h)/2;default:return n*e[l]}},xb:function(h){var k=h.currentStyle.fontSize,n,l;if(k.indexOf("px")>0)return parseFloat(k);else if(h.tagName in f.cc){l=this;n=h.parentNode;return f.n(k).a(n,function(){return l.xb(n)})}else{h.appendChild(b);k=b.offsetWidth;b.parentNode===h&&h.removeChild(b);return k}}};
f.n=function(h){return j[h]||(j[h]=new a(h))};return a}();f.Ja=function(){function a(e){this.X=e}var b=f.n("50%"),c={top:1,center:1,bottom:1},d={left:1,center:1,right:1};a.prototype={zd:function(){if(!this.ac){var e=this.X,g=e.length,i=f.v,j=i.pa,h=f.n("0");j=j.ma;h=["left",h,"top",h];if(g===1){e.push(new i.ob(j,"center"));g++}if(g===2){j&(e[0].k|e[1].k)&&e[0].d in c&&e[1].d in d&&e.push(e.shift());if(e[0].k&j)if(e[0].d==="center")h[1]=b;else h[0]=e[0].d;else if(e[0].W())h[1]=f.n(e[0].d);if(e[1].k&
j)if(e[1].d==="center")h[3]=b;else h[2]=e[1].d;else if(e[1].W())h[3]=f.n(e[1].d)}this.ac=h}return this.ac},coords:function(e,g,i){var j=this.zd(),h=j[1].a(e,g);e=j[3].a(e,i);return{x:j[0]==="right"?g-h:h,y:j[2]==="bottom"?i-e:e}}};return a}();f.Ka=function(){function a(b,c){this.i=b;this.f=c}a.prototype={a:function(b,c,d,e,g){var i=this.i,j=this.f,h=c/d;e=e/g;if(i==="contain"){i=e>h?c:d*e;j=e>h?c/e:d}else if(i==="cover"){i=e<h?c:d*e;j=e<h?c/e:d}else if(i==="auto"){j=j==="auto"?g:j.a(b,d);i=j*e}else{i=
i.a(b,c);j=j==="auto"?i/e:j.a(b,d)}return{i:i,f:j}}};a.Kc=new a("auto","auto");return a}();f.Ec=function(){function a(b){this.Y=b}a.prototype={Kb:/[a-z]+$/i,yb:function(){return this.ad||(this.ad=this.Y.match(this.Kb)[0].toLowerCase())},jd:function(){var b=this.Vc,c;if(b===undefined){b=this.yb();c=parseFloat(this.Y,10);b=this.Vc=b==="deg"?c:b==="rad"?c/Math.PI*180:b==="grad"?c/400*360:b==="turn"?c*360:0}return b}};return a}();f.Jc=function(){function a(c){this.Y=c}var b={};a.Pd=/\s*rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d+|\d*\.\d+)\s*\)\s*/;
a.Fb={aliceblue:"F0F8FF",antiquewhite:"FAEBD7",aqua:"0FF",aquamarine:"7FFFD4",azure:"F0FFFF",beige:"F5F5DC",bisque:"FFE4C4",black:"000",blanchedalmond:"FFEBCD",blue:"00F",blueviolet:"8A2BE2",brown:"A52A2A",burlywood:"DEB887",cadetblue:"5F9EA0",chartreuse:"7FFF00",chocolate:"D2691E",coral:"FF7F50",cornflowerblue:"6495ED",cornsilk:"FFF8DC",crimson:"DC143C",cyan:"0FF",darkblue:"00008B",darkcyan:"008B8B",darkgoldenrod:"B8860B",darkgray:"A9A9A9",darkgreen:"006400",darkkhaki:"BDB76B",darkmagenta:"8B008B",
darkolivegreen:"556B2F",darkorange:"FF8C00",darkorchid:"9932CC",darkred:"8B0000",darksalmon:"E9967A",darkseagreen:"8FBC8F",darkslateblue:"483D8B",darkslategray:"2F4F4F",darkturquoise:"00CED1",darkviolet:"9400D3",deeppink:"FF1493",deepskyblue:"00BFFF",dimgray:"696969",dodgerblue:"1E90FF",firebrick:"B22222",floralwhite:"FFFAF0",forestgreen:"228B22",fuchsia:"F0F",gainsboro:"DCDCDC",ghostwhite:"F8F8FF",gold:"FFD700",goldenrod:"DAA520",gray:"808080",green:"008000",greenyellow:"ADFF2F",honeydew:"F0FFF0",
hotpink:"FF69B4",indianred:"CD5C5C",indigo:"4B0082",ivory:"FFFFF0",khaki:"F0E68C",lavender:"E6E6FA",lavenderblush:"FFF0F5",lawngreen:"7CFC00",lemonchiffon:"FFFACD",lightblue:"ADD8E6",lightcoral:"F08080",lightcyan:"E0FFFF",lightgoldenrodyellow:"FAFAD2",lightgreen:"90EE90",lightgrey:"D3D3D3",lightpink:"FFB6C1",lightsalmon:"FFA07A",lightseagreen:"20B2AA",lightskyblue:"87CEFA",lightslategray:"789",lightsteelblue:"B0C4DE",lightyellow:"FFFFE0",lime:"0F0",limegreen:"32CD32",linen:"FAF0E6",magenta:"F0F",
maroon:"800000",mediumauqamarine:"66CDAA",mediumblue:"0000CD",mediumorchid:"BA55D3",mediumpurple:"9370D8",mediumseagreen:"3CB371",mediumslateblue:"7B68EE",mediumspringgreen:"00FA9A",mediumturquoise:"48D1CC",mediumvioletred:"C71585",midnightblue:"191970",mintcream:"F5FFFA",mistyrose:"FFE4E1",moccasin:"FFE4B5",navajowhite:"FFDEAD",navy:"000080",oldlace:"FDF5E6",olive:"808000",olivedrab:"688E23",orange:"FFA500",orangered:"FF4500",orchid:"DA70D6",palegoldenrod:"EEE8AA",palegreen:"98FB98",paleturquoise:"AFEEEE",
palevioletred:"D87093",papayawhip:"FFEFD5",peachpuff:"FFDAB9",peru:"CD853F",pink:"FFC0CB",plum:"DDA0DD",powderblue:"B0E0E6",purple:"800080",red:"F00",rosybrown:"BC8F8F",royalblue:"4169E1",saddlebrown:"8B4513",salmon:"FA8072",sandybrown:"F4A460",seagreen:"2E8B57",seashell:"FFF5EE",sienna:"A0522D",silver:"C0C0C0",skyblue:"87CEEB",slateblue:"6A5ACD",slategray:"708090",snow:"FFFAFA",springgreen:"00FF7F",steelblue:"4682B4",tan:"D2B48C",teal:"008080",thistle:"D8BFD8",tomato:"FF6347",turquoise:"40E0D0",
violet:"EE82EE",wheat:"F5DEB3",white:"FFF",whitesmoke:"F5F5F5",yellow:"FF0",yellowgreen:"9ACD32"};a.prototype={parse:function(){if(!this.Ua){var c=this.Y,d;if(d=c.match(a.Pd)){this.Ua="rgb("+d[1]+","+d[2]+","+d[3]+")";this.Yb=parseFloat(d[4])}else{if((d=c.toLowerCase())in a.Fb)c="#"+a.Fb[d];this.Ua=c;this.Yb=c==="transparent"?0:1}}},T:function(c){this.parse();return this.Ua==="currentColor"?c.currentStyle.color:this.Ua},fa:function(){this.parse();return this.Yb}};f.ha=function(c){return b[c]||(b[c]=
new a(c))};return a}();f.v=function(){function a(c){this.$a=c;this.ch=0;this.X=[];this.Ga=0}var b=a.pa={Ia:1,Wb:2,B:4,Lc:8,Xb:16,ma:32,J:64,na:128,oa:256,Ra:512,Tc:1024,URL:2048};a.ob=function(c,d){this.k=c;this.d=d};a.ob.prototype={Ca:function(){return this.k&b.J||this.k&b.na&&this.d==="0"},W:function(){return this.Ca()||this.k&b.Ra}};a.prototype={ce:/\s/,Jd:/^[\+\-]?(\d*\.)?\d+/,url:/^url\(\s*("([^"]*)"|'([^']*)'|([!#$%&*-~]*))\s*\)/i,nc:/^\-?[_a-z][\w-]*/i,Xd:/^("([^"]*)"|'([^']*)')/,Bd:/^#([\da-f]{6}|[\da-f]{3})/i,
ae:{px:b.J,em:b.J,ex:b.J,mm:b.J,cm:b.J,"in":b.J,pt:b.J,pc:b.J,deg:b.Ia,rad:b.Ia,grad:b.Ia},fd:{rgb:1,rgba:1,hsl:1,hsla:1},next:function(c){function d(q,s){q=new a.ob(q,s);if(!c){k.X.push(q);k.Ga++}return q}function e(){k.Ga++;return null}var g,i,j,h,k=this;if(this.Ga<this.X.length)return this.X[this.Ga++];for(;this.ce.test(this.$a.charAt(this.ch));)this.ch++;if(this.ch>=this.$a.length)return e();i=this.ch;g=this.$a.substring(this.ch);j=g.charAt(0);switch(j){case "#":if(h=g.match(this.Bd)){this.ch+=
h[0].length;return d(b.B,h[0])}break;case '"':case "'":if(h=g.match(this.Xd)){this.ch+=h[0].length;return d(b.Tc,h[2]||h[3]||"")}break;case "/":case ",":this.ch++;return d(b.oa,j);case "u":if(h=g.match(this.url)){this.ch+=h[0].length;return d(b.URL,h[2]||h[3]||h[4]||"")}}if(h=g.match(this.Jd)){j=h[0];this.ch+=j.length;if(g.charAt(j.length)==="%"){this.ch++;return d(b.Ra,j+"%")}if(h=g.substring(j.length).match(this.nc)){j+=h[0];this.ch+=h[0].length;return d(this.ae[h[0].toLowerCase()]||b.Lc,j)}return d(b.na,
j)}if(h=g.match(this.nc)){j=h[0];this.ch+=j.length;if(j.toLowerCase()in f.Jc.Fb||j==="currentColor"||j==="transparent")return d(b.B,j);if(g.charAt(j.length)==="("){this.ch++;if(j.toLowerCase()in this.fd){g=function(q){return q&&q.k&b.na};h=function(q){return q&&q.k&(b.na|b.Ra)};var n=function(q,s){return q&&q.d===s},l=function(){return k.next(1)};if((j.charAt(0)==="r"?h(l()):g(l()))&&n(l(),",")&&h(l())&&n(l(),",")&&h(l())&&(j==="rgb"||j==="hsa"||n(l(),",")&&g(l()))&&n(l(),")"))return d(b.B,this.$a.substring(i,
this.ch));return e()}return d(b.Xb,j)}return d(b.ma,j)}this.ch++;return d(b.Wb,j)},D:function(){return this.X[this.Ga-- -2]},all:function(){for(;this.next(););return this.X},la:function(c,d){for(var e=[],g,i;g=this.next();){if(c(g)){i=true;this.D();break}e.push(g)}return d&&!i?null:e}};return a}();var da=function(a){this.e=a};da.prototype={Z:0,Nd:function(){var a=this.qb,b;return!a||(b=this.o())&&(a.x!==b.x||a.y!==b.y)},Sd:function(){var a=this.qb,b;return!a||(b=this.o())&&(a.i!==b.i||a.f!==b.f)},
hc:function(){var a=this.e,b=a.getBoundingClientRect(),c=f.Ba===9;return{x:b.left,y:b.top,i:c?a.offsetWidth:b.right-b.left,f:c?a.offsetHeight:b.bottom-b.top}},o:function(){return this.Z?this.Va||(this.Va=this.hc()):this.hc()},Ad:function(){return!!this.qb},cb:function(){++this.Z},hb:function(){if(!--this.Z){if(this.Va)this.qb=this.Va;this.Va=null}}};(function(){function a(b){var c=f.p.Aa(b);return function(){if(this.Z){var d=this.$b||(this.$b={});return c in d?d[c]:(d[c]=b.call(this))}else return b.call(this)}}
f.C={Z:0,ja:function(b){function c(d){this.e=d;this.Zb=this.ia()}f.p.Eb(c.prototype,f.C,b);c.$c={};return c},j:function(){var b=this.ia(),c=this.constructor.$c;return b?b in c?c[b]:(c[b]=this.ka(b)):null},ia:a(function(){var b=this.e,c=this.constructor,d=b.style;b=b.currentStyle;var e=this.va,g=this.Fa,i=c.Yc||(c.Yc=f.Q+e);c=c.Zc||(c.Zc=f.nb+g.charAt(0).toUpperCase()+g.substring(1));return d[c]||b.getAttribute(i)||d[g]||b.getAttribute(e)}),h:a(function(){return!!this.j()}),G:a(function(){var b=this.ia(),
c=b!==this.Zb;this.Zb=b;return c}),ua:a,cb:function(){++this.Z},hb:function(){--this.Z||delete this.$b}}})();f.Sb=f.C.ja({va:f.Q+"background",Fa:f.nb+"Background",cd:{scroll:1,fixed:1,local:1},fb:{"repeat-x":1,"repeat-y":1,repeat:1,"no-repeat":1},sc:{"padding-box":1,"border-box":1,"content-box":1},Od:{top:1,right:1,bottom:1,left:1,center:1},Td:{contain:1,cover:1},eb:{Ma:"backgroundClip",B:"backgroundColor",da:"backgroundImage",Pa:"backgroundOrigin",R:"backgroundPosition",S:"backgroundRepeat",Sa:"backgroundSize"},
ka:function(a){function b(v){return v&&v.W()||v.k&k&&v.d in m}function c(v){return v&&(v.W()&&f.n(v.d)||v.d==="auto"&&"auto")}var d=this.e.currentStyle,e,g,i,j=f.v.pa,h=j.oa,k=j.ma,n=j.B,l,q,s=0,m=this.Od,r,p,t={L:[]};if(this.wb()){e=new f.v(a);for(i={};g=e.next();){l=g.k;q=g.d;if(!i.N&&l&j.Xb&&q==="linear-gradient"){r={ca:[],N:q};for(p={};g=e.next();){l=g.k;q=g.d;if(l&j.Wb&&q===")"){p.color&&r.ca.push(p);r.ca.length>1&&f.p.Eb(i,r);break}if(l&n){if(r.ra||r.zb){g=e.D();if(g.k!==h)break;e.next()}p=
{color:f.ha(q)};g=e.next();if(g.W())p.db=f.n(g.d);else e.D()}else if(l&j.Ia&&!r.ra&&!p.color&&!r.ca.length)r.ra=new f.Ec(g.d);else if(b(g)&&!r.zb&&!p.color&&!r.ca.length){e.D();r.zb=new f.Ja(e.la(function(v){return!b(v)},false))}else if(l&h&&q===","){if(p.color){r.ca.push(p);p={}}}else break}}else if(!i.N&&l&j.URL){i.Ab=q;i.N="image"}else if(b(g)&&!i.$){e.D();i.$=new f.Ja(e.la(function(v){return!b(v)},false))}else if(l&k)if(q in this.fb&&!i.bb)i.bb=q;else if(q in this.sc&&!i.Wa){i.Wa=q;if((g=e.next())&&
g.k&k&&g.d in this.sc)i.ub=g.d;else{i.ub=q;e.D()}}else if(q in this.cd&&!i.bc)i.bc=q;else return null;else if(l&n&&!t.color)t.color=f.ha(q);else if(l&h&&q==="/"&&!i.Xa&&i.$){g=e.next();if(g.k&k&&g.d in this.Td)i.Xa=new f.Ka(g.d);else if(g=c(g)){l=c(e.next());if(!l){l=g;e.D()}i.Xa=new f.Ka(g,l)}else return null}else if(l&h&&q===","&&i.N){i.Hb=a.substring(s,e.ch-1);s=e.ch;t.L.push(i);i={}}else return null}if(i.N){i.Hb=a.substring(s);t.L.push(i)}}else this.Bc(f.Ba<9?function(){var v=this.eb,o=d[v.R+
"X"],u=d[v.R+"Y"],x=d[v.da],y=d[v.B];if(y!=="transparent")t.color=f.ha(y);if(x!=="none")t.L=[{N:"image",Ab:(new f.v(x)).next().d,bb:d[v.S],$:new f.Ja((new f.v(o+" "+u)).all())}]}:function(){var v=this.eb,o=/\s*,\s*/,u=d[v.da].split(o),x=d[v.B],y,z,D,G,E,B;if(x!=="transparent")t.color=f.ha(x);if((G=u.length)&&u[0]!=="none"){x=d[v.S].split(o);y=d[v.R].split(o);z=d[v.Pa].split(o);D=d[v.Ma].split(o);v=d[v.Sa].split(o);t.L=[];for(o=0;o<G;o++)if((E=u[o])&&E!=="none"){B=v[o].split(" ");t.L.push({Hb:E+" "+
x[o]+" "+y[o]+" / "+v[o]+" "+z[o]+" "+D[o],N:"image",Ab:(new f.v(E)).next().d,bb:x[o],$:new f.Ja((new f.v(y[o])).all()),Wa:z[o],ub:D[o],Xa:new f.Ka(B[0],B[1])})}}});return t.color||t.L[0]?t:null},Bc:function(a){var b=f.Ba>8,c=this.eb,d=this.e.runtimeStyle,e=d[c.da],g=d[c.B],i=d[c.S],j,h,k,n;if(e)d[c.da]="";if(g)d[c.B]="";if(i)d[c.S]="";if(b){j=d[c.Ma];h=d[c.Pa];n=d[c.R];k=d[c.Sa];if(j)d[c.Ma]="";if(h)d[c.Pa]="";if(n)d[c.R]="";if(k)d[c.Sa]=""}a=a.call(this);if(e)d[c.da]=e;if(g)d[c.B]=g;if(i)d[c.S]=
i;if(b){if(j)d[c.Ma]=j;if(h)d[c.Pa]=h;if(n)d[c.R]=n;if(k)d[c.Sa]=k}return a},ia:f.C.ua(function(){return this.wb()||this.Bc(function(){var a=this.e.currentStyle,b=this.eb;return a[b.B]+" "+a[b.da]+" "+a[b.S]+" "+a[b.R+"X"]+" "+a[b.R+"Y"]})}),wb:f.C.ua(function(){var a=this.e;return a.style[this.Fa]||a.currentStyle.getAttribute(this.va)}),qc:function(){var a=0;if(f.V<7){a=this.e;a=""+(a.style[f.nb+"PngFix"]||a.currentStyle.getAttribute(f.Q+"png-fix"))==="true"}return a},h:f.C.ua(function(){return(this.wb()||
this.qc())&&!!this.j()})});f.Vb=f.C.ja({wc:["Top","Right","Bottom","Left"],Hd:{thin:"1px",medium:"3px",thick:"5px"},ka:function(){var a={},b={},c={},d=false,e=true,g=true,i=true;this.Cc(function(){for(var j=this.e.currentStyle,h=0,k,n,l,q,s,m,r;h<4;h++){l=this.wc[h];r=l.charAt(0).toLowerCase();k=b[r]=j["border"+l+"Style"];n=j["border"+l+"Color"];l=j["border"+l+"Width"];if(h>0){if(k!==q)g=false;if(n!==s)e=false;if(l!==m)i=false}q=k;s=n;m=l;c[r]=f.ha(n);l=a[r]=f.n(b[r]==="none"?"0":this.Hd[l]||l);if(l.a(this.e)>
0)d=true}});return d?{I:a,Yd:b,gd:c,de:i,hd:e,Zd:g}:null},ia:f.C.ua(function(){var a=this.e,b=a.currentStyle,c;a.tagName in f.Ac&&a.offsetParent.currentStyle.borderCollapse==="collapse"||this.Cc(function(){c=b.borderWidth+"|"+b.borderStyle+"|"+b.borderColor});return c}),Cc:function(a){var b=this.e.runtimeStyle,c=b.borderWidth,d=b.borderColor;if(c)b.borderWidth="";if(d)b.borderColor="";a=a.call(this);if(c)b.borderWidth=c;if(d)b.borderColor=d;return a}});(function(){f.jb=f.C.ja({va:"border-radius",
Fa:"borderRadius",ka:function(b){var c=null,d,e,g,i,j=false;if(b){e=new f.v(b);var h=function(){for(var k=[],n;(g=e.next())&&g.W();){i=f.n(g.d);n=i.ic();if(n<0)return null;if(n>0)j=true;k.push(i)}return k.length>0&&k.length<5?{tl:k[0],tr:k[1]||k[0],br:k[2]||k[0],bl:k[3]||k[1]||k[0]}:null};if(b=h()){if(g){if(g.k&f.v.pa.oa&&g.d==="/")d=h()}else d=b;if(j&&b&&d)c={x:b,y:d}}}return c}});var a=f.n("0");a={tl:a,tr:a,br:a,bl:a};f.jb.Dc={x:a,y:a}})();f.Ub=f.C.ja({va:"border-image",Fa:"borderImage",fb:{stretch:1,
round:1,repeat:1,space:1},ka:function(a){var b=null,c,d,e,g,i,j,h=0,k=f.v.pa,n=k.ma,l=k.na,q=k.Ra;if(a){c=new f.v(a);b={};for(var s=function(p){return p&&p.k&k.oa&&p.d==="/"},m=function(p){return p&&p.k&n&&p.d==="fill"},r=function(){g=c.la(function(p){return!(p.k&(l|q))});if(m(c.next())&&!b.fill)b.fill=true;else c.D();if(s(c.next())){h++;i=c.la(function(p){return!p.W()&&!(p.k&n&&p.d==="auto")});if(s(c.next())){h++;j=c.la(function(p){return!p.Ca()})}}else c.D()};a=c.next();){d=a.k;e=a.d;if(d&(l|q)&&
!g){c.D();r()}else if(m(a)&&!b.fill){b.fill=true;r()}else if(d&n&&this.fb[e]&&!b.repeat){b.repeat={f:e};if(a=c.next())if(a.k&n&&this.fb[a.d])b.repeat.Ob=a.d;else c.D()}else if(d&k.URL&&!b.src)b.src=e;else return null}if(!b.src||!g||g.length<1||g.length>4||i&&i.length>4||h===1&&i.length<1||j&&j.length>4||h===2&&j.length<1)return null;if(!b.repeat)b.repeat={f:"stretch"};if(!b.repeat.Ob)b.repeat.Ob=b.repeat.f;a=function(p,t){return{t:t(p[0]),r:t(p[1]||p[0]),b:t(p[2]||p[0]),l:t(p[3]||p[1]||p[0])}};b.slice=
a(g,function(p){return f.n(p.k&l?p.d+"px":p.d)});if(i&&i[0])b.I=a(i,function(p){return p.W()?f.n(p.d):p.d});if(j&&j[0])b.Da=a(j,function(p){return p.Ca()?f.n(p.d):p.d})}return b}});f.Ic=f.C.ja({va:"box-shadow",Fa:"boxShadow",ka:function(a){var b,c=f.n,d=f.v.pa,e;if(a){e=new f.v(a);b={Da:[],Bb:[]};for(a=function(){for(var g,i,j,h,k,n;g=e.next();){j=g.d;i=g.k;if(i&d.oa&&j===",")break;else if(g.Ca()&&!k){e.D();k=e.la(function(l){return!l.Ca()})}else if(i&d.B&&!h)h=j;else if(i&d.ma&&j==="inset"&&!n)n=
true;else return false}g=k&&k.length;if(g>1&&g<5){(n?b.Bb:b.Da).push({ee:c(k[0].d),fe:c(k[1].d),blur:c(k[2]?k[2].d:"0"),Ud:c(k[3]?k[3].d:"0"),color:f.ha(h||"currentColor")});return true}return false};a(););}return b&&(b.Bb.length||b.Da.length)?b:null}});f.Uc=f.C.ja({ia:f.C.ua(function(){var a=this.e.currentStyle;return a.visibility+"|"+a.display}),ka:function(){var a=this.e,b=a.runtimeStyle;a=a.currentStyle;var c=b.visibility,d;b.visibility="";d=a.visibility;b.visibility=c;return{be:d!=="hidden",
nd:a.display!=="none"}},h:function(){return false}});f.u={P:function(a){function b(c,d,e,g){this.e=c;this.s=d;this.g=e;this.parent=g}f.p.Eb(b.prototype,f.u,a);return b},Cb:false,O:function(){return false},Ea:f.aa,Lb:function(){this.m();this.h()&&this.U()},ib:function(){this.Cb=true},Mb:function(){this.h()?this.U():this.m()},sb:function(a,b){this.vc(a);for(var c=this.qa||(this.qa=[]),d=a+1,e=c.length,g;d<e;d++)if(g=c[d])break;c[a]=b;this.H().insertBefore(b,g||null)},ya:function(a){var b=this.qa;return b&&
b[a]||null},vc:function(a){var b=this.ya(a),c=this.Ta;if(b&&c){c.removeChild(b);this.qa[a]=null}},za:function(a,b,c,d){var e=this.rb||(this.rb={}),g=e[a];if(!g){g=e[a]=f.p.Za("shape");if(b)g.appendChild(g[b]=f.p.Za(b));if(d){c=this.ya(d);if(!c){this.sb(d,doc.createElement("group"+d));c=this.ya(d)}}c.appendChild(g);a=g.style;a.position="absolute";a.left=a.top=0;a.behavior="url(#default#VML)"}return g},vb:function(a){var b=this.rb,c=b&&b[a];if(c){c.parentNode.removeChild(c);delete b[a]}return!!c},kc:function(a){var b=
this.e,c=this.s.o(),d=c.i,e=c.f,g,i,j,h,k,n;c=a.x.tl.a(b,d);g=a.y.tl.a(b,e);i=a.x.tr.a(b,d);j=a.y.tr.a(b,e);h=a.x.br.a(b,d);k=a.y.br.a(b,e);n=a.x.bl.a(b,d);a=a.y.bl.a(b,e);d=Math.min(d/(c+i),e/(j+k),d/(n+h),e/(g+a));if(d<1){c*=d;g*=d;i*=d;j*=d;h*=d;k*=d;n*=d;a*=d}return{x:{tl:c,tr:i,br:h,bl:n},y:{tl:g,tr:j,br:k,bl:a}}},xa:function(a,b,c){b=b||1;var d,e,g=this.s.o();e=g.i*b;g=g.f*b;var i=this.g.F,j=Math.floor,h=Math.ceil,k=a?a.Jb*b:0,n=a?a.Ib*b:0,l=a?a.tb*b:0;a=a?a.Db*b:0;var q,s,m,r,p;if(c||i.h()){d=
this.kc(c||i.j());c=d.x.tl*b;i=d.y.tl*b;q=d.x.tr*b;s=d.y.tr*b;m=d.x.br*b;r=d.y.br*b;p=d.x.bl*b;b=d.y.bl*b;e="m"+j(a)+","+j(i)+"qy"+j(c)+","+j(k)+"l"+h(e-q)+","+j(k)+"qx"+h(e-n)+","+j(s)+"l"+h(e-n)+","+h(g-r)+"qy"+h(e-m)+","+h(g-l)+"l"+j(p)+","+h(g-l)+"qx"+j(a)+","+h(g-b)+" x e"}else e="m"+j(a)+","+j(k)+"l"+h(e-n)+","+j(k)+"l"+h(e-n)+","+h(g-l)+"l"+j(a)+","+h(g-l)+"xe";return e},H:function(){var a=this.parent.ya(this.M),b;if(!a){a=doc.createElement(this.Ya);b=a.style;b.position="absolute";b.top=b.left=
0;this.parent.sb(this.M,a)}return a},mc:function(){var a=this.e,b=a.currentStyle,c=a.runtimeStyle,d=a.tagName,e=f.V===6,g;if(e&&(d in f.cc||d==="FIELDSET")||d==="BUTTON"||d==="INPUT"&&a.type in f.Gd){c.borderWidth="";d=this.g.z.wc;for(g=d.length;g--;){e=d[g];c["padding"+e]="";c["padding"+e]=f.n(b["padding"+e]).a(a)+f.n(b["border"+e+"Width"]).a(a)+(f.V!==8&&g%2?1:0)}c.borderWidth=0}else if(e){if(a.childNodes.length!==1||a.firstChild.tagName!=="ie6-mask"){b=doc.createElement("ie6-mask");d=b.style;d.visibility=
"visible";for(d.zoom=1;d=a.firstChild;)b.appendChild(d);a.appendChild(b);c.visibility="hidden"}}else c.borderColor="transparent"},he:function(){},m:function(){this.parent.vc(this.M);delete this.rb;delete this.qa}};f.Rc=f.u.P({h:function(){var a=this.ed;for(var b in a)if(a.hasOwnProperty(b)&&a[b].h())return true;return false},O:function(){return this.g.Pb.G()},ib:function(){if(this.h()){var a=this.jc(),b=a,c;a=a.currentStyle;var d=a.position,e=this.H().style,g=0,i=0;i=this.s.o();if(d==="fixed"&&f.V>
6){g=i.x;i=i.y;b=d}else{do b=b.offsetParent;while(b&&b.currentStyle.position==="static");if(b){c=b.getBoundingClientRect();b=b.currentStyle;g=i.x-c.left-(parseFloat(b.borderLeftWidth)||0);i=i.y-c.top-(parseFloat(b.borderTopWidth)||0)}else{b=doc.documentElement;g=i.x+b.scrollLeft-b.clientLeft;i=i.y+b.scrollTop-b.clientTop}b="absolute"}e.position=b;e.left=g;e.top=i;e.zIndex=d==="static"?-1:a.zIndex;this.Cb=true}},Mb:f.aa,Nb:function(){var a=this.g.Pb.j();this.H().style.display=a.be&&a.nd?"":"none"},
Lb:function(){this.h()?this.Nb():this.m()},jc:function(){var a=this.e;return a.tagName in f.Ac?a.offsetParent:a},H:function(){var a=this.Ta,b;if(!a){b=this.jc();a=this.Ta=doc.createElement("css3-container");a.style.direction="ltr";this.Nb();b.parentNode.insertBefore(a,b)}return a},ab:f.aa,m:function(){var a=this.Ta,b;if(a&&(b=a.parentNode))b.removeChild(a);delete this.Ta;delete this.qa}});f.Fc=f.u.P({M:2,Ya:"background",O:function(){var a=this.g;return a.w.G()||a.F.G()},h:function(){var a=this.g;
return a.q.h()||a.F.h()||a.w.h()||a.ga.h()&&a.ga.j().Bb},U:function(){var a=this.s.o();if(a.i&&a.f){this.od();this.pd()}},od:function(){var a=this.g.w.j(),b=this.s.o(),c=this.e,d=a&&a.color,e,g;if(d&&d.fa()>0){this.lc();a=this.za("bgColor","fill",this.H(),1);e=b.i;b=b.f;a.stroked=false;a.coordsize=e*2+","+b*2;a.coordorigin="1,1";a.path=this.xa(null,2);g=a.style;g.width=e;g.height=b;a.fill.color=d.T(c);c=d.fa();if(c<1)a.fill.opacity=c}else this.vb("bgColor")},pd:function(){var a=this.g.w.j(),b=this.s.o();
a=a&&a.L;var c,d,e,g,i;if(a){this.lc();d=b.i;e=b.f;for(i=a.length;i--;){b=a[i];c=this.za("bgImage"+i,"fill",this.H(),2);c.stroked=false;c.fill.type="tile";c.fillcolor="none";c.coordsize=d*2+","+e*2;c.coordorigin="1,1";c.path=this.xa(0,2);g=c.style;g.width=d;g.height=e;if(b.N==="linear-gradient")this.bd(c,b);else{c.fill.src=b.Ab;this.Md(c,i)}}}for(i=a?a.length:0;this.vb("bgImage"+i++););},Md:function(a,b){var c=this;f.p.Rb(a.fill.src,function(d){var e=c.e,g=c.s.o(),i=g.i;g=g.f;if(i&&g){var j=a.fill,
h=c.g,k=h.z.j(),n=k&&k.I;k=n?n.t.a(e):0;var l=n?n.r.a(e):0,q=n?n.b.a(e):0;n=n?n.l.a(e):0;h=h.w.j().L[b];e=h.$?h.$.coords(e,i-d.i-n-l,g-d.f-k-q):{x:0,y:0};h=h.bb;q=l=0;var s=i+1,m=g+1,r=f.V===8?0:1;n=Math.round(e.x)+n+0.5;k=Math.round(e.y)+k+0.5;j.position=n/i+","+k/g;if(h&&h!=="repeat"){if(h==="repeat-x"||h==="no-repeat"){l=k+1;m=k+d.f+r}if(h==="repeat-y"||h==="no-repeat"){q=n+1;s=n+d.i+r}a.style.clip="rect("+l+"px,"+s+"px,"+m+"px,"+q+"px)"}}})},bd:function(a,b){var c=this.e,d=this.s.o(),e=d.i,g=
d.f;a=a.fill;d=b.ca;var i=d.length,j=Math.PI,h=f.Na,k=h.tc,n=h.dc;b=h.gc(c,e,g,b);h=b.ra;var l=b.xc,q=b.yc,s=b.Vd,m=b.Wd,r=b.rd,p=b.sd,t=b.kd,v=b.ld;b=b.rc;e=h%90?Math.atan2(t*e/g,v)/j*180:h+90;e+=180;e%=360;r=k(s,m,h,r,p);g=n(s,m,r[0],r[1]);j=[];r=k(l,q,h,s,m);n=n(l,q,r[0],r[1])/g*100;k=[];for(h=0;h<i;h++)k.push(d[h].db?d[h].db.a(c,b):h===0?0:h===i-1?b:null);for(h=1;h<i;h++){if(k[h]===null){l=k[h-1];b=h;do q=k[++b];while(q===null);k[h]=l+(q-l)/(b-h+1)}k[h]=Math.max(k[h],k[h-1])}for(h=0;h<i;h++)j.push(n+
k[h]/g*100+"% "+d[h].color.T(c));a.angle=e;a.type="gradient";a.method="sigma";a.color=d[0].color.T(c);a.color2=d[i-1].color.T(c);if(a.colors)a.colors.value=j.join(",");else a.colors=j.join(",")},lc:function(){var a=this.e.runtimeStyle;a.backgroundImage="url(about:blank)";a.backgroundColor="transparent"},m:function(){f.u.m.call(this);var a=this.e.runtimeStyle;a.backgroundImage=a.backgroundColor=""}});f.Gc=f.u.P({M:4,Ya:"border",O:function(){var a=this.g;return a.z.G()||a.F.G()},h:function(){var a=
this.g;return(a.F.h()||a.w.h())&&!a.q.h()&&a.z.h()},U:function(){var a=this.e,b=this.g.z.j(),c=this.s.o(),d=c.i;c=c.f;var e,g,i,j,h;if(b){this.mc();b=this.wd(2);j=0;for(h=b.length;j<h;j++){i=b[j];e=this.za("borderPiece"+j,i.stroke?"stroke":"fill",this.H());e.coordsize=d*2+","+c*2;e.coordorigin="1,1";e.path=i.path;g=e.style;g.width=d;g.height=c;e.filled=!!i.fill;e.stroked=!!i.stroke;if(i.stroke){e=e.stroke;e.weight=i.Qb+"px";e.color=i.color.T(a);e.dashstyle=i.stroke==="dashed"?"2 2":i.stroke==="dotted"?
"1 1":"solid";e.linestyle=i.stroke==="double"&&i.Qb>2?"ThinThin":"Single"}else e.fill.color=i.fill.T(a)}for(;this.vb("borderPiece"+j++););}},wd:function(a){var b=this.e,c,d,e,g=this.g.z,i=[],j,h,k,n,l=Math.round,q,s,m;if(g.h()){c=g.j();g=c.I;s=c.Yd;m=c.gd;if(c.de&&c.Zd&&c.hd){if(m.t.fa()>0){c=g.t.a(b);k=c/2;i.push({path:this.xa({Jb:k,Ib:k,tb:k,Db:k},a),stroke:s.t,color:m.t,Qb:c})}}else{a=a||1;c=this.s.o();d=c.i;e=c.f;c=l(g.t.a(b));k=l(g.r.a(b));n=l(g.b.a(b));b=l(g.l.a(b));var r={t:c,r:k,b:n,l:b};
b=this.g.F;if(b.h())q=this.kc(b.j());j=Math.floor;h=Math.ceil;var p=function(o,u){return q?q[o][u]:0},t=function(o,u,x,y,z,D){var G=p("x",o),E=p("y",o),B=o.charAt(1)==="r";o=o.charAt(0)==="b";return G>0&&E>0?(D?"al":"ae")+(B?h(d-G):j(G))*a+","+(o?h(e-E):j(E))*a+","+(j(G)-u)*a+","+(j(E)-x)*a+","+y*65535+","+2949075*(z?1:-1):(D?"m":"l")+(B?d-u:u)*a+","+(o?e-x:x)*a},v=function(o,u,x,y){var z=o==="t"?j(p("x","tl"))*a+","+h(u)*a:o==="r"?h(d-u)*a+","+j(p("y","tr"))*a:o==="b"?h(d-p("x","br"))*a+","+j(e-
u)*a:j(u)*a+","+h(e-p("y","bl"))*a;o=o==="t"?h(d-p("x","tr"))*a+","+h(u)*a:o==="r"?h(d-u)*a+","+h(e-p("y","br"))*a:o==="b"?j(p("x","bl"))*a+","+j(e-u)*a:j(u)*a+","+j(p("y","tl"))*a;return x?(y?"m"+o:"")+"l"+z:(y?"m"+z:"")+"l"+o};b=function(o,u,x,y,z,D){var G=o==="l"||o==="r",E=r[o],B,A;if(E>0&&s[o]!=="none"&&m[o].fa()>0){B=r[G?o:u];u=r[G?u:o];A=r[G?o:x];x=r[G?x:o];if(s[o]==="dashed"||s[o]==="dotted"){i.push({path:t(y,B,u,D+45,0,1)+t(y,0,0,D,1,0),fill:m[o]});i.push({path:v(o,E/2,0,1),stroke:s[o],Qb:E,
color:m[o]});i.push({path:t(z,A,x,D,0,1)+t(z,0,0,D-45,1,0),fill:m[o]})}else i.push({path:t(y,B,u,D+45,0,1)+v(o,E,0,0)+t(z,A,x,D,0,0)+(s[o]==="double"&&E>2?t(z,A-j(A/3),x-j(x/3),D-45,1,0)+v(o,h(E/3*2),1,0)+t(y,B-j(B/3),u-j(u/3),D,1,0)+"x "+t(y,j(B/3),j(u/3),D+45,0,1)+v(o,j(E/3),1,0)+t(z,j(A/3),j(x/3),D,0,0):"")+t(z,0,0,D-45,1,0)+v(o,0,1,0)+t(y,0,0,D,1,0),fill:m[o]})}};b("t","l","r","tl","tr",90);b("r","t","b","tr","br",0);b("b","r","l","br","bl",-90);b("l","b","t","bl","tl",-180)}}return i},m:function(){if(this.ec||
!this.g.q.h())this.e.runtimeStyle.borderColor="";f.u.m.call(this)}});f.Tb=f.u.P({M:5,Ld:["t","tr","r","br","b","bl","l","tl","c"],O:function(){return this.g.q.G()},h:function(){return this.g.q.h()},U:function(){this.H();var a=this.g.q.j(),b=this.g.z.j(),c=this.s.o(),d=this.e,e=this.uc;f.p.Rb(a.src,function(g){function i(v,o,u,x,y){v=e[v].style;var z=Math.max;v.width=z(o,0);v.height=z(u,0);v.left=x;v.top=y}function j(v,o,u){for(var x=0,y=v.length;x<y;x++)e[v[x]].imagedata[o]=u}var h=c.i,k=c.f,n=f.n("0"),
l=a.I||(b?b.I:{t:n,r:n,b:n,l:n});n=l.t.a(d);var q=l.r.a(d),s=l.b.a(d);l=l.l.a(d);var m=a.slice,r=m.t.a(d),p=m.r.a(d),t=m.b.a(d);m=m.l.a(d);i("tl",l,n,0,0);i("t",h-l-q,n,l,0);i("tr",q,n,h-q,0);i("r",q,k-n-s,h-q,n);i("br",q,s,h-q,k-s);i("b",h-l-q,s,l,k-s);i("bl",l,s,0,k-s);i("l",l,k-n-s,0,n);i("c",h-l-q,k-n-s,l,n);j(["tl","t","tr"],"cropBottom",(g.f-r)/g.f);j(["tl","l","bl"],"cropRight",(g.i-m)/g.i);j(["bl","b","br"],"cropTop",(g.f-t)/g.f);j(["tr","r","br"],"cropLeft",(g.i-p)/g.i);j(["l","r","c"],"cropTop",
r/g.f);j(["l","r","c"],"cropBottom",t/g.f);j(["t","b","c"],"cropLeft",m/g.i);j(["t","b","c"],"cropRight",p/g.i);e.c.style.display=a.fill?"":"none"},this)},H:function(){var a=this.parent.ya(this.M),b,c,d,e=this.Ld,g=e.length;if(!a){a=doc.createElement("border-image");b=a.style;b.position="absolute";this.uc={};for(d=0;d<g;d++){c=this.uc[e[d]]=f.p.Za("rect");c.appendChild(f.p.Za("imagedata"));b=c.style;b.behavior="url(#default#VML)";b.position="absolute";b.top=b.left=0;c.imagedata.src=this.g.q.j().src;
c.stroked=false;c.filled=false;a.appendChild(c)}this.parent.sb(this.M,a)}return a},Ea:function(){if(this.h()){var a=this.e,b=a.runtimeStyle,c=this.g.q.j().I;b.borderStyle="solid";if(c){b.borderTopWidth=c.t.a(a)+"px";b.borderRightWidth=c.r.a(a)+"px";b.borderBottomWidth=c.b.a(a)+"px";b.borderLeftWidth=c.l.a(a)+"px"}this.mc()}},m:function(){var a=this.e.runtimeStyle;a.borderStyle="";if(this.ec||!this.g.z.h())a.borderColor=a.borderWidth="";f.u.m.call(this)}});f.Hc=f.u.P({M:1,Ya:"outset-box-shadow",O:function(){var a=
this.g;return a.ga.G()||a.F.G()},h:function(){var a=this.g.ga;return a.h()&&a.j().Da[0]},U:function(){function a(B,A,L,N,H,I,F){B=b.za("shadow"+B+A,"fill",d,i-B);A=B.fill;B.coordsize=n*2+","+l*2;B.coordorigin="1,1";B.stroked=false;B.filled=true;A.color=H.T(c);if(I){A.type="gradienttitle";A.color2=A.color;A.opacity=0}B.path=F;p=B.style;p.left=L;p.top=N;p.width=n;p.height=l;return B}var b=this,c=this.e,d=this.H(),e=this.g,g=e.ga.j().Da;e=e.F.j();var i=g.length,j=i,h,k=this.s.o(),n=k.i,l=k.f;k=f.V===
8?1:0;for(var q=["tl","tr","br","bl"],s,m,r,p,t,v,o,u,x,y,z,D,G,E;j--;){m=g[j];t=m.ee.a(c);v=m.fe.a(c);h=m.Ud.a(c);o=m.blur.a(c);m=m.color;u=-h-o;if(!e&&o)e=f.jb.Dc;u=this.xa({Jb:u,Ib:u,tb:u,Db:u},2,e);if(o){x=(h+o)*2+n;y=(h+o)*2+l;z=o*2/x;D=o*2/y;if(o-h>n/2||o-h>l/2)for(h=4;h--;){s=q[h];G=s.charAt(0)==="b";E=s.charAt(1)==="r";s=a(j,s,t,v,m,o,u);r=s.fill;r.focusposition=(E?1-z:z)+","+(G?1-D:D);r.focussize="0,0";s.style.clip="rect("+((G?y/2:0)+k)+"px,"+(E?x:x/2)+"px,"+(G?y:y/2)+"px,"+((E?x/2:0)+k)+
"px)"}else{s=a(j,"",t,v,m,o,u);r=s.fill;r.focusposition=z+","+D;r.focussize=1-z*2+","+(1-D*2)}}else{s=a(j,"",t,v,m,o,u);t=m.fa();if(t<1)s.fill.opacity=t}}}});f.Pc=f.u.P({M:6,Ya:"imgEl",O:function(){var a=this.g;return this.e.src!==this.Xc||a.F.G()},h:function(){var a=this.g;return a.F.h()||a.w.qc()},U:function(){this.Xc=i;this.Cd();var a=this.za("img","fill",this.H()),b=a.fill,c=this.s.o(),d=c.i;c=c.f;var e=this.g.z.j(),g=e&&e.I;e=this.e;var i=e.src,j=Math.round,h=e.currentStyle,k=f.n;if(!g||f.V<
7){g=f.n("0");g={t:g,r:g,b:g,l:g}}a.stroked=false;b.type="frame";b.src=i;b.position=(d?0.5/d:0)+","+(c?0.5/c:0);a.coordsize=d*2+","+c*2;a.coordorigin="1,1";a.path=this.xa({Jb:j(g.t.a(e)+k(h.paddingTop).a(e)),Ib:j(g.r.a(e)+k(h.paddingRight).a(e)),tb:j(g.b.a(e)+k(h.paddingBottom).a(e)),Db:j(g.l.a(e)+k(h.paddingLeft).a(e))},2);a=a.style;a.width=d;a.height=c},Cd:function(){this.e.runtimeStyle.filter="alpha(opacity=0)"},m:function(){f.u.m.call(this);this.e.runtimeStyle.filter=""}});f.Oc=f.u.P({ib:f.aa,
Mb:f.aa,Nb:f.aa,Lb:f.aa,Kd:/^,+|,+$/g,Fd:/,+/g,gb:function(a,b){(this.pb||(this.pb=[]))[a]=b||void 0},ab:function(){var a=this.pb,b;if(a&&(b=a.join(",").replace(this.Kd,"").replace(this.Fd,","))!==this.Wc)this.Wc=this.e.runtimeStyle.background=b},m:function(){this.e.runtimeStyle.background="";delete this.pb}});f.Mc=f.u.P({ta:1,O:function(){return this.g.w.G()},h:function(){var a=this.g;return a.w.h()||a.q.h()},U:function(){var a=this.g.w.j(),b,c,d=0,e,g;if(a){b=[];if(c=a.L)for(;e=c[d++];)if(e.N===
"linear-gradient"){g=this.vd(e.Wa);g=(e.Xa||f.Ka.Kc).a(this.e,g.i,g.f,g.i,g.f);b.push("url(data:image/svg+xml,"+escape(this.xd(e,g.i,g.f))+") "+this.dd(e.$)+" / "+g.i+"px "+g.f+"px "+(e.bc||"")+" "+(e.Wa||"")+" "+(e.ub||""))}else b.push(e.Hb);a.color&&b.push(a.color.Y);this.parent.gb(this.ta,b.join(","))}},dd:function(a){return a?a.X.map(function(b){return b.d}).join(" "):"0 0"},vd:function(a){var b=this.e,c=this.s.o(),d=c.i;c=c.f;var e;if(a!=="border-box")if((e=this.g.z.j())&&(e=e.I)){d-=e.l.a(b)+
e.l.a(b);c-=e.t.a(b)+e.b.a(b)}if(a==="content-box"){a=f.n;e=b.currentStyle;d-=a(e.paddingLeft).a(b)+a(e.paddingRight).a(b);c-=a(e.paddingTop).a(b)+a(e.paddingBottom).a(b)}return{i:d,f:c}},xd:function(a,b,c){var d=this.e,e=a.ca,g=e.length,i=f.Na.gc(d,b,c,a);a=i.xc;var j=i.yc,h=i.td,k=i.ud;i=i.rc;var n,l,q,s,m;n=[];for(l=0;l<g;l++)n.push(e[l].db?e[l].db.a(d,i):l===0?0:l===g-1?i:null);for(l=1;l<g;l++)if(n[l]===null){s=n[l-1];q=l;do m=n[++q];while(m===null);n[l]=s+(m-s)/(q-l+1)}b=['<svg width="'+b+'" height="'+
c+'" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="g" gradientUnits="userSpaceOnUse" x1="'+a/b*100+'%" y1="'+j/c*100+'%" x2="'+h/b*100+'%" y2="'+k/c*100+'%">'];for(l=0;l<g;l++)b.push('<stop offset="'+n[l]/i+'" stop-color="'+e[l].color.T(d)+'" stop-opacity="'+e[l].color.fa()+'"/>');b.push('</linearGradient></defs><rect width="100%" height="100%" fill="url(#g)"/></svg>');return b.join("")},m:function(){this.parent.gb(this.ta)}});f.Nc=f.u.P({S:"repeat",Sc:"stretch",Qc:"round",ta:0,O:function(){return this.g.q.G()},
h:function(){return this.g.q.h()},U:function(){var a=this,b=a.g.q.j(),c=a.g.z.j(),d=a.s.o(),e=b.repeat,g=e.f,i=e.Ob,j=a.e,h=0;f.p.Rb(b.src,function(k){function n(R,S,U,V,W,T,w,C,K,O){J.push('<pattern patternUnits="userSpaceOnUse" id="pattern'+Q+'" x="'+(g===p?R+U/2-K/2:R)+'" y="'+(i===p?S+V/2-O/2:S)+'" width="'+K+'" height="'+O+'"><svg width="'+K+'" height="'+O+'" viewBox="'+W+" "+T+" "+w+" "+C+'" preserveAspectRatio="none"><image xlink:href="'+r+'" x="0" y="0" width="'+s+'" height="'+m+'" /></svg></pattern>');
P.push('<rect x="'+R+'" y="'+S+'" width="'+U+'" height="'+V+'" fill="url(#pattern'+Q+')" />');Q++}var l=d.i,q=d.f,s=k.i,m=k.f,r=a.Dd(b.src,s,m),p=a.S,t=a.Sc;k=a.Qc;var v=Math.ceil,o=f.n("0"),u=b.I||(c?c.I:{t:o,r:o,b:o,l:o});o=u.t.a(j);var x=u.r.a(j),y=u.b.a(j);u=u.l.a(j);var z=b.slice,D=z.t.a(j),G=z.r.a(j),E=z.b.a(j);z=z.l.a(j);var B=l-u-x,A=q-o-y,L=s-z-G,N=m-D-E,H=g===t?B:L*o/D,I=i===t?A:N*x/G,F=g===t?B:L*y/E;t=i===t?A:N*u/z;var J=[],P=[],Q=0;if(g===k){H-=(H-(B%H||H))/v(B/H);F-=(F-(B%F||F))/v(B/
F)}if(i===k){I-=(I-(A%I||I))/v(A/I);t-=(t-(A%t||t))/v(A/t)}k=['<svg width="'+l+'" height="'+q+'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'];n(0,0,u,o,0,0,z,D,u,o);n(u,0,B,o,z,0,L,D,H,o);n(l-x,0,x,o,s-G,0,G,D,x,o);n(0,o,u,A,0,D,z,N,u,t);if(b.fill)n(u,o,B,A,z,D,L,N,H||F||L,t||I||N);n(l-x,o,x,A,s-G,D,G,N,x,I);n(0,q-y,u,y,0,m-E,z,E,u,y);n(u,q-y,B,y,z,m-E,L,E,F,y);n(l-x,q-y,x,y,s-G,m-E,G,E,x,y);k.push("<defs>"+J.join("\n")+"</defs>"+P.join("\n")+"</svg>");a.parent.gb(a.ta,
"url(data:image/svg+xml,"+escape(k.join(""))+") no-repeat border-box border-box");h&&a.parent.ab()},a);h=1},Dd:function(){var a={};return function(b,c,d){var e=a[b],g;if(!e){e=new Image;g=doc.createElement("canvas");e.src=b;g.width=c;g.height=d;g.getContext("2d").drawImage(e,0,0);e=a[b]=g.toDataURL()}return e}}(),Ea:f.Tb.prototype.Ea,m:function(){var a=this.e.runtimeStyle;this.parent.gb(this.ta);a.borderColor=a.borderStyle=a.borderWidth=""}});f.kb=function(){function a(m,r){m.className+=" "+r}function b(m){var r=
s.slice.call(arguments,1),p=r.length;setTimeout(function(){for(;p--;)a(m,r[p])},0)}function c(m){var r=s.slice.call(arguments,1),p=r.length;setTimeout(function(){for(;p--;){var t=r[p];t=q[t]||(q[t]=new RegExp("\\b"+t+"\\b","g"));m.className=m.className.replace(t,"")}},0)}function d(m){function r(){if(!R){var w,C,K=f.Ba,O=m.currentStyle,M=O.getAttribute(g)==="true";T=O.getAttribute(i);T=K>7?T!=="false":T==="true";if(!Q){Q=1;m.runtimeStyle.zoom=1;O=m;for(var ba=1;O=O.previousSibling;)if(O.nodeType===
1){ba=0;break}ba&&a(m,n)}F.cb();if(M&&(C=F.o())&&(w=doc.documentElement||doc.body)&&(C.y>w.clientHeight||C.x>w.clientWidth||C.y+C.f<0||C.x+C.i<0)){if(!V){V=1;f.mb.ba(r)}}else{R=1;V=Q=0;f.mb.Ha(r);if(K===9){J={w:new f.Sb(m),q:new f.Ub(m),z:new f.Vb(m)};P=[J.w,J.q];I=new f.Oc(m,F,J);w=[new f.Mc(m,F,J,I),new f.Nc(m,F,J,I)]}else{J={w:new f.Sb(m),z:new f.Vb(m),q:new f.Ub(m),F:new f.jb(m),ga:new f.Ic(m),Pb:new f.Uc(m)};P=[J.w,J.z,J.q,J.F,J.ga,J.Pb];I=new f.Rc(m,F,J);w=[new f.Hc(m,F,J,I),new f.Fc(m,F,J,
I),new f.Gc(m,F,J,I),new f.Tb(m,F,J,I)];m.tagName==="IMG"&&w.push(new f.Pc(m,F,J,I));I.ed=w}H=[I].concat(w);if(w=m.currentStyle.getAttribute(f.Q+"watch-ancestors")){w=parseInt(w,10);C=0;for(M=m.parentNode;M&&(w==="NaN"||C++<w);){A(M,"onpropertychange",G);A(M,"onmouseenter",o);A(M,"onmouseleave",u);A(M,"onmousedown",x);if(M.tagName in f.fc){A(M,"onfocus",z);A(M,"onblur",D)}M=M.parentNode}}if(T){f.Oa.ba(t);f.Oa.Qd()}t(1)}if(!S){S=1;K<9&&A(m,"onmove",p);A(m,"onresize",p);A(m,"onpropertychange",v);A(m,
"onmouseenter",o);A(m,"onmouseleave",u);A(m,"onmousedown",x);if(m.tagName in f.fc){A(m,"onfocus",z);A(m,"onblur",D)}f.Qa.ba(p);f.K.ba(L)}F.hb()}}function p(){F&&F.Ad()&&t()}function t(w){if(!W)if(R){var C,K=H.length;E();for(C=0;C<K;C++)H[C].Ea();if(w||F.Nd())for(C=0;C<K;C++)H[C].ib();if(w||F.Sd())for(C=0;C<K;C++)H[C].Mb();I.ab();B()}else Q||r()}function v(){var w,C=H.length,K;w=event;if(!W&&!(w&&w.propertyName in l))if(R){E();for(w=0;w<C;w++)H[w].Ea();for(w=0;w<C;w++){K=H[w];K.Cb||K.ib();K.O()&&K.Lb()}I.ab();
B()}else Q||r()}function o(){b(m,j)}function u(){c(m,j,h)}function x(){b(m,h);f.lb.ba(y)}function y(){c(m,h);f.lb.Ha(y)}function z(){b(m,k)}function D(){c(m,k)}function G(){var w=event.propertyName;if(w==="className"||w==="id")v()}function E(){F.cb();for(var w=P.length;w--;)P[w].cb()}function B(){for(var w=P.length;w--;)P[w].hb();F.hb()}function A(w,C,K){w.attachEvent(C,K);U.push([w,C,K])}function L(){if(S){for(var w=U.length,C;w--;){C=U[w];C[0].detachEvent(C[1],C[2])}f.K.Ha(L);S=0;U=[]}}function N(){if(!W){var w,
C;L();W=1;if(H){w=0;for(C=H.length;w<C;w++){H[w].ec=1;H[w].m()}}T&&f.Oa.Ha(t);f.Qa.Ha(t);H=F=J=P=m=null}}var H,I,F=new da(m),J,P,Q,R,S,U=[],V,W,T;this.Ed=r;this.update=t;this.m=N;this.qd=m}var e={},g=f.Q+"lazy-init",i=f.Q+"poll",j=f.La+"hover",h=f.La+"active",k=f.La+"focus",n=f.La+"first-child",l={background:1,bgColor:1,display:1},q={},s=[];d.yd=function(m){var r=f.p.Aa(m);return e[r]||(e[r]=new d(m))};d.m=function(m){m=f.p.Aa(m);var r=e[m];if(r){r.m();delete e[m]}};d.md=function(){var m=[],r;if(e){for(var p in e)if(e.hasOwnProperty(p)){r=
e[p];m.push(r.qd);r.m()}e={}}return m};return d}();f.supportsVML=f.zc;f.attach=function(a){f.Ba<10&&f.zc&&f.kb.yd(a).Ed()};f.detach=function(a){f.kb.m(a)}};
})();
#>>> copy text xtensions/ie/pie/license.txt
Copyright 2010 Jason JohnstonCSS3 PIE is licensed under the terms of the Apache License Version 2.0, oralternatively under the terms of the General Public License (GPL) Version 2.You may use PIE according to either of these licenses as is most appropriatefor your project on a case-by-case basis.The terms of each license can be found in the main directory of the PIE sourcerepository:Apache License: http://github.com/lojjic/PIE/blob/master/LICENSE-APACHE2.txtGPL2 License: http://github.com/lojjic/PIE/blob/master/LICENSE-GPL2.txt
#>>> copy text xtensions/ie/pie/readme.txt
http://css3pie.com/PIE script makes IE 6-9 understand some of CSS3 properties: border-radiusbox-shadowlinear-gradient (with -pie- prefix only)Script requires jQuery http://jquery.com/ To use it copy PIE.js to the javascript files folder, include link to the script in your pages in this way<!--[if lt IE 10]><script type="text/javascript" src="js/PIE.js"></script><![endif]-->And invoke the script on elements with CSS3 properties. You can do it by adding special class to every such element (.rounded in example) or by listing existing classes in your javascript block ('.menu_main a, .menu_bottom a')$(function() {    if (window.PIE) {        $('.rounded').each(function() {            PIE.attach(this);        });    }});PS Sometimes you will need to change the "position" property of the elements with PIE applied to "relative", it will help you to avoid some bugs:.rounded {  position:relative;}
#>>> copy text xtensions/scripts/flexslider/LICENSE.txt
 Copyright (c) 2011 Tyler Smith

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
#>>> copy text xtensions/scripts/flexslider/demo.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
  <title></title>
  <!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
      <article class="hero clearfix">
        <div class="col_100">
          <h1>Simplest solution for your simple tasks</h1>
          <p>You don't always need to make difficult work of running management system with administrative panel to have a web site. “Simpliste” is a very simple and easy to use HTML template for web projects where you only need to create one or couple of pages with simple layout. If you are working on a lightweight information page with as less efforts for you to code and as less kilobytes  for the user to download as possible, “Simpliste” is what you need.</p>
          <p>No CMS required and it's free. Clean code will make your task even easier. HTML5 and CSS3 bring all their features for your future site. This template has skins which you can choose from. No images are used for styling.</p>
          <p>Are you worried about convenience of your site users with mobile devices? “Simpliste” responds to the width of user's device and makes information more accessible.</p>
        </div>
      </article>


      <article class="article clearfix">
        <div class="col_33">
          <h2>Clean code</h2>
          <p>HTML5 and CSS3 made live of web developers easier than ever. Welcome to the world where less code and less files required. “Simpliste” has different skins and all of them are created with no images for styling at all.</p>
          <p>Template contains CSS-reset based on the reset file from <a href="http://html5boilerplate.com/" target="_blank">HTML5 boilerplate</a> which makes appearens of “Simpliste” skins consistent in different browsers.</p>
          <p>Print styles and styles for mobile devices are already included in the stylesheet.</p>
        </div>

        <div class="col_33">
          <h2>Responsive markup</h2>
          <p>You know that now it's time to think more about your users with mobile devices. This template will make your site respond to your client's browser with no effort on your part.</p>
          <p>Multi-column layout becomes one column for viewers with tablets, navigation elements become bigger for users with smartphones. And your desktop browser users will see just a normal web site.</p>
          <p>Try changing the width of your browser window and you'll see how “Simpliste” works.</p>
        </div>

        <div class="col_33">
          <h2>Easy to use</h2>
          <p>“Simpliste” is not a template for a CMS. You can use its code right away after downloading without reading any documentation. Place your content, make customisations and voilà the site is ready to upload to the server.</p>
          <p>All content management can be done by using existing sample blocks and styles. Almost every template style is represented among <a href="#samples">samples</a> on this page. Off course you can create your own styles, which is easy as well.</p>
        </div>

        <div class="clearfix"></div>


        <h1>“Simpliste” in use</h1>

        <div class="col_50">
          <h2>Sample content</h2>

          <h3>Principles behind “Simpliste”</h3>
          <ul>
             <li>Really simple</li>
             <li>Has ready to use set of simple designs</li>
             <li>It's written using HTML5 and CSS3</li>
             <li>It responds to mobile devices</li>
             <li>No CMS</li>
             <li>Free</li>
          </ul>

          <h3>How to use?</h3>
          <form action="">
          <select name=skin onchange='reskin(this.form.skin);'>
          <option>default</option>
          <option>aim</option>
          <option>blackberry</option>
          <option>blue</option>
          <option>dark-blue</option>
          <option>fresh</option>
          <option>fruitjuice</option>
          <option>glimpse</option>
          <option>green</option>
          <option>humble</option>
          <option>illusion</option>
          <option>isimple</option>
          <option>liner</option>
          <option>maple</option>
          <option>mentol</option>
          <option>nightroad</option>
          <option>orange</option>
          <option>passion</option>
          <option>pink</option>
          <option>purple</option>
          <option>red</option>
          <option>simplesoft</option>
          <option>simpleswiss</option>
          <option>simploid</option>
          <option>snobbish</option>
          <option>solution</option>
          <option>stylus</option>
          <option>teawithmilk</option>
          <option>yellow</option>
          </select>
          </form>
          <script>
            function reskin(dropdown){
              var theIndex  = dropdown.selectedIndex;
              var theValue = dropdown.options[theIndex].value;
              var sheet  = "skin/" + theValue + ".css";
              document.getElementById('css_skin').setAttribute('href', sheet);
              return true;
            }
          </script>
          <ol>
             <li>Choose one skin from the list above</li>
             <li>Copy the file from the skin folder</li>
             <li>Rename it to skin.css</li>
             <li>Make any customisation you need</li>
          </ol>
        </div>

        <div class="col_50">
          <form action="#" method="post" class="form">
            <h2>Sample form</h2>

            <p class="col_50">
              <label for="name">Simple name:</label><br/>
              <input type="text" name="name" id="name" value="" />
            </p>
            <p class="col_50">
              <label for="email">Simple e-mail:</label><br/>
              <input type="text" name="email" id="email" value="" />
            </p>
            <div class="clearfix"></div>

            <h3>Your favorite number</h3>
            <p>
              <div class="col_33">
                <label for="radio-choice-1"><input type="radio" name="radio-choice-1" id="radio-choice-1" tabindex="2" value="choice-1" /> One</label><br/>
                <label for="radio-choice-2"><input type="radio" name="radio-choice-1" id="radio-choice-2" tabindex="3" value="choice-2" /> Two</label><br/>
                <label for="radio-choice-3"><input type="radio" name="radio-choice-1" id="radio-choice-3" tabindex="4" value="choice-3" /> Three</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-4"><input type="radio" name="radio-choice-1" id="radio-choice-4" tabindex="2" value="choice-1" /> Four</label><br/>
                <label for="radio-choice-5"><input type="radio" name="radio-choice-1" id="radio-choice-5" tabindex="3" value="choice-2" /> Five</label><br/>
                <label for="radio-choice-6"><input type="radio" name="radio-choice-1" id="radio-choice-6" tabindex="4" value="choice-3" /> Six</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-7"><input type="radio" name="radio-choice-1" id="radio-choice-7" tabindex="2" value="choice-1" /> Seven</label><br/>
                <label for="radio-choice-8"><input type="radio" name="radio-choice-1" id="radio-choice-8" tabindex="3" value="choice-2" /> Eight</label><br/>
                <label for="radio-choice-9"><input type="radio" name="radio-choice-1" id="radio-choice-9" tabindex="3" value="choice-2" /> Niine</label>
              </div>

            <div class="clearfix"></div>
            </p>

            <p>
              <label for="select-choice">Simple city:</label>
              <select name="select-choice" id="select-choice">
                <option value="Choice 1">London</option>
                <option value="Choice 2">Paris</option>
                <option value="Choice 3">Rome</option>
              </select>
            </p>

            <p>
              <label for="textarea">Simple testimonial:</label><br/>
              <textarea cols="40" rows="8" name="textarea" id="textarea"></textarea>
            </p>

            <p>
              <label for="checkbox"><input type="checkbox" name="checkbox" id="checkbox" /> Simple agreement</label><br/>
            </p>

            <div>
                <button type="button" class="button">Submit</button>
            </div>
          </form>
        </div>

        <div class="clearfix"></div>


        <div class="col_33">
          <h2>More elements</h2>

          <p>Use <code>strong</code> tag for information with <strong>strong importance</strong>. Use <code>em</code> tag to <em>stress emphasis</em> on a word or phrase.</p>

          <p class="warning">Sample <code>.warning</code></p>
          <p class="success">Sample <code>.success</code></p>
          <p class="message">Sample <code>.message</code></p>
        </div>

        <div class="col_66">
          <h2>CSS classes table</h2>

          <table class="table">
            <tr>
              <th>Class</th>
              <th>Description</th>
            </tr>

            <tr>
              <td><code>.col_33</code></td>
              <td>Column with 33% width</td>
            </tr>
            <tr>
              <td><code>.col_50</code></td>
              <td>Column with 50% width</td>
            </tr>
            <tr>
              <td><code>.col_66</code></td>
              <td>Column with 66% width</td>
            </tr>
            <tr>
              <td><code>.col_100</code></td>
              <td>Full width column with proper margins</td>
            </tr>
            <tr>
              <td><code>.clearfix</code></td>
              <td>Use after or wrap a block of floated columns</td>
            </tr>
            <tr>
              <td><code>.left</code></td>
              <td>Left text alignment</td>
            </tr>
            <tr>
              <td><code>.right</code></td>
              <td>Right text alignment</td>
            </tr>
            <tr>
              <td><code>.center</code></td>
              <td>Centered text alignment</td>
            </tr>
            <tr>
              <td><code>.img_floatleft</code></td>
              <td>Left alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img_floatright</code></td>
              <td>Right alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img</code></td>
              <td>Makes image change its width when browser window width is changed</td>
            </tr>
          </table>
        </div>

        <div class="clearfix"></div>

      </article>
      <!-- endsection primary -->
      <!-- section secondary -->
      <!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text xtensions/scripts/flexslider/flexslider.css
.flexslider {
	width:100%;
	margin:0;
	padding:0;
}

.flexslider .slides>li {
	display:none;
}
.flexslider .slides img {
	max-width:100%;
	display:block;
}
.flex-pauseplay span {
	text-transform:capitalize;
}
.slides:after {
	content:".";
	display:block;
	clear:both;
	visibility:hidden;
	line-height:0;
	height:0;
}

html[xmlns] .slides {
	display:block;
}
* html .slides {
	height:1%;
}

.flexslider {
	background:#fff;
	border:4px solid #fff;
	position:relative;
	-webkit-border-radius:5px;
	-moz-border-radius:5px;
	-o-border-radius:5px;
	border-radius:5px;
	zoom:1;
}
.flexslider ul {list-style:none; margin:0; padding:0;}
.flexslider .slides {
	zoom:1;
}
.flexslider .slides>li {
	position:relative;
}
.flex-container {
	zoom:1;
	position: relative;
}

/* Caption style */
/* IE rgba() hack */
.flex-caption {
	background:none;
	-ms-filter:progid:DXImageTransform.Microsoft.gradient(startColorstr=#4C000000,endColorstr=#4C000000);
	filter:progid:DXImageTransform.Microsoft.gradient(startColorstr=#4C000000,endColorstr=#4C000000);
	zoom:1;
}
.flex-caption {
	width:96%;
	padding:2%;
	position:absolute;
	left:0;
	bottom:0;
	background:rgba(0,0,0,.3);
	color:#fff;
	text-shadow:0 -1px 0 rgba(0,0,0,.3);
	font-size:14px;
	line-height: 18px;
}

/* Direction Nav */
.flex-direction-nav li a {
	width:52px;
	height:50px;
	margin:-13px 0 0;
	display:block;
	background:#d4d4d4;
	position:absolute;
	top:50%;
	cursor:pointer;
	text-indent:-9999px;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius: 6px;
  -webkit-box-shadow:rgba(0,0,0,0.3) 0px 2px 2px;
  -moz-box-shadow:rgba(0,0,0,0.3) 0px 2px 2px;
  box-shadow:rgba(0,0,0,0.3) 0px 2px 2px;
}
.flex-direction-nav li .next {
	right:-21px;
}
.flex-direction-nav li .next:before {
  content:"";
  position:absolute;
  right:15px;
  top:8px;
	width:0;
	height:0;
	border-top:18px solid transparent;
	border-bottom:18px solid transparent;
	border-left:18px solid #6a6a6a;
}
.flex-direction-nav li .next:after {
  content:"";
  position:absolute;
  right:24px;
  top:17px;
	width:0;
	height:0;
	border-top:9px solid transparent;
	border-bottom:9px solid transparent; 
	border-left:9px solid #d4d4d4;
}

.flex-direction-nav li .prev {
	left:-20px;
}
.flex-direction-nav li .prev:before {
  content:"";
  position:absolute;
  left:15px;
  top:8px;
	width: 0;
	height: 0;
	border-top:18px solid transparent;
	border-bottom:18px solid transparent; 
	border-right:18px solid #6a6a6a;
}
.flex-direction-nav li .prev:after {
  content:"";
  position:absolute;
  left:24px;
  top:17px;
	width: 0;
	height: 0;
	border-top:9px solid transparent;
	border-bottom:9px solid transparent; 
	border-right:9px solid #d4d4d4;
}

.flex-direction-nav li .disabled {
	opacity:.3;
	filter:alpha(opacity=30);
	cursor: default;
}

/* Control Nav */
.flex-control-nav {
	width:100%;
	position:absolute;
	bottom:-30px;
	text-align:center;
}
.flex-control-nav li {
	margin:0 0 0 5px;
	display:inline-block;
	zoom:1;
	/display:inline;
}
.flex-control-nav li:first-child {
	margin:0;
}
.flex-control-nav li a {
	width:12px;
	height:12px;
	display:block;
	background:#ffffff;
	cursor:pointer;
	text-indent:-9999px;
  border:1px solid #bbbbbb;
  -webkit-border-radius: 6px;
  -moz-border-radius: 6px;
  border-radius: 6px;
}
.flex-control-nav li a:hover {
	background:#82c5e7;
  border:1px solid #82c5e7;
}
.flex-control-nav li a.active {
  border:0;
	display:block;
	background:#289aca;
	cursor:default;
  border:1px solid #289aca;
}
#>>> copy text xtensions/scripts/flexslider/jquery.flexslider-min.js
/*
 * jQuery FlexSlider v1.8
 * http://flex.madebymufffin.com
 * Copyright 2011, Tyler Smith
 */
(function(a){a.flexslider=function(c,b){var d=c;d.init=function(){d.vars=a.extend({},a.flexslider.defaults,b);d.data("flexslider",true);d.container=a(".slides",d);d.slides=a(".slides > li",d);d.count=d.slides.length;d.animating=false;d.currentSlide=d.vars.slideToStart;d.animatingTo=d.currentSlide;d.atEnd=(d.currentSlide==0)?true:false;d.eventType=("ontouchstart" in document.documentElement)?"touchstart":"click";d.cloneCount=0;d.cloneOffset=0;d.manualPause=false;d.vertical=(d.vars.slideDirection=="vertical");d.prop=(d.vertical)?"top":"marginLeft";d.args={};d.transitions="webkitTransition" in document.body.style;if(d.transitions){d.prop="-webkit-transform"}if(d.vars.controlsContainer!=""){d.controlsContainer=a(d.vars.controlsContainer).eq(a(".slides").index(d.container));d.containerExists=d.controlsContainer.length>0}if(d.vars.manualControls!=""){d.manualControls=a(d.vars.manualControls,((d.containerExists)?d.controlsContainer:d));d.manualExists=d.manualControls.length>0}if(d.vars.randomize){d.slides.sort(function(){return(Math.round(Math.random())-0.5)});d.container.empty().append(d.slides)}if(d.vars.animation.toLowerCase()=="slide"){if(d.transitions){d.setTransition(0)}d.css({overflow:"hidden"});if(d.vars.animationLoop){d.cloneCount=2;d.cloneOffset=1;d.container.append(d.slides.filter(":first").clone().addClass("clone")).prepend(d.slides.filter(":last").clone().addClass("clone"))}d.newSlides=a(".slides > li",d);var m=(-1*(d.currentSlide+d.cloneOffset));if(d.vertical){d.newSlides.css({display:"block",width:"100%","float":"left"});d.container.height((d.count+d.cloneCount)*200+"%").css("position","absolute").width("100%");setTimeout(function(){d.css({position:"relative"}).height(d.slides.filter(":first").height());d.args[d.prop]=(d.transitions)?"translate3d(0,"+m*d.height()+"px,0)":m*d.height()+"px";d.container.css(d.args)},100)}else{d.args[d.prop]=(d.transitions)?"translate3d("+m*d.width()+"px,0,0)":m*d.width()+"px";d.container.width((d.count+d.cloneCount)*200+"%").css(d.args);setTimeout(function(){d.newSlides.width(d.width()).css({"float":"left",display:"block"})},100)}}else{d.transitions=false;d.slides.css({width:"100%","float":"left",marginRight:"-100%"}).eq(d.currentSlide).fadeIn(d.vars.animationDuration)}if(d.vars.controlNav){if(d.manualExists){d.controlNav=d.manualControls}else{var e=a('<ol class="flex-control-nav"></ol>');var s=1;for(var t=0;t<d.count;t++){e.append("<li><a>"+s+"</a></li>");s++}if(d.containerExists){a(d.controlsContainer).append(e);d.controlNav=a(".flex-control-nav li a",d.controlsContainer)}else{d.append(e);d.controlNav=a(".flex-control-nav li a",d)}}d.controlNav.eq(d.currentSlide).addClass("active");d.controlNav.bind(d.eventType,function(i){i.preventDefault();if(!a(this).hasClass("active")){(d.controlNav.index(a(this))>d.currentSlide)?d.direction="next":d.direction="prev";d.flexAnimate(d.controlNav.index(a(this)),d.vars.pauseOnAction)}})}if(d.vars.directionNav){var v=a('<ul class="flex-direction-nav"><li><a class="prev" href="#">'+d.vars.prevText+'</a></li><li><a class="next" href="#">'+d.vars.nextText+"</a></li></ul>");if(d.containerExists){a(d.controlsContainer).append(v);d.directionNav=a(".flex-direction-nav li a",d.controlsContainer)}else{d.append(v);d.directionNav=a(".flex-direction-nav li a",d)}if(!d.vars.animationLoop){if(d.currentSlide==0){d.directionNav.filter(".prev").addClass("disabled")}else{if(d.currentSlide==d.count-1){d.directionNav.filter(".next").addClass("disabled")}}}d.directionNav.bind(d.eventType,function(i){i.preventDefault();var j=(a(this).hasClass("next"))?d.getTarget("next"):d.getTarget("prev");if(d.canAdvance(j)){d.flexAnimate(j,d.vars.pauseOnAction)}})}if(d.vars.keyboardNav&&a("ul.slides").length==1){function h(i){if(d.animating){return}else{if(i.keyCode!=39&&i.keyCode!=37){return}else{if(i.keyCode==39){var j=d.getTarget("next")}else{if(i.keyCode==37){var j=d.getTarget("prev")}}if(d.canAdvance(j)){d.flexAnimate(j,d.vars.pauseOnAction)}}}}a(document).bind("keyup",h)}if(d.vars.mousewheel){d.mousewheelEvent=(/Firefox/i.test(navigator.userAgent))?"DOMMouseScroll":"mousewheel";d.bind(d.mousewheelEvent,function(y){y.preventDefault();y=y?y:window.event;var i=y.detail?y.detail*-1:y.wheelDelta/40,j=(i<0)?d.getTarget("next"):d.getTarget("prev");if(d.canAdvance(j)){d.flexAnimate(j,d.vars.pauseOnAction)}})}if(d.vars.slideshow){if(d.vars.pauseOnHover&&d.vars.slideshow){d.hover(function(){d.pause()},function(){if(!d.manualPause){d.resume()}})}d.animatedSlides=setInterval(d.animateSlides,d.vars.slideshowSpeed)}if(d.vars.pausePlay){var q=a('<div class="flex-pauseplay"><span></span></div>');if(d.containerExists){d.controlsContainer.append(q);d.pausePlay=a(".flex-pauseplay span",d.controlsContainer)}else{d.append(q);d.pausePlay=a(".flex-pauseplay span",d)}var n=(d.vars.slideshow)?"pause":"play";d.pausePlay.addClass(n).text((n=="pause")?d.vars.pauseText:d.vars.playText);d.pausePlay.bind(d.eventType,function(i){i.preventDefault();if(a(this).hasClass("pause")){d.pause();d.manualPause=true}else{d.resume();d.manualPause=false}})}if("ontouchstart" in document.documentElement){var w,u,l,r,o,x,p=false;d.each(function(){if("ontouchstart" in document.documentElement){this.addEventListener("touchstart",g,false)}});function g(i){if(d.animating){i.preventDefault()}else{if(i.touches.length==1){d.pause();r=(d.vertical)?d.height():d.width();x=Number(new Date());l=(d.vertical)?(d.currentSlide+d.cloneOffset)*d.height():(d.currentSlide+d.cloneOffset)*d.width();w=(d.vertical)?i.touches[0].pageY:i.touches[0].pageX;u=(d.vertical)?i.touches[0].pageX:i.touches[0].pageY;d.setTransition(0);this.addEventListener("touchmove",k,false);this.addEventListener("touchend",f,false)}}}function k(i){o=(d.vertical)?w-i.touches[0].pageY:w-i.touches[0].pageX;p=(d.vertical)?(Math.abs(o)<Math.abs(i.touches[0].pageX-u)):(Math.abs(o)<Math.abs(i.touches[0].pageY-u));if(!p){i.preventDefault();if(d.vars.animation=="slide"&&d.transitions){if(!d.vars.animationLoop){o=o/((d.currentSlide==0&&o<0||d.currentSlide==d.count-1&&o>0)?(Math.abs(o)/r+2):1)}d.args[d.prop]=(d.vertical)?"translate3d(0,"+(-l-o)+"px,0)":"translate3d("+(-l-o)+"px,0,0)";d.container.css(d.args)}}}function f(j){d.animating=false;if(d.animatingTo==d.currentSlide&&!p&&!(o==null)){var i=(o>0)?d.getTarget("next"):d.getTarget("prev");if(d.canAdvance(i)&&Number(new Date())-x<550&&Math.abs(o)>20||Math.abs(o)>r/2){d.flexAnimate(i,d.vars.pauseOnAction)}else{d.flexAnimate(d.currentSlide,d.vars.pauseOnAction)}}this.removeEventListener("touchmove",k,false);this.removeEventListener("touchend",f,false);w=null;u=null;o=null;l=null}}if(d.vars.animation.toLowerCase()=="slide"){a(window).resize(function(){if(!d.animating){if(d.vertical){d.height(d.slides.filter(":first").height());d.args[d.prop]=(-1*(d.currentSlide+d.cloneOffset))*d.slides.filter(":first").height()+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}else{d.newSlides.width(d.width());d.args[d.prop]=(-1*(d.currentSlide+d.cloneOffset))*d.width()+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}}})}d.vars.start(d)};d.flexAnimate=function(g,f){if(!d.animating){d.animating=true;d.animatingTo=g;d.vars.before(d);if(f){d.pause()}if(d.vars.controlNav){d.controlNav.removeClass("active").eq(g).addClass("active")}d.atEnd=(g==0||g==d.count-1)?true:false;if(!d.vars.animationLoop&&d.vars.directionNav){if(g==0){d.directionNav.removeClass("disabled").filter(".prev").addClass("disabled")}else{if(g==d.count-1){d.directionNav.removeClass("disabled").filter(".next").addClass("disabled")}else{d.directionNav.removeClass("disabled")}}}if(!d.vars.animationLoop&&g==d.count-1){d.pause();d.vars.end(d)}if(d.vars.animation.toLowerCase()=="slide"){var e=(d.vertical)?d.slides.filter(":first").height():d.slides.filter(":first").width();if(d.currentSlide==0&&g==d.count-1&&d.vars.animationLoop&&d.direction!="next"){d.slideString="0px"}else{if(d.currentSlide==d.count-1&&g==0&&d.vars.animationLoop&&d.direction!="prev"){d.slideString=(-1*(d.count+1))*e+"px"}else{d.slideString=(-1*(g+d.cloneOffset))*e+"px"}}d.args[d.prop]=d.slideString;if(d.transitions){d.setTransition(d.vars.animationDuration);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.slideString+",0)":"translate3d("+d.slideString+",0,0)";d.container.css(d.args).one("webkitTransitionEnd transitionend",function(){d.wrapup(e)})}else{d.container.animate(d.args,d.vars.animationDuration,function(){d.wrapup(e)})}}else{d.slides.eq(d.currentSlide).fadeOut(d.vars.animationDuration);d.slides.eq(g).fadeIn(d.vars.animationDuration,function(){d.wrapup()})}}};d.wrapup=function(e){if(d.vars.animation=="slide"){if(d.currentSlide==0&&d.animatingTo==d.count-1&&d.vars.animationLoop){d.args[d.prop]=(-1*d.count)*e+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}else{if(d.currentSlide==d.count-1&&d.animatingTo==0&&d.vars.animationLoop){d.args[d.prop]=-1*e+"px";if(d.transitions){d.setTransition(0);d.args[d.prop]=(d.vertical)?"translate3d(0,"+d.args[d.prop]+",0)":"translate3d("+d.args[d.prop]+",0,0)"}d.container.css(d.args)}}}d.animating=false;d.currentSlide=d.animatingTo;d.vars.after(d)};d.animateSlides=function(){if(!d.animating){d.flexAnimate(d.getTarget("next"))}};d.pause=function(){clearInterval(d.animatedSlides);if(d.vars.pausePlay){d.pausePlay.removeClass("pause").addClass("play").text(d.vars.playText)}};d.resume=function(){d.animatedSlides=setInterval(d.animateSlides,d.vars.slideshowSpeed);if(d.vars.pausePlay){d.pausePlay.removeClass("play").addClass("pause").text(d.vars.pauseText)}};d.canAdvance=function(e){if(!d.vars.animationLoop&&d.atEnd){if(d.currentSlide==0&&e==d.count-1&&d.direction!="next"){return false}else{if(d.currentSlide==d.count-1&&e==0&&d.direction=="next"){return false}else{return true}}}else{return true}};d.getTarget=function(e){d.direction=e;if(e=="next"){return(d.currentSlide==d.count-1)?0:d.currentSlide+1}else{return(d.currentSlide==0)?d.count-1:d.currentSlide-1}};d.setTransition=function(e){d.container.css({"-webkit-transition-duration":(e/1000)+"s"})};d.init()};a.flexslider.defaults={animation:"fade",slideDirection:"horizontal",slideshow:true,slideshowSpeed:7000,animationDuration:600,directionNav:true,controlNav:true,keyboardNav:true,mousewheel:false,prevText:"Previous",nextText:"Next",pausePlay:false,pauseText:"Pause",playText:"Play",randomize:false,slideToStart:0,animationLoop:true,pauseOnAction:true,pauseOnHover:false,controlsContainer:"",manualControls:"",start:function(){},before:function(){},after:function(){},end:function(){}};a.fn.flexslider=function(b){return this.each(function(){if(a(this).find(".slides li").length==1){a(this).find(".slides li").fadeIn(400)}else{if(a(this).data("flexslider")!=true){new a.flexslider(a(this),b)}}})}})(jQuery);
#>>> copy text xtensions/scripts/flexslider/readme.txt
http://flex.madebymufffin.com/

Flexslider is a fully responsive jQuery slider plugin. It's supported in all major browsers, has custimizable animations, multiple slider support, Callback API, and more.

You can see demo to understand how it works. 

Include link to flexslider.css or copy its content into your skin.css file. Styles in flexslider.css are edited to work better with Simpliste.

Create your sliders in html file:

<div class="flexslider">
  <ul class="slides">
    <li>
      <img src="slide1.jpg" />
    </li>
    <li>
      <img src="slide2.jpg" />
    </li>
    <li>
      <img src="slide3.jpg" />
    </li>
  </ul>
</div>

Include links to scripts and call flexslider on your blocks with sliders:

<script type="text/javascript" charset="utf-8">
  $(window).load(function() {
    $('.flexslider').flexslider();
  });
</script>

#>>> copy text xtensions/snippets/dropdown_menu.txt
This is the common way to create a dropdown menu which shows on hover by using CSS.Include in your skin.css/* Dropdown menu */.menu_main li {  position:relative;}.menu_main li ul {  display:none;  background:#fff;  padding:10px 3px;  border:1px solid #ddd;  text-align:left;  width:6em;  -webkit-box-shadow:rgba(0,0,0,0.2) 0px 4px 6px;  -moz-box-shadow:rgba(0,0,0,0.2) 0px 4px 6px;  box-shadow:rgba(0,0,0,0.2) 0px 4px 6px;}.menu_main li ul li {  display:block;  margin:0;  line-height:1.1;}.menu_main li ul a{  display:block;  padding:3px;}.menu_main li ul a:hover{  background:#f1f1f1;}.menu_main li:hover ul {  display:block;  position:absolute;  right:-1em;  top:100%;}/* End dropdown menu */Example of usage in html file. Add new lavel ul in your .menu_main<nav class="menu_main">  <ul>    <li class="active"><a href="#">About</a></li>    <li><a href="#">Skins</a>      <ul>        <li class="active"><a href="#">Simple</a></li>        <li><a href="#">iSimple</a></li>        <li><a href="#">Simploid</a></li>      </ul>    </li>    <li><a href="#">Samples</a></li>  </ul></nav>
#>>> copy text xtensions/snippets/sticky_footer.txt
Sticky footer will always be displayed on the bottom of the browser window (when there is not much content on the page). This solution will not work if your .footer and .header have dynamic height.Add this to your skin.csshtml, body {   height:100%; }.container {  height: 65%; /* may be different depending on height of your .header */}.info {   height: auto;   min-height: 100%;  padding-bottom: 8em; /* must be same height as the footer (including paddings) */}.footer {  padding-top:2em;  padding-bottom:3em;  position:relative;  margin-top:-8em; /* negative value of footer height */  height:3em;  clear:both;} 
#>>> copy text xtensions/snippets/responsive_navigation/footer_anchor.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
  <title></title>
  <!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
      <article class="hero clearfix">
        <div class="col_100">
          <h1>Simplest solution for your simple tasks</h1>
          <p>You don't always need to make difficult work of running management system with administrative panel to have a web site. “Simpliste” is a very simple and easy to use HTML template for web projects where you only need to create one or couple of pages with simple layout. If you are working on a lightweight information page with as less efforts for you to code and as less kilobytes  for the user to download as possible, “Simpliste” is what you need.</p>
          <p>No CMS required and it's free. Clean code will make your task even easier. HTML5 and CSS3 bring all their features for your future site. This template has skins which you can choose from. No images are used for styling.</p>
          <p>Are you worried about convenience of your site users with mobile devices? “Simpliste” responds to the width of user's device and makes information more accessible.</p>
        </div>
      </article>


      <article class="article clearfix">
        <div class="col_33">
          <h2>Clean code</h2>
          <p>HTML5 and CSS3 made live of web developers easier than ever. Welcome to the world where less code and less files required. “Simpliste” has different skins and all of them are created with no images for styling at all.</p>
          <p>Template contains CSS-reset based on the reset file from <a href="http://html5boilerplate.com/" target="_blank">HTML5 boilerplate</a> which makes appearens of “Simpliste” skins consistent in different browsers.</p>
          <p>Print styles and styles for mobile devices are already included in the stylesheet.</p>
        </div>

        <div class="col_33">
          <h2>Responsive markup</h2>
          <p>You know that now it's time to think more about your users with mobile devices. This template will make your site respond to your client's browser with no effort on your part.</p>
          <p>Multi-column layout becomes one column for viewers with tablets, navigation elements become bigger for users with smartphones. And your desktop browser users will see just a normal web site.</p>
          <p>Try changing the width of your browser window and you'll see how “Simpliste” works.</p>
        </div>

        <div class="col_33">
          <h2>Easy to use</h2>
          <p>“Simpliste” is not a template for a CMS. You can use its code right away after downloading without reading any documentation. Place your content, make customisations and voilà the site is ready to upload to the server.</p>
          <p>All content management can be done by using existing sample blocks and styles. Almost every template style is represented among <a href="#samples">samples</a> on this page. Off course you can create your own styles, which is easy as well.</p>
        </div>

        <div class="clearfix"></div>


        <h1>“Simpliste” in use</h1>

        <div class="col_50">
          <h2>Sample content</h2>

          <h3>Principles behind “Simpliste”</h3>
          <ul>
             <li>Really simple</li>
             <li>Has ready to use set of simple designs</li>
             <li>It's written using HTML5 and CSS3</li>
             <li>It responds to mobile devices</li>
             <li>No CMS</li>
             <li>Free</li>
          </ul>

          <h3>How to use?</h3>
          <form action="">
          <select name=skin onchange='reskin(this.form.skin);'>
          <option>default</option>
          <option>aim</option>
          <option>blackberry</option>
          <option>blue</option>
          <option>dark-blue</option>
          <option>fresh</option>
          <option>fruitjuice</option>
          <option>glimpse</option>
          <option>green</option>
          <option>humble</option>
          <option>illusion</option>
          <option>isimple</option>
          <option>liner</option>
          <option>maple</option>
          <option>mentol</option>
          <option>nightroad</option>
          <option>orange</option>
          <option>passion</option>
          <option>pink</option>
          <option>purple</option>
          <option>red</option>
          <option>simplesoft</option>
          <option>simpleswiss</option>
          <option>simploid</option>
          <option>snobbish</option>
          <option>solution</option>
          <option>stylus</option>
          <option>teawithmilk</option>
          <option>yellow</option>
          </select>
          </form>
          <script>
            function reskin(dropdown){
              var theIndex  = dropdown.selectedIndex;
              var theValue = dropdown.options[theIndex].value;
              var sheet  = "skin/" + theValue + ".css";
              document.getElementById('css_skin').setAttribute('href', sheet);
              return true;
            }
          </script>
          <ol>
             <li>Choose one skin from the list above</li>
             <li>Copy the file from the skin folder</li>
             <li>Rename it to skin.css</li>
             <li>Make any customisation you need</li>
          </ol>
        </div>

        <div class="col_50">
          <form action="#" method="post" class="form">
            <h2>Sample form</h2>

            <p class="col_50">
              <label for="name">Simple name:</label><br/>
              <input type="text" name="name" id="name" value="" />
            </p>
            <p class="col_50">
              <label for="email">Simple e-mail:</label><br/>
              <input type="text" name="email" id="email" value="" />
            </p>
            <div class="clearfix"></div>

            <h3>Your favorite number</h3>
            <p>
              <div class="col_33">
                <label for="radio-choice-1"><input type="radio" name="radio-choice-1" id="radio-choice-1" tabindex="2" value="choice-1" /> One</label><br/>
                <label for="radio-choice-2"><input type="radio" name="radio-choice-1" id="radio-choice-2" tabindex="3" value="choice-2" /> Two</label><br/>
                <label for="radio-choice-3"><input type="radio" name="radio-choice-1" id="radio-choice-3" tabindex="4" value="choice-3" /> Three</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-4"><input type="radio" name="radio-choice-1" id="radio-choice-4" tabindex="2" value="choice-1" /> Four</label><br/>
                <label for="radio-choice-5"><input type="radio" name="radio-choice-1" id="radio-choice-5" tabindex="3" value="choice-2" /> Five</label><br/>
                <label for="radio-choice-6"><input type="radio" name="radio-choice-1" id="radio-choice-6" tabindex="4" value="choice-3" /> Six</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-7"><input type="radio" name="radio-choice-1" id="radio-choice-7" tabindex="2" value="choice-1" /> Seven</label><br/>
                <label for="radio-choice-8"><input type="radio" name="radio-choice-1" id="radio-choice-8" tabindex="3" value="choice-2" /> Eight</label><br/>
                <label for="radio-choice-9"><input type="radio" name="radio-choice-1" id="radio-choice-9" tabindex="3" value="choice-2" /> Niine</label>
              </div>

            <div class="clearfix"></div>
            </p>

            <p>
              <label for="select-choice">Simple city:</label>
              <select name="select-choice" id="select-choice">
                <option value="Choice 1">London</option>
                <option value="Choice 2">Paris</option>
                <option value="Choice 3">Rome</option>
              </select>
            </p>

            <p>
              <label for="textarea">Simple testimonial:</label><br/>
              <textarea cols="40" rows="8" name="textarea" id="textarea"></textarea>
            </p>

            <p>
              <label for="checkbox"><input type="checkbox" name="checkbox" id="checkbox" /> Simple agreement</label><br/>
            </p>

            <div>
                <button type="button" class="button">Submit</button>
            </div>
          </form>
        </div>

        <div class="clearfix"></div>


        <div class="col_33">
          <h2>More elements</h2>

          <p>Use <code>strong</code> tag for information with <strong>strong importance</strong>. Use <code>em</code> tag to <em>stress emphasis</em> on a word or phrase.</p>

          <p class="warning">Sample <code>.warning</code></p>
          <p class="success">Sample <code>.success</code></p>
          <p class="message">Sample <code>.message</code></p>
        </div>

        <div class="col_66">
          <h2>CSS classes table</h2>

          <table class="table">
            <tr>
              <th>Class</th>
              <th>Description</th>
            </tr>

            <tr>
              <td><code>.col_33</code></td>
              <td>Column with 33% width</td>
            </tr>
            <tr>
              <td><code>.col_50</code></td>
              <td>Column with 50% width</td>
            </tr>
            <tr>
              <td><code>.col_66</code></td>
              <td>Column with 66% width</td>
            </tr>
            <tr>
              <td><code>.col_100</code></td>
              <td>Full width column with proper margins</td>
            </tr>
            <tr>
              <td><code>.clearfix</code></td>
              <td>Use after or wrap a block of floated columns</td>
            </tr>
            <tr>
              <td><code>.left</code></td>
              <td>Left text alignment</td>
            </tr>
            <tr>
              <td><code>.right</code></td>
              <td>Right text alignment</td>
            </tr>
            <tr>
              <td><code>.center</code></td>
              <td>Centered text alignment</td>
            </tr>
            <tr>
              <td><code>.img_floatleft</code></td>
              <td>Left alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img_floatright</code></td>
              <td>Right alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img</code></td>
              <td>Makes image change its width when browser window width is changed</td>
            </tr>
          </table>
        </div>

        <div class="clearfix"></div>

      </article>
      <!-- endsection primary -->
      <!-- section secondary -->
      <!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text xtensions/snippets/responsive_navigation/jquery.mobilemenu.min.js
(function(a){function f(a){document.location.href=a}function g(){return a(".mnav").length?!0:!1}function h(b){var c=!0;b.each(function(){if(!a(this).is("ul")&&!a(this).is("ol")){c=!1;console.log(c)}});return c}function i(){return a(window).width()<b.switchWidth}function j(b){return a.trim(b.clone().children("ul, ol").remove().end().text())}function k(b){return a.inArray(b,e)===-1?!0:!1}function l(b){b.find(" > li").each(function(){var c=a(this),d=c.find("a").attr("href"),f=function(){return c.parent().parent().is("li")?c.parent().parent().find("a").attr("href"):null};c.find(" ul, ol").length&&l(c.find("> ul, > ol"));c.find(" > ul li, > ol li").length||c.find("ul, ol").remove();!k(f(),e)&&k(d,e)?c.appendTo(b.closest("ul#mmnav").find("li:has(a[href="+f()+"]):first ul")):k(d)?e.push(d):c.remove()})}function m(){var b=a('<ul id="mmnav" />');c.each(function(){a(this).children().clone().appendTo(b)});l(b);console.log(b);return b}function n(b,c,d){d?a('<option value="'+b.find("a:first").attr("href")+'">'+d+"</option>").appendTo(c):a('<option value="'+b.find("a:first").attr("href")+'">'+a.trim(j(b))+"</option>").appendTo(c)}function o(c,d){var e=a('<optgroup label="'+a.trim(j(c))+'" />');n(c,e,b.groupPageText);c.children("ul, ol").each(function(){a(this).children("li").each(function(){n(a(this),e)})});e.appendTo(d)}function p(c){var e=a('<select id="mm'+d+'" class="mnav" />');d++;b.topOptionText&&n(a("<li>"+b.topOptionText+"</li>"),e);c.children("li").each(function(){var c=a(this);c.children("ul, ol").length&&b.nested?o(c,e):n(c,e)});e.change(function(){f(a(this).val())}).prependTo(b.prependTo)}function q(){if(i()&&!g())if(b.combine){var d=m();p(d)}else c.each(function(){p(a(this))});if(i()&&g()){a(".mnav").show();c.hide()}if(!i()&&g()){a(".mnav").hide();c.show()}}var b={combine:!0,groupPageText:"Main",nested:!0,prependTo:"body",switchWidth:480,topOptionText:"Select a page"},c,d=0,e=[];a.fn.mobileMenu=function(d){d&&a.extend(b,d);if(h(a(this))){c=a(this);q();a(window).resize(function(){q()})}else alert("mobileMenu only works with <ul>/<ol>")}})(jQuery);
#>>> copy text xtensions/snippets/responsive_navigation/select_menu.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
  <title></title>
  <!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
      <article class="hero clearfix">
        <div class="col_100">
          <h1>Simplest solution for your simple tasks</h1>
          <p>You don't always need to make difficult work of running management system with administrative panel to have a web site. “Simpliste” is a very simple and easy to use HTML template for web projects where you only need to create one or couple of pages with simple layout. If you are working on a lightweight information page with as less efforts for you to code and as less kilobytes  for the user to download as possible, “Simpliste” is what you need.</p>
          <p>No CMS required and it's free. Clean code will make your task even easier. HTML5 and CSS3 bring all their features for your future site. This template has skins which you can choose from. No images are used for styling.</p>
          <p>Are you worried about convenience of your site users with mobile devices? “Simpliste” responds to the width of user's device and makes information more accessible.</p>
        </div>
      </article>


      <article class="article clearfix">
        <div class="col_33">
          <h2>Clean code</h2>
          <p>HTML5 and CSS3 made live of web developers easier than ever. Welcome to the world where less code and less files required. “Simpliste” has different skins and all of them are created with no images for styling at all.</p>
          <p>Template contains CSS-reset based on the reset file from <a href="http://html5boilerplate.com/" target="_blank">HTML5 boilerplate</a> which makes appearens of “Simpliste” skins consistent in different browsers.</p>
          <p>Print styles and styles for mobile devices are already included in the stylesheet.</p>
        </div>

        <div class="col_33">
          <h2>Responsive markup</h2>
          <p>You know that now it's time to think more about your users with mobile devices. This template will make your site respond to your client's browser with no effort on your part.</p>
          <p>Multi-column layout becomes one column for viewers with tablets, navigation elements become bigger for users with smartphones. And your desktop browser users will see just a normal web site.</p>
          <p>Try changing the width of your browser window and you'll see how “Simpliste” works.</p>
        </div>

        <div class="col_33">
          <h2>Easy to use</h2>
          <p>“Simpliste” is not a template for a CMS. You can use its code right away after downloading without reading any documentation. Place your content, make customisations and voilà the site is ready to upload to the server.</p>
          <p>All content management can be done by using existing sample blocks and styles. Almost every template style is represented among <a href="#samples">samples</a> on this page. Off course you can create your own styles, which is easy as well.</p>
        </div>

        <div class="clearfix"></div>


        <h1>“Simpliste” in use</h1>

        <div class="col_50">
          <h2>Sample content</h2>

          <h3>Principles behind “Simpliste”</h3>
          <ul>
             <li>Really simple</li>
             <li>Has ready to use set of simple designs</li>
             <li>It's written using HTML5 and CSS3</li>
             <li>It responds to mobile devices</li>
             <li>No CMS</li>
             <li>Free</li>
          </ul>

          <h3>How to use?</h3>
          <form action="">
          <select name=skin onchange='reskin(this.form.skin);'>
          <option>default</option>
          <option>aim</option>
          <option>blackberry</option>
          <option>blue</option>
          <option>dark-blue</option>
          <option>fresh</option>
          <option>fruitjuice</option>
          <option>glimpse</option>
          <option>green</option>
          <option>humble</option>
          <option>illusion</option>
          <option>isimple</option>
          <option>liner</option>
          <option>maple</option>
          <option>mentol</option>
          <option>nightroad</option>
          <option>orange</option>
          <option>passion</option>
          <option>pink</option>
          <option>purple</option>
          <option>red</option>
          <option>simplesoft</option>
          <option>simpleswiss</option>
          <option>simploid</option>
          <option>snobbish</option>
          <option>solution</option>
          <option>stylus</option>
          <option>teawithmilk</option>
          <option>yellow</option>
          </select>
          </form>
          <script>
            function reskin(dropdown){
              var theIndex  = dropdown.selectedIndex;
              var theValue = dropdown.options[theIndex].value;
              var sheet  = "skin/" + theValue + ".css";
              document.getElementById('css_skin').setAttribute('href', sheet);
              return true;
            }
          </script>
          <ol>
             <li>Choose one skin from the list above</li>
             <li>Copy the file from the skin folder</li>
             <li>Rename it to skin.css</li>
             <li>Make any customisation you need</li>
          </ol>
        </div>

        <div class="col_50">
          <form action="#" method="post" class="form">
            <h2>Sample form</h2>

            <p class="col_50">
              <label for="name">Simple name:</label><br/>
              <input type="text" name="name" id="name" value="" />
            </p>
            <p class="col_50">
              <label for="email">Simple e-mail:</label><br/>
              <input type="text" name="email" id="email" value="" />
            </p>
            <div class="clearfix"></div>

            <h3>Your favorite number</h3>
            <p>
              <div class="col_33">
                <label for="radio-choice-1"><input type="radio" name="radio-choice-1" id="radio-choice-1" tabindex="2" value="choice-1" /> One</label><br/>
                <label for="radio-choice-2"><input type="radio" name="radio-choice-1" id="radio-choice-2" tabindex="3" value="choice-2" /> Two</label><br/>
                <label for="radio-choice-3"><input type="radio" name="radio-choice-1" id="radio-choice-3" tabindex="4" value="choice-3" /> Three</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-4"><input type="radio" name="radio-choice-1" id="radio-choice-4" tabindex="2" value="choice-1" /> Four</label><br/>
                <label for="radio-choice-5"><input type="radio" name="radio-choice-1" id="radio-choice-5" tabindex="3" value="choice-2" /> Five</label><br/>
                <label for="radio-choice-6"><input type="radio" name="radio-choice-1" id="radio-choice-6" tabindex="4" value="choice-3" /> Six</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-7"><input type="radio" name="radio-choice-1" id="radio-choice-7" tabindex="2" value="choice-1" /> Seven</label><br/>
                <label for="radio-choice-8"><input type="radio" name="radio-choice-1" id="radio-choice-8" tabindex="3" value="choice-2" /> Eight</label><br/>
                <label for="radio-choice-9"><input type="radio" name="radio-choice-1" id="radio-choice-9" tabindex="3" value="choice-2" /> Niine</label>
              </div>

            <div class="clearfix"></div>
            </p>

            <p>
              <label for="select-choice">Simple city:</label>
              <select name="select-choice" id="select-choice">
                <option value="Choice 1">London</option>
                <option value="Choice 2">Paris</option>
                <option value="Choice 3">Rome</option>
              </select>
            </p>

            <p>
              <label for="textarea">Simple testimonial:</label><br/>
              <textarea cols="40" rows="8" name="textarea" id="textarea"></textarea>
            </p>

            <p>
              <label for="checkbox"><input type="checkbox" name="checkbox" id="checkbox" /> Simple agreement</label><br/>
            </p>

            <div>
                <button type="button" class="button">Submit</button>
            </div>
          </form>
        </div>

        <div class="clearfix"></div>


        <div class="col_33">
          <h2>More elements</h2>

          <p>Use <code>strong</code> tag for information with <strong>strong importance</strong>. Use <code>em</code> tag to <em>stress emphasis</em> on a word or phrase.</p>

          <p class="warning">Sample <code>.warning</code></p>
          <p class="success">Sample <code>.success</code></p>
          <p class="message">Sample <code>.message</code></p>
        </div>

        <div class="col_66">
          <h2>CSS classes table</h2>

          <table class="table">
            <tr>
              <th>Class</th>
              <th>Description</th>
            </tr>

            <tr>
              <td><code>.col_33</code></td>
              <td>Column with 33% width</td>
            </tr>
            <tr>
              <td><code>.col_50</code></td>
              <td>Column with 50% width</td>
            </tr>
            <tr>
              <td><code>.col_66</code></td>
              <td>Column with 66% width</td>
            </tr>
            <tr>
              <td><code>.col_100</code></td>
              <td>Full width column with proper margins</td>
            </tr>
            <tr>
              <td><code>.clearfix</code></td>
              <td>Use after or wrap a block of floated columns</td>
            </tr>
            <tr>
              <td><code>.left</code></td>
              <td>Left text alignment</td>
            </tr>
            <tr>
              <td><code>.right</code></td>
              <td>Right text alignment</td>
            </tr>
            <tr>
              <td><code>.center</code></td>
              <td>Centered text alignment</td>
            </tr>
            <tr>
              <td><code>.img_floatleft</code></td>
              <td>Left alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img_floatright</code></td>
              <td>Right alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img</code></td>
              <td>Makes image change its width when browser window width is changed</td>
            </tr>
          </table>
        </div>

        <div class="clearfix"></div>

      </article>
      <!-- endsection primary -->
      <!-- section secondary -->
      <!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text xtensions/snippets/responsive_navigation/side_flyout.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
  <title></title>
  <!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
      <article class="hero clearfix">
        <div class="col_100">
          <h1>Simplest solution for your simple tasks</h1>
          <p>You don't always need to make difficult work of running management system with administrative panel to have a web site. “Simpliste” is a very simple and easy to use HTML template for web projects where you only need to create one or couple of pages with simple layout. If you are working on a lightweight information page with as less efforts for you to code and as less kilobytes  for the user to download as possible, “Simpliste” is what you need.</p>
          <p>No CMS required and it's free. Clean code will make your task even easier. HTML5 and CSS3 bring all their features for your future site. This template has skins which you can choose from. No images are used for styling.</p>
          <p>Are you worried about convenience of your site users with mobile devices? “Simpliste” responds to the width of user's device and makes information more accessible.</p>
        </div>
      </article>


      <article class="article clearfix">
        <div class="col_33">
          <h2>Clean code</h2>
          <p>HTML5 and CSS3 made live of web developers easier than ever. Welcome to the world where less code and less files required. “Simpliste” has different skins and all of them are created with no images for styling at all.</p>
          <p>Template contains CSS-reset based on the reset file from <a href="http://html5boilerplate.com/" target="_blank">HTML5 boilerplate</a> which makes appearens of “Simpliste” skins consistent in different browsers.</p>
          <p>Print styles and styles for mobile devices are already included in the stylesheet.</p>
        </div>

        <div class="col_33">
          <h2>Responsive markup</h2>
          <p>You know that now it's time to think more about your users with mobile devices. This template will make your site respond to your client's browser with no effort on your part.</p>
          <p>Multi-column layout becomes one column for viewers with tablets, navigation elements become bigger for users with smartphones. And your desktop browser users will see just a normal web site.</p>
          <p>Try changing the width of your browser window and you'll see how “Simpliste” works.</p>
        </div>

        <div class="col_33">
          <h2>Easy to use</h2>
          <p>“Simpliste” is not a template for a CMS. You can use its code right away after downloading without reading any documentation. Place your content, make customisations and voilà the site is ready to upload to the server.</p>
          <p>All content management can be done by using existing sample blocks and styles. Almost every template style is represented among <a href="#samples">samples</a> on this page. Off course you can create your own styles, which is easy as well.</p>
        </div>

        <div class="clearfix"></div>


        <h1>“Simpliste” in use</h1>

        <div class="col_50">
          <h2>Sample content</h2>

          <h3>Principles behind “Simpliste”</h3>
          <ul>
             <li>Really simple</li>
             <li>Has ready to use set of simple designs</li>
             <li>It's written using HTML5 and CSS3</li>
             <li>It responds to mobile devices</li>
             <li>No CMS</li>
             <li>Free</li>
          </ul>

          <h3>How to use?</h3>
          <form action="">
          <select name=skin onchange='reskin(this.form.skin);'>
          <option>default</option>
          <option>aim</option>
          <option>blackberry</option>
          <option>blue</option>
          <option>dark-blue</option>
          <option>fresh</option>
          <option>fruitjuice</option>
          <option>glimpse</option>
          <option>green</option>
          <option>humble</option>
          <option>illusion</option>
          <option>isimple</option>
          <option>liner</option>
          <option>maple</option>
          <option>mentol</option>
          <option>nightroad</option>
          <option>orange</option>
          <option>passion</option>
          <option>pink</option>
          <option>purple</option>
          <option>red</option>
          <option>simplesoft</option>
          <option>simpleswiss</option>
          <option>simploid</option>
          <option>snobbish</option>
          <option>solution</option>
          <option>stylus</option>
          <option>teawithmilk</option>
          <option>yellow</option>
          </select>
          </form>
          <script>
            function reskin(dropdown){
              var theIndex  = dropdown.selectedIndex;
              var theValue = dropdown.options[theIndex].value;
              var sheet  = "skin/" + theValue + ".css";
              document.getElementById('css_skin').setAttribute('href', sheet);
              return true;
            }
          </script>
          <ol>
             <li>Choose one skin from the list above</li>
             <li>Copy the file from the skin folder</li>
             <li>Rename it to skin.css</li>
             <li>Make any customisation you need</li>
          </ol>
        </div>

        <div class="col_50">
          <form action="#" method="post" class="form">
            <h2>Sample form</h2>

            <p class="col_50">
              <label for="name">Simple name:</label><br/>
              <input type="text" name="name" id="name" value="" />
            </p>
            <p class="col_50">
              <label for="email">Simple e-mail:</label><br/>
              <input type="text" name="email" id="email" value="" />
            </p>
            <div class="clearfix"></div>

            <h3>Your favorite number</h3>
            <p>
              <div class="col_33">
                <label for="radio-choice-1"><input type="radio" name="radio-choice-1" id="radio-choice-1" tabindex="2" value="choice-1" /> One</label><br/>
                <label for="radio-choice-2"><input type="radio" name="radio-choice-1" id="radio-choice-2" tabindex="3" value="choice-2" /> Two</label><br/>
                <label for="radio-choice-3"><input type="radio" name="radio-choice-1" id="radio-choice-3" tabindex="4" value="choice-3" /> Three</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-4"><input type="radio" name="radio-choice-1" id="radio-choice-4" tabindex="2" value="choice-1" /> Four</label><br/>
                <label for="radio-choice-5"><input type="radio" name="radio-choice-1" id="radio-choice-5" tabindex="3" value="choice-2" /> Five</label><br/>
                <label for="radio-choice-6"><input type="radio" name="radio-choice-1" id="radio-choice-6" tabindex="4" value="choice-3" /> Six</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-7"><input type="radio" name="radio-choice-1" id="radio-choice-7" tabindex="2" value="choice-1" /> Seven</label><br/>
                <label for="radio-choice-8"><input type="radio" name="radio-choice-1" id="radio-choice-8" tabindex="3" value="choice-2" /> Eight</label><br/>
                <label for="radio-choice-9"><input type="radio" name="radio-choice-1" id="radio-choice-9" tabindex="3" value="choice-2" /> Niine</label>
              </div>

            <div class="clearfix"></div>
            </p>

            <p>
              <label for="select-choice">Simple city:</label>
              <select name="select-choice" id="select-choice">
                <option value="Choice 1">London</option>
                <option value="Choice 2">Paris</option>
                <option value="Choice 3">Rome</option>
              </select>
            </p>

            <p>
              <label for="textarea">Simple testimonial:</label><br/>
              <textarea cols="40" rows="8" name="textarea" id="textarea"></textarea>
            </p>

            <p>
              <label for="checkbox"><input type="checkbox" name="checkbox" id="checkbox" /> Simple agreement</label><br/>
            </p>

            <div>
                <button type="button" class="button">Submit</button>
            </div>
          </form>
        </div>

        <div class="clearfix"></div>


        <div class="col_33">
          <h2>More elements</h2>

          <p>Use <code>strong</code> tag for information with <strong>strong importance</strong>. Use <code>em</code> tag to <em>stress emphasis</em> on a word or phrase.</p>

          <p class="warning">Sample <code>.warning</code></p>
          <p class="success">Sample <code>.success</code></p>
          <p class="message">Sample <code>.message</code></p>
        </div>

        <div class="col_66">
          <h2>CSS classes table</h2>

          <table class="table">
            <tr>
              <th>Class</th>
              <th>Description</th>
            </tr>

            <tr>
              <td><code>.col_33</code></td>
              <td>Column with 33% width</td>
            </tr>
            <tr>
              <td><code>.col_50</code></td>
              <td>Column with 50% width</td>
            </tr>
            <tr>
              <td><code>.col_66</code></td>
              <td>Column with 66% width</td>
            </tr>
            <tr>
              <td><code>.col_100</code></td>
              <td>Full width column with proper margins</td>
            </tr>
            <tr>
              <td><code>.clearfix</code></td>
              <td>Use after or wrap a block of floated columns</td>
            </tr>
            <tr>
              <td><code>.left</code></td>
              <td>Left text alignment</td>
            </tr>
            <tr>
              <td><code>.right</code></td>
              <td>Right text alignment</td>
            </tr>
            <tr>
              <td><code>.center</code></td>
              <td>Centered text alignment</td>
            </tr>
            <tr>
              <td><code>.img_floatleft</code></td>
              <td>Left alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img_floatright</code></td>
              <td>Right alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img</code></td>
              <td>Makes image change its width when browser window width is changed</td>
            </tr>
          </table>
        </div>

        <div class="clearfix"></div>

      </article>
      <!-- endsection primary -->
      <!-- section secondary -->
      <!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
#>>> copy text xtensions/snippets/responsive_navigation/toggle_menu.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link href="favicon.ico" rel="shortcut icon">
  <link rel="stylesheet" id="css_reset" href="reset.css">
  <link rel="stylesheet" id="css_skin" href="skin.css">
  <link rel="stylesheet" id="css_style" href="style.css">
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
  <!-- section meta -->
  <title></title>
  <!-- endsection meta -->
</head>

<body>
  <div class="container">

    <header class="header clearfix">
      <div class="logo">.Simpliste</div>

      <nav class="menu_main">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </header>


    <div class="info">
      <!-- section primary -->
      <article class="hero clearfix">
        <div class="col_100">
          <h1>Simplest solution for your simple tasks</h1>
          <p>You don't always need to make difficult work of running management system with administrative panel to have a web site. “Simpliste” is a very simple and easy to use HTML template for web projects where you only need to create one or couple of pages with simple layout. If you are working on a lightweight information page with as less efforts for you to code and as less kilobytes  for the user to download as possible, “Simpliste” is what you need.</p>
          <p>No CMS required and it's free. Clean code will make your task even easier. HTML5 and CSS3 bring all their features for your future site. This template has skins which you can choose from. No images are used for styling.</p>
          <p>Are you worried about convenience of your site users with mobile devices? “Simpliste” responds to the width of user's device and makes information more accessible.</p>
        </div>
      </article>


      <article class="article clearfix">
        <div class="col_33">
          <h2>Clean code</h2>
          <p>HTML5 and CSS3 made live of web developers easier than ever. Welcome to the world where less code and less files required. “Simpliste” has different skins and all of them are created with no images for styling at all.</p>
          <p>Template contains CSS-reset based on the reset file from <a href="http://html5boilerplate.com/" target="_blank">HTML5 boilerplate</a> which makes appearens of “Simpliste” skins consistent in different browsers.</p>
          <p>Print styles and styles for mobile devices are already included in the stylesheet.</p>
        </div>

        <div class="col_33">
          <h2>Responsive markup</h2>
          <p>You know that now it's time to think more about your users with mobile devices. This template will make your site respond to your client's browser with no effort on your part.</p>
          <p>Multi-column layout becomes one column for viewers with tablets, navigation elements become bigger for users with smartphones. And your desktop browser users will see just a normal web site.</p>
          <p>Try changing the width of your browser window and you'll see how “Simpliste” works.</p>
        </div>

        <div class="col_33">
          <h2>Easy to use</h2>
          <p>“Simpliste” is not a template for a CMS. You can use its code right away after downloading without reading any documentation. Place your content, make customisations and voilà the site is ready to upload to the server.</p>
          <p>All content management can be done by using existing sample blocks and styles. Almost every template style is represented among <a href="#samples">samples</a> on this page. Off course you can create your own styles, which is easy as well.</p>
        </div>

        <div class="clearfix"></div>


        <h1>“Simpliste” in use</h1>

        <div class="col_50">
          <h2>Sample content</h2>

          <h3>Principles behind “Simpliste”</h3>
          <ul>
             <li>Really simple</li>
             <li>Has ready to use set of simple designs</li>
             <li>It's written using HTML5 and CSS3</li>
             <li>It responds to mobile devices</li>
             <li>No CMS</li>
             <li>Free</li>
          </ul>

          <h3>How to use?</h3>
          <form action="">
          <select name=skin onchange='reskin(this.form.skin);'>
          <option>default</option>
          <option>aim</option>
          <option>blackberry</option>
          <option>blue</option>
          <option>dark-blue</option>
          <option>fresh</option>
          <option>fruitjuice</option>
          <option>glimpse</option>
          <option>green</option>
          <option>humble</option>
          <option>illusion</option>
          <option>isimple</option>
          <option>liner</option>
          <option>maple</option>
          <option>mentol</option>
          <option>nightroad</option>
          <option>orange</option>
          <option>passion</option>
          <option>pink</option>
          <option>purple</option>
          <option>red</option>
          <option>simplesoft</option>
          <option>simpleswiss</option>
          <option>simploid</option>
          <option>snobbish</option>
          <option>solution</option>
          <option>stylus</option>
          <option>teawithmilk</option>
          <option>yellow</option>
          </select>
          </form>
          <script>
            function reskin(dropdown){
              var theIndex  = dropdown.selectedIndex;
              var theValue = dropdown.options[theIndex].value;
              var sheet  = "skin/" + theValue + ".css";
              document.getElementById('css_skin').setAttribute('href', sheet);
              return true;
            }
          </script>
          <ol>
             <li>Choose one skin from the list above</li>
             <li>Copy the file from the skin folder</li>
             <li>Rename it to skin.css</li>
             <li>Make any customisation you need</li>
          </ol>
        </div>

        <div class="col_50">
          <form action="#" method="post" class="form">
            <h2>Sample form</h2>

            <p class="col_50">
              <label for="name">Simple name:</label><br/>
              <input type="text" name="name" id="name" value="" />
            </p>
            <p class="col_50">
              <label for="email">Simple e-mail:</label><br/>
              <input type="text" name="email" id="email" value="" />
            </p>
            <div class="clearfix"></div>

            <h3>Your favorite number</h3>
            <p>
              <div class="col_33">
                <label for="radio-choice-1"><input type="radio" name="radio-choice-1" id="radio-choice-1" tabindex="2" value="choice-1" /> One</label><br/>
                <label for="radio-choice-2"><input type="radio" name="radio-choice-1" id="radio-choice-2" tabindex="3" value="choice-2" /> Two</label><br/>
                <label for="radio-choice-3"><input type="radio" name="radio-choice-1" id="radio-choice-3" tabindex="4" value="choice-3" /> Three</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-4"><input type="radio" name="radio-choice-1" id="radio-choice-4" tabindex="2" value="choice-1" /> Four</label><br/>
                <label for="radio-choice-5"><input type="radio" name="radio-choice-1" id="radio-choice-5" tabindex="3" value="choice-2" /> Five</label><br/>
                <label for="radio-choice-6"><input type="radio" name="radio-choice-1" id="radio-choice-6" tabindex="4" value="choice-3" /> Six</label>
              </div>

              <div class="col_33">
                <label for="radio-choice-7"><input type="radio" name="radio-choice-1" id="radio-choice-7" tabindex="2" value="choice-1" /> Seven</label><br/>
                <label for="radio-choice-8"><input type="radio" name="radio-choice-1" id="radio-choice-8" tabindex="3" value="choice-2" /> Eight</label><br/>
                <label for="radio-choice-9"><input type="radio" name="radio-choice-1" id="radio-choice-9" tabindex="3" value="choice-2" /> Niine</label>
              </div>

            <div class="clearfix"></div>
            </p>

            <p>
              <label for="select-choice">Simple city:</label>
              <select name="select-choice" id="select-choice">
                <option value="Choice 1">London</option>
                <option value="Choice 2">Paris</option>
                <option value="Choice 3">Rome</option>
              </select>
            </p>

            <p>
              <label for="textarea">Simple testimonial:</label><br/>
              <textarea cols="40" rows="8" name="textarea" id="textarea"></textarea>
            </p>

            <p>
              <label for="checkbox"><input type="checkbox" name="checkbox" id="checkbox" /> Simple agreement</label><br/>
            </p>

            <div>
                <button type="button" class="button">Submit</button>
            </div>
          </form>
        </div>

        <div class="clearfix"></div>


        <div class="col_33">
          <h2>More elements</h2>

          <p>Use <code>strong</code> tag for information with <strong>strong importance</strong>. Use <code>em</code> tag to <em>stress emphasis</em> on a word or phrase.</p>

          <p class="warning">Sample <code>.warning</code></p>
          <p class="success">Sample <code>.success</code></p>
          <p class="message">Sample <code>.message</code></p>
        </div>

        <div class="col_66">
          <h2>CSS classes table</h2>

          <table class="table">
            <tr>
              <th>Class</th>
              <th>Description</th>
            </tr>

            <tr>
              <td><code>.col_33</code></td>
              <td>Column with 33% width</td>
            </tr>
            <tr>
              <td><code>.col_50</code></td>
              <td>Column with 50% width</td>
            </tr>
            <tr>
              <td><code>.col_66</code></td>
              <td>Column with 66% width</td>
            </tr>
            <tr>
              <td><code>.col_100</code></td>
              <td>Full width column with proper margins</td>
            </tr>
            <tr>
              <td><code>.clearfix</code></td>
              <td>Use after or wrap a block of floated columns</td>
            </tr>
            <tr>
              <td><code>.left</code></td>
              <td>Left text alignment</td>
            </tr>
            <tr>
              <td><code>.right</code></td>
              <td>Right text alignment</td>
            </tr>
            <tr>
              <td><code>.center</code></td>
              <td>Centered text alignment</td>
            </tr>
            <tr>
              <td><code>.img_floatleft</code></td>
              <td>Left alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img_floatright</code></td>
              <td>Right alignment for images in content</td>
            </tr>
            <tr>
              <td><code>.img</code></td>
              <td>Makes image change its width when browser window width is changed</td>
            </tr>
          </table>
        </div>

        <div class="clearfix"></div>

      </article>
      <!-- endsection primary -->
      <!-- section secondary -->
      <!-- endsection secondary -->
    </div>

    <footer class="footer clearfix">
      <div class="copyright">Keep it simplest</div>

      <nav class="menu_bottom">
        <ul>
          <li class="active"><a href="#">About</a></li>
          <li><a href="#">Skins</a></li>
          <li><a href="#">Samples</a></li>
        </ul>
      </nav>
    </footer>

  </div>
</body>
</html>
