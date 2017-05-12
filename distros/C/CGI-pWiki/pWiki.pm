#!/usr/bin/perl

use 5.00503;
package CGI::pWiki;
use strict;
use URI::Escape qw(uri_escape uri_unescape);
use vars qw($VERSION); $VERSION = "0.15";

#------------------------------------------------------------------------------#

=pod

=head1 NAME

CGI::pWiki - Perl Wiki Environment

=head1 SYNOPSIS

 #!/usr/bin/perl
 use CGI::pWiki;
 use strict;
 my $pWiki = new CGI::pWiki()->server();
 0;

=head1 DESCRIPTION

The B<CGI::pWiki> class, is providing an environment for serving
a WikiWikiWeb for virtual hosts and multiple databases.

=head1 USAGE

=head2 Installation

At first install the CGI::pWiki module either on the CPAN,
or the Debian or by hand as usual with :

 perl Makefile.PL &&
      make &&
      make test &&
      su -c "make install"

First check your /etc/apache/httpd.conf for the system wide
ScriptAlias path and directory path.

 ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/

The pWiki distibution includes a pWiki.cgi to be symlinked
from your install point to your system wide cgi-bin directory.
 
 ln -s /usr/local/bin/pWiki.cgi /usr/lib/cgi-bin/

Next check your /etc/apache/httpd.conf to contain at least
those modules :

 LoadModule mime_module /usr/lib/apache/1.3/mod_mime.so
 LoadModule dir_module /usr/lib/apache/1.3/mod_dir.so
 LoadModule cgi_module /usr/lib/apache/1.3/mod_cgi.so
 LoadModule alias_module /usr/lib/apache/1.3/mod_alias.so
 LoadModule access_module /usr/lib/apache/1.3/mod_access.so
 LoadModule auth_module /usr/lib/apache/1.3/mod_auth.so
 LoadModule setenvif_module /usr/lib/apache/1.3/mod_setenvif.so
 LoadModule action_module /usr/lib/apache/1.3/mod_actions.so

Add a virtual host directive :

 NameVirtualHost *
 <VirtualHost *>
     ServerName test.copyleft.de
     DocumentRoot /var/www/test.copyleft.de
     DirectoryIndex index.wiki index.xml index.html index.htm index.text
     Action wiki-script /cgi-bin/pWiki.cgi
   # Some Apaches need the next line, also.
   # ErrorDocument 404 /cgi-bin/pWiki.cgi
   
     AddHandler wiki-script .wiki
     AddHandler wiki-script .text
     AddHandler wiki-script .html
     AddHandler wiki-script .htm
     AddHandler wiki-script .pod
     AddHandler wiki-script .xml
   # The next line should be in 127.0.0.1 virtual hosts, only !
   # AddHandler wiki-script .xsl
 </VirtualHost>

There is no need to add any handler besides B<.wiki> and B<.text>,
if you dont want to manage the other files with B<pWiki>.
Handling B<.xsl> files in fact opens a wide security hole, and should
B<NOT> be done outside a B<VirtualHost 127.0.0.1> environment.

=head2 Security

CGI::pWiki will offer users from outside to write files in the
document root of your webserver. It is therefore a possible
security hole. The minimal security is to constrain write access
by using the Unix C<chmod> command. e.g. :

 mkdir /var/www/test.copyleft.de
 echo "=location /open/index.wiki" /var/www/test.copyleft.de/index.wiki
 mkdir /var/www/test.copyleft.de/open
 touch /var/www/test.copyleft.de/open/index.wiki
 chmod a+w /var/www/test.copyleft.de/open
 chmod a+w /var/www/test.copyleft.de/open/index.wiki

This will create a document root for the test site, installs
a relocation of the index page, and creates an open area and
its index page, and makes it world writeable, while other
areas will stay read only.

A typical all public site for creating open content may want
to allow every directory to be writeable. Adopt the following
lines to migrate existing content.

 find /var/www/test.copyleft.de/ -print | xargs sudo chown kraehe.www-data
 find /var/www/test.copyleft.de/ -type d -print | xargs chmod 6775
 find /var/www/test.copyleft.de/ ! -type d -print | xargs chmod 664

