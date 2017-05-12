use strict;
use warnings;
use Test::More;
use CSS::Coverage;
use Data::Section -setup;

my $css = ${ __PACKAGE__->section_data('css') };
my $html = ${ __PACKAGE__->section_data('html') };

my $report = CSS::Coverage->new(
    css       => \$css,
    documents => [\$html],
)->check;

is_deeply(
    [$report->unmatched_selectors],
    [
        "ul#talks",
        "#talks .title a",
        "#talks .date",
        "#post #date",
        "#talk #date",
        "#talks li",
        "#talks .conference",
        "#about ul",
        "#about a",
        "#about li",
        "#projects ul",
        "#projects li",
        "#projects li a",
        "#projects li .name",
        "#projects li img.icon",
        "#projects li img.icon",
        "#projects li:hover img.icon",
        "#projects li .details",
        "#projects li:hover .details",
        "#post h1",
        "#talk h1",
        "#post h1",
        "#talk h1",
        "#post h2",
        "#talk h2",
        "#post h3",
        "#talk h3",
        "#post h4",
        "#talk h4",
        "#post h5",
        "#talk h5",
        "#post article",
        "#talk article",
        ".spoiler",
        ".spoiler:hover",
        "sup",
        "sub",
        "sup",
        "sub",
        ".code_snippet",
        "pre",
        ".code_snippet",
        ".code_snippet:hover",
        ".synComment",
        ".synConstant",
        ".synIdentifier",
        ".synStatement",
        ".synPreProc",
        ".synTodo",
        ".synSpecial",
        ".synType",
        "dt",
        "#talks .metadata",
        "#talk .metadata",
        "dd",
        "#slides",
        "#post",
        "#talk",
        "blockquote",
    ],
);

done_testing;

__DATA__
__[ css ]__
a {
    color: blue;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

nav {
    text-align: center;
    position: fixed;
    top: 0;
    left: 10px;
    width: 140px;
}

nav .sartak a {
    color: black;
}
nav h1, nav img, nav ul, nav li {
    margin: 0;
    padding: 0;
}
nav li {
    padding-bottom: 0.3em;
}
nav ul {
    list-style-type: none;
}
nav img {
    border: 0;
    border-radius: 17px;
}

#content {
    margin-left: 140px;
    width: 800px;
}

ul#posts, ul#talks {
    margin-top: 0;
    list-style-type: none;
}
#posts .title a, #talks .title a {
    font-size: 1.1em;
    line-height: 1.2em;
}
#posts .date, #talks .date, #post #date, #talk #date {
    float: right;
    color: #AAAAAA;
}
#posts .date {
    color: #AAAAAA;
    -webkit-transition: color 1s ease-out;
    -moz-transition: color 1s ease-out;
    -o-transition: color 1s ease-out;
    -ms-transition: color 1s ease-out;
    transition: color 1s ease-out;
}
#posts li:hover .date {
    color: #000000;
    -webkit-transition: color .25s;
    -moz-transition: color .25s;
    -o-transition: color .25s;
    -ms-transition: color .25s;
    transition: color .25s;
}
#posts li, #talks li {
    padding-bottom: 0.4em;
}
#talks .conference {
    font-size: 0.7em;
}

#about ul {
    list-style-type: none;
}
#about a {
    font-weight: bold;
    font-size: 1.3em;
}
#about li {
    margin-bottom: 1em;
}

#projects ul {
    list-style-type: none;
}
#projects li {
    display: inline-block;
    vertical-align: top;
    text-align: center;
    width: 228px;
    height: 228px;
}
#projects li a {
    text-decoration: none;
    color: black;
}
#projects li .name {
    font-weight: bold;
    display: block;
}

#projects li img.icon {
    height: 114px;
    width: 114px;
    border-radius: 20px;
}

