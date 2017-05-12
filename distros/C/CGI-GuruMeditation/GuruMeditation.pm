##
##  CGI::GuruMeditation -- Guru Meditation for CGIs
##  Copyright (c) 2004-2006 Ralf S. Engelschall <rse@engelschall.com>
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
##  USA, or contact Ralf S. Engelschall <rse@engelschall.com>.
##
##  GuruMeditation.pm: Module Implementation
##

package CGI::GuruMeditation;

require 5.006;
use strict;
use IO::File;

our $VERSION = '1.10';

our $option  = { -name => "", -debug => 0 };

sub configure {
    my (@args) = @_;

    if (@args >= 2 and (@args % 2) == 0) {
        $CGI::GuruMeditation::option = { %{$CGI::GuruMeditation::option}, @args };
    }
    elsif (@args == 1) {
        $CGI::GuruMeditation::option->{-name} = $args[0];
    }
}

sub import {
    my ($self, @args) = @_;

    #   parse parameters
    configure(@args);

    #   no operation outside CGI environments
    #   (usually either CGI/1.1 or CGI-Perl/1.1)
    return unless ($ENV{'GATEWAY_INTERFACE'} =~ m|^CGI|);

    #   setup termination handler
    $SIG{__DIE__} = sub {
        my ($msg) = @_;

        #   determine stack backtrace
        my $bt = [];
        if ($option->{-debug}) {
            for (my $i = 0; $i < 100; $i++) {
                my $caller = {}; @${caller}{qw(
                    -package -filename -line -subroutine -hasargs
                    -wantarray -evaltext -is_require -hints -bitmask
                )} = caller($i) or last;
                push(@{$bt}, $caller);
            }
        }

        #   fetch options from external variable
        my $option = $CGI::GuruMeditation::option;

        #   determine whether we are running under Apache/mod_perl
        my $mod_perl = 0;
        if (exists($ENV{'MOD_PERL'})) {
            $mod_perl = ($ENV{'MOD_PERL_API_VERSION'} ? $ENV{'MOD_PERL_API_VERSION'} : 1);
        }

        #   pass-through if exception is caught (via "eval" except for Apache/mod_perl)
        die @_ if ($^S and not $mod_perl);

        #   make sure we are not called multiple times
        $SIG{__DIE__} = 'IGNORE';

        #   helper function: properly escape characters for HTML inclusion
        sub escape_html {
            my ($txt) = @_;
            $txt =~ s/&/&amp;/sg;
            $txt =~ s/</&lt;/sg;
            $txt =~ s/>/&gt;/sg;
            $txt =~ s/\"/&quot;/sg;
            $txt =~ s/^[ \t]+//s;
            $txt =~ s/[ \t]+$//s;
            $txt =~ s/\r//sg;
            $txt =~ s/\n\n+/\n/sg;
            return $txt;
        }

        #   helper function: render mail address as simply scrambled HTML hyperlink
        sub html_url {
            my ($url, $link) = @_;
            my $html = $url;
            $html = escape_html($html);
            $html =~ s/@/<!-- XXX -->&#64;<!-- XXX -->/sg;
            $html =~ s/\./<!-- XXX -->&#46;<!-- XXX -->/sg;
            if ($link) {
                my $href = $url;
                $href =~ s/@/&#64;/sg;
                $href =~ s/\./&#46;/sg;
                $html = "<a href=\"mailto:$href\">$html</a>";
            }
            return $html;
        }

        #   helper function: calculate minimum number
        sub min {
            my ($a, $b) = @_;
            return ($a <= $b ? $a : $b);
        }

        #   determine title
        my $name = $ENV{'SCRIPT_FILENAME'} || "unknown";
        $name =~ s/^.*\/([^\/]+)$/$1/s;
        $name =~ s/\.[a-z0-9]{2,4}$//s;
        my @prog = split(//, $name);
        my $line = 0;
        if ($msg =~ m|line\s+(\d+)|) {
            $line = $1;
        }
        my $id = sprintf("#%02x%02x%02x%02x.%08d",
            ord($prog[0]), ord($prog[1]), ord($prog[2]), ord($prog[3]), $line);
        my $title =
            "Software Failure.&nbsp;&nbsp;Press browser RELOAD button to retry.<br/>\n" .
            "Guru Meditation $id\n";

        #   determine signature
        my $sig = "";
        if ($option->{-name}) {
            $sig .= "<b>" . &escape_html($option->{-name}) . "</b>";
        }
        else {
            $sig .= ($ENV{'SCRIPT_NAME'} || $0);
        }
        $sig .= " running under ";
        if (exists($ENV{'SERVER_ADMIN'}) and $ENV{'SERVER_ADMIN'} =~ m/^.+\@.+$/) {
            $sig .= "&lt;<b>" . html_url($ENV{'SERVER_ADMIN'}, 1) . "</b>&gt;'s ";
        }
        $sig .= "<br/>\n";
        if (exists($ENV{'SERVER_SOFTWARE'}) and $ENV{'SERVER_SOFTWARE'} ne '') {
            $sig .= "<b>" . escape_html($ENV{'SERVER_SOFTWARE'}) . "</b>";
        }
        $sig .= " at ";
        $sig .= sprintf("<b><a href=\"http://%s:%s/\">%s</a></b>:%s",
            $ENV{'SERVER_NAME'}, $ENV{'SERVER_PORT'},
            escape_html($ENV{'SERVER_NAME'}), escape_html($ENV{'SERVER_PORT'}));
        $sig .= "<br/>\n";
        $sig .= sprintf(" with <b>CGI::GuruMeditation %.2f</b> enabled.", $CGI::GuruMeditation::VERSION);

        #   determine optional debug information
        my $debug = '';
        if ($option->{-debug}) {
            #   determine stack backtrace
            my $backtrace = '';
            foreach my $frame (@{$bt}) {
                my $subroutine = &escape_html($frame->{-subroutine});
                $subroutine = "" if ($subroutine =~ m/^CGI::GuruMeditation::/);
                $subroutine = "sub <span class=\"hi\">$subroutine</span>" if ($subroutine);
                $backtrace .= sprintf(
                    "package <span class=\"hi\">%s</span> " .
                    "file <span class=\"hi\">%s</span> " .
                    "line <span class=\"hi\">%d</span> " .
                    "%s\n",
                    &escape_html($frame->{-package}), &escape_html($frame->{-filename}),
                    &escape_html($frame->{-line}), $subroutine
                );
            }

            #   determine source-code excerpt
            my $excerpt = '';
            if ($msg =~ m|\s+at\s+(.+)\s+line\s+(\d+)|) {
                my $file = $1;
                my $line = $2;
                my @code = ();
                my $io = new IO::File "<$file";
                if (defined($io)) {
                    @code = $io->getlines();
                    $io->close();
                }
                my $k = 2;
                my $l1 = $line-$k; $l1 = 1     if ($l1 < 1);
                my $l2 = $line+$k; $l2 = @code if ($l2 > @code);
                my $i = 0;
                $excerpt = join("", map {
                    $_ = escape_html($_);
                    s/^(.+)$/<span class="marker">$1<\/span>/ if ($i == $k);
                    s/^/sprintf("%d: ", $line - $k + $i)/se;
                    $i++;
                    $_;
                } @code[$l1-1..$l2-1]);
            }

            #   determine run-time environment
            my $env = '';
            foreach my $var (sort keys %ENV) {
                my $val = $ENV{$var};
                $val = escape_html($val);
                $val =~ s/\\/<span class="escaped">\\\\<\/span>/sg;
                $val =~ s/\n/<span class="escaped">\\n<\/span>/sg;
                $val =~ s/\r/<span class="escaped">\\r<\/span>/sg;
                $val =~ s/\t/<span class="escaped">\\t<\/span>/sg;
                $val =~ s/([^[:print:]])/sprintf("<span class=\"escaped\">\\x%02X<\/span>", ord($1))/sge;
                $env .= sprintf("%s=\"<span class=\"hi\">%s</span>\"\n", escape_html($var), $val);
            }

            #   determine run-time error message
            $msg = &escape_html($msg);
            $msg =~ s;^(.+)(\s+at\s+)(.+?)(\s+line\s+)(.+?)(\.?\r?\n?)$;
                "<span class=\"hi\">$1</span>$2<span class=\"hi\">$3</span>$4<span class=\"hi\">$5</span>$6"
            ;se;

            $debug = qq{
                <p/>
                <span class="debug">Perl Run-Time Error:</span><br/>
                <pre class="debug">$msg</pre>
                <p/>
                <span class="debug">Perl Run-Time Stack Backtrace:</span><br/>
                <pre class="debug">$backtrace</pre>
                <p/>
                <span class="debug">Perl Source-Code Excerpt:</span><br/>
                <pre class="debug">$excerpt</pre>
                <p/>
                <span class="debug">Perl Run-Time Environment:</span><br/>
                <pre class="debug">$env</pre>
            };
        }

        #   generate HTML page
        my $html = qq{
            <html>
              <head>
                <style type="text/css">
                  HTML {
                    width:            100%;
                    height:           auto;
                  }
                  BODY {
                    background:       #cccccc;
                    margin:           0 0 0 0;
                    padding:          0 0 0 0;
                  }
                  DIV.canvas {
                    background:       #000000;
                    border:           20px solid #000000;
                    background:       #000000;
                    color:            #ff0000;
                    font-family:      monospace;
                  }
                  DIV.error1 {
                    border-top:       6px solid #ff0000;
                    border-left:      6px solid #ff0000;
                    border-right:     6px solid #ff0000;
                    border-bottom:    6px solid #ff0000;
                    padding:          10px 10px 10px 10px;
                  }
                  DIV.error2 {
                    border-top:       6px solid #000000;
                    border-left:      6px solid #000000;
                    border-right:     6px solid #000000;
                    border-bottom:    6px solid #000000;
                    padding:          10px 10px 10px 10px;
                  }
                  DIV.title {
                    font-size:        150%;
                    font-weight:      bold;
                    text-align:       center;
                    width:            100%;
                  }
                  DIV.sig {
                    color:            #ff0000;
                    text-align:       center;
                  }
                  DIV.sig A {
                    color:            #ff0000;
                    text-decoration:  none;
                  }
                  DIV.sig A:link {
                    color:            #ff0000;
                    text-decoration:  none;
                  }
                  DIV.sig A:visited {
                    color:            #ff0000;
                    text-decoration:  none;
                  }
                  SPAN.debug {
                    font-size:        120%;
                    font-weight:      bold;
                    color:            #f0f0f0;
                  }
                  PRE.debug {
                    color:            #f0f0f0;
                    padding:          0px 0px 0px 20px;
                  }
                  PRE.debug SPAN.hi {
                    color:            #ffcc99;
                  }
                  PRE.debug SPAN.marker {
                    border:           1px solid #ff0000;
                    padding:          1px 2px 1px 2px;
                    color:            #ffcc99;
                  }
                  PRE.debug SPAN.escaped {
                    color:            #000000;
                    background-color: #cc9966;
                    padding:          0px 1px 0px 1px;
                    font-weight:      bold;
                  }
                </style>
                <script language="JavaScript">
                  var count = 0;
                  function blinker() {
                      var obj = document.getElementById('error');
                      if (count++ % 2 == 0)
                          obj.className = 'error1';
                      else
                          obj.className = 'error2';
                      setTimeout('blinker()', 680);
                  }
                </script>
                <title>Guru Meditation</title>
              </head>
              <body onLoad="setTimeout('blinker()', 1);">
                <div class="canvas">
                  <div id="error" class="error1">
                    <div class="title">$title</div>
                  </div>
                  <p/>
                  <div class="sig">$sig</div>
                  $debug
                </div>
              </body>
            </html>
        };

        #   post-process HTML page
        my $n = 99; $html =~ s/^(\s+)/$n = min($n, length($1)), $1/mge;
        $html =~ s/^\s{$n}//mg; # get rid of common indentation
        $html =~ s/^\s+//s;     # get rid of leading newline

        #   brain-dead MSIE won't display a custom 500 response unless it is >512 bytes!
        if ($ENV{'HTTP_USER_AGENT'} =~ /MSIE/) {
            $html .= "<!-- " . ('X' x 512) . " -->\n";
        }

        #   generate HTTP response
        my $http = "";
        if ($mod_perl) {
            my $r;
            if ($mod_perl >= 2) {
                require Apache2::RequestRec;
                require Apache2::RequestIO;
                require Apache2::RequestUtil;
                require APR::Pool;
                require ModPerl::Util;
                require Apache2::Response;
                $r = Apache2::RequestUtil->request;
            }
            else {
                $r = Apache->request;
            }
            if (not $r->bytes_sent) {
                $r->status(500);
                $r->header_out("Expires", "0");
                $r->no_cache(1);
                $r->content_type("text/html; charset=ISO-8859-1");
                $r->send_http_header();
            }
            $r->print($html);
            if ($mod_perl >= 2) {
                ModPerl::Util::exit(0);
            }
            else {
                $r->exit();
            }
        }
        else {
            $|++;
            my $bytes_sent = eval { tell STDOUT };
            if (not (defined($bytes_sent) && $bytes_sent > 0)) {
                print STDOUT
                    "Status: 500 Internal Server Error\n" .
                    "Expires: 0\n" .
                    "Cache-Control: no-cache\n" .
                    "Pragma: no-cache\n" .
                    "Content-Type: text/html; charset=ISO-8859-1\n" .
                    "\n";
            }
            print STDOUT $html;
            exit(0);
        }
    };
}

1;

__END__

=pod

=head1 NAME

B<CGI::GuruMeditation> -- Guru Meditation for CGIs

=head1 SYNOPSIS

=over 2

=item B<use CGI;>

=item B<use CGI::GuruMeditation> [I<options>]B<;>

=item B<CGI::GuruMeditation::configure(>I<options>B<);>

=back

=head1 DESCRIPTION

This is a small module accompanying the B<CGI> module, providing the
display of an error screen (somewhat resembling the classical
red-on-black blinking I<Guru Meditation> from the good-old AmigaOS
before version 2.04) in case of abnormal termination of a CGI.

The module simply installs a C<$SIG{__DIE__}> handler which sends
a HTTP response showing a HTML/CSS based screen which optionally includes the
Perl run-time error message, an excerpt from the CGI source code
and the Perl run-time environment variables. This provides both
optically more pleasant and functionally more elaborate error
messages for CGIs.

This module supports both the regular CGI and the Apache/mod_perl CGI
environment.

=head1 OPTIONS

The following I<options> can be passed either during module importing
or with the B<configure> function:

=over 4

=item B<-name =E<gt> >I<name>

Set an explicit name for the CGI application. Default is
derived from CGI environment variable C<SCRIPT_FILENAME>.
This is disabled for identification reasons in the
error screen signature text.

=item B<-debug =E<gt> 0>|B<1>

Enables (B<1>) or disables (B<0>) debugging informations
like the run-time error message, the source-code excerpt and
the run-time environment variables.

=back

=head1 HISTORY

This small module actually was a quick hack and proof of concept during
the development of B<OSSP quos> in 2004. It was later found useful and reusable
enough for other CGIs and encapsulated into a stand-alone module. It was
worked-off in July 2006 to support Apache/mod_perl, configuration options, debug
information, etc. In September 2006 run-time stack backtrace information was
added and the visual appearance further improved.

=head1 AUTHOR

Ralf S. Engelschall E<lt>rse@engelschall.comE<gt>

=head1 CAVEAT

Under the Apache/mod_perl CGI environment I<compile-time> errors
cannot be catched due to the design of mod_perl and its use
of the Perl C<eval> construct.

=head1 SEE ALSO

B<CGI>, B<CGI::Carp>.

http://en.wikipedia.org/wiki/Guru_meditation

=cut