You may want to restrict edit access to the Wiki as a webmaster
by defining a directory directive :

 <Directory /var/www/test.copyleft.de>
     AuthUserFile /usr/local/etc/test.copyleft.de.htpasswd
     AuthName "For Test Only"
     AuthType Basic
     <Limit POST>
         require valid-user
     </Limit>
 </Directory>

Or leave this as an option for .htaccess :

 AuthUserFile /usr/local/etc/test.copyleft.de.htpasswd
 AuthName "For Test Only"
 AuthType Basic
 <Limit POST>
     require valid-user
 </Limit>

=head2 First Test

You can now test the pWiki by reloading Apache. Create a directories
for your virtual host to contain a database called pWiki. The second
directory needs to be writeable by the webserver, as it contains the
shadow pages, if people change the content online.

 mkdir -p /var/www/test.copyleft.de/pWiki
 mkdir -p /var/lib/pWiki/test.copyleft.de/pWiki
 chmod a+w /var/lib/pWiki/test.copyleft.de/pWiki

Browse at your fresh created test site and enter the URL :

 http://test.copyleft.de/pWiki/index.wiki

This should show an edit window. Submit something like the following :

 This is a test for pWiki.

Click on the pWiki and submit the following :

 The CGI_pWiki Perl_Module is an Apache_Handler acting as a
 wrapper around a WikiWikiWeb for creating content in a
 [comunity] on the fly.

 Benefits : 

 * rapid content creation
 * easy formatting rules
 * multiple authors

 CGI_pWiki is able to handle the following extensions :

 | .html | normal hypertext pages |
 | .text | preformated text pages |
 | .wiki | pWiki formated hypertext pages |
 | .xml | XSL formated hypertext pages |
 | .pod | PlainOldDocumentation |

Ensure that there are no leading white space when cut and paste.

=head2 Adding Style