#projects li img.icon {
    -webkit-filter: grayscale(80%) blur(1px);
    filter: grayscale(80%) blur(1px);
    border: 2px solid #333;

    -webkit-transition: all .25s ease-out;
    -moz-transition: all .25s ease-out;
    -o-transition: all .25s ease-out;
    -ms-transition: all .25s ease-out;
    transition: all .25s ease-out;
}
#projects li:hover img.icon {
    -webkit-filter: grayscale(0%) blur(0);
    filter: grayscale(0%) blur(0);
    border: 2px solid #000;
}
#projects li .details {
    opacity: 0.2;
    -webkit-transition: all .5s ease-out;
    -moz-transition: all .5s ease-out;
    -o-transition: all .5s ease-out;
    -ms-transition: all .5s ease-out;
    transition: all .5s ease-out;
}
#projects li:hover .details {
    opacity: 1;
}

#post h1, #talk h1 {
    margin: 0;
}

#post h1, #talk h1,
#post h2, #talk h2,
#post h3, #talk h3,
#post h4, #talk h4,
#post h5, #talk h5 {
    font-family: "Helvetica Neue", "Helvetica", "Arial", sans-serif;
}

#post article, #talk article {
    font-family: "Baskerville", "Georgia", serif;
    font-size: 1.2em;
}

.spoiler {
    color: black;
    background: black;
    padding: .1em;
}

.spoiler:hover {
    color: white;
}

sup, sub {
    height: 0;
    line-height: 1;
    vertical-align: baseline;
    position: relative;
}

sup {
    bottom: 1ex;
}

sub {
    top: .5ex;
}

.code_snippet, pre {
    font-family: "Consolas","Bitstream Vera Sans Mono","Courier New",Courier,monospace;
}

.code_snippet {
    width: 100%;
    color: #DDDDDD;
    background: black;
    -webkit-border-radius: 10px;
    -moz-border-radius: 10px;
    border-radius: 10px;
    padding: 1em 1em 1em 1em;
    overflow: hidden;
}
.code_snippet:hover {
    overflow: auto;
}

