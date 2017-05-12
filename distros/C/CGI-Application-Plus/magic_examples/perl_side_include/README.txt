PERL SIDE INCLUDE EXAMPLE
=========================

The /www dir is the DocumentRoot site directory.

The files in this directory are 3 simple HTML files with some
labels inside. The files are directly linked toghether as they where
just static files. (In the '/www/index.html' file you can
see the links that are pointing to the other 2 files: they do not
point to any cgi-script.)

The '/www/.htaccess' file contains the Apache/mod_perl configuration
that instruct the server to use the MagicWebApp.pm as the perl
response handler, that parses the HTML files in the /www dir just
before they are served.

The /lib/MagicWebApp.pm is a sub class of Apache::Application::Magic
and define just the code needed to supply the run time values.
The Apache::Application::Magic super class will auto-magically
integrate that code with the HTML files, that will be filled with
the run time values.

As you see in the /lib/MagicWebApp.pm source, no run mode, no run method,
and no template management are involved in the code: all that is
auto-magically handled by the Apache::Application::Magic super class.


--
Domizio Demichelis <dd@4pro.net>
2004-01-19