The CGI-pWiki distribution contains an example database.
Copy it to your document root :

 cp htdocs/pWiki/* /var/www/test.copyleft.de/pWiki/

The style is defined in pairs of files with B<.lnx> and B<.moz>
extension. Copy the pWiki/content.{lnx,moz}-exam files to your
document root and define the main table of contents.

=head2 METHODS

=over

=item new proto HASH

Creates a new pWiki object. Default options are passed as key-value
pairs or as a single hash. Options may be changed directly in the
object.

=head1 AUTHOR

 (c) 2002 GNU/GPL+Perl/Artistic Michael Koehne kraehe@copyleft.de

=head1 SEE ALSO

CGI

=cut

#------------------------------------------------------------------------------#

my $ESCAPE1 = '(&|<|>|"|--)';
my $ESCAPE2 = {
    '&'  => '&amp;',
    '<'  => '&lt;',
    '>'  => '&gt;',
    '"'  => '&quot;',
    '--' => '&#45;&#45;'
};
my $TEMPLATE= {
    'edit' => '<form action="%URL%?save" method="POST">
Edit: %TOPIC%<br>
<input type="submit" value="Submit" ><input type="reset" value="Reset">
<br><textarea name="text" wrap="virtual" rows="15" cols="80">
%TEXT%
</textarea></form>',
    'notfound' => '
<b>%TOPIC%</b> was not found in pWiki.<p>
This could be, because this page has moved,
or because nothing has been written yet.<p>

<form method="get" action="%URL%">
You may want to
<input type="submit" value="Search">
for
<input type="text" value="%TOPIC%" name="search" size="12"/>
</form>

<form action="%URL%?edit" method="POST">
<input type="hidden" value="%PATH% name="path">
You may want to
<input type="submit" value="Edit">
it now.
</form>
',
    'content' => '',
    'style' => '%HTML%'
};

#------------------------------------------------------------------------------#

sub new {
    my $proto = shift;
    my $self  = ($#_ == 0) ? { %{ (shift) } } : { @_ };
    my $class = ref($proto) || $proto;

    bless($self, $class);

    return $self;
}

sub server {
    my $self=shift;

       $self->parse_request;
    my $html = $self->translate;

    if ($html ne "") {
        print "Content-type: text/html\n\n";
        print $html;
    } else {
        $self->error("$self->{pt} not found");
    }
}

#------------------------------------------------------------------------------#

sub html {
    my $self = shift;

    $_ = $self->readfile($self->{pt});
    $self->{TITLE} = $1 if m!<title>(.+)</title>!i;
    $_ = $1 if m!<body[^>]*>(.+)</body>!is;

    return $_;
}

sub text {
    my $self = shift;

    $_ = "\n".$self->readfile($self->{pt});

    return "<font size=2><pre>$_</pre></font>";
}

sub wiki {
    my $self = shift;
    my $html = "";

    $_ = "\n".$self->readfile($self->{pt});

    # convert old wiki tags
    s!<wiki ([a-z]+)>!\n=$1\n!g;
    s!<wiki ([a-z]+)="([^"]+)"[^>]*>!\n=$1 $2\n!g;
    s!<wiki [^>]+>!!g;


    # handle paragraphs, lists and tables.
    foreach (split /\n\n+/) {
        next, if /^[ \t\n]*$/;
        $_ = "\n$_" unless /^\n/;
        chomp;
        $html .= $self->format_command($_), next
                if /^(\n=[^\n]+)+$/;
        $html .= $self->format_list($_), next
                if /^(\n[ \t]*[*-][^\n]+)+$/;
        $html .= $self->format_table($_), next
                if /^(\n[ \t]*[|][^\n]+[|][ \t]*)+$/;
        $html .= $self->format_verbatim($_), next
                if /^(\n[ \t]+[^\n]+)+$/;
        $html .= $self->format_ordinary($_);
    }

    return "<font size=4>$html</font>";
}

#------------------------------------------------------------------------------#

sub error {
    my $self = shift;
    my $reason = shift;

    print "Content-type: text/html\n\n";

    print "<code><pre>\n\n";
    print $reason,"\n";
    print "\n\n</pre><code>";

    foreach (keys %ENV) { print $_," = ",$ENV{$_},"<br>\n" };
    exit 0;
}

sub notfound {
    my $self = shift;

    return $self->template('notfound');
}

sub checkwrite {
    my $self = shift;

    my $file = $self->{pt};
    my $dir  = $self->{pt};
       $dir  =~ s!/[^/]*$!!;

    return "this should be a POST event" unless $self->{rm} eq "POST";

    return "<b>user $self->{ru} not authorized</b><p>"
        if $self->{ru} eq "unknown";
    return "<b>directory $dir not writeable</b><p>"
        unless -w $dir;
    return "<b>file $self->{pt} not writeable</b><p>"
        if -r $self->{pt} && ! -w $self->{pt};
    return "<b>file $self->{pt} contains slashdot</b>"
        if $self->{pt} =~ m!/[.]!;
    return "<b>file $self->{pt} contains funnychars</b>"
        unless $self->{pt} =~ m!^[a-zA-Z0-9_./-]+$!;

    return;
}

sub edit {
    my $self = shift;

    $_ = $self->checkwrite();
    return $_ if $_;

    $_ = $self->readfile($self->{pt});
    s/$ESCAPE1/$ESCAPE2->{$1}/geo;
    $self->{TEXT}=$_;

    return $self->template('edit');
}

sub save {
    my $self = shift;

    $_ = $self->checkwrite();
    return $_ if $_;

    if ($self->{VAL}->{text}) {
        $_ = $self->{VAL}->{text};
        s/\r//g;

	if (-f $self->{pt}) {
	    rename($self->{pt}, $self->{pt}.'~') unless -f $self->{pt}.'~';
	} else {
	    open OUT, ">$self->{pt}~"; print OUT "\n"; close OUT;
	}
        open OUT, ">$self->{pt}"; print OUT "$_\n"; close OUT;
    } else {
        $self->error("no text");
    }

    return $self->display();
}

sub search {
    my $self = shift;
    my $want = $self->{qs};
       $want =~ s/^search=//;
       $want = "pWiki" if $want eq "";
    my $html = "<h2>Search Results</h2>\nmatching: $want<p>\n";
    my $rslt = `find . -type f ! -name '*~' -print | fgrep -v /CVS/ | xargs egrep -iE '$want' 2>/dev/null`;
    my $hits;
    my $matches=0;

    SEARCHLOOP: foreach (split( /\n/, $rslt)) {
       my ($file,$str) = split /:/, $_, 2;
       $file =~ s/^\.//;
       $str =~ s/<[^>]+>//g;
       next SEARCHLOOP if $str =~ /^[ \t\r\n]*$/;
       my $qm = quotemeta $str;
       $hits->{$file} .= "$str<br>\n" if $hits->{$file} !~ m!$qm!;
    }

    $html .= "<ul>";
    foreach (sort keys %$hits) {
        $matches++;
        my $tag = $_;
        $tag =~ s!^\/!!;
        $tag =~ s![_/]! !g;
        $tag =~ s![.].*$!!;

        $html .= "<li><a href=\"$_\">$tag</a><br>\n$hits->{$_}";
    }
    $html .= "</ul>";

    $html .= "<p>... $matches matches  <b>search complete</b>." if ($matches);
    $html .= "<p>... <b>there are no matches</b>." if (! $matches);

    return $html;
}

sub diff {
    my $self = shift;

    my $html = "\n<h3>pWiki Diff</h3>\n<ul>\n";
    my $rslt = `find . -type f ! -name '*~' -print | fgrep -v /CVS/`;

    DIFFLOOP: foreach (split( /\n/, $rslt)) {
        my $file = $_; $file =~ s!^[.]/!!;
        my $path = $_; $path =~ s!^[.]!!;
        my $old  = $file."~";
        next DIFFLOOP unless -r $old;

        my $diff = `diff -p $old $file`;
           $diff =~ s/$ESCAPE1/$ESCAPE2->{$1}/geo;

        $html .= "<li><a href=\"$path\">$file</a><br>\n<pre>\n$diff\n</pre>";
    }
    $html .= "</ul>";

    return $html;
}

#------------------------------------------------------------------------------#

sub parse_request {
    my $self = shift;

    $self->{dr} = $ENV{DOCUMENT_ROOT}  || $self->error('DOCUMENT_ROOT not defined');
    $self->{hh} = $ENV{HTTP_HOST}      || $self->error('HTTP_HOST not defined');
    $self->{rm} = $ENV{REQUEST_METHOD} || $self->error('REQUEST_METHOD not defined');
    $self->{sn} = $ENV{SCRIPT_NAME}    || $self->error('SCRIPT_NAME not defined');
    $self->{ur} = $ENV{REQUEST_URI}    || $self->error('REQUEST_URI not defined');
    $self->{ru} = $ENV{REMOTE_USER}    || "unknown";
    $self->{ua} = ($ENV{HTTP_USER_AGENT} =~ /(links|lynx)/i);

    if ($ENV{PATH_INFO}) {
        $self->{pi}  = $ENV{PATH_INFO};
    } else {
        $self->{pi} = $self->{ur};
        $self->{pi} =~ s/\?.*//;
    }

    if ($ENV{QUERY_STRING}) {
        $self->{qs}  = $ENV{QUERY_STRING};
    } else {
        $self->{qs} = $self->{ur};
        $self->{qs} =~ s/^[^?]*\?//;
    }

    if ($ENV{PATH_TRANSLATED}) {
        $self->{pt}  = $ENV{PATH_TRANSLATED};
    } else {
        $self->{pt} = $self->{dr}.$self->{ur};
        $self->{pt} =~ s/\?.*//;
    }

    if ($self->{rm} eq "POST") {
        alarm(60);
        my $contlen = 0+$ENV{CONTENT_LENGTH};
           $contlen = 0 if ($contlen < 1);
        my $query;
        my $readlen = read(STDIN, $query, $contlen);
        alarm(0);

        $self->error("POST failed") if $readlen != $contlen;
        $self->{QUERY_BODY} = $query;

        $query =~ tr/+/ /;	# RFC1630
        my @parts = split(/&/, $query);

        $self->{VAL}={};
        foreach (@parts) {
            my ($key, $val) = split(/=/,$_,2);
            $val = (defined $val) ? uri_unescape($val) : '';
            $key = uri_unescape($key);
            $self->{VAL}->{$key} = $val;
        }

        if ($self->{VAL}->{path}) {
            $self->{pi} = $self->{VAL}->{path};
            $self->{pt} = $self->{dr}.$self->{VAL}->{path};
        }
        $self->{qs} = $self->{VAL}->{query} if $self->{VAL}->{query};
    }

    $self->error("no path info") unless $self->{pi};
    $self->error("no query string") unless $self->{qs};
    $self->error("no path translated") unless $self->{pt};
    $self->error("can not chdir to doc root") unless chdir $self->{dr};
    umask 000;
}