.synComment       { color: #DDDD00 }
.synConstant      { color: #DD0000 }
.synIdentifier    { color: #00DDDD }
.synStatement     { color: #B8860B }
.synPreProc       { color: #DD00DD } /* shebang */
.synTodo          {  } /* # XXX: */
.synSpecial       { color: #DD00DD } /* \n etc */
.synType          { color: #00DD00 } /* ctermbg in vimrc */
/*
.synUnderlined    { color: #FFFFFF ; text-decoration: underline }
.synError         { color: #FFFFFF }
*/

dt {
    font-size: 1.2em;
}
#talks .metadata, #talk .metadata {
    font-size: .8em;
}
dd {
    margin-bottom: 1em;
}

#slides {
    max-width: 500px;
    margin-left: auto;
    margin-right: auto;
}

#post, #talk {
    font-size: 1.1em;
}

.xyzzy {
    color: white;
}
.xyzzy:hover {
    color: blue;
}

blockquote {
    font-style: italic;
}

__[ html ]__
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />


        <title>sartak</title>
        <link rel="stylesheet" href="/style.css" type="text/css" />

        <link rel="apple-touch-icon" href="/img/apple-touch-icon.png" />

        <link rel="alternate" type="application/rss+xml" title="RSS" href="/rss.xml" />

        <meta property="og:image" content="http://sartak.org/img/sartak-100x100.jpg" />

        <meta http-equiv="x-xrds-location" content="http://sartak.myopenid.com/?xrds=1" />
        <link rel="openid.server"    href="http://www.myopenid.com/server" />
        <link rel="openid2.provider" href="http://www.myopenid.com/server" />
        <link rel="openid.delegate" href="http://sartak.myopenid.com/" />
        <link rel="openid2.local_id" href="http://sartak.myopenid.com" />
    </head>
    <body>
        <nav>
            <h1 class="sartak"><a href="/">sartak</a></h1>
            <a href="/"><img height="100" width="100" src="/img/sartak-100x100.jpg" /></a>
            <ul id="links">
                <li><a href="/">blog</a></li>
                <li><a href="/about.html">about</a></li>
                <li><a href="/projects.html">projects</a></li>
                <li><a href="/talks">talks</a></li>
                <li><a href="http://twitter.com/sartak">twitter</a></li>
                <li><a href="http://github.com/sartak">github</a></li>
                <li><a href="https://metacpan.org/author/SARTAK?sort=%5B%5B2%2C1%5D%5D">cpan</a></li>
                <li><a href="http://www.amazon.com/wishlist/28Z3PMAC42Z9F/ref=cm_wl_rlist_go?tag=533633855-20">wishlist</a></li>
                <li><a href="mailto:www@sartak.org">email</a></li>
                <li><a href="http://rpglanguage.net">RPGlanguage</a></li>
                <li><a class="xyzzy" href="http://github.com/sartak/sartak.org">fork me</a></li>
            </ul>
        </nav>
        <div id="content">
            <ul id="posts"><li>
    <span class="date">March 18, 2013</span>
    <span class="title"><a href="http://sartak.org/2013/03/reinstating-class-mops-commit-history-in-moose.html">Reinstating Class::MOP's Commit History in Moose</a></span>
</li><li>
    <span class="date">March 16, 2013</span>
    <span class="title"><a href="http://sartak.org/2013/03/marketing-101.html">Marketing 101</a></span>
</li><li>
    <span class="date">December 23, 2012</span>
    <span class="title"><a href="http://www.perladvent.org/2012/2012-12-23.html">Give and Receive the Right Number of Gifts</a> ⤴ </span>
</li><li>
    <span class="date">December 21, 2012</span>
    <span class="title"><a href="http://ox.iinteractive.com/advent/2012-12-21.html">OX off the Web</a> ⤴ </span>
</li><li>
    <span class="date">December 16, 2012</span>
    <span class="title"><a href="http://ox.iinteractive.com/advent/2012-12-16.html">Configuration with OX</a> ⤴ </span>
</li><li>
    <span class="date">August 31, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/08/moving-to-moose-hackathon.html">Mooseを利用するに変えるハッカソン</a></span>
</li><li>
    <span class="date">August 04, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/08/why-dragon-quest-never-took-off-in-america.html">Why Dragon Quest Never Took Off in America</a></span>
</li><li>
    <span class="date">July 28, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/07/my-study-calendar.html">My Study Calendar</a></span>
</li><li>
    <span class="date">June 22, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/06/roaming-elasticsearch.html">Roaming ElasticSearch</a></span>
</li><li>
    <span class="date">June 03, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/06/shake-to-pause.html">Shake to Pause</a></span>
</li><li>
    <span class="date">May 14, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/05/introducing-kanaswirl.html">Introducing KanaSwirl</a></span>
</li><li>
    <span class="date">March 02, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/03/near-miss-words.html">Near-Miss Words</a></span>
</li><li>
    <span class="date">February 24, 2012</span>
    <span class="title"><a href="http://gihyo.jp/dev/serial/01/perl-hackers-hub/001301">メタオブジェクトプロトコル入門</a> ⤴ </span>
</li><li>
    <span class="date">February 16, 2012</span>
    <span class="title"><a href="http://sartak.org/2012/02/how-many-sentences-teaches-a-word.html">How Many Sentences Teaches a Word?</a></span>
</li><li>
    <span class="date">December 21, 2011</span>
    <span class="title"><a href="http://perladvent.org/2011/2011-12-21.html">A Shortcut to Unicode</a> ⤴ </span>
</li><li>
    <span class="date">September 28, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/09/why-i-read-books-on-my-ipod.html">Why I Read Books on My iPod</a></span>
</li><li>
    <span class="date">September 20, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/09/todo-vim-ack.html">TODO? vim ♥ ack</a></span>
</li><li>
    <span class="date">August 01, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/08/july-2011.html">July 2011</a></span>
</li><li>
    <span class="date">July 08, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/07/ニートであることについての記述.html">ニートであることについての記述</a></span>
</li><li>
    <span class="date">March 01, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/03/end-of-line-whitespace-in-vim.html">End-of-Line Whitespace in Vim</a></span>
</li><li>
    <span class="date">January 24, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/01/interhack-and-taeb-postmortem.html">Interhack and TAEB Postmortem</a></span>
</li><li>
    <span class="date">January 11, 2011</span>
    <span class="title"><a href="http://sartak.org/2011/01/replace-a-lightweight-git-tag-with-an-annotated-tag.html">Replace a Lightweight Git Tag with an Annotated Tag</a></span>
</li><li>
    <span class="date">December 27, 2010</span>
    <span class="title"><a href="http://sartak.org/2010/12/installing-imager-file-gif-and-imager-file-jpeg-with-homebrew.html">Installing Imager::File::GIF and Imager::File::JPEG with homebrew</a></span>
</li><li>
    <span class="date">September 12, 2010</span>
    <span class="title"><a href="http://sartak.org/2010/09/頑張らなきゃ！.html">頑張らなきゃ！</a></span>
</li><li>
    <span class="date">September 11, 2010</span>
    <span class="title"><a href="http://sartak.org/2010/09/piggybacking-motivation.html">Piggybacking Motivation</a></span>
</li><li>
    <span class="date">August 22, 2010</span>
    <span class="title"><a href="http://sartak.org/2010/08/super-mario-world.html">Super Mario World</a></span>
</li><li>
    <span class="date">April 20, 2010</span>
    <span class="title"><a href="http://sartak.org/2010/04/learning-japanese-with-sentences.html">Learning Japanese with Sentences</a></span>
</li><li>
    <span class="date">January 01, 2010</span>
    <span class="title"><a href="http://sartak.org/2010/01/on-learning.html">On Learning</a></span>
</li><li>
    <span class="date">October 07, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/10/jiftys-request-inspector.html">Jifty's Request Inspector</a></span>
</li><li>
    <span class="date">September 30, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/09/google-wave-mania.html">Google Wave Mania</a></span>
</li><li>
    <span class="date">September 17, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/09/yapc-asia-2009-moose-course.html">YAPC::Asia 2009 Moose Course</a></span>
</li><li>
    <span class="date">June 28, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/06/reflections-on-yapc-na-2009.html">Reflections on YAPC::NA 2009</a></span>
</li><li>
    <span class="date">June 17, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/06/shawn-m-moose-at-yapc-na-2009.html">Shawn M Moose at YAPC::NA 2009</a></span>
</li><li>
    <span class="date">June 07, 2009</span>
    <span class="title"><a href="http://taeb-nethack.blogspot.com/2009/06/anatomy-of-step.html">Anatomy of a NetHack Step</a> ⤴ </span>
</li><li>
    <span class="date">May 12, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/05/the-design-of-parameterized-roles.html">The Design of Parameterized Roles</a></span>
</li><li>
    <span class="date">May 03, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/05/perl-critic-dynamic-moose.html">Perl::Critic::Dynamic::Moose</a></span>
</li><li>
    <span class="date">April 24, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/04/the-new-moose-warning-and-the-new-moose-critic.html">The New Moose Warning and the New Moose Critic</a></span>
</li><li>
    <span class="date">March 25, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/03/breaking-sys-protect.html">Breaking Sys::Protect</a></span>
</li><li>
    <span class="date">March 14, 2009</span>
    <span class="title"><a href="http://taeb-nethack.blogspot.com/2009/03/taeb-pubsub-and-announcements.html">TAEB, PubSub, and Announcements</a> ⤴ </span>
</li><li>
    <span class="date">March 02, 2009</span>
    <span class="title"><a href="http://taeb-nethack.blogspot.com/2009/03/predicting-and-controlling-nethacks.html">Predicting and Controlling NetHack's Randomness</a> ⤴ </span>
</li><li>
    <span class="date">January 17, 2009</span>
    <span class="title"><a href="http://sartak.org/2009/01/parametric-roles-in-perl-5.html">Parametric Roles in Perl 5</a></span>
</li><li>
    <span class="date">September 21, 2007</span>
    <span class="title"><a href="http://sartak.org/2007/09/devel-repl-now-with-multiline-support.html">Devel::REPL: Now with Multiline Support</a></span>
</li><li>
    <span class="date">January 27, 2007</span>
    <span class="title"><a href="http://taeb-nethack.blogspot.com/2013/06/solving-nethacks-mastermind.html">Solving NetHack's Mastermind</a> ⤴ </span>
</li></ul>
        </div>
        <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-21253667-1']);
        _gaq.push(['_setDomainName', '.sartak.org']);
        _gaq.push(['_setSiteSpeedSampleRate', 100]);
        _gaq.push(['_trackPageview']);
        (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();
        </script>
    </body>
</html>
