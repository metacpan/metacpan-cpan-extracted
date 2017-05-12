package CGI::Kwiki::Style;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki';

CGI::Kwiki->rebuild if @ARGV and $ARGV[0] eq '--rebuild';

sub directory { 'css' }
sub suffix { '.css' }

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Style - Default Stylesheets for CGI::Kwiki

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

__Klassik__
body {
    background:#FFF;        
}

h1, h2, h3 {
    margin: 0px;
    padding: 0px;
    font-weight: bold;
}

#banner {
    width: 10%;
    float: left;
    font-size:x-large;
    font-weight:bold;
    background:#FFF;
}
    
#banner h1 { display: none; }
            
#content {
    float:left;
    width:510px;
    background:#FFF;
    margin-bottom:20px;
}

#links {
    background:#FFF;
    color:#CCC;
    margin-right:25%;
}
    
.blog {
    padding-left:15px;                    
    padding-right:15px;                    
}    

.blogbody {
    font-size:small;
    font-weight:normal;
    background:#FFF;
}

.blogbody a,
.blogbody a:link,
.blogbody a:visited,
.blogbody a:active,
.blogbody a:hover {
    font-weight: normal;
}

.title    { 
    font-size: small;
    color: #CCC;
}

div#content div.blog div.blogbody h2.title {
    font-size: xx-large;
    padding-bottom: 10px;
}

    
.date    { 
    display: none;
}            
    
.side {
    color:#CCC;
    font-size:x-small;
    font-weight:normal;
    background:#FFF;
}    

.sidetitle {
    display: none;
}        
#links .side { display: none; float: right; }
div#links div.side span a { display: inline }
div#links div.side span:after { content: " | " }
    
.powered {
    display: none;
}    
    
.posted    { 
    padding:3px;
    width:100%
}
    
.comments-head    { 
    background: lightgrey;
    padding:3px;
    width:100%
}        

div#content div.blogbody div.posted { font-size: medium; }
div#content div.comments-head { font-size: medium; }

div#content div.blog div.blogbody table tr th h2 { text-align:left; }
div#content div.blog div.blogbody table tr td.edit-by { text-align: center; }
div#content div.blog div.blogbody table tr td.edit-time { font-size: medium; }
span.blog-date h2.date {display: inline; }

div.blog-meta {
    background-color: #e0e0e0;
    width: 100%;
    padding: 0.5em;
    height: 1.5em;
}

span.blog-date { float:left; }
span.blog-title { float:right; }
span.description { display: none; }
div#content div.blog div.upper-nav { display: inline; }
div.blog h1 { display: block; padding-bottom:0.5em; }

div.slide-body div.blogbody div#banner {
    width: 96%;
    float: none;
    text-align: center;
    background-color: #C0FFC0;
    font-size: medium;
    padding: 0.5em;
    margin-left: 2%;
    margin-right: 2%;
    line-height: 100%;
}
div.slide-body div.blogbody { padding: 0; margin: 0; left:0; right:0 }
form.edit input { position: absolute; left: 3% }
form.admin input { position: absolute; left: 3% }
h2.comments-head { display: none }
div textarea { width: auto }
body.diff div.posted { display: none }
body.diff div.comments-head { display: none }
body.diff div.comments-body { display: none }
blockquote pre {
    background-color: #FFF;
    color: black;
    border: none;
}

/* ------------------------------------------------------------------- */

a         {text-decoration: none}
a:link    {color: #d64}
a:visited {color: #864}
a:hover   {text-decoration: underline}
a:active  {text-decoration: underline}
a.empty   {color: gray}
a.private {color: black}

.error    {color: #f00;}

pre {
    font-family: monospace;
    font-size: 13px;
    color: #EEE;
    background-color: #333;
    border: 1px dashed #EEE;
    padding: 2px;
    padding-left: 10px;
    margin-left: 30px;
    margin-right: 75px;
}

del {
    text-decoration: none;
    background-color: yellow;
    color: blue;
}
ins {
    text-decoration: none;
    background-color: lightgreen;
    color: blue;
}

.title,
.side,
.sidetitle {
    font-size: large;
}

.description,
.blogbody,
.date,
.comments-body,
.comments-post,
.comments-head {
    font-size: medium;
}

.posted {
    font-size: small;
}

.syndicate,
.powered {
    font-size: x-small;
}

table.changes {
    width: 100%;
    table-layout: fixed;
} /* fix width of table from RecentChange page */

table.changes td.page-id {
} /* do nothing to "Page-ID" cell from RecentChange table */

table.changes td.edit-by {
    text-align: right;
} /* make "Edit-By" cell from RecentChange table align to right */

table.changes td.edit-time {
    font-size: x-small;
} /* decrease font size of "Edit-Time" cell from RecentChange table */

div.side a { display: list-item; list-style-type: none }
div.upper-nav { display: none; }
.blog h1 { display: none; }
textarea { width: 100% }
body div#content div.blog div.blogbody h1 { display: inline; }