sub translate {
    my $self = shift;
    my $html;

    $self->{URL}   = "http://$self->{hh}$self->{pi}";
    $self->{SCR}   = "http://$self->{hh}$self->{sn}";
    $self->{PATH}  = $self->{pi};
    $self->{DIR}   = $self->{pi};
    $self->{DIR}   =~ s!/[^/]*$!!;
    $self->{DIR}   =~ s!^/!!;
    $self->{TOPIC} = $self->{pi};
    $self->{TOPIC} =~ s!^.*/!!;
    $self->{TOPIC} =~ s![.].*$!!;
    $self->{TOPIC} =~ s!_! !g;
    $self->{TITLE} = $self->{TOPIC};
    
    QUERYCASE: {
        $html = $self->error(),    last QUERYCASE if $self->{error};
        $html = $self->error(),    last QUERYCASE if $self->{qs} =~ /^error/;
        $html = $self->search(),   last QUERYCASE if $self->{qs} =~ /^search=/;
        $html = $self->diff(),     last QUERYCASE if $self->{qs} eq "diff";
        $html = $self->edit(),     last QUERYCASE if $self->{qs} eq "edit";
        $html = $self->save(),     last QUERYCASE if $self->{qs} eq "save";
        $html = $self->display();
    }

    $self->{HTML}  = $html;
    $self->{INDEX} = $self->template("content");

    return $self->template("style") || $self->{HTML};
}

