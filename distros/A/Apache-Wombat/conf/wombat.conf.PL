# ripped off from LWP. Thanks!

use strict;
use warnings;

use Config;
use File::Basename qw(basename dirname);

chdir dirname $0;

(my $file = basename $0) =~ s/\.PL$//;
$file =~ s/\.pl$// if ($Config{'osname'} eq 'VMS' or
                       $Config{'osname'} eq 'OS2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";
chmod 0755, $file;

require '../.cfg';

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
#
# Sample Apache configuration file for Wombat
#
# Include this file into your httpd.conf with this directive:
#
#   Include $Apache::Wombat::cfg::apacheconfigfile
#
# These directives create an Apache::Wombat instance and configure it
# to handle requests for the Examples web application.
#

<IfModule mod_perl.c>

# Sometimes it's useful to locate your modules in directories that are
# not part of \@INC. If you set \$PERL5LIB in your environment (or
# apachectl script) before starting httpd, this directive will ensure
# that it's propagated to all mod_perl code.

  PerlPassEnv PERL5LIB

# Create, configure and start a Wombat server instance. This will
# break hard if Wombat can't find any of your server or application
# deployment descriptors, if they are incorrectly formatted, or if any
# of the classes specified in those files are not found.

  <Perl>
  unless (\$Apache::Server::Starting) {
     require Apache::Wombat;
     my \$home = '$Apache::Wombat::cfg::installdir';
     my \$config = '$Apache::Wombat::cfg::serverconfigfile';
     \$Apache::Wombat = Apache::Wombat->new(\$home, \$config);
  }
  </Perl>

# Make the the Examples webapp (from the wombat-webapps distribution)
# visible to Apache, mounting it in the /wombat-examples URI
# namespace. This corresponds to the following Wombat server.xml
# configuration:
#
#   Engine home:                   $Apache::Wombat::cfg::installdir
#   Host appBase:                  $Apache::Wombat::cfg::webappdir
#   Examples application docBase:  examples
#
# If you selected a different webapps directory, adjust these paths
# accordingly.

  Alias /wombat-examples $Apache::Wombat::cfg::fullwebappdir/examples

  <Location /wombat-examples>
    Options Indexes
    AllowOverride None
    Order allow,deny
    Allow from all
  </Location>

# Configure the Apache equivalent of the InvokerServlet servlet
# mapping in the Examples application. Note that if SSL is enabled,
# the standard SSL environment variables will be propagated to the
# Wombat server (which will cause it to look for a secure connector).

  <Location /wombat-examples/servlet>
    SetHandler perl-script
    PerlHandler \$Apache::Wombat->handler
    <IfDefine SSL>
      SSLOptions +StdEnvVars
    </IfDefine>
  </Location>

# Disallow access to WEB-INF and META-INF application subdirectories
# (META-INF isn't currently used but is still reserved). This is
# redundant with Wombat::Core::ApplicationValve's check, but it's
# better to head things off here before going almost all the way
# through Wombat processing.

  IndexIgnore WEB-INF META-INF
  <LocationMatch (WEB|META)-INF>
    deny from all
  </LocationMatch>

</IfModule>
!GROK!THIS!
