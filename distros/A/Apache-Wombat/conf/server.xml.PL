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
<!-- Wombat server configuration file -->

<!--
Component elements are nested corresponding to their parent-child
relationships with each other.
-->

<!--
A Server represents the entire perl interpreter, which may contain one
or more Services.

Note: a Server is not a Container, so you may not define subcomponents
such as Valves or Loggers at this level.
-->
<Server>

<!--
A Service is a collection of one or more Connectors that share a
single Container (and therefore the web applications visible within
that Container). Normally that container is an Engine, but this is not
required.

When embedding Wombat within Apache/mod_perl, only a single Service is
needed, using the Apache Connector and a standard Engine.

Note: a Service is not a Container, so you may not define
subcomponents such as Valves or Loggers at this level.
-->
  <Service>

<!--
A Connector represents an endpoint by which requests are received and
response are returned. Each Connector passes requests on to the
associated Container for processing.

By default, a non-secure Connector is enabled. You may also enable a
secure Connector by uncommenting the second Connector
entry. Apache::Wombat will refuse a request if the \$HTTPS
environment variable is set but no secure Connector is enabled.
-->
    <Connector className="Apache::Wombat::Connector"
               scheme="http"/>
<!--
    <Connector className="Apache::Wombat::Connector"
               scheme="https" secure="1"/>
-->

<!--
An Engine is the highest level container; it processes every
request. The Engine inspects the HTTP Host header and passes the
request along to the appropriate Host (virtual host).

The defaultHost attribute should be be the same value as the Apache
ServerName.
-->
    <Engine name="Apache-Wombat"
            defaultHost="localhost">

<!--
Unless overridden in a lower level Container, all log messages will be
handled by this Logger, which writes to the Apache ErrorLog.

The level attribute is usually set to INFO for a production server.

If you wish, you can try the experimental FileLogger support by
commenting out the first Logger and uncommenting the second one. Note
that this Logger is known to crash Apache.
-->
      <Logger className="Apache::Wombat::Logger"
              level="DEBUG"/>
<!--
      <Logger className="Apache::Wombat::FileLogger"
              filename="$Apache::Wombat::cfg::logfile"
              level="DEBUG"/>
-->

<!--
All Applications within this Engine will share the following Realm
unless it is overridden. The Realm may be enabled by configuring the
driver, connection, and schema information and uncommenting the
definition.
-->
<!--
      <Realm className="Wombat::Realm::DBIRealm"
             driverName="mysql"
             connectionName="test"
             connectionPassword="test"
             connectionURL="database=test"
             roleNameCol="rolename"
             userCredCol="password"
             userNameCol="username"
             userRoleTable="user_roles"
             userTable="users"/>
-->

<!--
All Applications within this Engine will share the following
SessionManager unless it is overridden. Note that the SessionManager
is not persistent and that a different session will be used for each
Application (single signon is not supported).

The maxInactiveInterval attribute specifies the number of seconds
after which an idle session is timed out (invalidated).

The cacheClass attribute specifies the name of the Cache::Cache implementation
class to use for the session cache.
-->
      <SessionManager maxInactiveInterval="300"
              cacheClass="Cache::SharedMemoryCache"
              className="Wombat::SessionManager::StandardSessionManager"/>

<!--
The default Host is used to handle requests for which the host
specified in the HTTP Host header is not configured. The Host inspects
the request URI and passes the request along to the appropriate
Application.

The name attribute should be be the same value as the Apache
ServerName.

The appBase attribute should either be specified as an absolute path
or relative to the Wombat installation directory. For example, if
Wombat is installed into /usr/local/wombat and the host's applications
are installed into /usr/local/wombat/webapps, then a value of
"webapps" is sufficient. However, if the host's applications are
installed into /usr/local/webapps, then the value of appBase must be
specified as "/usr/local/webapps".
-->
      <Host name="localhost"
            appBase="$Apache::Wombat::cfg::webappdir">
<!--
The Examples Application is distributed in the wombat-webapps
package. The Application inspects the request URI and passes the
request along to the appropriate Servlet.

The path attribute is specified as the URI base for this
Application. This value will be used as the Servlet API's context
path.

The docBase attribute should either be specified as an absolute path
or relative to the containing Host's appBase. The Application's
deployment descriptor is located in the WEB-INF subdirectory of the
docBase directory.
-->
        <Application displayName="Example Application"
                     path="/wombat-examples"
                     docBase="examples"/>
      </Host>
    </Engine>
  </Service>
</Server>
!GROK!THIS!