sub display {
    my $self = shift;

    return $self->notfound() unless -r $self->{pt};
    return $self->html()     if $self->{pt} =~ /\.html$/;
    return $self->html()     if $self->{pt} =~ /\.htm$/;
    return $self->wiki()     if $self->{pt} =~ /\.wiki$/;
    return $self->wiki()     if $self->{pt} =~ /\.pod$/;
    return $self->xml()      if $self->{pt} =~ /\.xml$/;
    return $self->text();
}

sub readfile {
    my $self = shift;
    my $file = shift;

    if (-r $file) {
        my $oirs = $/;
        undef $/;
        open IN, $file;
        my $html = <IN>;
        close IN;
        $/ = $oirs;
        return $html;
    }
    return;
}

sub template {
    my $self = shift;
    my $temp = shift;
    my $file = $self->{ua} ? "$temp.lnx" : "$temp.moz";
    my $html = "";

    TEMPLCASE: {
        $html = $self->readfile("$self->{DIR}/$file"), last TEMPLCASE
            if -r "$self->{DIR}/$file";
        $html = $self->readfile("$self->{dr}/$file"), last TEMPLCASE
            if -r $file;
        $html = $self->readfile("pWiki/$file"), last TEMPLCASE
            if -r "pWiki/$file";
        $html = $TEMPLATE->{$temp} || "";
    }
    $html =~ s!%([A-Z]+)%!$self->{$1}!geo;

    return $html;
}

