package CGI::Kwiki::Javascript;
$VERSION = '0.15';
use strict;
use base 'CGI::Kwiki';

CGI::Kwiki->rebuild if @ARGV and $ARGV[0] eq '--rebuild';

sub directory { 'javascript' }
sub suffix { '.js' }

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Javascript - Default Javascript for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__Debug__
function xxx(x) {
    alert("Value is ->" + x + "<-")
}
__Display__
function gotoPage(page_id) {
    var url = "index.cgi?" + page_id
    document.location = url;
}

function editPage() {
    var myForm = document.getElementsByTagName("form")[2]
    myForm.submit()
}

function savePage() {
    var myForm = document.getElementsByTagName("form")[2]
    var mySave = myForm.getElementsByTagName("input")[2]
    mySave.checked = true
    myForm.submit()
}

function previewPage() {
    var myForm = document.getElementsByTagName("form")[2]
    var myPreview = myForm.getElementsByTagName("input")[3]
    myPreview.focus()
    myForm.submit()
}

function handleKey(e) {
    var key;
    if (e == null) {
        // IE
        key = event.keyCode
    } 
    else {
        // Mozilla
        if (e.altKey || e.ctrlKey) {
            return true
        }
        key = e.which
    }
    letter = String.fromCharCode(key).toLowerCase();
    switch(letter) {
        case "t": gotoPage(top_page); break
        case "?": gotoPage('KwikiHotKeys'); break
        case "h": gotoPage('KwikiHelpIndex'); break
        case "e": editPage(); break
        case "s": savePage(); break
        case "p": previewPage(); break
    }
}

document.onkeypress = handleKey
__Edit__
function setProtected(self) {
    if (self.checked) {
        var myForm = document.getElementsByTagName("form")[2]
        myForm.getElementsByTagName("input")[6].checked = true
    }
}

function setForDelete(self) {
    if (self.checked) {
        var myForm = document.getElementsByTagName("form")[2]
        myForm.getElementsByTagName("input")[5].checked = false
        myForm.getElementsByTagName("input")[6].checked = false
        myForm.getElementsByTagName("input")[7].checked = false
        myForm.getElementsByTagName("input")[8].checked = false
    }
}
__SlideShow__
function setControl(c) {
    var myForm = document.getElementsByTagName("form")[0]
    var myNum = myForm.getElementsByTagName("input")[0]
    myNum.value = c
    myForm.submit()
}

function gotoSlide(i) {
    var myForm = document.getElementsByTagName("form")[0]
    var myNum = myForm.getElementsByTagName("input")[1]
    myNum.value = i
    myForm.submit()
}

function nextSlide() {
    setControl('advance')
}

function prevSlide() {
    setControl('goback')
}

function handleKey(e) {
    var key;
    if (e == null) {
        // IE
        key = event.keyCode
    } 
    else {
        // Mozilla
        if (e.altKey || e.ctrlKey) {
            return true
        }
        key = e.which
    }
    switch(key) {
        case 8: prevSlide(); break
        case 13: nextSlide(); break
        case 32: nextSlide(); break
        case 49: gotoSlide(1); break
        case 113: window.close(); break
        default: //xxx(e.which)
    }
}

function handleMouseDown(e) {
    var button = e.which
    if (button == 1) {
        nextSlide()
    }
    else if (button == 3) {
        alert("You are on slide number $slide_num")
    }
    return false
}

document.onkeypress = handleKey
// document.onmousedown = handleMouseDown
document.onclick = nextSlide
document.ondblclick = prevSlide

__SlideStart__
function startSlides() {
    var myForm = document.getElementsByTagName("form")[2]
    var mySize = myForm.getElementsByTagName("select")[0]
    var myPage = myForm.getElementsByTagName("input")[2]
    var width = ""
    var height = ""
    var fullscreen = "no"
    switch(mySize.value) {
        case "640x480": width = "640"; height = "480"; break
        case "800x600": width = "800"; height = "600"; break
        case "1024x768": width = "1024"; height = "768"; break
        case "1280x1024": width = "1280"; height = "1024"; break
        case "1600x1200": width = "1600"; height = "1200"; break
        case "fullscreen": fullscreen = "yes"; break
    }
    myUrl = "index.cgi?action=slides&page_id=" + myPage.value
    myArgs = "fullscreen=" + fullscreen + ",height=" + height + ",width=" + width + ",location=no,menubar=no,scrollbars=yes,toolbar=no,resizable=no,titlebar=no"
    myTarget = "SlideShow"
    newWindow = open(myUrl, myTarget, myArgs)
    newWindow.focus()
}
