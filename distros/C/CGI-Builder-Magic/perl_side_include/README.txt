PERL SIDE INCLUDE EXAMPLE
=========================

In order to run this example you Apache::CGI::Builder must be installed.

In this example you can appreciate how simple it can be
to parse all the '*.html' files in the '/www' dir with a magic
application that simply fills all the labels it finds in the files
with the run time values.

You can structure your dinamic site directory as it were simply
static files, easily linked toghether with any WYSIWYG editor.
This could be done by anyone able to use an HTML editor ;-)

In the '/www' directory  there are 3 html files linked as they
were just static files. In the '/www/index.html' file you can
see the links that are pointing to the other 2 files: they do not
point to any cgi-script.

The '/www/.htaccess' file contains the Apache/mod_perl configuration
that instruct the server to use the MagicWebApp.pm as the perl
response handler.

--
Domizio Demichelis <dd@4pro.net>
2004-02-18