sub autolink {
    my ($self,$link) = @_;

    return $link if $link =~ /:$/; # oups ...

    $link =~ tr/[]//d;
    my $url = $link;
    my $tag = $link;

    if ($link =~ /(.*)[|](.*)/) {
        $url = $2;
        $tag = $1;
        $tag =~ s!_! !g;
        $url =~ s!::!-!g;
        $url .= ".pod" if $self->{pt} =~ /\.pod/;
    } else {
        $url =~ s!/".*!!g;
        $url =~ s!/!_!g if $self->{pt} =~ /\.wiki/;
        $url =~ s!/.*$!!g if $self->{pt} =~ /\.pod/;
        $url =~ s!:+!-!g;
        $url = "$self->{DIR}/$url" if $self->{DIR};
        $url = "/$url"             if $url !~ m!^/!;
        $tag =~ s!_! !g;

        EXTCASE: {
            $url .= ".wiki", last EXTCASE if -r $self->{dr}.$url.".wiki";
            $url .= ".text", last EXTCASE if -r $self->{dr}.$url.".text";
            $url .= ".html", last EXTCASE if -r $self->{dr}.$url.".html";
            $url .= ".htm",  last EXTCASE if -r $self->{dr}.$url.".htm";
            $url .= ".pod",  last EXTCASE if -r $self->{dr}.$url.".pod";
            $url .= ".xml",  last EXTCASE if -r $self->{dr}.$url.".xml";

            $_ = $self->{pt};
            m/\.([^.]+)$/;
            $url .= ".$1";
            $tag  = "?".$tag."?";
        }
    }

    return "<a href=\"$url\">$tag</a>";
}

sub expand {
    my $self = shift; my $cmd = shift; $_ = shift;

    s!([IBSCLFXE])<+(.*)!$self->expand($1,$2)!geo;

    return "<i>$_</i>" if $cmd eq "I";
    return "<b>$_</b>" if $cmd eq "B";
    return "<code>$_</code>" if $cmd =~ /[CFX]/;
    return $self->autolink($_) if $cmd eq "L";
    return "&".$_.";" if ($cmd eq "E") && /^[^0-9]/;
    return "\\0".$_   if ($cmd eq "E") && /^[0-9]/;

    s/ /&nbsp;/g if $cmd eq "S";

    return "$_";
}

sub wikify {
    my $self = shift; $_ = shift;

    s!([IBSCLFXE])<+([^>]+)>+!$self->expand($1,$2)!geo;
    s!([\n\t ])(\[[0-9A-Za-z_/:-]+\]|[A-Za-z0-9]+[A-Z_/:-][0-9A-Za-z_/:-]*)!$1.$self->autolink($2)!geo;

    return $_;
}

#------------------------------------------------------------------------------#

sub format_table {
    my $self = shift; $_ = $self->wikify(shift);

    s!^[ \t]*[|]!\n<tr><td>!g;
    s!\n[ \t]*[|]!\n<tr><td>!g;
    s![|][ \t]*$!</td></tr>\n!g;
    s![|][ \t]*\n!</td></tr>\n!g;
    s![|]!</td><td>!g;

    return "\n<table border=1>$_\n</table>\n";
}

sub format_list {
    my $self = shift; $_ = $self->wikify(shift);

    s!\n[ \t]*[*-] !\n<li>!g;

    return "\n<ul>$_\n</ul>\n";
}

sub format_ordinary {
    my $self = shift; $_ = $self->wikify(shift);

    s!\n[ \t]+!\n<br>!g;

    return "\n$_\n<p>\n";
}

sub format_verbatim {
    my $self = shift; $_ = shift;

    s/$ESCAPE1/$ESCAPE2->{$1}/geo;

    return "\n<pre>$_\n</pre>\n";
}

sub format_command {
    my $self = shift; $_ = shift;
    my $html = "";

    if (/\n=location (.+)/i) {
        print "Location: $1\n\n";
        exit 0;
    }
    s!([IBSCLFXE])<([^>]+)>!$self->expand($1,$2)!geo;

    $self->{TITLE} = $1              if /\n=title ([^\n]+)/i;
    $html .= "<h1>$1</h1>"           if /\n=head1 ([^\n]+)/i;
    $html .= "<h2>$1</h2>"           if /\n=head2 ([^\n]+)/i;
    $html .= "<h3>$1</h3>"           if /\n=head3 ([^\n]+)/i;
    $html .= "<dl>"                  if /\n=over.*/i;
    $html .= "<dt>$1</dt><dd>"       if /\n=item (.*)/i;
    $html .= "</dl>"                 if /\n=back.*/i;

    return $html;
}

#------------------------------------------------------------------------------#

1;
